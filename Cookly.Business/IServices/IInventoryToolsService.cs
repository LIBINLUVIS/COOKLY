using Cookly.Data.DTOS;

namespace Cookly.Business.IServices;

public interface IInventoryToolsService
{
    public Task<ServiceResponseDto<List<ListItems>>> ListItems(CancellationToken token);
    
    public Task<ServiceResponseDto<List<ListItems>>> GetExpiredItems(CancellationToken token);
    public Task<ServiceResponseDto<List<ListItems>>> GetExpiringSoonItems(CancellationToken token);
}