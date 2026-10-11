using Cookly.Data.DTOS;
using Cookly.Data.enums;

namespace Cookly.Business.IServices;

public interface INutritionToolsService
{
    public Task<ServiceResponseDto<UserGoalsDto>> GetGoalsAndPreferences(CancellationToken token);
    public Task<ServiceResponseDto<List<string>>> GetPreviouslySuggestedMeals(Meal mealType, CancellationToken token);
    public Task<ServiceResponseDto<string?>> FindMatchingSuggestedDish(string dishName, Meal mealType, CancellationToken token);
}
