using Cookly.Data.enums;

namespace Cookly.Data.Models;

/// <summary>Typical home-storage shelf life of a food, keyed by its normalized name.</summary>
public class ShelfLife
{
    public int ShelfLifeId { get; set; }
    public string NormalizedName { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public int ShelfLifeDays { get; set; }
    public Category? Category { get; set; }
    public string Source { get; set; } = ShelfLifeSources.Seed;
    public DateTime CreatedAt { get; set; }
}

public static class ShelfLifeSources
{
    public const string Seed = "Seed";
    public const string AI = "AI";
}
