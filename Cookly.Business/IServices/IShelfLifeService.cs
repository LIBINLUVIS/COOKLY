using Cookly.Data.DTOS;

namespace Cookly.Business.IServices;

public interface IShelfLifeService
{
    /// <summary>Days an item typically keeps after purchase: lookup table first, AI fallback for unknown items.</summary>
    public Task<ServiceResponseDto<int>> GetShelfLifeDays(string itemName, CancellationToken token);
}
