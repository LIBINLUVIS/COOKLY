namespace Cookly.Data.DTOS.Authentication;

public class AuthRequestDto
{
    public string Email { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? DisplayName { get; set; }
}