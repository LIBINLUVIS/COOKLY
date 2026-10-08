import 'package:flutter/material.dart';

import '../../models/cookly_session.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../widgets/cookly_bottom_nav.dart';
import '../../widgets/cookly_chip.dart';
import '../../widgets/cookly_top_bar.dart';
import '../../widgets/profile_sheet.dart';
import '../../models/meal_type.dart';
import '../meal_plan/meal_prep_screen.dart';
import '../pantry/pantry_screen.dart';

/// Kitchen dashboard. Only the greeting is live; the meal selector, pantry
/// summary and recent dishes are placeholder content for now.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.session});

  final CooklySession session;

  void _openPantry(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PantryScreen(session: session)));
  }

  void _openMealPrep(BuildContext context, MealType mealType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealPrepScreen(session: session, mealType: mealType),
      ),
    );
  }

  void _onTabSelected(BuildContext context, CooklyTab tab) {
    switch (tab) {
      case CooklyTab.kitchen:
        break;
      case CooklyTab.pantry:
        _openPantry(context);
      case CooklyTab.profile:
        showProfileSheet(context, session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CooklyColors.surface,
      bottomNavigationBar: CooklyBottomNav(
        current: CooklyTab.kitchen,
        onSelected: (tab) => _onTabSelected(context, tab),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CooklySpacing.marginMobile,
                  12,
                  CooklySpacing.marginMobile,
                  CooklySpacing.lg,
                ),
                children: [
                  _GreetingSection(firstName: session.firstName),
                  const SizedBox(height: 12),
                  _PrepareMealCard(
                    onMealSelected: (meal) => _openMealPrep(context, meal),
                  ),
                  const SizedBox(height: CooklySpacing.md),
                  _PantrySummaryCard(onManage: () => _openPantry(context)),
                  const SizedBox(height: CooklySpacing.md),
                  const _DishSearchField(),
                  const SizedBox(height: CooklySpacing.lg),
                  const _RecentDishesHeader(),
                  const SizedBox(height: CooklySpacing.md),
                  for (final dish in _dummyDishes) ...[
                    _DishCard(dish: dish),
                    const SizedBox(height: CooklySpacing.md),
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

String _greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CooklyChip(
              label: 'Pantry Ready',
              background: CooklyColors.secondaryContainer,
              foreground: CooklyColors.onSecondaryContainer,
              leading: CooklyStatusDot(color: CooklyColors.secondary),
            ),
            const SizedBox(width: 6),
            const CooklyChip(
              label: 'Spring Season',
              background: CooklyColors.surfaceContainerHigh,
              foreground: CooklyColors.onSurfaceVariant,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showRecentDishesSheet(context),
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
  const _DishSearchField();

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
          IconButton(
            onPressed: () {},
            tooltip: 'Filter dishes',
            icon: const Icon(
              Icons.tune,
              size: 20,
              color: CooklyColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentDishesHeader extends StatelessWidget {
  const _RecentDishesHeader();

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
        TextButton(
          onPressed: () => _showRecentDishesSheet(context),
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

class _DishCard extends StatefulWidget {
  const _DishCard({required this.dish});

  final _DummyDish dish;

  @override
  State<_DishCard> createState() => _DishCardState();
}

class _DishCardState extends State<_DishCard> {
  bool _isStarred = false;

  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;
    final overlayChipColor = CooklyColors.surfaceBright.withValues(alpha: 0.9);

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
          SizedBox(
            height: 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _DishImage(url: dish.imageUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x80000000),
                        Color(0x1A000000),
                        Color(0x00000000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      CooklyChip(
                        label: dish.meal,
                        background: overlayChipColor,
                        foreground: CooklyColors.onSurface,
                        leading: Icon(
                          dish.mealIcon,
                          size: 15,
                          color: dish.mealIconColor,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      const SizedBox(width: CooklySpacing.sm),
                      CooklyChip(
                        label: dish.tag,
                        background: dish.tagBackground,
                        foreground: dish.tagForeground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: CooklyChip(
                    label: dish.cookTime,
                    background: overlayChipColor,
                    foreground: CooklyColors.onSurface,
                    textStyle: CooklyTextStyles.labelMd,
                    leading: const Icon(
                      Icons.schedule,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dish.name, style: CooklyTextStyles.headlineMd),
                          Text(
                            dish.description,
                            style: CooklyTextStyles.bodySm,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isStarred = !_isStarred),
                      tooltip: _isStarred ? 'Unstar' : 'Star',
                      icon: Icon(
                        _isStarred ? Icons.star : Icons.star_border,
                        size: 22,
                        color: _isStarred
                            ? CooklyColors.primary
                            : CooklyColors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('In pantry:', style: CooklyTextStyles.labelSm),
                    for (final ingredient in dish.pantryIngredients)
                      CooklyChip(
                        label: ingredient,
                        background: CooklyColors.secondaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        foreground: CooklyColors.onSecondaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      dish.footerIcon,
                      size: 16,
                      color: CooklyColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dish.footer,
                        style: CooklyTextStyles.labelSm.copyWith(
                          color: CooklyColors.secondary,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: CooklyColors.primary,
                        foregroundColor: CooklyColors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                        textStyle: CooklyTextStyles.labelMd,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CooklyRadius.xl),
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
    );
  }
}

class _DishImage extends StatelessWidget {
  const _DishImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: CooklyColors.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.restaurant, size: 32, color: CooklyColors.outline),
      ),
    );
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

void _showRecentDishesSheet(BuildContext context) {
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
                      Text('Recent Dishes', style: CooklyTextStyles.headlineMd),
                      Text(
                        'Tap any dish to quickly start step-by-step cooking',
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
            for (final dish in _dummyDishes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CooklyColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(CooklyRadius.card),
                    boxShadow: CooklyShadows.subtle,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(CooklyRadius.xl),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: _DishImage(url: dish.imageUrl),
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
                              dish.historySummary,
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
          ],
        ),
      ),
    ),
  );
}

class _DummyDish {
  const _DummyDish({
    required this.name,
    required this.description,
    required this.meal,
    required this.mealIcon,
    required this.mealIconColor,
    required this.tag,
    required this.tagBackground,
    required this.tagForeground,
    required this.cookTime,
    required this.imageUrl,
    required this.pantryIngredients,
    required this.footerIcon,
    required this.footer,
    required this.historySummary,
  });

  final String name;
  final String description;
  final String meal;
  final IconData mealIcon;
  final Color mealIconColor;
  final String tag;
  final Color tagBackground;
  final Color tagForeground;
  final String cookTime;
  final String imageUrl;
  final List<String> pantryIngredients;
  final IconData footerIcon;
  final String footer;
  final String historySummary;
}

const _dummyDishes = [
  _DummyDish(
    name: 'Apple Banana Oats Bowl',
    description:
        'Cinnamon rolled oats, fresh honeycrisp apple & toasted almonds',
    meal: 'Breakfast',
    mealIcon: Icons.wb_twilight,
    mealIconColor: CooklyColors.tertiary,
    tag: 'Morning Calm',
    tagBackground: CooklyColors.tertiaryFixed,
    tagForeground: CooklyColors.onTertiaryFixed,
    cookTime: '10-15 min',
    imageUrl:
        'https://lh3.googleusercontent.com/aida/AEtjO1XqXxdZqFATJYX328CIPIRiLwDvarznTtuFjFcDj6MlCOB_wEG9v79CAhYUa-3zDiJouXTEl18Kznxm8C4HXNUl0oOefOJPb9LSP6reLao_eAbzFD8TND0JCAeEJP7U4l0S1Oe5rxrvQo2qBJ-DBjdHJ14mw5Z4YXv600gCiHcYADxIYThjKpRLuENgRrP5H0ZgxFQgooSSmXEmUjZFwEwWbXz9uAfAIjj4qRm5owoxR4kh1p-31EetiMtf',
    pantryIngredients: ['Rolled Oats', 'Bananas', 'Chia Seeds'],
    footerIcon: Icons.check_circle_outline,
    footer: '100% pantry match',
    historySummary: 'Breakfast Oats • 10-15 min • Cooked yesterday',
  ),
  _DummyDish(
    name: 'Balanced Harvest Bowl',
    description: 'Seared herb chicken breast, edamame & seasoned avocado',
    meal: 'Lunch',
    mealIcon: Icons.wb_sunny_outlined,
    mealIconColor: CooklyColors.primary,
    tag: 'High Protein',
    tagBackground: CooklyColors.secondaryContainer,
    tagForeground: CooklyColors.onSecondaryContainer,
    cookTime: '20-25 min',
    imageUrl:
        'https://lh3.googleusercontent.com/aida/AEtjO1XOYPn3A5uAVvSP5cHjBYPD7jAu6LvcidCWh6SgnFJlA2cgepfmRJi1IyFrL5kWaNOHeZQcJGqKDPRAVJJR4Nygew-CheJMT6qy9pakUsjLFg5mv8EpwejxaYb7xBDvmNmSMHlDax-Zl_pwq9iZcWqKiMpoLhDvOP_rzx9z0415R6zxMtPZoMpEA_PJ3HZdbXxWclPdN0ghiiiTPzAjfk-mSTG_FgECdHKrF5YTSxoGF21uRkKtjkyCFkE',
    pantryIngredients: ['Free-range Chicken', 'Jasmine Rice', 'Sweet Potatoes'],
    footerIcon: Icons.check_circle_outline,
    footer: '42g Protein • Low GI',
    historySummary: 'High Protein Bowl • 20-25 min • Cooked 3 days ago',
  ),
  _DummyDish(
    name: 'Creamy Tomato Penne',
    description: 'Creamy roasted garlic and cherry tomato penne with basil',
    meal: 'Dinner',
    mealIcon: Icons.nights_stay_outlined,
    mealIconColor: CooklyColors.primary,
    tag: 'Comfort Food',
    tagBackground: CooklyColors.primaryFixed,
    tagForeground: CooklyColors.onPrimaryFixed,
    cookTime: '20 min',
    imageUrl:
        'https://lh3.googleusercontent.com/aida/AEtjO1VkVq1jePNm0CsL8Am4wuQRyfsIfmm6IXimjp9X7Qo9JSLFkkekolufdhF25rE6rLInSwiYun7HKjFunme1cyklDCIbwtIi241Yf1e5zo8HYan-1bNTcdU9APiDQ6jMIcdcKxUSGnEJNo3UCKNxXB-4bXrrou19dE6zn4L6sCjbuZxCmzYgDT_0vS8uyIQXroSo6-B45O2Ow0man6xrfS_mZ0Z7_Nu1mABaHtmg_KZoguG2o7gOYkHEEVrL',
    pantryIngredients: ['Penne Rigate', 'San Marzano', 'Sweet Basil'],
    footerIcon: Icons.eco_outlined,
    footer: 'Fresh herb harvest ready',
    historySummary: 'Italian Penne • 20 min • Cooked 2 days ago',
  ),
];
