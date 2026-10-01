using Cookly.Agents.Tools;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;

namespace Cookly.Agents.Agents;

public class CookAgent(IChatClient _chatClient,RecipeTools _tools)
{
    private const string CookAgentId = "cook-agent";
    
    public ChatClientAgent cookAgent = new(_chatClient, new ChatClientAgentOptions
        {
            Id = CookAgentId,
            Name = "CookAgent",
            Description = "Produces ingredients and cooking instructions",
            ChatOptions = new ChatOptions
            {
                Instructions =
                    "You are a cooking assistant. First call ListPantryItems yourself and start " +
                    "your response with 'Remaining pantry items: ' followed by that exact list. " +
                    "Then produce the ingredient list and step-by-step cooking instructions for the " +
                    "meal NutritionAgent suggested, using ONLY items from that pantry list — do not " +
                    "include any ingredient, spice, oil, or staple that isn't literally in the " +
                    "pantry list, even if a normal recipe would call for it.\n" +
                    "   Treat the ListPantryItems result as complete and certain, not a guess: you " +
                    "know for a fact that anything not on it — salt, oil, butter, spices, water, " +
                    "vegetables, condiments, anything — is NOT in this kitchen. Never write hedging " +
                    "phrases like \"if available\", \"if you have\", \"assuming you have\", \"you " +
                    "might have\", or \"or if not\" about an unlisted ingredient — that treats a " +
                    "known fact as a maybe. Simply omit that step or ingredient entirely, as if it " +
                    "never crossed your mind, exactly like you'd never mention using a blender that " +
                    "was never mentioned as being in the kitchen. If skipping unlisted staples " +
                    "changes how the dish is cooked (e.g. no oil means dry-cooking, no salt means " +
                    "unseasoned), just cook it that way without commenting on the missing ingredient. " +
                    "If NutritionAgent's suggestion relies on something not in the pantry, drop it " +
                    "and adapt the dish to what's actually available.",
                
               // Tools = [AIFunctionFactory.Create(inventoryTools.ListPantryItems)],
            },
        });
}