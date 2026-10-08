using Cookly.Business.IServices;
using Cookly.Data;
using Cookly.Data.DTOS;
using Cookly.Data.Models;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Business.Services;

public class RecipeToolsService(UserService _userService, CooklyDbContext _context) : IRecipeToolsService
{
    public async Task<ServiceResponseDto<int>> SaveDish(SaveDishDto dish, CancellationToken token)
    {
        var userId = _userService.GetUserId();
        if (userId <= 0)
            return new() { Success = false, MessageKey = "UserId is null" };

        if (string.IsNullOrWhiteSpace(dish.Name))
            return new() { Success = false, Message = "Dish name is required" };

        try
        {
            var profile = await _context.Profiles.AsNoTracking()
                .Where(p => p.UserId == userId)
                .Select(p => new { p.ProfileId, p.Goal })
                .FirstOrDefaultAsync(token);

            var entity = new Dish
            {
                Name = dish.Name.Trim(),
                Meal = dish.Meal,
                Goal = profile?.Goal,
                SuggestedDate = DateTime.UtcNow,
                UserId = userId,
                ProfileId = profile?.ProfileId,
                Ingredients = dish.Ingredients
                    .Where(i => !string.IsNullOrWhiteSpace(i.Name))
                    .Select(i => new Ingredient { Name = i.Name.Trim(), Quantity = i.Quantity?.Trim() })
                    .ToList(),
                Instructions = dish.Instructions
                    .Where(step => !string.IsNullOrWhiteSpace(step))
                    .Select(step => new Instruction { Preparation = step.Trim() })
                    .ToList()
            };

            _context.Dishes.Add(entity);
            await _context.SaveChangesAsync(token);

            return new() { Data = entity.DishId, Success = true, Message = "Dish saved successfully" };
        }
        catch (Exception ex)
        {
            return new()
            {
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception occurred while saving the dish,{ex.Message}"
            };
        }
    }
}
