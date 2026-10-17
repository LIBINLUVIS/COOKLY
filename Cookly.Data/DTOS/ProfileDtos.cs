using System.ComponentModel.DataAnnotations;

namespace Cookly.Data.DTOS;

public class ProfileDto
{
    public string Email { get; set; } = "";
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? DisplayName { get; set; }
    public DateTime MemberSince { get; set; }
    public string? Goal { get; set; }
    public string? Preference { get; set; }
    public int DishesCount { get; set; }
    public int PantryItemsCount { get; set; }
}

public class UpdateProfilePreferencesDto
{
    [StringLength(350, ErrorMessage = "Goal can be at most 350 characters")]
    public string? Goal { get; set; }

    [StringLength(350, ErrorMessage = "Preferences can be at most 350 characters")]
    public string? Preference { get; set; }
}
