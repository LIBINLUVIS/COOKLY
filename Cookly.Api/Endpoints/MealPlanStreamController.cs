using System.Text.Json;
using System.Text.Json.Serialization;
using Cookly.Api.Services;
using Cookly.Business.IServices;
using Cookly.Business.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.AI;

namespace Cookly.Api.Endpoints;

/// <summary>Server-Sent Events version of the meal-plan endpoints, for live progress in the app.</summary>
[ApiController]
[Authorize]
[Route("meal-plan/stream")]
public class MealPlanStreamController(
    MealPlanStreamService _streamService,
    IConversationStateStore _conversationStateStore,
    UserService _userService) : ControllerBase
{
    private static readonly JsonSerializerOptions EventJson = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    [HttpPost("start")]
    public async Task<IActionResult> Start([FromBody] StartMealPlanRequest request, CancellationToken cancellationToken)
    {
        if (request.MealType is not { } mealType || !Enum.IsDefined(mealType))
            return BadRequest(new { message = "mealType is required: 1 (Breakfast), 2 (Lunch) or 3 (Dinner)." });

        var userId = _userService.GetUserId();
        if (userId <= 0)
            return Unauthorized();

        List<ChatMessage> messages =
        [
            new(ChatRole.User,
                $"Plan my {mealType} from my pantry. Review the inventory, handle any expired or " +
                $"expiring items, then suggest a new {mealType} meal and prepare cooking instructions."),
        ];

        var state = new ConversationState(userId, mealType, messages);
        return await StreamAsync(Guid.NewGuid().ToString(), state, cancellationToken);
    }

    [HttpPost("{runId}/respond")]
    public async Task<IActionResult> Respond(string runId, [FromBody] RespondToMealPlanRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
            return BadRequest(new { message = "message is required." });

        var state = await _conversationStateStore.LoadAsync(runId);
        if (state is null || state.UserId != _userService.GetUserId())
            return NotFound(new { message = "No pending run found for this runId." });

        state.Messages.Add(new ChatMessage(ChatRole.User, request.Message.Trim()));
        return await StreamAsync(runId, state, cancellationToken);
    }

    private async Task<IActionResult> StreamAsync(string runId, ConversationState state, CancellationToken cancellationToken)
    {
        Response.ContentType = "text/event-stream";
        Response.Headers.CacheControl = "no-cache";
        Response.Headers["X-Accel-Buffering"] = "no";
        HttpContext.Features.Get<IHttpResponseBodyFeature>()?.DisableBuffering();
        await Response.Body.FlushAsync(cancellationToken);

        await _streamService.RunTurnAsync(runId, state, evt => WriteEventAsync(evt, cancellationToken), cancellationToken);
        return new EmptyResult();
    }

    private async Task WriteEventAsync(MealPlanStreamEvent evt, CancellationToken cancellationToken)
    {
        var json = JsonSerializer.Serialize(evt.Data, EventJson);
        await Response.WriteAsync($"event: {evt.Type}\ndata: {json}\n\n", cancellationToken);
        await Response.Body.FlushAsync(cancellationToken);
    }
}
