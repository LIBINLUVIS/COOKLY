using System.Net.ServerSentEvents;
using System.Runtime.CompilerServices;
using Cookly.Api.Jobs;
using Cookly.Api.Services;
using Cookly.Business.IServices;
using Cookly.Business.Services;
using Cookly.Business.Validators;
using Cookly.Data.DTOS;
using Cookly.Data.DTOS.Authentication;
using Microsoft.AspNetCore.Http.HttpResults;
using Coravel.Queuing.Interfaces;
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
        group.MapDelete("/delete-item/{itemId:int}", DeleteItem).RequireAuthorization();
        group.MapPatch("/update-quantity", UpdateItemQuantity).RequireAuthorization();
        group.MapGet("/events", StreamEvents).RequireAuthorization();
       
        return app;
    }

    private static async Task<IResult> AddItem([FromBody] ItemAddRequestDto request,IInventoryService _inventoryService,UserService _user,IQueue _queue,CancellationToken ctk)
    {
        var (isValid, errors) = request.TryValidate();
        if (!isValid)
        {
            return Results.ValidationProblem(errors);
        }
        var userId = _user.GetUserId();
        
        var result = await _inventoryService.ItemAdd(request,userId,ctk);

        // No expiry given: fill it in the background and push it to the app over /events.
        if (result.Success && request.ExpiredAt is null && int.TryParse(result.Data, out var itemId))
        {
            _queue.QueueInvocableWithPayload<FillItemExpiryJob, FillItemExpiryPayload>(new FillItemExpiryPayload(itemId, userId));
        }
        
        return Results.Ok(result);
    }

    private static readonly TimeSpan KeepAliveInterval = TimeSpan.FromSeconds(25);

    // Server-Sent Events for the signed-in user's pantry (e.g. item_expiry_updated).
    private static IResult StreamEvents(UserService _user, PantryEventHub _eventHub, CancellationToken ctk)
    {
        var userId = _user.GetUserId();
        if (userId <= 0)
            return Results.Unauthorized();

        return TypedResults.ServerSentEvents(ReadEvents(userId, _eventHub, ctk));
    }

    private static async IAsyncEnumerable<SseItem<object>> ReadEvents(int userId, PantryEventHub eventHub,
        [EnumeratorCancellation] CancellationToken ctk)
    {
        var (subscriptionId, reader) = eventHub.Subscribe(userId);
        try
        {
            yield return new SseItem<object>(new { connected = true }, "ready");
            while (!ctk.IsCancellationRequested)
            {
                var evt = await WaitForEventAsync(reader, ctk);
                if (evt is null && ctk.IsCancellationRequested)
                    yield break;
                // A periodic ping keeps proxies and the app from treating an idle stream as dead.
                yield return evt is null
                    ? new SseItem<object>(new { }, "ping")
                    : new SseItem<object>(evt.Data, evt.Type);
            }
        }
        finally
        {
            eventHub.Unsubscribe(userId, subscriptionId);
        }
    }

    private static async Task<PantryEvent?> WaitForEventAsync(System.Threading.Channels.ChannelReader<PantryEvent> reader, CancellationToken ctk)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ctk);
        timeout.CancelAfter(KeepAliveInterval);
        try
        {
            return await reader.ReadAsync(timeout.Token);
        }
        catch (OperationCanceledException)
        {
            return null;
        }
    }

    private static async Task<IResult> ListItem(IInventoryService _inventoryService, UserService _user,
        CancellationToken ctk)
    {
        var userId = _user.GetUserId();
        var result = await _inventoryService.ListItems(userId, ctk);
        return Results.Ok(result);
    }

    private static async Task<IResult> DeleteItem(int itemId, IInventoryService _inventoryService, UserService _user,
        CancellationToken ctk)
    {
        var userId = _user.GetUserId();
        var result = await _inventoryService.ItemDelete(itemId, userId, ctk);
        return Results.Ok(result);
    }

    private static async Task<IResult> UpdateItemQuantity([FromBody] ItemQuantityUpdateRequestDto request,
        IInventoryService _inventoryService, UserService _user, CancellationToken ctk)
    {
        var (isValid, errors) = request.TryValidate();
        if (!isValid)
        {
            return Results.ValidationProblem(errors);
        }
        var userId = _user.GetUserId();

        var result = await _inventoryService.ItemQuantityUpdate(request, userId, ctk);

        return Results.Ok(result);
    }

    
}