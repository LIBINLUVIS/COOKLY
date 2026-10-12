using System.Diagnostics;
using Cookly.Business.IServices;
using Cookly.Data.DTOS;
using Cookly.Data.Models;
using Microsoft.Extensions.Logging;

namespace Cookly.Business.Services;

public class ShelfLifeService(ShelfLifeCatalog _catalog, IAIService _aiService, ILogger<ShelfLifeService> _logger) : IShelfLifeService
{
    public async Task<ServiceResponseDto<int>> GetShelfLifeDays(string itemName, CancellationToken token)
    {
        if (string.IsNullOrWhiteSpace(itemName))
            return new() { Success = false, Message = "Item name is required" };

        var timer = Stopwatch.StartNew();
        var known = await _catalog.FindAsync(itemName, token);
        if (known is { } days)
        {
            _logger.LogInformation("Shelf life for {Item}: {Days} days (lookup, {Ms} ms)", itemName, days, timer.ElapsedMilliseconds);
            return new() { Data = days, Success = true };
        }

        var predicted = await _aiService.GetShelfLifeDays(itemName, token);
        if (!predicted.Success)
        {
            _logger.LogWarning("Shelf life for {Item} unknown and AI failed: {Reason}", itemName, predicted.MessageKey ?? predicted.Message);
            return predicted;
        }

        await _catalog.AddAsync(itemName, predicted.Data, ShelfLifeSources.AI, token);
        _logger.LogInformation("Shelf life for {Item}: {Days} days (AI, {Ms} ms, saved)", itemName, predicted.Data, timer.ElapsedMilliseconds);
        return predicted;
    }
}
