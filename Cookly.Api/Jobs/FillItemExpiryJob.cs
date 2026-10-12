using Cookly.Api.Services;
using Cookly.Business.IServices;
using Cookly.Data;
using Coravel.Invocable;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Api.Jobs;

public record FillItemExpiryPayload(int ItemId, int UserId);

/// <summary>Queued after an item is added without an expiry: fills it from the shelf-life lookup (AI fallback) and notifies the app.</summary>
public class FillItemExpiryJob(
    CooklyDbContext _context,
    IShelfLifeService _shelfLifeService,
    PantryEventHub _eventHub,
    ILogger<FillItemExpiryJob> _logger) : IInvocable, IInvocableWithPayload<FillItemExpiryPayload>, ICancellableInvocable
{
    public FillItemExpiryPayload Payload { get; set; } = default!;
    public CancellationToken CancellationToken { get; set; }

    public async Task Invoke()
    {
        var item = await _context.Items
            .FirstOrDefaultAsync(i => i.ItemId == Payload.ItemId && i.Inventory!.UserId == Payload.UserId, CancellationToken);

        // Deleted meanwhile, or the user already set an expiry.
        if (item is null || item.ExpiryAt is not null)
            return;

        var shelfLife = await _shelfLifeService.GetShelfLifeDays(item.Name, CancellationToken);
        if (!shelfLife.Success)
        {
            _logger.LogWarning("Could not fill expiry for item {ItemId}: {Reason}", item.ItemId, shelfLife.MessageKey ?? shelfLife.Message);
            _eventHub.Publish(Payload.UserId, new PantryEvent("item_expiry_failed", new { itemId = item.ItemId }));
            return;
        }

        item.ExpiryAt = item.PurchasedAt.AddDays(shelfLife.Data);
        await _context.SaveChangesAsync(CancellationToken);

        _eventHub.Publish(Payload.UserId, new PantryEvent("item_expiry_updated", new
        {
            itemId = item.ItemId,
            expiredAt = DateTime.SpecifyKind(item.ExpiryAt.Value, DateTimeKind.Utc),
        }));
    }
}
