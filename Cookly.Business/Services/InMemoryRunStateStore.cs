using System.Collections.Concurrent;
using Cookly.Business.IServices;
using Microsoft.Agents.AI.Workflows;

namespace Cookly.Business.Services;

public sealed class InMemoryRunStateStore:IRunStateStore
{
    private readonly ConcurrentDictionary<string, CheckpointInfo> _store = new();

    public Task SaveAsync(string runId, CheckpointInfo checkpoint)
    {
        _store[runId] = checkpoint;
        return Task.CompletedTask;
    }

    public Task<CheckpointInfo?> LoadAsync(string runId) =>
        Task.FromResult(_store.TryGetValue(runId, out var checkpoint) ? checkpoint : null);
}