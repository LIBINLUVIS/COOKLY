using COOKLY.Data.enums;

namespace COOKLY.Data.Models;

public class Item
{
    public int ItemId { get; set; }
    public string Name { get; set; }
    public int Quantity { get; set; }
    public string Unit { get; set; }
    public DateTime PurchasedAt { get; set; }
    public DateTime? ExpiryAt { get; set; }
    public Category Category { get; set; }
    
    public int? InventoryId { get; set; }
    public Inventory? Inventory { get; set; }
}