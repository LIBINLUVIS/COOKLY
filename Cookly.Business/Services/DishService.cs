using Cookly.Business.IServices;
using Cookly.Data;
using Cookly.Data.DTOS;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Business.Services;

public class DishService(CooklyDbContext _context) : IDishService
{
    // Every dish suggested to the user, newest first, with its ingredients and steps.
    public async Task<ServiceResponseDto<List<DishHistoryDto>>> GetDishHistory(int userId, CancellationToken token)
    {
        if (userId <= 0)
            return new() { Data = [], Success = false, MessageKey = "UserId is null" };

        try
        {
            var dishes = await _context.Dishes.AsNoTracking()
                .Where(d => d.UserId == userId)
                .OrderByDescending(d => d.SuggestedDate)
                .Select(d => new DishHistoryDto
                {
                    DishId = d.DishId,
                    Name = d.Name,
                    Meal = d.Meal,
                    Goal = d.Goal,
                    SuggestedDate = d.SuggestedDate,
                    Ingredients = d.Ingredients!
                        .OrderBy(i => i.IngredientId)
                        .Select(i => new DishIngredientDto { Name = i.Name ?? "", Quantity = i.Quantity })
                        .ToList(),
                    Steps = d.Instructions!
                        .OrderBy(s => s.InstructionId)
                        .Select(s => s.Preparation)
                        .ToList(),
                })
                .AsSplitQuery()
                .ToListAsync(token);

            return new() { Data = dishes, Success = true };
        }
        catch (Exception ex)
        {
            return new()
            {
                Data = [],
                Success = false,
                Message = "Oops Something went wrong!",
                MessageKey = $"Exception occurred while loading the dish history,{ex.Message}"
            };
        }
    }
}
