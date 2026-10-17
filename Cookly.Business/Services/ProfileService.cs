using Cookly.Business.IServices;
using Cookly.Data;
using Cookly.Data.DTOS;
using Cookly.Data.Models;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Business.Services;

public class ProfileService(CooklyDbContext _context) : IProfileService
{
    public async Task<ServiceResponseDto<ProfileDto>> GetProfile(int userId, CancellationToken token)
    {
        if (userId <= 0)
            return new() { Data = null!, Success = false, MessageKey = "UserId is null" };

        try
        {
            var profile = await _context.Users.AsNoTracking()
                .Where(u => u.UserId == userId)
                .Select(u => new ProfileDto
                {
                    Email = u.Email,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    DisplayName = u.DisplayName,
                    MemberSince = u.CreatedAt,
                    Goal = u.Profile != null ? u.Profile.Goal : null,
                    Preference = u.Profile != null ? u.Profile.Preference : null,
                    DishesCount = _context.Dishes.Count(d => d.UserId == userId),
                    PantryItemsCount = _context.Items.Count(i => i.Inventory!.UserId == userId),
                })
                .FirstOrDefaultAsync(token);

            return profile is null
                ? new() { Data = null!, Success = false, Message = "User not found" }
                : new() { Data = profile, Success = true };
        }
        catch (Exception ex)
        {
            return new()
            {
                Data = null!,
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception occurred while loading the profile,{ex.Message}"
            };
        }
    }

    // Goal and Preference feed NutritionAgent's meal suggestions.
    public async Task<ServiceResponseDto<ProfileDto>> UpdatePreferences(int userId, UpdateProfilePreferencesDto request, CancellationToken token)
    {
        if (userId <= 0)
            return new() { Data = null!, Success = false, MessageKey = "UserId is null" };

        try
        {
            var profile = await _context.Profiles.FirstOrDefaultAsync(p => p.UserId == userId, token);
            if (profile is null)
            {
                profile = new Profile { UserId = userId };
                _context.Profiles.Add(profile);
            }

            profile.Goal = string.IsNullOrWhiteSpace(request.Goal) ? null : request.Goal.Trim();
            profile.Preference = string.IsNullOrWhiteSpace(request.Preference) ? null : request.Preference.Trim();
            await _context.SaveChangesAsync(token);
        }
        catch (Exception ex)
        {
            return new()
            {
                Data = null!,
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception occurred while saving the profile,{ex.Message}"
            };
        }

        var updated = await GetProfile(userId, token);
        if (updated.Success)
            updated.Message = "Profile updated";
        return updated;
    }
}
