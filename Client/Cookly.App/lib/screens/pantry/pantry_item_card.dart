import 'package:flutter/material.dart';

import '../../models/pantry_item.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../utils/dates.dart';
import '../../widgets/cookly_chip.dart';

class PantryItemCard extends StatelessWidget {
  const PantryItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
  });

  final PantryItem item;
  final VoidCallback onDelete;
  final VoidCallback onIncrease;

  /// Null disables the decrease button (quantity already at zero).
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    final expiry = _ExpiryStyle.of(item);
    final category = item.category;
    final addedAt = item.purchasedAt;

    return Container(
      padding: const EdgeInsets.all(CooklySpacing.md),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.card),
        boxShadow: CooklyShadows.subtle,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: expiry.iconBackground,
                  borderRadius: BorderRadius.circular(CooklyRadius.xl),
                ),
                child: Text(
                  category?.emoji ?? PantryCategory.others.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CooklyTextStyles.headlineSm,
                          ),
                        ),
                        if (category != null) ...[
                          const SizedBox(width: CooklySpacing.sm),
                          CooklyChip(
                            label: category.label,
                            background: CooklyColors.surfaceContainer,
                            foreground: CooklyColors.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                    if (addedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(_addedLabel(addedAt), style: CooklyTextStyles.bodySm),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete ${item.name}',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: CooklyColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: CooklyChip(
                  label: expiry.label,
                  background: expiry.background,
                  foreground: expiry.foreground,
                  leading: CooklyStatusDot(color: expiry.dot),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
              const SizedBox(width: CooklySpacing.sm),
              _QuantityStepper(
                label: item.quantityLabel,
                itemName: item.name,
                onIncrease: onIncrease,
                onDecrease: onDecrease,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _addedLabel(DateTime addedAt) {
    final daysAgo = -calendarDaysFromToday(addedAt);
    if (daysAgo <= 0) return 'Added today';
    if (daysAgo == 1) return 'Added yesterday';
    if (daysAgo < 7) return 'Added $daysAgo days ago';
    return 'Added ${formatShortDate(addedAt)}';
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.label,
    required this.itemName,
    required this.onIncrease,
    required this.onDecrease,
  });

  final String label;
  final String itemName;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(CooklyRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, tooltip: 'Decrease $itemName', onPressed: onDecrease),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(label, textAlign: TextAlign.center, style: CooklyTextStyles.labelMd),
            ),
          ),
          _StepButton(icon: Icons.add, tooltip: 'Increase $itemName', onPressed: onIncrease),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? CooklyColors.surfaceContainerLowest : Colors.transparent,
        borderRadius: BorderRadius.circular(CooklyRadius.lg),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(CooklyRadius.lg),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 16,
              color: enabled
                  ? CooklyColors.onSurface
                  : CooklyColors.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpiryStyle {
  const _ExpiryStyle({
    required this.label,
    required this.background,
    required this.foreground,
    required this.dot,
    required this.iconBackground,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color dot;
  final Color iconBackground;

  static final _calmIconBackground = CooklyColors.secondaryContainer.withValues(alpha: 0.5);
  static final _urgentIconBackground = CooklyColors.primaryFixed.withValues(alpha: 0.4);

  factory _ExpiryStyle.of(PantryItem item) {
    final days = item.daysUntilExpiry;
    if (days == null) {
      return _ExpiryStyle(
        label: 'No expiry date',
        background: CooklyColors.surfaceContainer,
        foreground: CooklyColors.onSurfaceVariant,
        dot: CooklyColors.outline,
        iconBackground: _calmIconBackground,
      );
    }
    if (days <= 1) {
      final label = switch (days) {
        1 => 'Expires tomorrow',
        0 => 'Expires today',
        -1 => 'Expired yesterday',
        _ => 'Expired ${-days} days ago',
      };
      return _ExpiryStyle(
        label: label,
        background: CooklyColors.errorContainer,
        foreground: CooklyColors.onErrorContainer,
        dot: CooklyColors.error,
        iconBackground: _urgentIconBackground,
      );
    }
    if (days <= 3) {
      return _ExpiryStyle(
        label: 'Expires in $days days',
        background: CooklyColors.tertiaryFixed,
        foreground: CooklyColors.onTertiaryFixed,
        dot: CooklyColors.tertiary,
        iconBackground: _calmIconBackground,
      );
    }
    return _ExpiryStyle(
      label: 'Fresh for $days days',
      background: CooklyColors.secondaryContainer,
      foreground: CooklyColors.onSecondaryContainer,
      dot: CooklyColors.secondary,
      iconBackground: _calmIconBackground,
    );
  }
}
