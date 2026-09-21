using Cookly.Data.Models;

namespace Cookly.Business.IServices;

public interface ITokenService
{
    public (string Token, DateTime ExpiresAt) CreateToken(User user);
}