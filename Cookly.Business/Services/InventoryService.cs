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
                ExpiryAt = request.ExpiredAt,
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
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception occured while fetching the inventory items.{ex.Message}"
            };
        }
    }

    public async Task<ServiceResponseDto<string>> ItemDelete(int itemId, int userId, CancellationToken token)
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

            var item = await _context.Items
                .Where(i => i.ItemId == itemId && i.InventoryId == userInventory.InventoryId)
                .FirstOrDefaultAsync(token);

            if (item == null)
            {
                return new ServiceResponseDto<string>
                {
                    Data = null,
                    Success = false,
                    Message = "Item not found in the user's inventory"
                };
            }

            _context.Items.Remove(item);
            userInventory.LastUpdatedOn = DateTime.UtcNow;
            await _context.SaveChangesAsync(token);

            return new ServiceResponseDto<string>
            {
                Data = item.ItemId.ToString(),
                Success = true,
                Message = "Item Deleted Successfully!"
            };
        }
        catch (Exception ex)
        {
            return new ServiceResponseDto<string>
            {
                Data = null,
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception Occured while deleting the item from inventory,{ex.Message}"
            };
        }
    }

    public async Task<ServiceResponseDto<string>> ItemQuantityUpdate(ItemQuantityUpdateRequestDto request, int userId, CancellationToken token)
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

            var item = await _context.Items
                .Where(i => i.ItemId == request.ItemId && i.InventoryId == userInventory.InventoryId)
                .FirstOrDefaultAsync(token);

            if (item == null)
            {
                return new ServiceResponseDto<string>
                {
                    Data = null,
                    Success = false,
                    Message = "Item not found in the user's inventory"
                };
            }

            var newQuantity = item.Quantity + request.QuantityChange;
            if (newQuantity < 0)
            {
                return new ServiceResponseDto<string>
                {
                    Data = null,
                    Success = false,
                    Message = "Quantity cannot be reduced below zero"
                };
            }

            item.Quantity = newQuantity;
            userInventory.LastUpdatedOn = DateTime.UtcNow;
            await _context.SaveChangesAsync(token);

            return new ServiceResponseDto<string>
            {
                Data = item.Quantity.ToString(),
                Success = true,
                Message = "Item Quantity Updated Successfully!"
            };
        }
        catch (Exception ex)
        {
            return new ServiceResponseDto<string>
            {
                Data = null,
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception Occured while updating the item quantity,{ex.Message}"
            };
        }
    }

    
}