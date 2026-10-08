using Cookly.Agents.Agents;
using Cookly.Agents.Tools;
using Cookly.Business.IServices;
using Cookly.Business.Services;
using Cookly.Data.DTOS;
using Cookly.Data.enums;
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.AI;

namespace Cookly.Api.Endpoints;

[ApiController]
[Authorize]
[Route("meal-plan")]
public class AgentController(IConversationStateStore conversationStateStore, IChatClient chatClient, 
    InventoryAgent _inventoryAgent,NutritionAgent _nutritionAgent,CookAgent _cookAgent,
    UserService _userService, MealPlanContext _mealPlan) : ControllerBase
{
    private const int ExpiryWindowDays = 3;

    private static List<PantryItem> GetDummyPantryItems()
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        return new()
        {
            new("Milk", today.AddDays(1)),
            new("Spinach", today.AddDays(2)),
            new("Yogurt", today.AddDays(3)),
            new("Chicken Breast", today.AddDays(5)),
            new("Rice", today.AddDays(60)),
        };
    }

    /// <summary>
    /// Handoff orchestration: InventoryAgent -&gt; NutritionAgent -&gt; CookAgent, each restricted to a
    /// single handoff target so the flow still runs in that fixed order. Unlike sequential
    /// orchestration, Handoff pauses for free-form user input whenever an agent responds without
    /// handing off — that's how InventoryAgent asks "should I remove these?" and gets a plain-text
    /// reply instead of a structural yes/no. NutritionAgent gets autonomous mode as a safety net so
    /// a missed handoff call doesn't wrongly surface as a question to the user.
    /// </summary>
    private Workflow BuildWorkflow()
    {
        /*var inventoryTools = new InventoryTools();
        var nutritionTools = new NutritionTools();*/

        // Explicit, stable Ids: BuildWorkflow() runs fresh on every request, and Handoff routing
        // depends on matching agent identities across runs (see Microsoft's own note on
        // Rehydrating from Checkpoints).
        /*ChatClientAgent inventoryAgent = new(chatClient, new ChatClientAgentOptions
        {
            Id = InventoryAgentId,
            Name = "InventoryAgent",
            Description = "Reviews pantry inventory, asks the user about expired or expiring items, and removes what they approve",
            ChatOptions = new ChatOptions
            {
                Instructions =
                    "You are an inventory manager for a home kitchen. Follow this procedure:\n" +
                    "1. Call CheckExpiredItems and CheckExpiringSoonItems.\n" +
                    "2. If both return no items, skip straight to step 4.\n" +
                    "3. Otherwise, tell the user exactly which items are expired or expiring soon " +
                    "(with days left for the expiring ones) and ask which, if any, they'd like you " +
                    "to remove. Do not call RemoveInventoryItem yet, and do not hand off yet — end " +
                    "your turn here and wait for their reply.\n" +
                    "   When the user replies, match what they said against the item names you " +
                    "listed and call RemoveInventoryItem once for each item they asked to remove — " +
                    "call it multiple times in the same turn if they named multiple items. Pass only " +
                    "the bare item name as it appears in the pantry, e.g. \"Milk\" — never include " +
                    "the \"(N days left)\" annotation in the itemName argument, that will fail to " +
                    "match. If they said not to remove anything, or named only some items, respect " +
                    "that exactly; never remove an item they didn't mention.\n" +
                    "4. Call ListPantryItems to get the accurate, complete list of what remains " +
                    "(it includes items you never checked for expiry, like long-shelf-life staples " +
                    "— don't rely on memory or guesswork for this). Hand off to NutritionAgent with " +
                    "that exact list as the final pantry contents, plus anything you flagged but the " +
                    "user chose to keep.",
                Tools =
                [
                    AIFunctionFactory.Create(inventoryTools.CheckExpiredItems),
                    AIFunctionFactory.Create(inventoryTools.CheckExpiringSoonItems),
                    AIFunctionFactory.Create(inventoryTools.RemoveInventoryItem),
                    AIFunctionFactory.Create(inventoryTools.ListPantryItems),
                ],
            },
        });*/

        /*
        ChatClientAgent nutritionAgent = new(chatClient, new ChatClientAgentOptions
        {
            Id = NutritionAgentId,
            Name = "NutritionAgent",
            Description = "Suggests a meal based on goals, preferences, and available ingredients",
            ChatOptions = new ChatOptions
            {
                Instructions =
                    "You are a nutrition planner. Look up the user's goals and preferences with " +
                    "your tool, then call ListPantryItems yourself to see the exact, current pantry " +
                    "contents — do not trust InventoryAgent's summary alone, confirm it with the " +
                    "tool. Suggest a single meal that can be made using ONLY items from that exact " +
                    "list. Do not add, assume, or suggest any ingredient that isn't in the list — " +
                    "no extra vegetables, spices, oil, salt, or staples unless they literally appear " +
                    "in ListPantryItems' output.\n" +
                    "   Treat that list as complete and certain: anything not on it — salt, oil, " +
                    "spices, condiments, anything — is a known fact to be absent from this kitchen, " +
                    "not a maybe. Never write hedging phrases like \"if available\" or \"if you have " +
                    "it\" about an unlisted ingredient; just don't mention it. If the available items " +
                    "don't add up to an ideal meal, suggest the simplest reasonable preparation of " +
                    "only what's there. Always hand off to CookAgent once you've suggested a meal, " +
                    "naming exactly which pantry items it uses.",
                Tools =
                [
                    AIFunctionFactory.Create(nutritionTools.GetUserGoalsAndPreferences),
                    AIFunctionFactory.Create(inventoryTools.ListPantryItems),
                ],
            },
        });*/

        /*ChatClientAgent cookAgent = new(chatClient, new ChatClientAgentOptions
        {
            Id = CookAgentId,
            Name = "CookAgent",
            Description = "Produces ingredients and cooking instructions",
            ChatOptions = new ChatOptions
            {
                Instructions =
                    "You are a cooking assistant. First call ListPantryItems yourself and start " +
                    "your response with 'Remaining pantry items: ' followed by that exact list. " +
                    "Then produce the ingredient list and step-by-step cooking instructions for the " +
                    "meal NutritionAgent suggested, using ONLY items from that pantry list — do not " +
                    "include any ingredient, spice, oil, or staple that isn't literally in the " +
                    "pantry list, even if a normal recipe would call for it.\n" +
                    "   Treat the ListPantryItems result as complete and certain, not a guess: you " +
                    "know for a fact that anything not on it — salt, oil, butter, spices, water, " +
                    "vegetables, condiments, anything — is NOT in this kitchen. Never write hedging " +
                    "phrases like \"if available\", \"if you have\", \"assuming you have\", \"you " +
                    "might have\", or \"or if not\" about an unlisted ingredient — that treats a " +
                    "known fact as a maybe. Simply omit that step or ingredient entirely, as if it " +
                    "never crossed your mind, exactly like you'd never mention using a blender that " +
                    "was never mentioned as being in the kitchen. If skipping unlisted staples " +
                    "changes how the dish is cooked (e.g. no oil means dry-cooking, no salt means " +
                    "unseasoned), just cook it that way without commenting on the missing ingredient. " +
                    "If NutritionAgent's suggestion relies on something not in the pantry, drop it " +
                    "and adapt the dish to what's actually available.",
                Tools = [AIFunctionFactory.Create(inventoryTools.ListPantryItems)],
            },
        });*/

        return AgentWorkflowBuilder.CreateHandoffBuilderWith(_inventoryAgent.inventoryAgent)
            .WithHandoffs(_inventoryAgent.inventoryAgent, [_nutritionAgent.nutritionAgent])
            .WithHandoffs(_nutritionAgent.nutritionAgent, [_cookAgent.cookAgent])
            .Build();
        
    }

    [HttpPost("start")]
    public async Task<IActionResult> StartMealPlan([FromBody] StartMealPlanRequest request)
    {
        if (request.MealType is not { } mealType || !Enum.IsDefined(mealType))
            return BadRequest(new { message = "mealType is required: 1 (Breakfast), 2 (Lunch) or 3 (Dinner)." });

        var userId = _userService.GetUserId();
        if (userId <= 0)
            return Unauthorized();

        var runId = Guid.NewGuid().ToString();

        List<ChatMessage> messages =
        [
            new(ChatRole.User,
                $"Plan my {mealType} from my pantry. Review the inventory, handle any expired or " +
                $"expiring items, then suggest a new {mealType} meal and prepare cooking instructions."),
        ];

        return await RunTurnAsync(runId, new ConversationState(userId, mealType, messages));
    }

    [HttpPost("{runId}/respond")]
    public async Task<IActionResult> RespondToMealPlan(string runId, [FromBody] RespondToMealPlanRequest request)
    {
        var state = await conversationStateStore.LoadAsync(runId);
        // Same response for "not found" and "someone else's run" so run ids can't be probed.
        if (state is null || state.UserId != _userService.GetUserId())
            return NotFound(new { message = "No pending run found for this runId." });

        state.Messages.Add(new ChatMessage(ChatRole.User, request.Message));

        return await RunTurnAsync(runId, state);
    }

    /// <summary>
    /// Runs one Handoff turn to its natural pause: either an agent finishing without handing off
    /// (the workflow just ends — no RequestInfoEvent, unlike tool approval) or CookAgent completing
    /// the pipeline. <paramref name="messages"/> is the full running conversation; the caller
    /// supplies it fresh each turn since Handoff has no mid-turn checkpoint to resume from here.
    /// </summary>
    private async Task<IActionResult> RunTurnAsync(string runId, ConversationState state)
    {
        _mealPlan.MealType = state.MealType;
        var messages = state.Messages;

        StreamingRun run = await InProcessExecution.RunStreamingAsync(BuildWorkflow(), messages);
        await run.TrySendMessageAsync(new TurnToken(emitEvents: true));

        string? lastAuthorName = null;
        List<ChatMessage> finalMessages = [];

        await foreach (WorkflowEvent evt in run.WatchStreamAsync())
        {
            if (evt is AgentResponseUpdateEvent update)
            {
                // ExecutorId is a compound "{Name}_{id-with-underscores}" string, not the plain Id
                // set on ChatClientAgentOptions — AuthorName is the reliable way to tell which
                // agent produced the latest response.
                lastAuthorName = update.Update.AuthorName;
            }
            else if (evt is WorkflowOutputEvent outputEvt && outputEvt.As<List<ChatMessage>>() is { } newMessages)
            {
                finalMessages = newMessages;
                break;
            }
            else if (evt is ExecutorFailedEvent failedEvt)
            {
                return StatusCode(500, new
                {
                    runId,
                    status = "failed",
                    executorId = failedEvt.ExecutorId,
                    error = failedEvt.Data?.ToString(),
                });
            }
        }

        messages.AddRange(finalMessages.Skip(messages.Count));

        if (_mealPlan.RefillRequired)
        {
            await conversationStateStore.RemoveAsync(runId);
            var items = _mealPlan.SuggestedItemsToBuy;
            var message = $"There is no new meal to suggest for this {state.MealType}. " +
                          "Please refill your inventory with sufficient items." +
                          (items.Count > 0 ? $" Suggested items to buy: {string.Join(", ", items)}." : "");
            return Ok(new { runId, status = "refill_required", message, suggestedItems = items });
        }

        if (lastAuthorName == "CookAgent")
        {
            await conversationStateStore.RemoveAsync(runId);
            return Ok(new { runId, status = "completed", result = messages.LastOrDefault()?.Text });
        }

        await conversationStateStore.SaveAsync(runId, state);
        return Ok(new { runId, status = "needs_user_input", message = messages.LastOrDefault()?.Text });
    }
}

public record RespondToMealPlanRequest(string Message);

public record StartMealPlanRequest(Meal? MealType);
