using System.ComponentModel;
using Cookly.Business.IServices;

namespace Cookly.Agents.Tools;

public class NutritionTools(INutritionToolsService _nutritionToolsService, MealPlanContext _mealPlan)
{
    [Description("Gets the user's dietary goal and food preferences, including any allergies or dislikes.")]
    public async Task<string> GetUserGoalsAndPreferences(CancellationToken token)
    {
        var result = await _nutritionToolsService.GetGoalsAndPreferences(token);
        if (!result.Success)
            return $"Could not load goals and preferences ({result.Message ?? result.MessageKey}). " +
                   "Assume a balanced diet with no restrictions.";

        var goal = string.IsNullOrWhiteSpace(result.Data.Goal) ? "not set, assume a balanced diet" : result.Data.Goal;
        var preference = string.IsNullOrWhiteSpace(result.Data.Preference) ? "none set" : result.Data.Preference;
        return $"Goal: {goal}. Preferences: {preference}.";
    }

    [Description("Lists every meal already suggested to this user. Never suggest any of these again.")]
    public async Task<string> GetPreviouslySuggestedMeals(CancellationToken token)
    {
        var result = await _nutritionToolsService.GetPreviouslySuggestedMeals(token);
        if (!result.Success)
            return $"Could not load previously suggested meals ({result.Message ?? result.MessageKey}).";

        return result.Data.Count == 0
            ? "No meals have been suggested yet."
            : string.Join(", ", result.Data);
    }

    [Description(
        "Call this ONLY when no new meal (one not already suggested) can be made from the current " +
        "pantry. Records grocery items for the user to buy, chosen to fit their goal and preferences.")]
    public string ReportNoNewMealPossible(
        [Description("3 to 8 grocery items to buy that fit the user's goal and preferences.")] string[] itemsToBuy)
    {
        _mealPlan.RequestRefill(itemsToBuy);
        return "Recorded. Do not hand off and do not ask the user anything; end your turn now.";
    }
}
