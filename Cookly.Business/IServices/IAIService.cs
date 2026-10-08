using Cookly.Data.DTOS;
using Cookly.Data.Models;

namespace Cookly.Business.IServices;

public interface IAIService
{
    Task<ServiceResponseDto<DateTime>> GetItemExpiryDateTime(string ItemName, DateTime purchasedAt, CancellationToken token);
}