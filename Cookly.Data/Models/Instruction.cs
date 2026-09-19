namespace Cookly.Data.Models;

public class Instruction
{
    public int InstructionId { get; set; }
    public string Preparation { get; set; }
    //fk
    public int? DishId { get; set; }
    public Dish? Dish { get; set; }
}