using Cookly.Business.IServices;
using Cookly.Business.Services;

namespace Cookly.Api.Endpoints;

public static class DishController
{
    public static IEndpointRouteBuilder MapDishEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/dishes")
            .WithTags("Dishes");

        group.MapGet("/history", GetHistory).RequireAuthorization();
        return app;
    }

    private static async Task<IResult> GetHistory(IDishService _dishService, UserService _user, CancellationToken ctk)
    {
        var result = await _dishService.GetDishHistory(_user.GetUserId(), ctk);
        return Results.Ok(result);
    }
}
