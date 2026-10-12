using System.Text.RegularExpressions;

namespace Cookly.Data.Utils;

/// <summary>
/// Turns free-text grocery names into lookup keys, e.g. "Organic Baby Spinach" → "spinach",
/// "Roma Tomatoes" → "roma tomato". Seed data and lookups must use the same rules.
/// </summary>
public static partial class FoodNameNormalizer
{
    private static readonly HashSet<string> DescriptorWords =
    [
        "organic", "baby", "whole", "large", "small", "medium", "ripe", "raw", "free", "range",
        "boneless", "skinless", "sliced", "chopped", "diced", "pack", "packet", "bag", "of", "the", "and",
        "homemade", "local", "farm", "premium", "natural", "pure", "extra", "virgin", "pcs", "piece",
    ];

    public static string Normalize(string name) => string.Join(' ', Words(name));

    /// <summary>Lookup keys from most to least specific: the full name, then shorter word endings
    /// (the head noun of a food name is usually its last word, e.g. "basmati rice" → "rice").</summary>
    public static IEnumerable<string> Candidates(string name)
    {
        var words = Words(name).ToList();
        for (var start = 0; start < words.Count; start++)
        {
            var key = string.Join(' ', words.Skip(start));
            if (key.Length >= 3)
                yield return key;
        }
    }

    private static IEnumerable<string> Words(string name) =>
        NonAlphanumeric().Split(name.ToLowerInvariant())
            .Where(w => w.Length > 0 && !DescriptorWords.Contains(w))
            .Select(Singular);

    private static string Singular(string word)
    {
        if (word.Length <= 3 || word.EndsWith("ss") || word.EndsWith("us") || word.EndsWith("is"))
            return word;
        if (word.EndsWith("ies")) return word[..^3] + "y";
        if (word.EndsWith("ves")) return word[..^3] + "f";
        if (word.EndsWith("oes") || word.EndsWith("ches") || word.EndsWith("shes") || word.EndsWith("xes"))
            return word[..^2];
        return word.EndsWith('s') ? word[..^1] : word;
    }

    [GeneratedRegex("[^a-z0-9]+")]
    private static partial Regex NonAlphanumeric();
}
