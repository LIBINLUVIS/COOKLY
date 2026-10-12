using System.Collections.Concurrent;
using System.Threading.Channels;

namespace Cookly.Api.Services;

public record PantryEvent(string Type, object Data);

/// <summary>
/// In-memory fan-out of pantry events to each user's open SSE connections.
/// Single-instance only; scaling out would need a shared backplane (e.g. Redis).
/// </summary>
public sealed class PantryEventHub
{
    private readonly ConcurrentDictionary<int, ConcurrentDictionary<Guid, Channel<PantryEvent>>> _subscribers = new();

    public (Guid Id, ChannelReader<PantryEvent> Reader) Subscribe(int userId)
    {
        var channel = Channel.CreateBounded<PantryEvent>(new BoundedChannelOptions(100)
        {
            FullMode = BoundedChannelFullMode.DropOldest,
        });
        var id = Guid.NewGuid();
        _subscribers.GetOrAdd(userId, _ => new())[id] = channel;
        return (id, channel.Reader);
    }

    public void Unsubscribe(int userId, Guid id)
    {
        if (_subscribers.TryGetValue(userId, out var connections) && connections.TryRemove(id, out var channel))
            channel.Writer.TryComplete();
    }

    public void Publish(int userId, PantryEvent evt)
    {
        if (!_subscribers.TryGetValue(userId, out var connections))
            return;
        foreach (var channel in connections.Values)
            channel.Writer.TryWrite(evt);
    }
}
