using Cookly.Business.IServices;
using Cookly.Data;
using Cookly.Data.DTOS;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Business.Services;

public class InventoryToolsService(UserService _userService,CooklyDbContext _context,IShelfLifeService _shelfLifeService): IInventoryToolsService
{
    public async Task<ServiceResponseDto<List<ListItems>>> ListItems(CancellationToken token)
    {
        try
        {
            int userId =  _userService.GetUserId();
            
            var userInventory =
                await _context.Inventories.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == userId, token);

            if (userInventory == null)
            {
                return new ServiceResponseDto<List<ListItems>>
                {
                    Data = [],
                    Success = false,
                    MessageKey = "UserInventory not found for this user"
                };
            }

            var inventoryId = userInventory.InventoryId;
            var items = await _context.Items.AsNoTracking().Where(i => i.InventoryId == inventoryId)
                .Select(itm=> new ListItems
                {
                    ItemId = itm.ItemId,
                    ItemName = itm.Name ?? "",
                    Quantity = itm.Quantity,
                    Unit = itm.Unit,
                    PurchasedAt = itm.PurchasedAt,
                    ExpiredAt = itm.ExpiryAt ?? null,
                    Category = itm.Category
                }).ToListAsync(token);

            return new ServiceResponseDto<List<ListItems>>
            {
                Data = items,
                Success = true,
            };
        }
        catch (Exception ex)
        {
            return new ServiceResponseDto<List<ListItems>>
            {
                Data = [],
                Success = false
            };
        }
    }
    
    public async Task<ServiceResponseDto<List<ListItems>>> GetExpiredItems(CancellationToken token)
    {
        int userId =  _userService.GetUserId();
        if (userId > 0)
        {
            //fist fetch all the items in the inventory
            var userInventory = await _context.Inventories.Include(i=>i.Items).Where(u => u.UserId == userId).SingleOrDefaultAsync(token);
            var allItems = userInventory?.Items ?? [];
            var itemsNotHaveExpiryDate = allItems.Where(itm => itm.ExpiryAt == null) ?? [];
            //call the ai service get the item expiry and set it bck and return
            if (itemsNotHaveExpiryDate.Any())
            {
                foreach (var itm in itemsNotHaveExpiryDate)
                {
                    var shelfLife = await _shelfLifeService.GetShelfLifeDays(itm.Name, token);
                    if (shelfLife.Success)
                        itm.ExpiryAt = itm.PurchasedAt.AddDays(shelfLife.Data);
                }
            }
            //save the ai predicted items expiry to db
            try
            {
                await _context.SaveChangesAsync(token);
            }
            catch(Exception ex)
            {
                // add logger
            }
            //check with the current date.
            var expiredItems = allItems.Where(i => i.ExpiryAt < DateTime.UtcNow).Select(i => new ListItems
            {
                ItemName = i.Name,
                Quantity = i.Quantity,
                Unit = i.Unit,
                PurchasedAt = i.PurchasedAt,
                ExpiredAt = i.ExpiryAt,
                Category = i.Category
            }).ToList();

            if (expiredItems.Any())
            {
                return new ServiceResponseDto<List<ListItems>>
                {
                    Data = expiredItems,
                    Success = true
                };
            }
            
            return new ServiceResponseDto<List<ListItems>>
            {
                Data = [],
                Success = true,
                Message = "No Expired Items."
            };
        }
        else
        {
            return new ServiceResponseDto<List<ListItems>>
            {
                Data = [],
                Success = false,
                MessageKey = "UserId is null"
            };
        }
    }
    
    public async Task<ServiceResponseDto<List<ListItems>>> GetExpiringSoonItems(CancellationToken token)
    {
        var userId = _userService.GetUserId();
        
        if (userId <= 0)
            return new() { Data = [], Success = false, MessageKey = "UserId is null" };

        var userItems = await _context.Items.AsNoTracking().Where(i => i.Inventory!.UserId == userId).ToListAsync(token);

        var now = DateTime.UtcNow;
        var windowEnd = now.AddDays(3);

        var expiringSoonItems = userItems
            .Where(x => x.ExpiryAt >= now && x.ExpiryAt <= windowEnd)
            .OrderBy(x => x.ExpiryAt)
            .Select(itm => new ListItems
            {
                ItemId = itm.ItemId,
                ItemName = itm.Name,
                Quantity = itm.Quantity,
                Unit = itm.Unit,
                PurchasedAt = itm.PurchasedAt,
                ExpiredAt = itm.ExpiryAt,
                Category = itm.Category
            }).ToList();

        return new ServiceResponseDto<List<ListItems>>
        {
            Data = expiringSoonItems,
            Success = true,
            Message = expiringSoonItems.Count == 0 ? "No items expiring soon." : null
        };
    }

    public async Task<ServiceResponseDto<string>> RemoveInventoryItems(string itemNames, CancellationToken token)
    {
        try
        {
            var userId =  _userService.GetUserId();
            var itemName = itemNames.Trim();
            var removedItems = await  _context.Items.AsNoTracking().Where(i => i.Inventory!.UserId == userId)
                .Where(x=> x.Name == itemName).ExecuteDeleteAsync(token);

            return new ServiceResponseDto<string>
            {
                Data = removedItems > 0 ? $"Removed {itemName} from the inventory." : $"No item named '{itemName}' was found.",
                Success = true
            };

        }
        catch (Exception ex)
        {
            return new ServiceResponseDto<string>
            {
                Data = null,
                Success = false
            };
        }
    }
}