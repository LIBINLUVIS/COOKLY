using System.ComponentModel;
using Cookly.Business.IServices;
using Cookly.Data.DTOS;

namespace Cookly.Agents.Tools;

public class RecipeTools(IRecipeToolsService _recipeToolsService, MealPlanContext _mealPlan)
{
    [Description("Saves the final recipe to the user's meal history. Call exactly once, after writing the recipe.")]
    public async Task<string> SaveSuggestedDish(
        [Description("The dish name, e.g. 'Spinach Chicken Rice Bowl'.")] string dishName,
        [Description("Every ingredient used, with its quantity.")] RecipeIngredient[] ingredients,
        [Description("The cooking steps in order, one per entry, each formatted 'Short title: what to do'.")] string[] instructions,
        CancellationToken token,
        [Description("One appetising sentence describing the dish.")] string? description = null)
    {
        var result = await _recipeToolsService.SaveDish(new SaveDishDto
        {
            Name = dishName,
            Meal = _mealPlan.MealType,
            Ingredients = ingredients.Select(i => new DishIngredientDto { Name = i.Name, Quantity = i.Quantity }).ToList(),
            Instructions = instructions.ToList()
        }, token);

        if (!result.Success)
            return $"Could not save the dish ({result.Message ?? result.MessageKey}). Still give the user the recipe.";

        _mealPlan.SavedDish = new SavedDish(result.Data, dishName.Trim(), description?.Trim(), ingredients, instructions);
        return "Saved to the user's meal history.";
    }
}

public record RecipeIngredient(
    [property: Description("Ingredient name exactly as it appears in the pantry.")] string Name,
    [property: Description("Amount used, e.g. '200 g' or '2 pcs'.")] string Quantity);
