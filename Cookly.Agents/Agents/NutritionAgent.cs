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
                "2. Brainstorm 4 to 5 candidate dishes for that meal type that:\n" +
                "   - suit the user's goal and preferences; any allergy or dislike is a hard rule,\n" +
                "   - are realistic for that meal type. Breakfast must be typical breakfast food: " +
                "light, quick (about 15 minutes) and morning-style — eggs (omelette, scramble, " +
                "frittata), porridge or oats, toast, pancakes, smoothies, fruit or yogurt bowls, " +
                "or a savoury rice/egg breakfast. No heavy curries, stir-fries or full dinner plates " +
                "at breakfast. Lunch and dinner can be fuller cooked meals,\n" +
                "   - can be made using ONLY items from ListPantryItems' output, preferring items " +
                "that are expiring soon.\n" +
                "   Vary them: different cooking styles (stir-fry, soup, curry, salad, omelette, bake, " +
                "rice bowl...) and cuisines, favouring styles not already in the history. Reusing the " +
                "same ingredients is fine — a dish is new if its name and preparation differ, e.g. " +
                "'Chicken Fried Rice', 'Chicken Rice Soup' and 'Garlic Chicken with Tomato Rice' are " +
                "three different dishes.\n" +
                "   Treat the pantry list as complete and certain: anything not on it — salt, oil, " +
                "spices, condiments, anything — is absent. Never write hedges like \"if available\".\n" +
                "3. Pick the best candidate and call CheckDishIsNew with its name. If it is ALREADY " +
                "SUGGESTED, move to the next candidate and check again. When one is NEW, hand off to " +
                "CookAgent, naming the dish, the meal type and exactly which pantry items it uses.\n" +
                "4. Only if every candidate is rejected — and you have tried at least 3 genuinely " +
                "different dishes — call ReportNoNewMealPossible with each candidate and its reason, " +
                "plus grocery items that would enable new dishes fitting the user's goal and " +
                "preferences. Then end your turn without handing off. Never ask the user a question.",
            Tools =
            [
                AIFunctionFactory.Create(_tools.GetUserGoalsAndPreferences),
                AIFunctionFactory.Create(_tools.GetPreviouslySuggestedMeals),
                AIFunctionFactory.Create(_tools.CheckDishIsNew),
                AIFunctionFactory.Create(_tools.ReportNoNewMealPossible),
                AIFunctionFactory.Create(_inventoryTools.ListPantryItems),
                AIFunctionFactory.Create(_inventoryTools.CheckExpiringSoonItems),
            ],
        },
    });
}
