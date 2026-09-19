namespace Cookly.Data.Models;

public class User
{
    public int UserId { get; set; }
    public string Email { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? DisplayName { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime LastLoginAt { get; set; }
    public DateTime DeletedAt { get; set; }
    public string AccessToken { get; set; }
    public DateTime AccessTokenExpiry { get; set; }
    public string RefreshToken { get; set; }
    public DateTime RefreshTokenExpiry { get; set; }
    
    public Inventory? Inventory { get; set; }
    public Profile? Profile { get; set; }
}