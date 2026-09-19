namespace Cookly.Data.Models;

public class Ingredient
{
    public int IngredientId { get; set; }
    public string? Name { get; set; }
    public string? Quantity { get; set; }
    //fk
    public int? DishId { get; set; }
    public Dish? Dish { get; set; }
    
}