import 'package:flutter/material.dart';

import '../models/cookly_session.dart';
import '../theme/cookly_colors.dart';
import '../theme/cookly_theme.dart';
import 'profile_sheet.dart';

/// App header: a leading action on the left, the profile avatar on the right.
class CooklyTopBar extends StatelessWidget {
  const CooklyTopBar({super.key, required this.session, required this.leading});

  final CooklySession session;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: CooklySpacing.sm),
      decoration: const BoxDecoration(
        color: CooklyColors.surface,
        boxShadow: CooklyShadows.subtle,
      ),
      child: Row(
        children: [
          leading,
          const Spacer(),
          Semantics(
            button: true,
            label: 'Profile',
            child: InkResponse(
              onTap: () => showProfileSheet(context, session),
              radius: 24,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CooklyAvatar(session: session),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
