using Cookly.Data.enums;
using Microsoft.Extensions.AI;

namespace Cookly.Business.IServices;

/// <summary>
/// Persists a paused Handoff run between HTTP calls. Resuming re-runs the workflow
/// with the saved conversation plus the user's new message.
/// </summary>
public interface IConversationStateStore
{
    Task SaveAsync(string runId, ConversationState state);
    Task<ConversationState?> LoadAsync(string runId);
    Task RemoveAsync(string runId);
}

/// <summary>A paused run: who owns it, which meal it plans, and the conversation so far.</summary>
public record ConversationState(int UserId, Meal MealType, List<ChatMessage> Messages);
