using Cookly.Data.DTOS;

namespace Cookly.Business.IServices;

public interface IDishService
{
    public Task<ServiceResponseDto<List<DishHistoryDto>>> GetDishHistory(int userId, CancellationToken token);
}
