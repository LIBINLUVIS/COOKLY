using Cookly.Data.enums;

namespace Cookly.Data.DTOS;

public class UserGoalsDto
{
    public string? Goal { get; set; }
    public string? Preference { get; set; }
}

public class SaveDishDto
{
    public string Name { get; set; } = "";
    public Meal Meal { get; set; }
    public List<DishIngredientDto> Ingredients { get; set; } = [];
    public List<string> Instructions { get; set; } = [];
}

public class DishIngredientDto
{
    public string Name { get; set; } = "";
    public string? Quantity { get; set; }
}
