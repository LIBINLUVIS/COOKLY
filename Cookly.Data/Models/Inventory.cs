namespace Cookly.Data.Models;

public class Inventory
{
    public int InventoryId { get; set; }
    //fk
    public int UserId { get; set; }
    public User? User { get; set; }
    public DateTime? LastUpdatedOn { get; set; }
    public ICollection<Item>? Items { get; set; }
    
}