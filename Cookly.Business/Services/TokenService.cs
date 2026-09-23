using System.Security.Claims;
using System.Text;
using Cookly.Business.IServices;
using Cookly.Data.DTOS;
using Cookly.Data.Models;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using JwtRegisteredClaimNames = System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames;

namespace Cookly.Business.Services;

public class TokenService(IOptions<JwtSettings> jwtSettings) : ITokenService
{
    private readonly JwtSettings _settings = jwtSettings.Value;


    public (string Token, DateTime ExpiresAt) CreateToken(User user)
    {
        var expiresAt = DateTime.UtcNow.AddMinutes(_settings.ExpiryMinutes);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email!),
            new(JwtRegisteredClaimNames.Name, $"{user.FirstName} {user.LastName}"),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

       var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.Key));
       var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);
        
        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = expiresAt,
            Issuer = _settings.Issuer,
            Audience = _settings.Audience,
            SigningCredentials = credentials
        };
        
        var handler = new JsonWebTokenHandler();
        var token = handler.CreateToken(descriptor);
        
        
        return (token, expiresAt);
    }
}