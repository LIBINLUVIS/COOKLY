import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/cookly_session.dart';
import '../../models/meal_plan_event.dart';
import '../../models/meal_type.dart';
import '../../models/recipe.dart';
import '../../navigation/sign_out.dart';
import '../../services/meal_plan_api_service.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../widgets/cookly_chip.dart';
import '../../widgets/cookly_top_bar.dart';
import '../pantry/pantry_screen.dart';
import 'recipe_guide_screen.dart';

enum _PhaseStatus { pending, active, waiting, done }

class _PhaseProgress {
  _PhaseStatus status = _PhaseStatus.pending;
  String? activity;
}

/// Streams the agents' progress (inventory → nutrition → cook) for one meal.
class MealPrepScreen extends StatefulWidget {
  const MealPrepScreen({super.key, required this.session, required this.mealType});

  final CooklySession session;
  final MealType mealType;

  @override
  State<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends State<MealPrepScreen> with SingleTickerProviderStateMixin {
  final _api = MealPlanApiService.instance;
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  final Map<MealPlanPhase, _PhaseProgress> _phases = {
    for (final phase in MealPlanPhase.values) phase: _PhaseProgress(),
  };
  StreamSubscription<MealPlanEvent>? _subscription;
  bool _isStreaming = false;
  bool _receivedFinalEvent = false;

  String? _runId;
  String? _question;
  RefillRequiredEvent? _refill;
  Recipe? _recipe;
  String? _fallbackRecipeText;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listen(_api.start(widget.mealType));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _replyController.dispose();
    _scrollController.dispose();
    _pulse.dispose();
    super.dispose();
  }

  bool get _isFinished => _recipe != null || _fallbackRecipeText != null;

  void _listen(Stream<MealPlanEvent> stream) {
    _subscription?.cancel();
    _receivedFinalEvent = false;
    setState(() => _isStreaming = true);
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    _subscription = stream.listen(_onEvent, onError: _onError, onDone: _onDone);
  }

  void _onEvent(MealPlanEvent event) {
    if (event is InputRequiredEvent ||
        event is RefillRequiredEvent ||
        event is CompletedEvent ||
        event is MealPlanErrorEvent) {
      _scrollToBottomAfterBuild();
    }
    setState(() {
      switch (event) {
        case RunStartedEvent(:final runId):
          _runId = runId;
        case PhaseChangedEvent(:final phase, :final isDone):
          if (isDone) {
            _markDone(phase);
          } else {
            MealPlanPhase.values.takeWhile((p) => p != phase).forEach(_markDone);
            _phases[phase]!.status = _PhaseStatus.active;
          }
        case ActivityEvent(:final phase, :final message):
          final target = phase ?? _activePhase;
          if (target != null && message.isNotEmpty) _phases[target]!.activity = message;
        case InputRequiredEvent(:final runId, :final question):
          _receivedFinalEvent = true;
          _runId = runId;
          _question = question;
          final target = _activePhase ?? MealPlanPhase.inventory;
          _phases[target]!
            ..status = _PhaseStatus.waiting
            ..activity = 'Waiting for your reply';
        case RefillRequiredEvent():
          _receivedFinalEvent = true;
          _refill = event;
          _markDone(MealPlanPhase.inventory);
          _phases[MealPlanPhase.nutrition]!
            ..status = _PhaseStatus.waiting
            ..activity = 'No new meal possible with your pantry';
        case CompletedEvent(:final recipe, :final text):
          _receivedFinalEvent = true;
          _recipe = recipe;
          _fallbackRecipeText = recipe == null ? (text ?? '') : null;
          MealPlanPhase.values.forEach(_markDone);
        case MealPlanErrorEvent(:final message):
          _receivedFinalEvent = true;
          _error = message;
      }
    });
  }

  void _markDone(MealPlanPhase phase) {
    _phases[phase]!
      ..status = _PhaseStatus.done
      ..activity = phase.doneSummary;
  }

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  MealPlanPhase? get _activePhase {
    for (final phase in MealPlanPhase.values) {
      final status = _phases[phase]!.status;
      if (status == _PhaseStatus.active || status == _PhaseStatus.waiting) return phase;
    }
    return null;
  }

  void _onError(Object error) {
    if (!mounted) return;
    if (error is MealPlanApiException && error.isUnauthorized) {
      signOutAndShowSplash(context);
      return;
    }
    setState(() {
      _receivedFinalEvent = true;
      _error = error is MealPlanApiException ? error.message : 'Something went wrong. Please try again.';
    });
  }

  void _onDone() {
    if (!mounted) return;
    setState(() {
      _isStreaming = false;
      if (!_receivedFinalEvent) {
        _error = 'The connection closed before Cookly finished. Please try again.';
      }
    });
    _pulse.stop();
  }

  void _sendReply() {
    final reply = _replyController.text.trim();
    final runId = _runId;
    if (reply.isEmpty || runId == null || _isStreaming) return;

    FocusScope.of(context).unfocus();
    _replyController.clear();
    setState(() {
      _question = null;
      final waiting = _activePhase;
      if (waiting != null) {
        _phases[waiting]!
          ..status = _PhaseStatus.active
          ..activity = 'Working on your reply';
      }
    });
    _listen(_api.respond(runId: runId, message: reply, mealType: widget.mealType));
  }

  void _restart() {
    setState(() {
      for (final progress in _phases.values) {
        progress
          ..status = _PhaseStatus.pending
          ..activity = null;
      }
      _runId = null;
      _question = null;
      _refill = null;
      _recipe = null;
      _fallbackRecipeText = null;
      _error = null;
    });
    _listen(_api.start(widget.mealType));
  }

  void _openRecipe(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeGuideScreen(session: widget.session, recipe: recipe)),
    );
  }

  void _openPantry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PantryScreen(session: widget.session)),
    );
  }

  ({String headline, String status}) get _copy {
    final meal = widget.mealType.label;
    if (_error != null) return (headline: 'Something went wrong', status: 'Planning stopped');
    if (_isFinished) return (headline: 'Your $meal is ready!', status: 'Plating complete! Ready to cook');
    if (_refill != null) return (headline: 'Your pantry needs a refill', status: 'No new $meal to suggest');
    if (_question != null) return (headline: 'Cookly needs your input', status: 'Waiting for your reply');
    final activity = _activePhase == null ? null : _phases[_activePhase]!.activity;
    return (headline: 'Cooking up something for you...', status: activity ?? 'Warming up the kitchen');
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    return Scaffold(
      backgroundColor: CooklyColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            CooklyTopBar(
              session: widget.session,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: CooklyColors.onSurface),
                  ),
                  Flexible(
                    child: Text('AI Preparation', maxLines: 1, overflow: TextOverflow.ellipsis, style: CooklyTextStyles.headlineSm),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  CooklySpacing.marginMobile,
                  12,
                  CooklySpacing.marginMobile,
                  CooklySpacing.xl,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CooklyChip(
                      label: '${widget.mealType.label.toUpperCase()} AI CURATE',
                      background: CooklyColors.secondaryContainer,
                      foreground: CooklyColors.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      textStyle: CooklyTextStyles.labelSm.copyWith(letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: CooklySpacing.md),
                  _PlateHero(
                    pulse: _pulse,
                    mealIcon: widget.mealType.icon,
                    status: copy.status,
                    isWorking: _isStreaming,
                  ),
                  const SizedBox(height: CooklySpacing.lg),
                  Text(copy.headline, textAlign: TextAlign.center, style: CooklyTextStyles.headlineLgMobile),
                  const SizedBox(height: CooklySpacing.sm),
                  Text(
                    'Cookly AI is cross-referencing your pantry with your goals and preferences.',
                    textAlign: TextAlign.center,
                    style: CooklyTextStyles.bodyMd,
                  ),
                  const SizedBox(height: CooklySpacing.lg),
                  _ReasoningTimeline(phases: _phases),
                  if (_question != null) ...[
                    const SizedBox(height: CooklySpacing.md),
                    _ReplyCard(
                      question: _question!,
                      controller: _replyController,
                      isSending: _isStreaming,
                      onSend: _sendReply,
                    ),
                  ],
                  if (_refill != null) ...[
                    const SizedBox(height: CooklySpacing.md),
                    _RefillCard(
                      mealType: widget.mealType,
                      refill: _refill!,
                      onOpenPantry: _openPantry,
                      onBackToKitchen: () => Navigator.of(context).pop(),
                    ),
                  ],
                  if (_recipe != null) ...[
                    const SizedBox(height: CooklySpacing.md),
                    _CuratedDishCard(recipe: _recipe!, onStartCooking: () => _openRecipe(_recipe!)),
                  ],
                  if (_fallbackRecipeText != null) ...[
                    const SizedBox(height: CooklySpacing.md),
                    _MessageCard(
                      icon: Icons.restaurant_menu,
                      title: 'Your recipe',
                      message: _fallbackRecipeText!.isEmpty ? 'Cookly finished planning your meal.' : _fallbackRecipeText!,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: CooklySpacing.md),
                    _MessageCard(
                      icon: Icons.error_outline,
                      title: "Couldn't finish planning",
                      message: _error!,
                      isError: true,
                      actionLabel: 'Try again',
                      onAction: _restart,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlateHero extends StatelessWidget {
  const _PlateHero({
    required this.pulse,
    required this.mealIcon,
    required this.status,
    required this.isWorking,
  });

  final Animation<double> pulse;
  final IconData mealIcon;
  final String status;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(left: 48, top: 16, child: _FloatingIngredient(icon: Icons.grain, color: CooklyColors.tertiary)),
          const Positioned(right: 44, top: 44, child: _FloatingIngredient(icon: Icons.lunch_dining, color: CooklyColors.primary)),
          const Positioned(left: 28, bottom: 52, child: _FloatingIngredient(icon: Icons.bakery_dining, color: CooklyColors.tertiary)),
          const Positioned(right: 24, bottom: 84, child: _FloatingIngredient(icon: Icons.eco_outlined, color: CooklyColors.secondary)),
          ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: pulse, curve: Curves.easeInOut)),
            child: Container(
              width: 176,
              height: 176,
              decoration: const BoxDecoration(
                color: CooklyColors.surfaceContainerLowest,
                shape: BoxShape.circle,
                boxShadow: CooklyShadows.card,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [CooklyColors.primaryContainer, CooklyColors.primary],
                      ),
                    ),
                    child: Icon(mealIcon, size: 40, color: CooklyColors.onPrimary),
                  ),
                  Positioned(
                    top: 28,
                    right: 28,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: CooklyColors.secondary, shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome, size: 18, color: CooklyColors.onSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CooklyColors.surfaceContainerHigh.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(CooklyRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isWorking)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: CooklyColors.primary),
                    )
                  else
                    const Icon(Icons.restaurant, size: 14, color: CooklyColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CooklyTextStyles.labelMd,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIngredient extends StatelessWidget {
  const _FloatingIngredient({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        shape: BoxShape.circle,
        boxShadow: CooklyShadows.subtle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _ReasoningTimeline extends StatelessWidget {
  const _ReasoningTimeline({required this.phases});

  final Map<MealPlanPhase, _PhaseProgress> phases;

  @override
  Widget build(BuildContext context) {
    final completed = phases.values.where((p) => p.status == _PhaseStatus.done).length;
    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        boxShadow: CooklyShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'REASONING TIMELINE',
                  style: CooklyTextStyles.labelMd.copyWith(color: CooklyColors.onSurfaceVariant, letterSpacing: 1),
                ),
              ),
              Text(
                '$completed of ${phases.length} Completed',
                style: CooklyTextStyles.labelMd.copyWith(color: CooklyColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in phases.entries) ...[
            _TimelineRow(phase: entry.key, progress: entry.value),
            if (entry.key != MealPlanPhase.values.last) const SizedBox(height: CooklySpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.phase, required this.progress});

  final MealPlanPhase phase;
  final _PhaseProgress progress;

  @override
  Widget build(BuildContext context) {
    final status = progress.status;
    final isPending = status == _PhaseStatus.pending;
    final subtitle = progress.activity ?? (isPending ? 'Up next' : 'Working on it');

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isPending ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: status == _PhaseStatus.waiting
              ? CooklyColors.tertiaryFixed.withValues(alpha: 0.5)
              : CooklyColors.surfaceContainer,
          borderRadius: BorderRadius.circular(CooklyRadius.xl),
        ),
        child: Row(
          children: [
            _StatusBadge(status: status),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CooklyTextStyles.labelLg.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: CooklyTextStyles.bodySm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _PhaseStatus status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: switch (status) {
        _PhaseStatus.done => const DecoratedBox(
            decoration: BoxDecoration(color: CooklyColors.secondary, shape: BoxShape.circle),
            child: Icon(Icons.check, size: 18, color: CooklyColors.onSecondary),
          ),
        _PhaseStatus.active => const Padding(
            padding: EdgeInsets.all(5),
            child: CircularProgressIndicator(strokeWidth: 2.5, color: CooklyColors.primary),
          ),
        _PhaseStatus.waiting => const DecoratedBox(
            decoration: BoxDecoration(color: CooklyColors.tertiary, shape: BoxShape.circle),
            child: Icon(Icons.hourglass_top, size: 16, color: CooklyColors.onTertiary),
          ),
        _PhaseStatus.pending => DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CooklyColors.outlineVariant, width: 2),
            ),
          ),
      },
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.question,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final String question;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        border: Border.all(color: CooklyColors.tertiaryFixedDim, width: 1.5),
        boxShadow: CooklyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, size: 20, color: CooklyColors.tertiary),
              const SizedBox(width: CooklySpacing.sm),
              Text('A quick question', style: CooklyTextStyles.headlineSm),
            ],
          ),
          const SizedBox(height: CooklySpacing.sm),
          Text(question, style: CooklyTextStyles.bodyMd.copyWith(color: CooklyColors.onSurface)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: CooklyTextStyles.bodyMd.copyWith(color: CooklyColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'e.g. Remove the milk, keep the spinach',
                    hintStyle: CooklyTextStyles.bodyMd.copyWith(
                      color: CooklyColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: CooklyColors.surfaceContainerLow,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CooklyRadius.xl),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CooklyRadius.xl),
                      borderSide: const BorderSide(color: CooklyColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CooklySpacing.sm),
              IconButton.filled(
                onPressed: isSending ? null : onSend,
                tooltip: 'Send reply',
                style: IconButton.styleFrom(
                  backgroundColor: CooklyColors.primary,
                  foregroundColor: CooklyColors.onPrimary,
                  minimumSize: const Size(46, 46),
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RefillCard extends StatelessWidget {
  const _RefillCard({
    required this.mealType,
    required this.refill,
    required this.onOpenPantry,
    required this.onBackToKitchen,
  });

  final MealType mealType;
  final RefillRequiredEvent refill;
  final VoidCallback onOpenPantry;
  final VoidCallback onBackToKitchen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
      decoration: BoxDecoration(
        color: CooklyColors.primaryFixed.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(CooklyRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: CooklyColors.primaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_basket_outlined, size: 20, color: CooklyColors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('No new ${mealType.label} to suggest', style: CooklyTextStyles.headlineSm)),
            ],
          ),
          const SizedBox(height: CooklySpacing.sm),
          Text(refill.message, style: CooklyTextStyles.bodyMd),
          if (refill.suggestedItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Suggested items to buy', style: CooklyTextStyles.labelMd),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in refill.suggestedItems)
                  CooklyChip(
                    label: item,
                    background: CooklyColors.secondaryContainer,
                    foreground: CooklyColors.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: CooklyTextStyles.labelMd,
                  ),
              ],
            ),
          ],
          const SizedBox(height: CooklySpacing.md),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onBackToKitchen,
                  style: TextButton.styleFrom(
                    foregroundColor: CooklyColors.onSurface,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: CooklyTextStyles.labelLg,
                  ),
                  child: const Text('Back to Kitchen'),
                ),
              ),
              const SizedBox(width: CooklySpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenPantry,
                  icon: const Icon(Icons.kitchen_outlined, size: 20),
                  label: const Text('Go to Pantry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CooklyColors.primary,
                    foregroundColor: CooklyColors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: CooklyTextStyles.labelLg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CooklyRadius.xl)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CuratedDishCard extends StatelessWidget {
  const _CuratedDishCard({required this.recipe, required this.onStartCooking});

  final Recipe recipe;
  final VoidCallback onStartCooking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.sheet),
        boxShadow: CooklyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, size: 20, color: CooklyColors.secondary),
              const SizedBox(width: 6),
              Text(
                'Curated Just For You',
                style: CooklyTextStyles.labelLg.copyWith(color: CooklyColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              CooklyChip(
                label: recipe.mealType.label,
                background: CooklyColors.tertiaryFixed,
                foreground: CooklyColors.onTertiaryFixed,
                leading: Icon(recipe.mealType.icon, size: 14, color: CooklyColors.tertiary),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              CooklyChip(
                label: '${recipe.ingredients.length} ingredients',
                background: CooklyColors.secondaryContainer,
                foreground: CooklyColors.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              CooklyChip(
                label: '${recipe.steps.length} steps',
                background: CooklyColors.surfaceContainerHigh,
                foreground: CooklyColors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(recipe.name, style: CooklyTextStyles.headlineMd),
          if (recipe.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(recipe.description!, style: CooklyTextStyles.bodyMd),
          ],
          const SizedBox(height: CooklySpacing.md),
          FilledButton.icon(
            onPressed: onStartCooking,
            icon: const Icon(Icons.local_fire_department, size: 20),
            label: const Text('Start Guided Cook'),
            style: FilledButton.styleFrom(
              backgroundColor: CooklyColors.primary,
              foregroundColor: CooklyColors.onPrimary,
              minimumSize: const Size.fromHeight(52),
              textStyle: CooklyTextStyles.labelLg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CooklyRadius.card)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? CooklyColors.error : CooklyColors.secondary;
    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
      decoration: BoxDecoration(
        color: isError ? CooklyColors.errorContainer : CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        boxShadow: isError ? null : CooklyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: CooklySpacing.sm),
              Expanded(child: Text(title, style: CooklyTextStyles.headlineSm)),
            ],
          ),
          const SizedBox(height: CooklySpacing.sm),
          Text(
            message,
            style: CooklyTextStyles.bodyMd.copyWith(
              color: isError ? CooklyColors.onErrorContainer : CooklyColors.onSurface,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: CooklyColors.primary,
                foregroundColor: CooklyColors.onPrimary,
                textStyle: CooklyTextStyles.labelLg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CooklyRadius.xl)),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
