using System.ComponentModel;
using Cookly.Data.DTOS;

namespace Cookly.Agents.Tools;

/// <summary>
/// Tools exposed to InventoryAgent, and (read-only) to NutritionAgent and CookAgent so they can
/// ground meal suggestions in the actual, current pantry contents instead of relying on a
/// paraphrased summary passed along the handoff chain.
/// </summary>
public class InventoryTools(List<PantryItem> pantryItems, int expiryWindowDays)
{
    [Description(
        "Lists every item currently in the pantry, by exact name, reflecting any removals already " +
        "made. This is the authoritative, current list — do not assume any item is available unless " +
        "it appears here.")]
    public string ListPantryItems() =>
        pantryItems.Count == 0 ? "The pantry is empty." : string.Join(", ", pantryItems.Select(i => i.Name));

    [Description("Lists pantry items that have already expired.")]
    public string CheckExpiredItems()
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        var expired = pantryItems.Where(i => i.ExpiryDate < today).Select(i => i.Name).ToList();
        return expired.Count == 0 ? "No items have expired." : string.Join(", ", expired);
    }

    [Description(
        "Lists pantry items expiring within the next few days but not yet expired, each with " +
        "the exact number of days left, e.g. 'Milk (1 day left)'. Use the day count, not the " +
        "item name alone, to decide whether an item needs to be removed.")]
    public string CheckExpiringSoonItems()
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        var expiringSoon = pantryItems
            .Select(i => new { i.Name, DaysUntilExpiry = i.ExpiryDate.DayNumber - today.DayNumber })
            .Where(i => i.DaysUntilExpiry > 0 && i.DaysUntilExpiry <= expiryWindowDays)
            .Select(i => $"{i.Name} ({i.DaysUntilExpiry} day{(i.DaysUntilExpiry == 1 ? "" : "s")} left)")
            .ToList();
        return expiringSoon.Count == 0 ? "No items are expiring soon." : string.Join(", ", expiringSoon);
    }

    [Description("Removes an item from the pantry inventory by its exact name.")]
    public string RemoveInventoryItem(
        [Description("The exact name of the pantry item to remove.")] string itemName)
    {
        var removed = pantryItems.RemoveAll(i =>
            string.Equals(i.Name, itemName, StringComparison.OrdinalIgnoreCase));
        return removed > 0
            ? $"Removed {itemName} from the inventory."
            : $"No item named '{itemName}' was found.";
    }
}
