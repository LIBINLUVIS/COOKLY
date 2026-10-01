using Microsoft.AspNetCore.Http;

namespace Cookly.Business.Services;

public class UserService(IHttpContextAccessor _httpContextAccessor)  
{
    public int GetUserId()
    {
        var context = _httpContextAccessor.HttpContext;

        if (context == null)
        {
            return 0;
        }

        var userId = context.User.FindFirst("sub")?.Value;

        if (!string.IsNullOrEmpty(userId))
        {
            return Convert.ToInt32(userId);
        }

        return 0;
    }
}