import 'package:flutter/material.dart';

import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../widgets/cookly_logo.dart';

/// Placeholder landing screen shown after a successful login, until the
/// real home/dashboard screen is designed.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.displayName,
    required this.email,
    required this.onSignOut,
  });

  final String? displayName;
  final String email;
  final Future<void> Function(BuildContext context) onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CooklyColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CooklySpacing.marginMobile),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CooklyLogo(size: 72),
                const SizedBox(height: 24),
                Text(
                  'Welcome${displayName != null ? ', $displayName' : ''}!',
                  textAlign: TextAlign.center,
                  style: CooklyTextStyles.headlineLg,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: CooklyTextStyles.bodyMd,
                ),
                const SizedBox(height: 24),
                Text(
                  "You're signed in. The real Cookly kitchen dashboard "
                  'goes here.',
                  textAlign: TextAlign.center,
                  style: CooklyTextStyles.bodySm,
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => onSignOut(context),
                  child: Text(
                    'Sign out',
                    style: CooklyTextStyles.labelLg.copyWith(
                      color: CooklyColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
