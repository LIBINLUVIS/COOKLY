using System.ComponentModel.DataAnnotations;
using Cookly.Data.enums;

namespace Cookly.Data.DTOS;

public class ItemAddRequestDto
{
    [Required(ErrorMessage="Item Name is Required")]
    public string ItemName { get; set; }
    
    [Required(ErrorMessage="Item Quantity is Required")]
    public int Quantity { get; set; }
    [Required(ErrorMessage="Item Unit is Required")]
    public string Unit { get; set; }
    public DateTime? ExpiredAt { get; set; }
    public Category Category { get; set; } = Category.Others;
    
}

public class ListItems
{
    public string ItemName { get; set; }
    public int Quantity { get; set; }
    public string Unit { get; set; }
    public DateTime PurchasedAt { get; set; }
    public DateTime? ExpiredAt { get; set; }
    public Category? Category { get; set; }
    public int ItemId { get; set; }
}

public class ItemQuantityUpdateRequestDto
{
    [Required(ErrorMessage="ItemId is Required")]
    public int ItemId { get; set; }

    [Required(ErrorMessage="QuantityChange is Required")]
    public int QuantityChange { get; set; }
}