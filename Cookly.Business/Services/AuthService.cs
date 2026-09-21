using Cookly.Business.IServices;
using Cookly.Data;
using Cookly.Data.DTOS;
using Cookly.Data.DTOS.Authentication;
using Cookly.Data.Models;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Business.Services;

public class AuthService(CooklyDbContext context,ITokenService tokenService):IAuthService
{
    public async Task<ServiceResponseDto<AuthResponseDto>> LoginAsync(AuthRequestDto data,CancellationToken ctk)
    {
        //check if the user is their in the db
        if (string.IsNullOrEmpty(data.Email))
        {
            return new ServiceResponseDto<AuthResponseDto>
            {
               Data = null,
               Message = "Email is Required for Signin",
               Success = false
            };
        }

        try
        {
            
        var user = await context.Users.AsNoTracking().Where(p => p.Email == data.Email).FirstOrDefaultAsync(ctk);

        if (user == null)
        {
            
            // create a new user and save to db,and return the auth token generated for the user.
            var userObj = new User()
            {
                Email = data.Email,
                FirstName = data.FirstName ?? "",
                LastName = data.LastName ?? "",
                DisplayName = data.DisplayName ?? "",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                //Todo: make it nullable field
                DeletedAt = DateTime.UtcNow,
                AccessToken = "",
                RefreshToken = "",
                AccessTokenExpiry = DateTime.UtcNow,
                RefreshTokenExpiry = DateTime.UtcNow
            };
            
            //generate a new accesstoken for the current user.
            var (token, expiry) = tokenService.CreateToken(userObj);

            userObj.AccessToken = token ?? "";
            userObj.AccessTokenExpiry = expiry;

            var userProfile = new Profile();
            var userInventory = new Inventory();

            userObj.Inventory = userInventory;
            userObj.Profile = userProfile;

             context.Users.Add(userObj);
             await context.SaveChangesAsync(ctk);

             var result = new AuthResponseDto()
             {
                Token = token ?? "",
                TokenExpiry = expiry
             };

             return new ServiceResponseDto<AuthResponseDto>
             {
                 Data = result,
                 Success = true,
                 Message = "User Saved Successfully!"
             };
        }
        
        //generate a new accesstoken for the current user.
        var (accessToken, expiryToken) = tokenService.CreateToken(user);

        user.AccessToken = accessToken;
        user.AccessTokenExpiry = expiryToken;
        user.LastLoginAt = DateTime.UtcNow;
        user.UpdatedAt = DateTime.UtcNow;

        await context.SaveChangesAsync(ctk);

        return new ServiceResponseDto<AuthResponseDto>
        {
            Data = new AuthResponseDto { Token = accessToken, TokenExpiry = expiryToken },
            Success = true,
            Message = "Auth Successfull!"
        };
            
        }

        catch (Exception ex)
        {
            //todo: add some logger for prod
            return new ServiceResponseDto<AuthResponseDto>
            {
                Data = null,
                Message = $"{ex}",
                Success = false
            };
        }
        
    }
}