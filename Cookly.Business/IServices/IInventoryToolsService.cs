using Cookly.Data.DTOS;

namespace Cookly.Business.IServices;

public interface IInventoryToolsService
{
    public Task<ServiceResponseDto<string>> ListPantryItems();
}