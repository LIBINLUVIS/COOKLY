using Cookly.Business.IServices;
using Cookly.Data;
using Cookly.Data.DTOS;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Business.Services;

public class NutritionToolsService(UserService _userService, CooklyDbContext _context) : INutritionToolsService
{
    public async Task<ServiceResponseDto<UserGoalsDto>> GetGoalsAndPreferences(CancellationToken token)
    {
        var userId = _userService.GetUserId();
        if (userId <= 0)
            return new() { Data = null!, Success = false, MessageKey = "UserId is null" };

        var goals = await _context.Profiles.AsNoTracking()
            .Where(p => p.UserId == userId)
            .Select(p => new UserGoalsDto { Goal = p.Goal, Preference = p.Preference })
            .FirstOrDefaultAsync(token);

        return new() { Data = goals ?? new UserGoalsDto(), Success = true };
    }

    // All-time, across every meal type, so a dish is never suggested twice.
    public async Task<ServiceResponseDto<List<string>>> GetPreviouslySuggestedMeals(CancellationToken token)
    {
        var userId = _userService.GetUserId();
        if (userId <= 0)
            return new() { Data = [], Success = false, MessageKey = "UserId is null" };

        var dishNames = await _context.Dishes.AsNoTracking()
            .Where(d => d.UserId == userId)
            .Select(d => d.Name)
            .Distinct()
            .ToListAsync(token);

        return new() { Data = dishNames, Success = true };
    }
}
