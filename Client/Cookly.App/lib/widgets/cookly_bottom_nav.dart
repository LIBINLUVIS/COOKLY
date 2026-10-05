import 'package:flutter/material.dart';

import '../theme/cookly_colors.dart';
import '../theme/cookly_text_styles.dart';
import '../theme/cookly_theme.dart';

enum CooklyTab { kitchen, pantry, profile }

class CooklyBottomNav extends StatelessWidget {
  const CooklyBottomNav({super.key, required this.current, required this.onSelected});

  final CooklyTab current;
  final ValueChanged<CooklyTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CooklyColors.surface,
        boxShadow: CooklyShadows.bottomBar,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(CooklyTab.kitchen, Icons.outdoor_grill_outlined, 'Kitchen'),
              _item(CooklyTab.pantry, Icons.kitchen_outlined, 'Pantry'),
              _item(CooklyTab.profile, Icons.account_circle_outlined, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(CooklyTab tab, IconData icon, String label) {
    final isActive = tab == current;
    final color = isActive ? CooklyColors.primary : CooklyColors.onSurfaceVariant;
    return Semantics(
      selected: isActive,
      button: true,
      child: InkResponse(
        onTap: () => onSelected(tab),
        radius: 32,
        child: Container(
          width: 72,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: CooklyTextStyles.labelSm.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
