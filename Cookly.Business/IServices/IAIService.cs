using Cookly.Data.DTOS;
using Cookly.Data.Models;

namespace Cookly.Business.IServices;

public interface IAIService
{
    Task<ServiceResponseDto<int>> GetShelfLifeDays(string itemName, CancellationToken token);
    Task<ServiceResponseDto<DateTime>> GetItemExpiryDateTime(string ItemName, DateTime purchasedAt, CancellationToken token);
}