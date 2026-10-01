using Cookly.Agents.Tools;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;

namespace Cookly.Agents.Agents;

public class NutritionAgent(IChatClient _chatClient,NutritionTools _tools)
{
    private const string NutritionAgentId = "nutrition-agent";

    public ChatClientAgent nutritionAgent = new(_chatClient, new ChatClientAgentOptions
    {
        Id = NutritionAgentId,
        Name = "NutritionAgent",
        Description = "Suggests a meal based on goals, preferences, and available ingredients",
        ChatOptions = new ChatOptions
        {
            Instructions =
                "You are a nutrition planner. Look up the user's goals and preferences with " +
                "your tool, then call ListPantryItems yourself to see the exact, current pantry " +
                "contents — do not trust InventoryAgent's summary alone, confirm it with the " +
                "tool. Suggest a single meal that can be made using ONLY items from that exact " +
                "list. Do not add, assume, or suggest any ingredient that isn't in the list — " +
                "no extra vegetables, spices, oil, salt, or staples unless they literally appear " +
                "in ListPantryItems' output.\n" +
                "   Treat that list as complete and certain: anything not on it — salt, oil, " +
                "spices, condiments, anything — is a known fact to be absent from this kitchen, " +
                "not a maybe. Never write hedging phrases like \"if available\" or \"if you have " +
                "it\" about an unlisted ingredient; just don't mention it. If the available items " +
                "don't add up to an ideal meal, suggest the simplest reasonable preparation of " +
                "only what's there. Always hand off to CookAgent once you've suggested a meal, " +
                "naming exactly which pantry items it uses.",
            Tools =
            [
                AIFunctionFactory.Create(_tools.GetUserGoalsAndPreferences),
                // AIFunctionFactory.Create(inventoryTools.ListPantryItems),
            ],
        },
    });
}