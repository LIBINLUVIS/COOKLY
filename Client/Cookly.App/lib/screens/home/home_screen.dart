import 'package:flutter/material.dart';

import '../../models/cookly_session.dart';
import '../../models/meal_type.dart';
import '../../models/recipe.dart';
import '../../navigation/sign_out.dart';
import '../../services/dish_api_service.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/cookly_bottom_nav.dart';
import '../../widgets/cookly_chip.dart';
import '../../widgets/cookly_top_bar.dart';
import '../meal_plan/meal_prep_screen.dart';
import '../meal_plan/recipe_guide_screen.dart';
import '../pantry/pantry_screen.dart';
import '../profile/profile_screen.dart';

/// Kitchen dashboard. The greeting and Recent Dishes are live; the pantry
/// summary card is still placeholder content.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});

  final CooklySession session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _homeDishLimit = 5;

  final _searchController = TextEditingController();
  List<Recipe> _dishes = [];
  bool _isLoadingDishes = true;
  String? _dishesError;

  CooklySession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadDishes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDishes() async {
    setState(() {
      _isLoadingDishes = true;
      _dishesError = null;
    });
    try {
      final dishes = await DishApiService.instance.history();
      if (!mounted) return;
      setState(() {
        _dishes = dishes;
        _isLoadingDishes = false;
      });
    } on DishApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        signOutAndShowSplash(context);
        return;
      }
      setState(() {
        _dishesError = error.message;
        _isLoadingDishes = false;
      });
    }
  }

  void _openPantry() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PantryScreen(session: session)));
  }

  Future<void> _openMealPrep(MealType mealType) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealPrepScreen(session: session, mealType: mealType),
      ),
    );
    // A finished meal plan saves a new dish to the history.
    if (mounted) _loadDishes();
  }

  void _openRecipe(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeGuideScreen(session: session, recipe: recipe),
      ),
    );
  }

  void _showAllDishes() =>
      _showRecentDishesSheet(context, _dishes, _openRecipe);

  void _onTabSelected(CooklyTab tab) {
    switch (tab) {
      case CooklyTab.kitchen:
        break;
      case CooklyTab.pantry:
        _openPantry();
      case CooklyTab.profile:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfileScreen(session: session)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CooklyColors.surface,
      bottomNavigationBar: CooklyBottomNav(
        current: CooklyTab.kitchen,
        onSelected: _onTabSelected,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CooklyTopBar(
              session: session,
              leading: IconButton(
                onPressed: () {},
                tooltip: 'Menu',
                icon: const Icon(Icons.menu, color: CooklyColors.onSurface),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: CooklyColors.primary,
                onRefresh: _loadDishes,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    CooklySpacing.marginMobile,
                    12,
                    CooklySpacing.marginMobile,
                    CooklySpacing.lg,
                  ),
                  children: [
                    _GreetingSection(
                      firstName: session.firstName,
                      onShowRecent: _showAllDishes,
                    ),
                    const SizedBox(height: 12),
                    _PrepareMealCard(onMealSelected: _openMealPrep),
                    const SizedBox(height: CooklySpacing.md),
                    _PantrySummaryCard(onManage: _openPantry),
                    const SizedBox(height: CooklySpacing.md),
                    _DishSearchField(controller: _searchController),
                    const SizedBox(height: CooklySpacing.lg),
                    _RecentDishesHeader(
                      onViewAll: _dishes.isEmpty ? null : _showAllDishes,
                    ),
                    const SizedBox(height: CooklySpacing.md),
                    ..._buildDishes(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDishes() {
    if (_isLoadingDishes && _dishes.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: CooklySpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: CooklyColors.primary),
          ),
        ),
      ];
    }
    if (_dishesError != null && _dishes.isEmpty) {
      return [
        _DishesMessage(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load your dishes",
          message: _dishesError!,
          actionLabel: 'Try again',
          onAction: _loadDishes,
        ),
      ];
    }
    if (_dishes.isEmpty) {
      return const [
        _DishesMessage(
          icon: Icons.restaurant_menu,
          title: 'No dishes yet',
          message:
              'Tap Breakfast, Lunch or Dinner above and Cookly will suggest your first meal.',
        ),
      ];
    }

    final query = _searchController.text.trim();
    final visible = query.isEmpty
        ? _dishes.take(_homeDishLimit).toList()
        : _dishes.where((dish) => dish.matches(query)).toList();
    if (visible.isEmpty) {
      return [
        _DishesMessage(
          icon: Icons.search_off,
          title: 'No dishes match "$query"',
          message: 'Try a dish name, an ingredient or a meal like "breakfast".',
        ),
      ];
    }
    return [
      for (final dish in visible) ...[
        _DishCard(dish: dish, onOpen: () => _openRecipe(dish)),
        const SizedBox(height: CooklySpacing.md),
      ],
    ];
  }
}

String _suggestedLabel(DateTime? suggestedAt) {
  if (suggestedAt == null) return 'Suggested earlier';
  final daysAgo = -calendarDaysFromToday(suggestedAt);
  if (daysAgo <= 0) return 'Suggested today';
  if (daysAgo == 1) return 'Suggested yesterday';
  if (daysAgo < 7) return 'Suggested $daysAgo days ago';
  return 'Suggested ${formatShortDate(suggestedAt)}';
}

String _greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.firstName, required this.onShowRecent});

  final String firstName;
  final VoidCallback onShowRecent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Chips keep their full width and only truncate when the row is too narrow.
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: CooklyChip(
                        label: 'Pantry Ready',
                        background: CooklyColors.secondaryContainer,
                        foreground: CooklyColors.onSecondaryContainer,
                        leading: CooklyStatusDot(color: CooklyColors.secondary),
                      ),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: CooklyChip(
                        label: 'Spring Season',
                        background: CooklyColors.surfaceContainerHigh,
                        foreground: CooklyColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onShowRecent,
              icon: const Icon(Icons.history, size: 18),
              label: Text('Recent', style: CooklyTextStyles.labelMd),
              style: TextButton.styleFrom(
                foregroundColor: CooklyColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_greetingFor(DateTime.now())}, $firstName 👋',
          style: CooklyTextStyles.headlineLgMobile,
        ),
        const SizedBox(height: 4),
        Text(
          'What would you like Cookly to prepare today?',
          style: CooklyTextStyles.bodyMd,
        ),
      ],
    );
  }
}

class _PrepareMealCard extends StatelessWidget {
  const _PrepareMealCard({required this.onMealSelected});

  final ValueChanged<MealType> onMealSelected;

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
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: CooklyColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: CooklyColors.onPrimaryFixedVariant,
                ),
              ),
              const SizedBox(width: CooklySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prepare New Meal',
                      style: CooklyTextStyles.headlineSm,
                    ),
                    Text(
                      'Tap a meal category to activate AI curation',
                      style: CooklyTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              CooklyChip(
                label: 'AI Cook',
                background: CooklyColors.primaryFixed.withValues(alpha: 0.6),
                foreground: CooklyColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                textStyle: CooklyTextStyles.labelSm.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MealTile(
                    onTap: () => onMealSelected(MealType.breakfast),
                    icon: Icons.wb_twilight,
                    iconBackground: CooklyColors.tertiaryFixed,
                    iconColor: CooklyColors.onTertiaryFixed,
                    title: 'Breakfast',
                    subtitle: 'Fresh & Energize',
                    badgeColor: CooklyColors.primary,
                  ),
                ),
                const SizedBox(width: CooklySpacing.sm),
                Expanded(
                  child: _MealTile(
                    onTap: () => onMealSelected(MealType.lunch),
                    icon: Icons.wb_sunny_outlined,
                    iconBackground: CooklyColors.secondaryContainer,
                    iconColor: CooklyColors.onSecondaryContainer,
                    title: 'Lunch',
                    subtitle: 'Quick & Nourish',
                    badgeColor: CooklyColors.secondary,
                  ),
                ),
                const SizedBox(width: CooklySpacing.sm),
                Expanded(
                  child: _MealTile(
                    onTap: () => onMealSelected(MealType.dinner),
                    icon: Icons.nights_stay_outlined,
                    iconBackground: CooklyColors.primaryFixed,
                    iconColor: CooklyColors.onPrimaryFixed,
                    title: 'Dinner',
                    subtitle: 'Warm Comfort',
                    badgeColor: CooklyColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.onTap,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CooklyColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        side: const BorderSide(color: CooklyColors.surfaceContainerHighest),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: CooklyTextStyles.headlineSm.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: CooklyTextStyles.bodySm.copyWith(
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              const SizedBox(height: CooklySpacing.sm),
              CooklyChip(
                label: 'CURATE',
                background: badgeColor,
                foreground: CooklyColors.onPrimary,
                textStyle: CooklyTextStyles.labelSm.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantrySummaryCard extends StatelessWidget {
  const _PantrySummaryCard({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainer,
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        boxShadow: CooklyShadows.subtle,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CooklyColors.secondaryContainer,
              borderRadius: BorderRadius.circular(CooklyRadius.xl),
            ),
            child: const Icon(
              Icons.kitchen_outlined,
              size: 22,
              color: CooklyColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '12 ingredients in pantry',
                  style: CooklyTextStyles.headlineSm,
                ),
                Text(
                  'All key staples fresh & verified',
                  style: CooklyTextStyles.bodySm,
                ),
              ],
            ),
          ),
          Material(
            color: CooklyColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(CooklyRadius.lg),
            child: InkWell(
              onTap: onManage,
              borderRadius: BorderRadius.circular(CooklyRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Manage', style: CooklyTextStyles.labelMd),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: CooklyColors.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishSearchField extends StatelessWidget {
  const _DishSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        border: Border.all(color: CooklyColors.surfaceContainerHighest),
        boxShadow: CooklyShadows.subtle,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(Icons.search, size: 20, color: CooklyColors.outline),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: CooklyTextStyles.bodyMd.copyWith(
                color: CooklyColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search past AI-suggested dishes...',
                hintStyle: CooklyTextStyles.bodyMd.copyWith(
                  color: CooklyColors.outline,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: controller.clear,
              tooltip: 'Clear search',
              icon: const Icon(
                Icons.close,
                size: 20,
                color: CooklyColors.onSurfaceVariant,
              ),
            )
          else
            const SizedBox(width: CooklySpacing.sm),
        ],
      ),
    );
  }
}

class _RecentDishesHeader extends StatelessWidget {
  const _RecentDishesHeader({required this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Dishes', style: CooklyTextStyles.headlineMd),
              Text(
                'Cook again from your kitchen history',
                style: CooklyTextStyles.bodySm,
              ),
            ],
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: CooklyColors.primary,
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View all',
                  style: CooklyTextStyles.labelMd.copyWith(
                    color: CooklyColors.primary,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

class _MealArt extends StatelessWidget {
  const _MealArt({required this.mealType, required this.iconSize});

  final MealType mealType;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CooklyColors.primaryFixed, CooklyColors.tertiaryFixed],
        ),
      ),
      child: Center(
        child: Icon(mealType.icon, size: iconSize, color: CooklyColors.primary),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({required this.dish, required this.onOpen});

  static const _previewIngredients = 3;

  final Recipe dish;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final overlayChipColor = CooklyColors.surfaceBright.withValues(alpha: 0.9);
    final extraIngredients = dish.ingredients.length - _previewIngredients;

    return Material(
      color: CooklyColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(CooklyRadius.sheet),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onOpen,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CooklyRadius.sheet),
            boxShadow: CooklyShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MealArt(mealType: dish.mealType, iconSize: 56),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: CooklyChip(
                        label: dish.mealType.label,
                        background: overlayChipColor,
                        foreground: CooklyColors.onSurface,
                        leading: Icon(
                          dish.mealType.icon,
                          size: 15,
                          color: CooklyColors.tertiary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: CooklyChip(
                        label: '${dish.steps.length} steps',
                        background: overlayChipColor,
                        foreground: CooklyColors.onSurface,
                        textStyle: CooklyTextStyles.labelMd,
                        leading: const Icon(
                          Icons.format_list_numbered,
                          size: 16,
                          color: CooklyColors.primary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                    Text(dish.name, style: CooklyTextStyles.headlineMd),
                    const SizedBox(height: 2),
                    Text(
                      _suggestedLabel(dish.suggestedAt),
                      style: CooklyTextStyles.bodySm,
                    ),
                    if (dish.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Uses:', style: CooklyTextStyles.labelSm),
                          for (final ingredient in dish.ingredients.take(
                            _previewIngredients,
                          ))
                            CooklyChip(
                              label: ingredient.name,
                              background: CooklyColors.secondaryContainer
                                  .withValues(alpha: 0.6),
                              foreground: CooklyColors.onSecondaryContainer,
                            ),
                          if (extraIngredients > 0)
                            CooklyChip(
                              label: '+$extraIngredients more',
                              background: CooklyColors.surfaceContainer,
                              foreground: CooklyColors.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.checklist,
                          size: 16,
                          color: CooklyColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${dish.ingredients.length} ingredients',
                            style: CooklyTextStyles.labelSm.copyWith(
                              color: CooklyColors.secondary,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: onOpen,
                          style: FilledButton.styleFrom(
                            backgroundColor: CooklyColors.primary,
                            foregroundColor: CooklyColors.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 36),
                            textStyle: CooklyTextStyles.labelMd,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                CooklyRadius.xl,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Cook Again'),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DishesMessage extends StatelessWidget {
  const _DishesMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: CooklySpacing.lg,
        horizontal: CooklySpacing.md,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CooklyColors.secondaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: CooklyColors.secondary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: CooklyTextStyles.headlineSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: CooklyTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: CooklySpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: CooklyColors.primary,
              ),
              child: Text(
                actionLabel!,
                style: CooklyTextStyles.labelLg.copyWith(
                  color: CooklyColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void _showRecentDishesSheet(
  BuildContext context,
  List<Recipe> dishes,
  ValueChanged<Recipe> onOpen,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CooklyColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(CooklyRadius.sheet),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, CooklySpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: CooklyColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(CooklyRadius.full),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Dishes',
                          style: CooklyTextStyles.headlineMd,
                        ),
                        Text(
                          dishes.isEmpty
                              ? 'Dishes Cookly suggests will appear here'
                              : 'Tap any dish to see its recipe and steps',
                          style: CooklyTextStyles.bodySm,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    tooltip: 'Close recent dishes',
                    style: IconButton.styleFrom(
                      backgroundColor: CooklyColors.surfaceContainer,
                    ),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: CooklyColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dishes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final dish = dishes[index];
                    return Material(
                      color: CooklyColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(CooklyRadius.card),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(CooklyRadius.card),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          onOpen(dish);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  CooklyRadius.xl,
                                ),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: _MealArt(
                                    mealType: dish.mealType,
                                    iconSize: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dish.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CooklyTextStyles.headlineSm,
                                    ),
                                    Text(
                                      '${dish.mealType.label} • ${dish.steps.length} steps • '
                                      '${_suggestedLabel(dish.suggestedAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CooklyTextStyles.bodySm,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: CooklyColors.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
