import 'package:flutter/material.dart';

import '../../models/cookly_session.dart';
import '../../models/user_profile.dart';
import '../../navigation/sign_out.dart';
import '../../services/profile_api_service.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/cookly_bottom_nav.dart';
import '../../widgets/cookly_top_bar.dart';
import '../../widgets/profile_sheet.dart';
import '../pantry/pantry_screen.dart';

/// User profile: basic info, dish and pantry counts, taste preferences and culinary goal.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.session});

  final CooklySession session;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ProfileApiService.instance;

  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await _api.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        signOutAndShowSplash(context);
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _edit({required bool focusGoal}) async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CooklyColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CooklyRadius.sheet),
        ),
      ),
      builder: (_) =>
          _EditPreferencesSheet(profile: profile, focusGoal: focusGoal),
    );
    if (!mounted || updated == null) return;
    setState(() => _profile = updated);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Saved. Cookly will use this for your next meal plan.'),
        ),
      );
  }

  Future<void> _openPantry() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PantryScreen(session: widget.session)),
    );
    if (mounted) _load();
  }

  void _onTabSelected(CooklyTab tab) {
    switch (tab) {
      case CooklyTab.kitchen:
        Navigator.of(context).popUntil((route) => route.isFirst);
      case CooklyTab.pantry:
        _openPantry();
      case CooklyTab.profile:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: CooklyColors.surface,
      bottomNavigationBar: CooklyBottomNav(
        current: CooklyTab.profile,
        onSelected: _onTabSelected,
      ),
      body: SafeArea(
        bottom: false,
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: CooklyColors.onSurface,
                    ),
                  ),
                  Text('Profile', style: CooklyTextStyles.headlineSm),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: CooklyColors.primary,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    CooklySpacing.marginMobile,
                    CooklySpacing.md,
                    CooklySpacing.marginMobile,
                    CooklySpacing.xl,
                  ),
                  children: [
                    if (profile == null && _isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: CooklyColors.primary,
                          ),
                        ),
                      )
                    else if (profile == null)
                      _ErrorMessage(
                        message: _error ?? 'Could not load your profile.',
                        onRetry: _load,
                      )
                    else ...[
                      _ProfileHeader(
                        session: widget.session,
                        profile: profile,
                        onEdit: () => _edit(focusGoal: false),
                        onSettings: () =>
                            showProfileSheet(context, widget.session),
                      ),
                      const SizedBox(height: CooklySpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.restaurant,
                              iconBackground: CooklyColors.primaryFixed,
                              iconColor: CooklyColors.primary,
                              value: profile.dishesCount,
                              label: 'Dishes Cooked',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.kitchen_outlined,
                              iconBackground: CooklyColors.secondaryContainer,
                              iconColor: CooklyColors.onSecondaryContainer,
                              value: profile.pantryItemsCount,
                              label: 'Pantry Items',
                              onTap: _openPantry,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: CooklySpacing.md),
                      _InfoCard(
                        icon: Icons.favorite_border,
                        title: 'Taste Preferences',
                        description:
                            'Cookly AI prioritises these flavours and respects any allergies or dislikes.',
                        fieldLabel: 'FAVORITE INGREDIENTS & NOTES',
                        value: profile.preference,
                        placeholder:
                            'Not set yet. Add flavours you love, allergies or foods to avoid.',
                        footer: 'Used for every AI recipe',
                        onEdit: () => _edit(focusGoal: false),
                      ),
                      const SizedBox(height: CooklySpacing.md),
                      _InfoCard(
                        icon: Icons.emoji_events_outlined,
                        title: 'Culinary Goal',
                        description:
                            'Meal suggestions are planned around this goal.',
                        fieldLabel: 'CURRENT CULINARY GOAL & TARGET',
                        value: profile.goal,
                        placeholder:
                            'Not set yet. Cookly plans balanced meals until you add a goal.',
                        footer:
                            'e.g. high-protein dinners, quick weekday meals',
                        onEdit: () => _edit(focusGoal: true),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.session,
    required this.profile,
    required this.onEdit,
    required this.onSettings,
  });

  final CooklySession session;
  final UserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final memberSince = profile.memberSince;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CooklyColors.primaryFixedDim, width: 2),
          ),
          child: CooklyAvatar(session: session, size: 96),
        ),
        const SizedBox(height: 12),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: CooklyTextStyles.headlineLgMobile,
        ),
        const SizedBox(height: 2),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: CooklyTextStyles.bodyMd,
        ),
        if (memberSince != null) ...[
          const SizedBox(height: 2),
          Text(
            'Member since ${formatShortDate(memberSince)}',
            style: CooklyTextStyles.bodySm,
          ),
        ],
        const SizedBox(height: CooklySpacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
                style: FilledButton.styleFrom(
                  backgroundColor: CooklyColors.primary,
                  foregroundColor: CooklyColors.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  textStyle: CooklyTextStyles.labelLg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CooklyRadius.card),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: onSettings,
              tooltip: 'Account settings',
              style: IconButton.styleFrom(
                backgroundColor: CooklyColors.surfaceContainer,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(
                Icons.settings_outlined,
                color: CooklyColors.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CooklyColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(CooklyRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: CooklySpacing.md,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CooklyRadius.card),
            boxShadow: CooklyShadows.subtle,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: CooklySpacing.sm),
              Text('$value', style: CooklyTextStyles.headlineLgMobile),
              Text(
                label,
                textAlign: TextAlign.center,
                style: CooklyTextStyles.bodySm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.value,
    required this.placeholder,
    required this.footer,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final String description;
  final String fieldLabel;
  final String? value;
  final String placeholder;
  final String footer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasValue = value?.trim().isNotEmpty ?? false;
    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
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
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.tune, size: 16),
                label: Text(hasValue ? 'Manage' : 'Add'),
                style: TextButton.styleFrom(
                  foregroundColor: CooklyColors.primary,
                  backgroundColor: CooklyColors.primaryFixed.withValues(
                    alpha: 0.5,
                  ),
                  visualDensity: VisualDensity.compact,
                  textStyle: CooklyTextStyles.labelMd,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CooklyRadius.full),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: CooklyTextStyles.bodySm),
          const SizedBox(height: 12),
          Text(
            fieldLabel,
            style: CooklyTextStyles.labelSm.copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(CooklyRadius.xl),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CooklyColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(CooklyRadius.xl),
                border: Border.all(color: CooklyColors.surfaceContainerHighest),
              ),
              child: Text(
                hasValue ? value!.trim() : placeholder,
                style: hasValue
                    ? CooklyTextStyles.bodyMd.copyWith(
                        color: CooklyColors.onSurface,
                      )
                    : CooklyTextStyles.bodyMd.copyWith(
                        color: CooklyColors.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: CooklyTextStyles.labelSm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: CooklyColors.outline,
          ),
          const SizedBox(height: 12),
          Text(
            "Couldn't load your profile",
            style: CooklyTextStyles.headlineSm,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: CooklyTextStyles.bodySm,
          ),
          const SizedBox(height: CooklySpacing.sm),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: CooklyColors.primary),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

/// Edits the taste preferences and culinary goal; pops with the updated profile.
class _EditPreferencesSheet extends StatefulWidget {
  const _EditPreferencesSheet({required this.profile, required this.focusGoal});

  final UserProfile profile;
  final bool focusGoal;

  @override
  State<_EditPreferencesSheet> createState() => _EditPreferencesSheetState();
}

class _EditPreferencesSheetState extends State<_EditPreferencesSheet> {
  static const _maxLength = 350;

  late final _preferenceController = TextEditingController(
    text: widget.profile.preference ?? '',
  );
  late final _goalController = TextEditingController(
    text: widget.profile.goal ?? '',
  );
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _preferenceController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final updated = await ProfileApiService.instance.updatePreferences(
        goal: _goalController.text.trim(),
        preference: _preferenceController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(updated);
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        Navigator.of(context).pop();
        signOutAndShowSplash(context);
        return;
      }
      setState(() {
        _error = error.message;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            CooklySpacing.marginMobile,
            12,
            CooklySpacing.marginMobile,
            CooklySpacing.marginMobile,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CooklyColors.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(CooklyRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: CooklySpacing.md),
              Text('Edit Profile', style: CooklyTextStyles.headlineMd),
              const SizedBox(height: 4),
              Text(
                'Cookly AI plans every meal around these.',
                style: CooklyTextStyles.bodySm,
              ),
              const SizedBox(height: CooklySpacing.md),
              _field(
                label: 'Taste preferences',
                controller: _preferenceController,
                hint: 'e.g. Mild spice, love garlic & basil, no peanuts',
                autofocus: !widget.focusGoal,
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Culinary goal',
                controller: _goalController,
                hint: 'e.g. High-protein dinners, quick weekday meals',
                autofocus: widget.focusGoal,
              ),
              if (_error != null) ...[
                const SizedBox(height: CooklySpacing.sm),
                Text(
                  _error!,
                  style: CooklyTextStyles.bodySm.copyWith(
                    color: CooklyColors.error,
                  ),
                ),
              ],
              const SizedBox(height: CooklySpacing.md),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: CooklyColors.primary,
                  foregroundColor: CooklyColors.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                  textStyle: CooklyTextStyles.labelLg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CooklyRadius.xl),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CooklyColors.onPrimary,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool autofocus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CooklyTextStyles.labelMd.copyWith(
            color: CooklyColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          autofocus: autofocus,
          minLines: 2,
          maxLines: 4,
          maxLength: _maxLength,
          textCapitalization: TextCapitalization.sentences,
          style: CooklyTextStyles.bodyMd.copyWith(
            color: CooklyColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: CooklyTextStyles.bodyMd.copyWith(
              color: CooklyColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: CooklyColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CooklyRadius.xl),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CooklyRadius.xl),
              borderSide: const BorderSide(
                color: CooklyColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
