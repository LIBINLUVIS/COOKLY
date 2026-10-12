using System.Text.Json;
using Cookly.Data.enums;
using Cookly.Data.Models;
using Cookly.Data.Utils;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Data.Seed;

/// <summary>Inserts shelf-life rows from the seed JSON that aren't in the table yet. Safe to run on every startup.</summary>
public static class ShelfLifeSeeder
{
    private sealed record SeedEntry(string Name, int Days, Category? Category, List<string>? Aliases);

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new System.Text.Json.Serialization.JsonStringEnumConverter() },
    };

    public static async Task<int> SeedAsync(CooklyDbContext context, string seedFilePath, CancellationToken token = default)
    {
        var entries = JsonSerializer.Deserialize<List<SeedEntry>>(await File.ReadAllTextAsync(seedFilePath, token), JsonOptions) ?? [];
        var existing = (await context.ShelfLives.Select(s => s.NormalizedName).ToListAsync(token)).ToHashSet();
        var now = DateTime.UtcNow;

        foreach (var entry in entries)
        {
            foreach (var name in (entry.Aliases ?? []).Prepend(entry.Name))
            {
                var key = FoodNameNormalizer.Normalize(name);
                if (key.Length == 0 || !existing.Add(key))
                    continue;

                context.ShelfLives.Add(new ShelfLife
                {
                    NormalizedName = key,
                    DisplayName = entry.Name,
                    ShelfLifeDays = entry.Days,
                    Category = entry.Category,
                    Source = ShelfLifeSources.Seed,
                    CreatedAt = now,
                });
            }
        }

        return await context.SaveChangesAsync(token);
    }
}
