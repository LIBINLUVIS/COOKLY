using Cookly.Data.DTOS;

namespace Cookly.Business.IServices;

public interface IRecipeToolsService
{
    public Task<ServiceResponseDto<int>> SaveDish(SaveDishDto dish, CancellationToken token);
}
