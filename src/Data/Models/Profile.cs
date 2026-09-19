namespace COOKLY.Data.Models;

public class Profile
{
    public int ProfileId { get; set; }
    public string? Goal { get; set; }
    public string? Preference { get; set; }
    public string? Progress { get; set; }
    //fk
    public int? UserId { get; set; }
    public User? User { get; set; }
    public ICollection<Dish>? Dishes { get; set; } = new List<Dish>();
}