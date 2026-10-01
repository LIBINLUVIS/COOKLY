using Cookly.Business.IServices;
using Cookly.Data.DTOS;

namespace Cookly.Business.Services;

public class InventoryToolsService: IInventoryToolsService
{
    public async Task<ServiceResponseDto<string>> ListPantryItems()
    {
        throw new NotImplementedException();
    }
}