using Cookly.Agents.Agents;
using Cookly.Agents.Tools;
using Cookly.Business.IServices;
using Microsoft.Agents.AI.Workflows;
using Microsoft.Extensions.AI;

namespace Cookly.Api.Services;

public record MealPlanStreamEvent(string Type, object Data);

/// <summary>
/// Runs one meal-plan Handoff turn and reports progress as events
/// (phase, activity, input_required, refill_required, completed, error).
/// </summary>
public class MealPlanStreamService(
    IConversationStateStore _conversationStateStore,
    InventoryAgent _inventoryAgent,
    NutritionAgent _nutritionAgent,
    CookAgent _cookAgent,
    MealPlanContext _mealPlan)
{
    private static readonly Dictionary<string, string> PhaseByAgent = new()
    {
        ["InventoryAgent"] = "inventory",
        ["NutritionAgent"] = "nutrition",
        ["CookAgent"] = "cook",
    };

    public async Task RunTurnAsync(string runId, ConversationState state,
        Func<MealPlanStreamEvent, Task> emit, CancellationToken cancellationToken)
    {
        _mealPlan.MealType = state.MealType;
        var messages = state.Messages;
        string? currentPhase = null;
        string? lastAuthorName = null;
        List<ChatMessage> finalMessages = [];
        HashSet<string> reportedCallIds = [];

        await emit(new("run", new { runId, mealType = state.MealType.ToString() }));

        try
        {
            await using StreamingRun run = await InProcessExecution.RunStreamingAsync(
                BuildWorkflow(), messages, cancellationToken: cancellationToken);
            await run.TrySendMessageAsync(new TurnToken(emitEvents: true));

            await foreach (WorkflowEvent evt in run.WatchStreamAsync(cancellationToken))
            {
                if (evt is AgentResponseUpdateEvent update)
                {
                    var author = update.Update.AuthorName;
                    if (!string.IsNullOrEmpty(author))
                    {
                        lastAuthorName = author;
                        if (PhaseByAgent.TryGetValue(author, out var phase) && phase != currentPhase)
                        {
                            if (currentPhase is not null)
                                await emit(PhaseEvent(currentPhase, "done"));
                            currentPhase = phase;
                            await emit(PhaseEvent(phase, "active"));
                        }
                    }

                    foreach (var call in update.Update.Contents.OfType<FunctionCallContent>())
                    {
                        if (reportedCallIds.Add(call.CallId) && ActivityFor(call) is { } activity)
                            await emit(new("activity", new { phase = currentPhase, message = activity }));
                    }
                }
                else if (evt is WorkflowOutputEvent outputEvt && outputEvt.As<List<ChatMessage>>() is { } newMessages)
                {
                    finalMessages = newMessages;
                    break;
                }
                else if (evt is ExecutorFailedEvent failedEvt)
                {
                    await emit(ErrorEvent(failedEvt.Data?.ToString()));
                    return;
                }
            }
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            return;
        }
        catch (Exception ex)
        {
            await emit(ErrorEvent(ex.Message));
            return;
        }

        messages.AddRange(finalMessages.Skip(messages.Count));

        if (_mealPlan.RefillRequired)
        {
            await _conversationStateStore.RemoveAsync(runId);
            var items = _mealPlan.SuggestedItemsToBuy;
            await emit(new("refill_required", new
            {
                runId,
                mealType = state.MealType.ToString(),
                message = $"There is no new meal to suggest for this {state.MealType}. " +
                          "Please refill your inventory with sufficient items.",
                suggestedItems = items,
            }));
            return;
        }

        if (lastAuthorName == "CookAgent")
        {
            await _conversationStateStore.RemoveAsync(runId);
            await emit(PhaseEvent("cook", "done"));
            await emit(new("completed", new
            {
                runId,
                mealType = state.MealType.ToString(),
                dish = _mealPlan.SavedDish,
                text = messages.LastOrDefault()?.Text,
            }));
            return;
        }

        await _conversationStateStore.SaveAsync(runId, state);
        await emit(new("input_required", new
        {
            runId,
            phase = currentPhase,
            question = messages.LastOrDefault()?.Text,
        }));
    }

    private Workflow BuildWorkflow() =>
        AgentWorkflowBuilder.CreateHandoffBuilderWith(_inventoryAgent.inventoryAgent)
            .WithHandoffs(_inventoryAgent.inventoryAgent, [_nutritionAgent.nutritionAgent])
            .WithHandoffs(_nutritionAgent.nutritionAgent, [_cookAgent.cookAgent])
            .Build();

    private static MealPlanStreamEvent PhaseEvent(string phase, string status) =>
        new("phase", new { phase, status });

    private static MealPlanStreamEvent ErrorEvent(string? detail) =>
        new("error", new { message = "Something went wrong while planning your meal.", detail });

    // User-facing progress line per tool; unknown calls (e.g. handoffs) are not shown.
    private static string? ActivityFor(FunctionCallContent call) => call.Name switch
    {
        "ListPantryItems" => "Looking through your pantry",
        "CheckExpiredItems" => "Checking for expired items",
        "CheckExpiringSoonItems" => "Spotting items that expire soon",
        "RemoveInventoryItem" => call.Arguments?.TryGetValue("itemName", out var name) == true
            ? $"Removing {name} from your pantry"
            : "Removing items from your pantry",
        "GetUserGoalsAndPreferences" => "Reviewing your goals & preferences",
        "GetPreviouslySuggestedMeals" => "Checking meals you've already had",
        "ReportNoNewMealPossible" => "Putting together a shopping list",
        "SaveSuggestedDish" => "Saving your recipe",
        _ => null,
    };
}
