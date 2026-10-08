import 'package:flutter/material.dart';

import '../../models/cookly_session.dart';
import '../../models/recipe.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../widgets/cookly_chip.dart';
import '../../widgets/cookly_top_bar.dart';

/// "Recipe & Preparation Guide": dish overview, ingredient checklist and steps.
class RecipeGuideScreen extends StatefulWidget {
  const RecipeGuideScreen({super.key, required this.session, required this.recipe});

  final CooklySession session;
  final Recipe recipe;

  @override
  State<RecipeGuideScreen> createState() => _RecipeGuideScreenState();
}

class _RecipeGuideScreenState extends State<RecipeGuideScreen> {
  final Set<int> _checkedIngredients = {};

  void _backToKitchen() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
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
                    child: Text('Recipe & Preparation', maxLines: 1, overflow: TextOverflow.ellipsis, style: CooklyTextStyles.headlineSm),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
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
                      label: '${recipe.mealType.label.toUpperCase()} AI CURATE',
                      background: CooklyColors.secondaryContainer,
                      foreground: CooklyColors.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      textStyle: CooklyTextStyles.labelSm.copyWith(letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OverviewCard(recipe: recipe),
                  const SizedBox(height: CooklySpacing.md),
                  _IngredientsCard(
                    ingredients: recipe.ingredients,
                    checked: _checkedIngredients,
                    onToggle: (index) => setState(() {
                      if (!_checkedIngredients.remove(index)) _checkedIngredients.add(index);
                    }),
                  ),
                  const SizedBox(height: CooklySpacing.md),
                  _StepsCard(steps: recipe.steps),
                  const SizedBox(height: CooklySpacing.md),
                  FilledButton.icon(
                    onPressed: _backToKitchen,
                    icon: const Icon(Icons.outdoor_grill_outlined, size: 20),
                    label: const Text('Back to Kitchen'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CooklyColors.surfaceContainerHigh,
                      foregroundColor: CooklyColors.onSurface,
                      minimumSize: const Size.fromHeight(52),
                      textStyle: CooklyTextStyles.labelLg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CooklyRadius.card)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.sheet),
        boxShadow: CooklyShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CooklyColors.primaryFixed, CooklyColors.tertiaryFixed],
              ),
            ),
            child: Stack(
              children: [
                Center(child: Icon(recipe.mealType.icon, size: 72, color: CooklyColors.primary)),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CooklyChip(
                    label: 'Made from your pantry',
                    background: CooklyColors.surfaceBright.withValues(alpha: 0.92),
                    foreground: CooklyColors.onSurface,
                    leading: const Icon(Icons.check_circle, size: 14, color: CooklyColors.secondary),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CooklySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    CooklyChip(
                      label: '${recipe.ingredients.length} ingredients',
                      background: CooklyColors.secondaryContainer,
                      foreground: CooklyColors.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    CooklyChip(
                      label: '${recipe.steps.length} steps',
                      background: CooklyColors.tertiaryFixed,
                      foreground: CooklyColors.onTertiaryFixed,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(recipe.name, style: CooklyTextStyles.headlineMd),
                if (recipe.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(recipe.description!, style: CooklyTextStyles.bodyMd),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({required this.ingredients, required this.checked, required this.onToggle});

  final List<RecipeIngredient> ingredients;
  final Set<int> checked;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.checklist,
      title: 'Ingredients Checklist',
      trailing: '${checked.length} of ${ingredients.length} ready',
      children: [
        for (var i = 0; i < ingredients.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: CooklySpacing.sm),
            child: Material(
              color: CooklyColors.surfaceContainer,
              borderRadius: BorderRadius.circular(CooklyRadius.xl),
              child: InkWell(
                onTap: () => onToggle(i),
                borderRadius: BorderRadius.circular(CooklyRadius.xl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        checked.contains(i) ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 22,
                        color: checked.contains(i) ? CooklyColors.secondary : CooklyColors.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ingredients[i].name,
                          style: CooklyTextStyles.labelLg.copyWith(
                            decoration: checked.contains(i) ? TextDecoration.lineThrough : null,
                            color: checked.contains(i)
                                ? CooklyColors.onSurface.withValues(alpha: 0.5)
                                : CooklyColors.onSurface,
                          ),
                        ),
                      ),
                      if (ingredients[i].quantity?.isNotEmpty ?? false)
                        Text(ingredients[i].quantity!, style: CooklyTextStyles.bodySm),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.steps});

  final List<RecipeStep> steps;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.menu_book_outlined,
      title: 'Step-by-Step Cooking Guide',
      children: [
        for (var i = 0; i < steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: CooklySpacing.sm),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CooklyColors.surfaceContainer,
              borderRadius: BorderRadius.circular(CooklyRadius.xl),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: CooklyColors.primary, shape: BoxShape.circle),
                  child: Text(
                    '${i + 1}',
                    style: CooklyTextStyles.labelMd.copyWith(color: CooklyColors.onPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (steps[i].title != null) ...[
                        Text(steps[i].title!, style: CooklyTextStyles.labelLg.copyWith(fontSize: 15)),
                        const SizedBox(height: 4),
                      ],
                      Text(steps[i].detail, style: CooklyTextStyles.bodyMd),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.children, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(CooklySpacing.md, CooklySpacing.md, CooklySpacing.md, CooklySpacing.sm),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        boxShadow: CooklyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: CooklyColors.primary),
              const SizedBox(width: CooklySpacing.sm),
              Expanded(child: Text(title, style: CooklyTextStyles.headlineSm)),
              if (trailing != null)
                Text(trailing!, style: CooklyTextStyles.labelMd.copyWith(color: CooklyColors.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
