using Cookly.Business.IServices;
using Cookly.Data;
using System.Text.RegularExpressions;
using Cookly.Data.DTOS;
using Cookly.Data.enums;
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

    private static readonly HashSet<string> FillerWords = ["a", "an", "and", "the", "with", "of", "in", "on", "style"];

    // All-time history, limited to the given meal type.
    public async Task<ServiceResponseDto<List<string>>> GetPreviouslySuggestedMeals(Meal mealType, CancellationToken token)
    {
        var userId = _userService.GetUserId();
        if (userId <= 0)
            return new() { Data = [], Success = false, MessageKey = "UserId is null" };

        var dishNames = await _context.Dishes.AsNoTracking()
            .Where(d => d.UserId == userId && d.Meal == mealType)
            .Select(d => d.Name)
            .Distinct()
            .ToListAsync(token);

        return new() { Data = dishNames, Success = true };
    }

    // Returns the already-suggested dish that matches the name (ignoring case, punctuation and filler words), or null if it's new.
    public async Task<ServiceResponseDto<string?>> FindMatchingSuggestedDish(string dishName, Meal mealType, CancellationToken token)
    {
        var history = await GetPreviouslySuggestedMeals(mealType, token);
        if (!history.Success)
            return new() { Success = false, MessageKey = history.MessageKey };

        var key = NormalizeDishName(dishName);
        var match = history.Data.FirstOrDefault(name => NormalizeDishName(name) == key);
        return new() { Data = match, Success = true };
    }

    private static string NormalizeDishName(string name)
    {
        var words = Regex.Split(name.ToLowerInvariant(), "[^a-z0-9]+")
            .Where(w => w.Length > 0 && !FillerWords.Contains(w))
            .Select(w => w.Length > 3 && w.EndsWith('s') ? w[..^1] : w);
        return string.Join(' ', words);
    }
}
