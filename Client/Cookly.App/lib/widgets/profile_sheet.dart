import 'package:flutter/material.dart';

import '../models/cookly_session.dart';
import '../navigation/sign_out.dart';
import '../theme/cookly_colors.dart';
import '../theme/cookly_text_styles.dart';
import '../theme/cookly_theme.dart';

class CooklyAvatar extends StatelessWidget {
  const CooklyAvatar({super.key, required this.session, this.size = 32});

  final CooklySession session;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = session.firstName.isEmpty ? '?' : session.firstName[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: CooklyColors.primaryFixed,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: CooklyTextStyles.labelLg.copyWith(
          fontSize: size * 0.42,
          color: CooklyColors.onPrimaryFixedVariant,
        ),
      ),
    );
  }
}

/// Shows the signed-in user's details with a sign-out action.
Future<void> showProfileSheet(BuildContext context, CooklySession session) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: CooklyColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CooklyRadius.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CooklySpacing.marginMobile,
          12,
          CooklySpacing.marginMobile,
          CooklySpacing.marginMobile,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: CooklySpacing.lg),
            CooklyAvatar(session: session, size: 64),
            const SizedBox(height: 12),
            Text(session.fullName, style: CooklyTextStyles.headlineSm, textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(session.email, style: CooklyTextStyles.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: CooklySpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  signOutAndShowSplash(context);
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Sign out'),
                style: FilledButton.styleFrom(
                  backgroundColor: CooklyColors.errorContainer,
                  foregroundColor: CooklyColors.onErrorContainer,
                  minimumSize: const Size.fromHeight(52),
                  textStyle: CooklyTextStyles.labelLg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CooklyRadius.card),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: CooklyColors.outlineVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(CooklyRadius.full),
      ),
    );
  }
}
