using Cookly.Agents.Tools;
using Cookly.Business.IServices;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;

namespace Cookly.Agents.Agents;

public class InventoryAgent(IChatClient _chatClient,InventoryTools _tools)
{
    private const string InventoryAgentId = "inventory-agent";
    
    public ChatClientAgent inventoryAgent = new(_chatClient, new ChatClientAgentOptions
        {
            Id = InventoryAgentId,
            Name = "InventoryAgent",
            Description = "Reviews pantry inventory, asks the user about expired or expiring items, and removes what they approve",
            ChatOptions = new ChatOptions
            {
                Instructions =
                    "You are an inventory manager for a home kitchen. Follow this procedure:\n" +
                    "1. Call CheckExpiredItems and CheckExpiringSoonItems,respectively.\n" +
                    "2. If both return no items, skip straight to step 4.\n" +
                    "3. Otherwise, tell the user exactly which items are expired or expiring soon " +
                    "(with days left for the expiring ones) and ask which, if any, they'd like you " +
                    "to remove. Do not call RemoveInventoryItem yet, and do not hand off yet — end " +
                    "your turn here and wait for their reply.\n" +
                    "   When the user replies, match what they said against the item names you " +
                    "listed and call RemoveInventoryItem once for each item they asked to remove — " +
                    "call it multiple times in the same turn if they named multiple items. Pass only " +
                    "the bare item name as it appears in the pantry, e.g. \"Milk\" — never include " +
                    "the \"(N days left)\" annotation in the itemName argument, that will fail to " +
                    "match. If they said not to remove anything, or named only some items, respect " +
                    "that exactly; never remove an item they didn't mention.\n" +
                    "4. Call ListPantryItems to get the accurate, complete list of what remains " +
                    "(it includes items you never checked for expiry, like long-shelf-life staples " +
                    "— don't rely on memory or guesswork for this). Hand off to NutritionAgent with " +
                    "that exact list as the final pantry contents, plus anything you flagged but the " +
                    "user chose to keep.",
                Tools =
                [
                    AIFunctionFactory.Create(_tools.ListPantryItems),
                    AIFunctionFactory.Create(_tools.CheckExpiredItems),
                    AIFunctionFactory.Create(_tools.CheckExpiringSoonItems),
                    AIFunctionFactory.Create(_tools.RemoveInventoryItem)
                ],
            },
        });
}