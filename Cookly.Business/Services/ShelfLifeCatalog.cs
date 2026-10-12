using System.Collections.Concurrent;
using Cookly.Data;
using Cookly.Data.Models;
using Cookly.Data.Utils;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Cookly.Business.Services;

/// <summary>Singleton in-memory copy of the ShelfLives table, loaded on first use.</summary>
public sealed class ShelfLifeCatalog(IServiceScopeFactory _scopeFactory)
{
    private readonly ConcurrentDictionary<string, int> _daysByName = new();
    private readonly SemaphoreSlim _loadLock = new(1, 1);
    private volatile bool _loaded;

    public async Task<int?> FindAsync(string itemName, CancellationToken token)
    {
        await EnsureLoadedAsync(token);
        foreach (var key in FoodNameNormalizer.Candidates(itemName))
        {
            if (_daysByName.TryGetValue(key, out var days))
                return days;
        }
        return null;
    }

    /// <summary>Remembers a shelf life learned from the AI so the next lookup is local.</summary>
    public async Task AddAsync(string itemName, int days, string source, CancellationToken token)
    {
        var key = FoodNameNormalizer.Normalize(itemName);
        if (key.Length == 0 || !_daysByName.TryAdd(key, days))
            return;

        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<CooklyDbContext>();
        context.ShelfLives.Add(new ShelfLife
        {
            NormalizedName = key,
            DisplayName = itemName.Trim(),
            ShelfLifeDays = days,
            Source = source,
            CreatedAt = DateTime.UtcNow,
        });

        try
        {
            await context.SaveChangesAsync(token);
        }
        catch (DbUpdateException)
        {
            // Another request saved the same name first; the cached value is still valid.
        }
    }

    private async Task EnsureLoadedAsync(CancellationToken token)
    {
        if (_loaded)
            return;

        await _loadLock.WaitAsync(token);
        try
        {
            if (_loaded)
                return;

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<CooklyDbContext>();
            var rows = await context.ShelfLives.AsNoTracking()
                .Select(s => new { s.NormalizedName, s.ShelfLifeDays })
                .ToListAsync(token);

            foreach (var row in rows)
                _daysByName.TryAdd(row.NormalizedName, row.ShelfLifeDays);
            _loaded = true;
        }
        finally
        {
            _loadLock.Release();
        }
    }
}
