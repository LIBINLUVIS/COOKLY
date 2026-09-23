using Cookly.Agents.Tools;
using Cookly.Business.IServices;
using Cookly.Data.DTOS;
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Workflows;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.AI;

namespace Cookly.Api.Endpoints;

[ApiController]
[Route("meal-plan")]
public class AgentController(CheckpointManager checkpointManager,
    IRunStateStore runStateStore,
    IChatClient chatClient) : ControllerBase
{
    private const int ExpiryWindowDays = 3;

    // The decision boundary InventoryAgent is told to apply: at or below this many days left,
    // removal is mandatory. This is intentionally tighter than ExpiryWindowDays (which only
    // controls how far ahead CheckExpiringSoonItems looks) so items just inside the "soon"
    // window (like Yogurt at 3 days) get flagged for awareness without forcing removal.
    private const int RemovalThresholdDays = 2;

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
    /// Sequential orchestration: InventoryAgent -> NutritionAgent -> CookAgent. Each agent
    /// hands its full response to the next. InventoryAgent's item-removal tool is wrapped in
    /// ApprovalRequiredAIFunction, so the workflow pauses for human approval before it runs;
    /// the other tools are plain and never pause.
    /// </summary>
    private Workflow BuildWorkflow()
    {
        var inventoryTools = new InventoryTools(GetDummyPantryItems(), ExpiryWindowDays);
        var nutritionTools = new NutritionTools();

        // Explicit, stable Ids are required here: checkpoint restore matches agents by Id, and
        // BuildWorkflow() is called fresh on every request (StartMealPlan and
        // ApproveMealPlanTool both call it independently). Without a fixed Id, ChatClientAgent
        // auto-generates a new one each time, and resuming a checkpoint built against the
        // previous instance's Ids fails with "checkpoint is not compatible with the workflow".
        ChatClientAgent inventoryAgent = new(chatClient, new ChatClientAgentOptions
        {
            Id = "inventory-agent",
            Name = "InventoryAgent",
            Description = "Reviews pantry inventory and removes expired items",
            ChatOptions = new ChatOptions
            {
                Instructions =
                    "You are an inventory manager for a home kitchen. Follow this exact procedure " +
                    "and do not deviate from it:\n" +
                    "1. Call CheckExpiredItems. Every item it returns has already expired — call " +
                    "RemoveInventoryItem for each one. This is mandatory, not a judgement call.\n" +
                    $"2. Call CheckExpiringSoonItems. It returns each item together with its exact " +
                    $"number of days left. For every item with {RemovalThresholdDays} day(s) left " +
                    $"or fewer, call RemoveInventoryItem for it — same as expired items, this is " +
                    $"mandatory. For items with more than {RemovalThresholdDays} days left, do not " +
                    "remove them; just note them in your summary as expiring soon.\n" +
                    "3. Never describe a removal in your summary without actually calling " +
                    "RemoveInventoryItem for it — only the tool call itself lets a human approve " +
                    "or reject the action; mentioning it in text alone changes nothing.\n" +
                    "4. Finish with a summary of the final pantry contents (after any removals) " +
                    "for the next agent, including which items you flagged as expiring soon but " +
                    "did not remove.",
                Tools =
                [
                    AIFunctionFactory.Create(inventoryTools.CheckExpiredItems),
                    AIFunctionFactory.Create(inventoryTools.CheckExpiringSoonItems),
                    new ApprovalRequiredAIFunction(AIFunctionFactory.Create(inventoryTools.RemoveInventoryItem)),
                ],
                // The model can otherwise emit several RemoveInventoryItem calls in one
                // response (observed: three near-identical calls for the same item). Every
                // call in a batch that contains one approval-required call also requires
                // approval, and answering a multi-call batch across separate HTTP requests
                // runs into rough edges in the SDK's tool-output reconstruction. One call at
                // a time avoids that entirely.
                AllowMultipleToolCalls = false,
            },
        });

        ChatClientAgent nutritionAgent = new(chatClient, new ChatClientAgentOptions
        {
            Id = "nutrition-agent",
            Name = "NutritionAgent",
            Description = "Suggests a meal based on goals, preferences, and available ingredients",
            ChatOptions = new ChatOptions
            {
                Instructions =
                    "You are a nutrition planner. Look up the user's goals and preferences with " +
                    "your tool, then use the pantry summary from the previous agent to suggest a " +
                    "single suitable meal.",
                Tools = [AIFunctionFactory.Create(nutritionTools.GetUserGoalsAndPreferences)],
            },
        });

        ChatClientAgent cookAgent = new(chatClient, new ChatClientAgentOptions
        {
            Id = "cook-agent",
            Name = "CookAgent",
            Description = "Produces ingredients and cooking instructions",
            ChatOptions = new ChatOptions
            {
                Instructions =
                    "You are a cooking assistant. Given the suggested meal, produce a clear " +
                    "ingredient list and step-by-step cooking instructions.",
            },
        });

        return AgentWorkflowBuilder.BuildSequential([inventoryAgent, nutritionAgent, cookAgent]);
    }

    [HttpPost("start")]
    public async Task<IActionResult> StartMealPlan()
    {
        var runId = Guid.NewGuid().ToString();

        List<ChatMessage> messages =
        [
            new(ChatRole.User,
                "Plan tonight's dinner from my pantry. Review the inventory, handle any expired or " +
                "expiring items, then suggest a meal and prepare cooking instructions."),
        ];

        StreamingRun run = await InProcessExecution.RunStreamingAsync(
            BuildWorkflow(), messages, checkpointManager);
        await run.TrySendMessageAsync(new TurnToken(emitEvents: true));

        (string tool, IDictionary<string, object?> arguments)? pendingApproval = null;

        await foreach (WorkflowEvent evt in run.WatchStreamAsync(blockOnPendingRequest: false))
        {
            if (evt is RequestInfoEvent requestEvt &&
                requestEvt.Request.TryGetDataAs(out ToolApprovalRequestContent? approval))
            {
                var toolCall = (FunctionCallContent)approval.ToolCall;
                pendingApproval = (toolCall.Name, toolCall.Arguments);
                continue;
            }

            // Intermediate participants (InventoryAgent, NutritionAgent) also surface as
            // WorkflowOutputEvent while streaming, carrying an AgentResponseUpdate chunk rather
            // than the final List<ChatMessage> — only the true terminal output (CookAgent's)
            // carries that. Skip anything that doesn't cast successfully.
            if (evt is WorkflowOutputEvent outputEvt && outputEvt.As<List<ChatMessage>>() is { } finalMessages)
            {
                return Ok(new { runId, status = "completed", result = finalMessages.LastOrDefault()?.Text });
            }

            if (evt is ExecutorFailedEvent failedEvt)
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

        if (pendingApproval is { } pending)
        {
            if (run.Checkpoints.Count > 0)
            {
                await runStateStore.SaveAsync(runId, run.Checkpoints.Last());
            }
            return Ok(new
            {
                runId,
                status = "needs_approval",
                tool = pending.tool,
                arguments = pending.arguments,
            });
        }

        return Ok(new { runId, status = "completed" });
    }

    [HttpPost("{runId}/approve")]
    public async Task<IActionResult> ApproveMealPlanTool(string runId, [FromBody] bool approved)
    {
        var savedCheckpoint = await runStateStore.LoadAsync(runId);
        if (savedCheckpoint is null)
            return NotFound(new { message = "No pending run found for this runId." });

        StreamingRun run = await InProcessExecution.ResumeStreamingAsync(
            BuildWorkflow(), savedCheckpoint, checkpointManager);

        // WatchStreamAsync(blockOnPendingRequest: false) ends its enumeration at each halt (a
        // still-pending RequestInfoEvent, or the workflow genuinely idle). Answering a request
        // only queues it "for the next superstep" (per the SDK's own doc comment) — that queued
        // work isn't driven forward by the same enumeration, so re-open a fresh watch after any
        // segment that answered at least one request, until a segment answers nothing new.
        for (var i = 0; i < 10; i++)
        {
            var answeredAny = false;

            await foreach (WorkflowEvent evt in run.WatchStreamAsync(blockOnPendingRequest: false))
            {
                if (evt is RequestInfoEvent requestEvt &&
                    requestEvt.Request.TryGetDataAs(out ToolApprovalRequestContent? approval))
                {
                    await run.SendResponseAsync(
                        requestEvt.Request.CreateResponse(approval.CreateResponse(approved)));
                    answeredAny = true;
                    continue;
                }

                if (evt is WorkflowOutputEvent outputEvt && outputEvt.As<List<ChatMessage>>() is { } finalMessages)
                {
                    return Ok(new { runId, status = "completed", result = finalMessages.LastOrDefault()?.Text });
                }

                if (evt is ExecutorFailedEvent failedEvt)
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

            if (!answeredAny)
            {
                break;
            }
        }

        return Ok(new { runId, status = "in_progress" });
    }
}
