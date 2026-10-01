using Cookly.Business.IServices;
using Cookly.Data;
using Cookly.Data.DTOS;
using Cookly.Data.enums;
using Cookly.Data.Models;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Business.Services;

public class InventoryService(CooklyDbContext _context):IInventoryService
{
    public async Task<ServiceResponseDto<string>> ItemAdd(ItemAddRequestDto request,int userId, CancellationToken token)
    {
        if (userId == 0)
        {
            return new ServiceResponseDto<string>
            {
                Data = null,
                Success = false,
                Message = "UserId is null"
            };
        }

        try
        {
            var userInventory = await _context.Inventories.Where(u => u.UserId == userId)
                .FirstOrDefaultAsync(token);

            if (userInventory == null)
            {
                return new ServiceResponseDto<string>
                {
                    Data = null,
                    Success = false,
                    Message = "Inventory not found for the user"
                };
            }

            var inventoryId = userInventory?.InventoryId ?? 0;
            
            if (inventoryId == 0)
            {
                return new ServiceResponseDto<string>
                {
                    Data = null,
                    Success = false,
                    Message = "Inventory not found for the user"
                };
            }
            
            //add item to inventory

            var item = new Item
            {
                Name = request.ItemName,
                Quantity = request.Quantity,
                Unit = request.Unit,
                PurchasedAt = DateTime.UtcNow,
                ExpiryAt = request?.ExpiredAt ?? null,
                Category = request?.Category ?? Category.Others,
                InventoryId = inventoryId
            };
            //update inventory
            userInventory.LastUpdatedOn = DateTime.UtcNow;
            await _context.AddAsync(item);
            await _context.SaveChangesAsync(token);

            return new ServiceResponseDto<string>
            {
                Data = item.ItemId.ToString(),
                Success = true,
                Message = "Item Saved Successfully!"
            };
        }
        catch (Exception ex)
        {
            return new ServiceResponseDto<string>
            {
                Data = null,
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception Occured while saving the item to inventory,{ex.Message}"
            };
        }
    }

    public async Task<ServiceResponseDto<List<ListItems>>> ListItems(int userId, CancellationToken token)
    {
        try
        {
            
        }
        catch (Exception ex)
        {
            return new ServiceResponseDto<List<ListItems>>
            {
                Data = [],
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception occured while fetching the inventory items.{ex.Message}"
            };
        }
        if (userId == 0)
        {
            return new ServiceResponseDto<List<ListItems>>
            {
                Data = [],
                Success = false,
                MessageKey = "UserId is Null"
            };
        }

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
}