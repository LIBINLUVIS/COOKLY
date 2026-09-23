using System.Collections.Concurrent;
using Cookly.Business.IServices;
using Microsoft.Extensions.AI;

namespace Cookly.Business.Services;

public sealed class InMemoryConversationStateStore : IConversationStateStore
{
    private readonly ConcurrentDictionary<string, List<ChatMessage>> _store = new();

    public Task SaveAsync(string runId, List<ChatMessage> messages)
    {
        _store[runId] = messages;
        return Task.CompletedTask;
    }

    public Task<List<ChatMessage>?> LoadAsync(string runId) =>
        Task.FromResult(_store.TryGetValue(runId, out var messages) ? messages : null);
}
