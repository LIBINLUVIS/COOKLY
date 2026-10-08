using System.ComponentModel;
using Cookly.Business.IServices;
using Cookly.Data.DTOS;

namespace Cookly.Agents.Tools;


public class InventoryTools(IInventoryToolsService _inventorytoolService)
{
    /*[Description(
        "Lists every item currently in the pantry, by exact name, reflecting any removals already " +
        "made. This is the authoritative, current list — do not assume any item is available unless " +
        "it appears here.")]
    public string ListPantryItems() =>
        pantryItems.Count == 0 ? "The pantry is empty." : string.Join(", ", pantryItems.Select(i => i.Name));*/

    [Description(
    "Lists every item currently in the pantry, by exact name, reflecting any removals already " +
    "made. This is the authoritative, current list — do not assume any item is available unless " +
    "it appears here.")]
    public async Task<string> ListPantryItems(CancellationToken token)
    {
        var inventoryItems = await _inventorytoolService.ListItems(token);
        if (!inventoryItems.Success)
            return FailureMessage("list the pantry items", inventoryItems);

        return inventoryItems.Data.Count == 0
            ? "The pantry is empty."
            : string.Join(", ", inventoryItems.Data.Select(x => x.ItemName));
    }


/*
[Description("Lists pantry items that have already expired.")]
public string CheckExpiredItems()
{
    var today = DateOnly.FromDateTime(DateTime.Today);
    var expired = pantryItems.Where(i => i.ExpiryDate < today).Select(i => i.Name).ToList();
    return expired.Count == 0 ? "No items have expired." : string.Join(", ", expired);
}*/

    [Description("Lists pantry items that have already expired.")]
    public async Task<string> CheckExpiredItems(CancellationToken token)
    {
        var expiredItems = await _inventorytoolService.GetExpiredItems(token);
        if (!expiredItems.Success)
            return FailureMessage("check for expired items", expiredItems);

        return expiredItems.Data.Count == 0
            ? "No items have expired."
            : string.Join(", ", expiredItems.Data.Select(x => x.ItemName));
    }

    /*[Description(
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
    }*/

    [Description(
    "Lists pantry items expiring within the next few days but not yet expired, each with " +
    "the exact number of days left, e.g. 'Milk (1 day left)'. Use the day count, not the " +
    "item name alone, to decide whether an item needs to be removed.")]
    public async Task<string> CheckExpiringSoonItems(CancellationToken token)
    {
        var expiringSoonItems = await _inventorytoolService.GetExpiringSoonItems(token);
        if (!expiringSoonItems.Success)
            return FailureMessage("check for items expiring soon", expiringSoonItems);

        if (expiringSoonItems.Data.Count == 0)
            return "No items are expiring soon.";

        var now = DateTime.UtcNow;
        return string.Join(", ", expiringSoonItems.Data.Select(x =>
        {
            var daysLeft = Math.Max(1, (int)Math.Ceiling((x.ExpiredAt!.Value - now).TotalDays));
            return $"{x.ItemName} ({daysLeft} day{(daysLeft == 1 ? "" : "s")} left)";
        }));
    }

/*
[Description("Removes an item from the pantry inventory by its exact name.")]
public string RemoveInventoryItem(
    [Description("The exact name of the pantry item to remove.")] string itemName)
{
    var removed = pantryItems.RemoveAll(i =>
        string.Equals(i.Name, itemName, StringComparison.OrdinalIgnoreCase));
    return removed > 0
        ? $"Removed {itemName} from the inventory."
        : $"No item named '{itemName}' was found.";
}*/

    [Description("Removes one item from the pantry inventory by its exact name.")]
    public async Task<string> RemoveInventoryItem(
        [Description("The exact name of the pantry item to remove, as it appears in the pantry list.")] string itemName,
        CancellationToken token)
    {
        var result = await _inventorytoolService.RemoveInventoryItems(itemName, token);
        if (!result.Success)
            return FailureMessage($"remove '{itemName}'", result);

        return result.Data;
    }

    private static string FailureMessage<T>(string action, ServiceResponseDto<T> response) =>
        $"Could not {action}: {response.Message ?? response.MessageKey ?? "unknown error"}. " +
        "Tell the user this step failed; do not assume the pantry is empty.";
}
