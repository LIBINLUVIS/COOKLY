using Microsoft.Extensions.AI;

namespace Cookly.Business.IServices;

/// <summary>
/// Persists the growing message history for a Handoff run between HTTP calls. Unlike
/// <see cref="IRunStateStore"/> (checkpoint-based, for a tool-approval halt mid-superstep), a
/// Handoff pause for free-form user input has no checkpoint — resuming it means re-running the
/// workflow from scratch with the accumulated conversation plus the new user message.
/// </summary>
public interface IConversationStateStore
{
    Task SaveAsync(string runId, List<ChatMessage> messages);
    Task<List<ChatMessage>?> LoadAsync(string runId);
}
