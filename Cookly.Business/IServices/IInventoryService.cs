using Cookly.Data.DTOS;

namespace Cookly.Business.IServices;

public interface IInventoryService
{
    public Task<ServiceResponseDto<string>> ItemAdd(ItemAddRequestDto request,int userId, CancellationToken token);
    public Task<ServiceResponseDto<List<ListItems>>> ListItems(int userId,CancellationToken token);
    public Task<ServiceResponseDto<string>> ItemDelete(int itemId, int userId, CancellationToken token);
    public Task<ServiceResponseDto<string>> ItemQuantityUpdate(ItemQuantityUpdateRequestDto request, int userId, CancellationToken token);
    
    
}