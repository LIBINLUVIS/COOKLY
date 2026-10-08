import 'meal_type.dart';
import 'recipe.dart';

enum MealPlanPhase {
  inventory('inventory', 'Checking your pantry inventory', 'Pantry reviewed'),
  nutrition('nutrition', 'Matching your goals & preferences', 'Picked a new meal for your goals'),
  cook('cook', 'Writing your step-by-step guide', 'Recipe written and saved');

  const MealPlanPhase(this.key, this.title, this.doneSummary);

  final String key;
  final String title;
  final String doneSummary;

  static MealPlanPhase? fromKey(Object? key) {
    for (final phase in values) {
      if (phase.key == key) return phase;
    }
    return null;
  }
}

/// One Server-Sent Event from `/meal-plan/stream/*`.
sealed class MealPlanEvent {
  const MealPlanEvent();

  static MealPlanEvent? fromSse(String type, Map<String, dynamic> data, MealType mealType) {
    return switch (type) {
      'run' => RunStartedEvent(data['runId'] as String),
      'phase' => switch (MealPlanPhase.fromKey(data['phase'])) {
          final phase? => PhaseChangedEvent(phase, isDone: data['status'] == 'done'),
          null => null,
        },
      'activity' => ActivityEvent(
          MealPlanPhase.fromKey(data['phase']),
          data['message'] as String? ?? '',
        ),
      'input_required' => InputRequiredEvent(
          runId: data['runId'] as String,
          question: (data['question'] as String?)?.trim() ?? '',
        ),
      'refill_required' => RefillRequiredEvent(
          message: data['message'] as String? ?? '',
          suggestedItems: [
            for (final item in data['suggestedItems'] as List? ?? const []) item.toString(),
          ],
        ),
      'completed' => CompletedEvent(
          recipe: data['dish'] is Map<String, dynamic>
              ? Recipe.fromJson(data['dish'] as Map<String, dynamic>, mealType)
              : null,
          text: data['text'] as String?,
        ),
      'error' => MealPlanErrorEvent(data['message'] as String? ?? 'Something went wrong.'),
      _ => null,
    };
  }
}

class RunStartedEvent extends MealPlanEvent {
  const RunStartedEvent(this.runId);
  final String runId;
}

class PhaseChangedEvent extends MealPlanEvent {
  const PhaseChangedEvent(this.phase, {required this.isDone});
  final MealPlanPhase phase;
  final bool isDone;
}

class ActivityEvent extends MealPlanEvent {
  const ActivityEvent(this.phase, this.message);
  final MealPlanPhase? phase;
  final String message;
}

class InputRequiredEvent extends MealPlanEvent {
  const InputRequiredEvent({required this.runId, required this.question});
  final String runId;
  final String question;
}

class RefillRequiredEvent extends MealPlanEvent {
  const RefillRequiredEvent({required this.message, required this.suggestedItems});
  final String message;
  final List<String> suggestedItems;
}

class CompletedEvent extends MealPlanEvent {
  const CompletedEvent({this.recipe, this.text});

  /// Null if CookAgent didn't save the dish; [text] then holds the raw answer.
  final Recipe? recipe;
  final String? text;
}

class MealPlanErrorEvent extends MealPlanEvent {
  const MealPlanErrorEvent(this.message);
  final String message;
}
