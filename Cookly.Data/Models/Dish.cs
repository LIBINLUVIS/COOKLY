using Cookly.Data.enums;

namespace Cookly.Data.Models;

public class Dish
{
    public int DishId { get; set; }
    public string Name { get; set; }
    public Meal Meal { get; set; }
    public string? Goal { get; set; }
    public DateTime? CookTime { get; set; }
    public DateTime SuggestedDate { get; set; }
    public int? UserId { get; set; }
    //fk
    public int? ProfileId { get; set; }
    public Profile? Profile { get; set; }
    public ICollection<Ingredient>? Ingredients { get; set; }
    public ICollection<Instruction>? Instructions { get; set; }
}