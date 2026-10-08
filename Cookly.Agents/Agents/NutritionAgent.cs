using Cookly.Agents.Tools;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;

namespace Cookly.Agents.Agents;

public class NutritionAgent(IChatClient _chatClient, NutritionTools _tools, InventoryTools _inventoryTools)
{
    private const string NutritionAgentId = "nutrition-agent";

    public ChatClientAgent nutritionAgent = new(_chatClient, new ChatClientAgentOptions
    {
        Id = NutritionAgentId,
        Name = "NutritionAgent",
        Description = "Suggests a new meal based on goals, preferences, meal history and available ingredients",
        ChatOptions = new ChatOptions
        {
            Instructions =
                "You are a nutrition planner. The user's request says which meal to plan " +
                "(Breakfast, Lunch or Dinner). Follow this procedure:\n" +
                "1. Call GetUserGoalsAndPreferences, GetPreviouslySuggestedMeals, ListPantryItems " +
                "and CheckExpiringSoonItems. Do not trust InventoryAgent's summary; use these tools.\n" +
                "2. Choose ONE dish for that meal type that:\n" +
                "   - suits the user's goal and preferences; any allergy or dislike is a hard rule,\n" +
                "   - is NOT in the previously suggested list (a genuinely different dish, not a renamed one),\n" +
                "   - can be made using ONLY items from ListPantryItems' output, preferring items " +
                "that are expiring soon.\n" +
                "   Treat the pantry list as complete and certain: anything not on it — salt, oil, " +
                "spices, condiments, anything — is absent. Never write hedges like \"if available\".\n" +
                "3. If such a dish exists, hand off to CookAgent, naming the dish, the meal type and " +
                "exactly which pantry items it uses.\n" +
                "4. If no new dish is possible (the pantry is too limited, or every possible dish was " +
                "already suggested), call ReportNoNewMealPossible with grocery items that would enable " +
                "new dishes fitting the user's goal and preferences, then end your turn without " +
                "handing off. Never ask the user a question.",
            Tools =
            [
                AIFunctionFactory.Create(_tools.GetUserGoalsAndPreferences),
                AIFunctionFactory.Create(_tools.GetPreviouslySuggestedMeals),
                AIFunctionFactory.Create(_tools.ReportNoNewMealPossible),
                AIFunctionFactory.Create(_inventoryTools.ListPantryItems),
                AIFunctionFactory.Create(_inventoryTools.CheckExpiringSoonItems),
            ],
        },
    });
}
