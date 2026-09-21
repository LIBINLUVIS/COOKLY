import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/cookly_colors.dart';
import '../../theme/cookly_text_styles.dart';
import '../../theme/cookly_theme.dart';
import '../../widgets/cookly_logo.dart';
import '../sign_in/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _ProgressStep {
  const _ProgressStep(this.threshold, this.text);
  final int threshold;
  final String text;
}

const _progressSteps = <_ProgressStep>[
  _ProgressStep(45, 'Inventorying seasonal pantry...'),
  _ProgressStep(72, 'Tuning heat & flavor pairings...'),
  _ProgressStep(92, 'Readying artisanal recipes...'),
  _ProgressStep(100, 'Welcome chef! Bon Appétit.'),
];

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _logoTapController;

  Timer? _progressTimer;
  final _random = math.Random();
  int _progress = 28;
  String _statusText = 'Warming up kitchen AI...';
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _logoTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 1,
      upperBound: 1.1,
      value: 1,
    );
    _startProgressTimer();
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 280), (
      timer,
    ) {
      if (_progress >= 100) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress = math.min(100, _progress + 4 + _random.nextInt(8));
        _statusText = _statusForProgress(_progress);
      });
    });
  }

  String _statusForProgress(int progress) {
    var text = _statusText;
    for (final step in _progressSteps) {
      if (progress >= step.threshold) {
        text = step.text;
      }
    }
    return text;
  }

  void _enterKitchen() {
    if (_navigating) return;
    _navigating = true;
    _progressTimer?.cancel();
    setState(() {
      _progress = 100;
      _statusText = _progressSteps.last.text;
    });
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignInScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _loopController.dispose();
    _logoTapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctaFilled = _progress >= 100;
    return Scaffold(
      backgroundColor: CooklyColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _AmbientBackground(loop: _loopController)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CooklySpacing.marginMobile,
                vertical: CooklySpacing.xl,
              ),
              child: Column(
                children: [
                  _IntelligenceBadge(loop: _loopController),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _logoTapController,
                            child: GestureDetector(
                              onTap: () {
                                _logoTapController.forward().then(
                                  (_) => _logoTapController.reverse(),
                                );
                              },
                              child: _GlowingLogo(loop: _loopController),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Cookly', style: CooklyTextStyles.displayLg
                                  .copyWith(color: CooklyColors.primary)),
                              const SizedBox(width: 6),
                              _BounceDot(
                                loop: _loopController,
                                delay: 0,
                                color: CooklyColors.tertiaryContainer,
                                size: 10,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Smarter cooking from your pantry',
                            textAlign: TextAlign.center,
                            style: CooklyTextStyles.headlineSm,
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Text(
                              'Transform daily leftovers & ingredients into '
                              'masterclass home dinners.',
                              textAlign: TextAlign.center,
                              style: CooklyTextStyles.bodyMd.copyWith(
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _FeaturePill(
                                icon: Icons.eco,
                                label: 'Zero-Waste',
                                iconColor: CooklyColors.secondary,
                              ),
                              _FeaturePill(
                                icon: Icons.local_fire_department,
                                label: 'Smart Timer',
                                iconColor: CooklyColors.primary,
                              ),
                              _FeaturePill(
                                icon: Icons.mic,
                                label: 'Hands-Free',
                                iconColor: CooklyColors.tertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      children: [
                        _ProgressSection(
                          progress: _progress,
                          statusText: _statusText,
                          loop: _loopController,
                        ),
                        const SizedBox(height: 20),
                        _EnterKitchenButton(
                          filled: ctaFilled,
                          onTap: _enterKitchen,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'v1.2.0 • AI Kitchen Sanctuary',
                          style: CooklyTextStyles.labelSm.copyWith(
                            color: CooklyColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BounceDot(
                        loop: _loopController,
                        delay: 0,
                        color: CooklyColors.primary,
                        size: 8,
                      ),
                      const SizedBox(width: 8),
                      _BounceDot(
                        loop: _loopController,
                        delay: 0.15,
                        color: CooklyColors.tertiary,
                        size: 8,
                      ),
                      const SizedBox(width: 8),
                      _BounceDot(
                        loop: _loopController,
                        delay: 0.3,
                        color: CooklyColors.secondary,
                        size: 8,
                      ),
                    ],
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

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final pulse = 0.85 + 0.15 * math.sin(loop.value * 2 * math.pi);
        return Stack(
          children: [
            Positioned(
              top: -96,
              left: -80,
              child: _blurCircle(320, CooklyColors.primaryFixed, 0.4 * pulse),
            ),
            Positioned(
              top: 220,
              right: -96,
              child: _blurCircle(
                384,
                CooklyColors.tertiaryFixed,
                0.35 * pulse,
              ),
            ),
            Positioned(
              bottom: 40,
              left: 90,
              child: _blurCircle(
                288,
                CooklyColors.secondaryFixed,
                0.3 * pulse,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blurCircle(double size, Color color, double opacity) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _IntelligenceBadge extends StatelessWidget {
  const _IntelligenceBadge({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CooklyColors.surfaceContainerHigh.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(CooklyRadius.full),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: CooklyColors.primary),
            const SizedBox(width: 8),
            Text(
              'CULINARY INTELLIGENCE',
              style: CooklyTextStyles.labelSm.copyWith(letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingLogo extends StatelessWidget {
  const _GlowingLogo({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final pulse = 0.85 + 0.15 * math.sin(loop.value * 2 * math.pi);
        return SizedBox(
          width: 176,
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        CooklyColors.primaryFixed,
                        CooklyColors.tertiaryFixed,
                        CooklyColors.secondaryContainer,
                      ],
                    ).withOpacity(0.6 * pulse),
                  ),
                ),
              ),
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CooklyColors.surfaceContainerLowest.withValues(
                    alpha: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const CooklyLogo(size: 96),
            ],
          ),
        );
      },
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CooklyColors.surfaceContainer,
        borderRadius: BorderRadius.circular(CooklyRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: CooklyTextStyles.labelMd),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.progress,
    required this.statusText,
    required this.loop,
  });

  final int progress;
  final String statusText;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    final complete = progress >= 100;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(CooklyRadius.full),
          child: Container(
            height: 6,
            color: CooklyColors.surfaceContainerHighest,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                widthFactor: progress / 100,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CooklyColors.primary,
                        CooklyColors.primaryContainer,
                        CooklyColors.tertiary,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (complete)
                    const Icon(
                      Icons.check_circle,
                      size: 13,
                      color: CooklyColors.secondary,
                    )
                  else
                    AnimatedBuilder(
                      animation: loop,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: loop.value * 2 * math.pi,
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.sync,
                        size: 13,
                        color: CooklyColors.primary,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      statusText,
                      overflow: TextOverflow.ellipsis,
                      style: CooklyTextStyles.labelSm.copyWith(
                        color: CooklyColors.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$progress%',
              style: CooklyTextStyles.labelSm.copyWith(
                color: CooklyColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EnterKitchenButton extends StatelessWidget {
  const _EnterKitchenButton({required this.filled, required this.onTap});

  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? CooklyColors.primary
        : CooklyColors.surfaceContainerLow;
    final foreground = filled ? CooklyColors.onPrimary : CooklyColors.onSurface;
    final iconColor = filled ? CooklyColors.onPrimary : CooklyColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CooklyRadius.full),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(CooklyRadius.full),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Tap to Enter Kitchen',
                    overflow: TextOverflow.ellipsis,
                    style: CooklyTextStyles.labelLg.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BounceDot extends StatelessWidget {
  const _BounceDot({
    required this.loop,
    required this.delay,
    required this.color,
    required this.size,
  });

  final Animation<double> loop;
  final double delay;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, child) {
        final t = (loop.value + delay) % 1.0;
        final bounce = math.sin(t * math.pi).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -bounce * 6),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
