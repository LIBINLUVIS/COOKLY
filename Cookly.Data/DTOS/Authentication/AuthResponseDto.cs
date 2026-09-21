namespace Cookly.Data.DTOS.Authentication;

public class AuthResponseDto
{
    public string Token { get; set; }
    public DateTime TokenExpiry { get; set; }
}