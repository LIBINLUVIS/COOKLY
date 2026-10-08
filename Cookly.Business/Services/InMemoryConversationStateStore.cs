using System.Collections.Concurrent;
using Cookly.Business.IServices;

namespace Cookly.Business.Services;

public sealed class InMemoryConversationStateStore : IConversationStateStore
{
    private readonly ConcurrentDictionary<string, ConversationState> _store = new();

    public Task SaveAsync(string runId, ConversationState state)
    {
        _store[runId] = state;
        return Task.CompletedTask;
    }

    public Task<ConversationState?> LoadAsync(string runId) =>
        Task.FromResult(_store.TryGetValue(runId, out var state) ? state : null);

    public Task RemoveAsync(string runId)
    {
        _store.TryRemove(runId, out _);
        return Task.CompletedTask;
    }
}
