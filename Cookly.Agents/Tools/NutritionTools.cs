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

    private const int MinRejectedCandidates = 3;

    [Description("Lists the dishes already suggested to this user for the current meal type. Do not suggest these again.")]
    public async Task<string> GetPreviouslySuggestedMeals(CancellationToken token)
    {
        var result = await _nutritionToolsService.GetPreviouslySuggestedMeals(_mealPlan.MealType, token);
        if (!result.Success)
            return $"Could not load previously suggested meals ({result.Message ?? result.MessageKey}).";

        return result.Data.Count == 0
            ? $"No {_mealPlan.MealType} dishes have been suggested yet."
            : string.Join(", ", result.Data);
    }

    [Description("Checks whether a proposed dish was already suggested for this meal type. Call it for your chosen dish before handing off.")]
    public async Task<string> CheckDishIsNew(
        [Description("The proposed dish name.")] string dishName,
        CancellationToken token)
    {
        var result = await _nutritionToolsService.FindMatchingSuggestedDish(dishName, _mealPlan.MealType, token);
        if (!result.Success)
            return $"Could not check the history ({result.Message ?? result.MessageKey}); treat '{dishName}' as new.";

        return result.Data is null
            ? $"NEW: '{dishName}' has not been suggested for {_mealPlan.MealType}."
            : $"ALREADY SUGGESTED: matches '{result.Data}'. Pick a different dish.";
    }

    [Description(
        "Last resort, only after you have tried at least 3 different candidate dishes for this meal type " +
        "and rejected every one. Records grocery items for the user to buy.")]
    public string ReportNoNewMealPossible(
        [Description("Every candidate dish you considered and why it was rejected (at least 3).")] RejectedDish[] rejectedCandidates,
        [Description("3 to 8 grocery items to buy that fit the user's goal and preferences.")] string[] itemsToBuy)
    {
        var distinct = rejectedCandidates
            .Where(c => !string.IsNullOrWhiteSpace(c.Dish))
            .DistinctBy(c => c.Dish.Trim().ToLowerInvariant())
            .ToList();

        if (distinct.Count < MinRejectedCandidates)
            return $"Not accepted: you only rejected {distinct.Count} distinct candidate(s). Consider at least " +
                   $"{MinRejectedCandidates} different dishes from the pantry (other cooking styles or cuisines) " +
                   "and check each with CheckDishIsNew before reporting.";

        _mealPlan.RequestRefill(itemsToBuy, distinct);
        return "Recorded. Do not hand off and do not ask the user anything; end your turn now.";
    }
}
