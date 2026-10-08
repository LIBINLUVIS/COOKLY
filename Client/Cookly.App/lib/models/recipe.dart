import 'meal_type.dart';

class RecipeIngredient {
  const RecipeIngredient({required this.name, this.quantity});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as String?,
      );

  final String name;
  final String? quantity;
}

class RecipeStep {
  const RecipeStep({this.title, required this.detail});

  /// Steps arrive as "Short title: what to do"; anything else is detail only.
  factory RecipeStep.parse(String raw) {
    final text = raw.trim();
    final colon = text.indexOf(':');
    if (colon > 0 && colon <= 48) {
      return RecipeStep(
        title: text.substring(0, colon).trim(),
        detail: text.substring(colon + 1).trim(),
      );
    }
    return RecipeStep(detail: text);
  }

  final String? title;
  final String detail;
}

/// The dish CookAgent saved, from the stream's `completed` event.
class Recipe {
  const Recipe({
    required this.dishId,
    required this.name,
    required this.mealType,
    required this.ingredients,
    required this.steps,
    this.description,
  });

  factory Recipe.fromJson(Map<String, dynamic> json, MealType mealType) => Recipe(
        dishId: (json['dishId'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? 'Your dish',
        description: json['description'] as String?,
        mealType: mealType,
        ingredients: [
          for (final item in json['ingredients'] as List? ?? const [])
            RecipeIngredient.fromJson(item as Map<String, dynamic>),
        ],
        steps: [
          for (final step in json['steps'] as List? ?? const [])
            if (step is String && step.trim().isNotEmpty) RecipeStep.parse(step),
        ],
      );

  final int dishId;
  final String name;
  final String? description;
  final MealType mealType;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
}
