using Microsoft.Agents.AI.Workflows;

namespace Cookly.Business.IServices;

public interface IRunStateStore
{
    Task SaveAsync(string runId, CheckpointInfo checkpoint);
    Task<CheckpointInfo?> LoadAsync(string runId);
}