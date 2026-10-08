using Cookly.Data.DTOS;

namespace Cookly.Business.IServices;

public interface INutritionToolsService
{
    public Task<ServiceResponseDto<UserGoalsDto>> GetGoalsAndPreferences(CancellationToken token);
    public Task<ServiceResponseDto<List<string>>> GetPreviouslySuggestedMeals(CancellationToken token);
}
