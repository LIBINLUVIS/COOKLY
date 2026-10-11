using Cookly.Data.enums;

namespace Cookly.Agents.Tools;

/// <summary>Per-request meal-plan state shared by the controller and the agent tools.</summary>
public class MealPlanContext
{
    public Meal MealType { get; set; }
    public bool RefillRequired { get; private set; }
    public IReadOnlyList<string> SuggestedItemsToBuy { get; private set; } = [];
    public IReadOnlyList<RejectedDish> RejectedCandidates { get; private set; } = [];
    public SavedDish? SavedDish { get; set; }

    public void RequestRefill(IEnumerable<string> itemsToBuy, IEnumerable<RejectedDish> rejectedCandidates)
    {
        RefillRequired = true;
        RejectedCandidates = rejectedCandidates.ToList();
        SuggestedItemsToBuy = itemsToBuy
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .Select(item => item.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }
}

public record RejectedDish(
    [property: System.ComponentModel.Description("The candidate dish name.")] string Dish,
    [property: System.ComponentModel.Description("Why it was rejected, e.g. 'already suggested' or 'needs eggs, not in pantry'.")] string Reason);

/// <summary>The recipe CookAgent saved, for clients that need it structured.</summary>
public record SavedDish(int DishId, string Name, string? Description, IReadOnlyList<RecipeIngredient> Ingredients, IReadOnlyList<string> Steps);
