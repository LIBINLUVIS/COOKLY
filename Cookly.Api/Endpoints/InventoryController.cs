using Cookly.Business.IServices;
using Cookly.Business.Services;
using Cookly.Business.Validators;
using Cookly.Data.DTOS;
using Cookly.Data.DTOS.Authentication;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;

namespace Cookly.Api.Endpoints;

public static class InventoryController
{
    public static IEndpointRouteBuilder MapInventoryEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/inventory")
            .WithTags("Inventory");

        
        group.MapPost("/add-item", AddItem).RequireAuthorization();
        group.MapGet("/list-item", ListItem).RequireAuthorization();
        return app;
    }

    private static async Task<IResult> AddItem([FromBody] ItemAddRequestDto request,IInventoryService _inventoryService,UserService _user,CancellationToken ctk)
    {
        var (isValid, errors) = request.TryValidate();
        if (!isValid)
        {
            return Results.ValidationProblem(errors);
        }
        var userId = _user.GetUserId();
        
        var result = await _inventoryService.ItemAdd(request,userId,ctk);
        
        return Results.Ok(result);
    }

    private static async Task<IResult> ListItem(IInventoryService _inventoryService, UserService _user,
        CancellationToken ctk)
    {
        var userId = _user.GetUserId();
        var result = await _inventoryService.ListItems(userId, ctk);
        return Results.Ok(result);
    }
}