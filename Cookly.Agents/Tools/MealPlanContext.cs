using Cookly.Data.enums;

namespace Cookly.Agents.Tools;

/// <summary>Per-request meal-plan state shared by the controller and the agent tools.</summary>
public class MealPlanContext
{
    public Meal MealType { get; set; }
    public bool RefillRequired { get; private set; }
    public IReadOnlyList<string> SuggestedItemsToBuy { get; private set; } = [];
    public SavedDish? SavedDish { get; set; }

    public void RequestRefill(IEnumerable<string> itemsToBuy)
    {
        RefillRequired = true;
        SuggestedItemsToBuy = itemsToBuy
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .Select(item => item.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }
}

/// <summary>The recipe CookAgent saved, for clients that need it structured.</summary>
public record SavedDish(int DishId, string Name, string? Description, IReadOnlyList<RecipeIngredient> Ingredients, IReadOnlyList<string> Steps);
