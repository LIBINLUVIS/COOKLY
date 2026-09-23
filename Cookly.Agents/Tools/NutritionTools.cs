using System.ComponentModel;

namespace Cookly.Agents.Tools;

/// <summary>
/// Tools exposed to NutritionAgent. Dummy, hardcoded profile for now — a real implementation
/// would look this up per user.
/// </summary>
public class NutritionTools
{
    [Description("Gets the user's dietary goals and food preferences.")]
    public string GetUserGoalsAndPreferences() =>
        "Goal: high-protein, moderately spicy meals. Avoid red meat. Allergic to peanuts.";
}
