import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/cookly_session.dart';
import '../../services/auth_api_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/session_store.dart';
import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../widgets/cookly_logo.dart';
import '../../widgets/google_logo.dart';
import '../home/home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSigningIn = false;

  Future<void> _continueWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);

    try {
      final googleUser = await GoogleAuthService.instance.signIn();

      final authResponse = await AuthApiService.instance.loginWithProfile(
        email: googleUser.email,
        firstName: googleUser.firstName,
        lastName: googleUser.lastName,
        displayName: googleUser.displayName,
      );

      final session = CooklySession(
        token: authResponse.token,
        tokenExpiry: authResponse.tokenExpiry,
        email: googleUser.email,
        displayName: googleUser.displayName,
      );
      await SessionStore.instance.save(session);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen(session: session)),
      );
    } on GoogleSignInCancelled {
      // User dismissed the account picker; nothing to report.
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(error.message);
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Google sign-in failed: $error');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          backgroundColor: CooklyColors.errorContainer,
          content: Text(
            message,
            style: CooklyTextStyles.bodySm.copyWith(
              color: CooklyColors.onErrorContainer,
            ),
          ),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: CooklyColors.onErrorContainer,
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CooklyColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CooklySpacing.marginMobile,
          ),
          child: Column(
            children: [
              const _BrandHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const _PantryToPlateCard(),
                      const SizedBox(height: 12),
                      const _SuperpowerPills(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              _AuthFooter(
                isSigningIn: _isSigningIn,
                onGoogleTap: _continueWithGoogle,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: -48,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CooklyColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        Positioned(
          top: 24,
          right: 16,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CooklyColors.tertiaryFixed.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: CooklyColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: CooklyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CooklyLogo(size: 44)),
                ),
              ),
              Text(
                'Welcome to Cookly',
                style: CooklyTextStyles.headlineLgMobile,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Your smart AI kitchen companion for zero-waste cooking '
                    'and tailored recipes.',
                    textAlign: TextAlign.center,
                    style: CooklyTextStyles.bodyMd,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PantryToPlateCard extends StatelessWidget {
  const _PantryToPlateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CooklyColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: CooklyColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'PANTRY TO PLATE AI',
                        overflow: TextOverflow.ellipsis,
                        style: CooklyTextStyles.labelSm.copyWith(
                          color: CooklyColors.secondary,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: CooklyColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(CooklyRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: CooklyColors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '15 min',
                      style: CooklyTextStyles.labelSm.copyWith(
                        color: CooklyColors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CooklyColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DETECTED IN YOUR FRIDGE',
                  style: CooklyTextStyles.labelSm.copyWith(
                    color: CooklyColors.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _IngredientChip(emoji: '🍅', label: 'Fresh Tomato'),
                    _IngredientChip(emoji: '🧀', label: 'Parmesan'),
                    _IngredientChip(emoji: '🌿', label: 'Fresh Basil'),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: CooklyColors.outlineVariant.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.restaurant,
                              size: 20,
                              color: CooklyColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rustic Caprese Pasta Toss',
                                    style: CooklyTextStyles.labelMd,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Zero waste • 480 kcal',
                                    style: CooklyTextStyles.bodySm.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: CooklyColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: CooklyColors.primary,
                        ),
                      ),
                    ],
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

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CooklyRadius.xl),
        border: Border.all(
          color: CooklyColors.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 2),
        ],
      ),
      child: Text('$emoji $label', style: CooklyTextStyles.labelMd),
    );
  }
}

class _SuperpowerPills extends StatelessWidget {
  const _SuperpowerPills();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SuperpowerCard(
            icon: Icons.document_scanner,
            iconBackground: Color(0x1AA83212),
            iconColor: CooklyColors.primary,
            title: 'Smart Scan',
            subtitle: 'Snap ingredients or receipt',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _SuperpowerCard(
            icon: Icons.eco,
            iconBackground: CooklyColors.secondaryContainer,
            iconColor: CooklyColors.secondary,
            title: 'Zero Waste',
            subtitle: 'Cook before food expires',
          ),
        ),
      ],
    );
  }
}

class _SuperpowerCard extends StatelessWidget {
  const _SuperpowerCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(CooklyRadius.xl),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(title, style: CooklyTextStyles.labelMd),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: CooklyTextStyles.bodySm.copyWith(
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter({required this.isSigningIn, required this.onGoogleTap});

  final bool isSigningIn;
  final VoidCallback onGoogleTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CooklyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: CooklyColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
              ),
            ],
          ),
          child: Material(
            color: CooklyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onGoogleTap,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: CooklyColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: isSigningIn
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CooklyColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Entering Kitchen...',
                              style: CooklyTextStyles.labelLg,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GoogleLogo(size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: CooklyTextStyles.labelLg,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            _FooterLink('Privacy Policy'),
            Text(
              '•',
              style: TextStyle(color: CooklyColors.surfaceContainerHighest),
            ),
            _FooterLink('Terms of Service'),
            Text(
              '•',
              style: TextStyle(color: CooklyColors.surfaceContainerHighest),
            ),
            _FooterLink('Help Center'),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Cookly Culinary AI © 2026. Crafted for food lovers.',
          style: CooklyTextStyles.bodySm.copyWith(
            fontSize: 11,
            color: CooklyColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: CooklyTextStyles.labelSm.copyWith(
        color: CooklyColors.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}

