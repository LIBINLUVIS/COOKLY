using System.ComponentModel;
using Cookly.Business.IServices;
using Cookly.Data.DTOS;
using Cookly.Data.Models;
using Microsoft.Extensions.AI;

namespace Cookly.Business.Services;

public class AIService(IChatClient _chatClient) : IAIService
{
    private const int MaxShelfLifeDays = 3650;

    public async Task<ServiceResponseDto<DateTime>> GetItemExpiryDateTime(string ItemName, DateTime purchasedAt, CancellationToken token)
    {
        var days = await GetShelfLifeDays(ItemName, token);
        return days.Success
            ? new ServiceResponseDto<DateTime> { Data = purchasedAt.AddDays(days.Data), Success = true, Message = "Expiry predicted successfully" }
            : Fail<DateTime>(days.Message, days.MessageKey);
    }

    public async Task<ServiceResponseDto<int>> GetShelfLifeDays(string ItemName, CancellationToken token)
    {
        if (string.IsNullOrWhiteSpace(ItemName))
        {
            return Fail<int>("Item name is required");
        }

        var prediction = await AskAsync<ShelfLifePrediction>(
            "You are a food-safety assistant for a home kitchen. Estimate how many days a freshly " +
            "purchased grocery item stays safe and good to eat under typical home storage " +
            "(refrigerate perishables, keep dry goods in the pantry). Be conservative.",
            $"Item: {ItemName.Trim()}",
            token);

        if (!prediction.Success)
        {
            return Fail<int>(prediction.Message, prediction.MessageKey);
        }

        var days = prediction.Data!.ShelfLifeDays;
        if (days < 0 || days > MaxShelfLifeDays)
        {
            return Fail<int>("Could not predict the expiry for this item",
                $"AI returned an out-of-range shelf life of {days} days for '{ItemName}'");
        }

        return new ServiceResponseDto<int> { Data = days, Success = true, Message = "Shelf life predicted successfully" };
    }

    /// <summary>
    /// Sends one instruction + input pair and parses the reply into <typeparamref name="T"/>
    /// via a JSON-schema structured response. New AI features should go through here.
    /// </summary>
    private async Task<ServiceResponseDto<T>> AskAsync<T>(string instructions, string input, CancellationToken token)
    {
        try
        {
            var response = await _chatClient.GetResponseAsync<T>(
                [new ChatMessage(ChatRole.System, instructions), new ChatMessage(ChatRole.User, input)],
                cancellationToken: token);

            if (response.TryGetResult(out var result) && result is not null)
            {
                return new ServiceResponseDto<T> { Data = result, Success = true };
            }

            return Fail<T>("Oops Something went wrong!", $"AI response could not be parsed as {typeof(T).Name}");
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            return Fail<T>("Oops Something went wrong!", $"Exception occurred while calling the AI service,{ex.Message}");
        }
    }

    private static ServiceResponseDto<T> Fail<T>(string? message, string? messageKey = null) => new()
    {
        Data = default!,
        Success = false,
        Message = message,
        MessageKey = messageKey
    };

    private sealed record ShelfLifePrediction(
        [property: Description("Estimated number of days from purchase until the item should be used or discarded.")]
        int ShelfLifeDays);
}
