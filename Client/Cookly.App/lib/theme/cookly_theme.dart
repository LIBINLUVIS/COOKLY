import 'package:flutter/material.dart';

import 'cookly_colors.dart';
import 'cookly_text_styles.dart';

/// Spacing scale (in logical pixels) matching the Stitch design tokens.
class CooklySpacing {
  CooklySpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double marginMobile = 16;
  static const double margin = 20;
  static const double lg = 24;
  static const double gutterLg = 24;
  static const double xl = 32;
}

/// Corner radii matching the Stitch design tokens.
class CooklyRadius {
  CooklyRadius._();

  static const double sm = 4;
  static const double lg = 8;
  static const double xl = 12;
  static const double card = 16;
  static const double sheet = 24;
  static const double full = 9999;
}

/// Warm, low-opacity ambient shadows from the design system's elevation levels.
class CooklyShadows {
  CooklyShadows._();

  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D1F2421), blurRadius: 20, spreadRadius: -2, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08E25B38), blurRadius: 6, spreadRadius: -1, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> bottomBar = [
    BoxShadow(color: Color(0x0D1F2421), blurRadius: 20, offset: Offset(0, -4)),
  ];
}

class CooklyTheme {
  CooklyTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: CooklyColors.primary,
      onPrimary: CooklyColors.onPrimary,
      primaryContainer: CooklyColors.primaryContainer,
      onPrimaryContainer: CooklyColors.onPrimaryContainer,
      secondary: CooklyColors.secondary,
      onSecondary: CooklyColors.onSecondary,
      secondaryContainer: CooklyColors.secondaryContainer,
      onSecondaryContainer: CooklyColors.onSecondaryContainer,
      tertiary: CooklyColors.tertiary,
      onTertiary: CooklyColors.onTertiary,
      tertiaryContainer: CooklyColors.tertiaryContainer,
      onTertiaryContainer: CooklyColors.onTertiaryContainer,
      error: CooklyColors.error,
      onError: CooklyColors.onError,
      errorContainer: CooklyColors.errorContainer,
      onErrorContainer: CooklyColors.onErrorContainer,
      surface: CooklyColors.surface,
      onSurface: CooklyColors.onSurface,
      surfaceContainerLowest: CooklyColors.surfaceContainerLowest,
      surfaceContainerLow: CooklyColors.surfaceContainerLow,
      surfaceContainer: CooklyColors.surfaceContainer,
      surfaceContainerHigh: CooklyColors.surfaceContainerHigh,
      surfaceContainerHighest: CooklyColors.surfaceContainerHighest,
      onSurfaceVariant: CooklyColors.onSurfaceVariant,
      outline: CooklyColors.outline,
      outlineVariant: CooklyColors.outlineVariant,
      inverseSurface: CooklyColors.inverseSurface,
      onInverseSurface: CooklyColors.inverseOnSurface,
      inversePrimary: CooklyColors.inversePrimary,
      surfaceTint: CooklyColors.surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CooklyColors.background,
      fontFamily: CooklyTextStyles.bodyMd.fontFamily,
      textTheme: TextTheme(
        displayLarge: CooklyTextStyles.displayLg,
        headlineLarge: CooklyTextStyles.headlineLg,
        headlineMedium: CooklyTextStyles.headlineMd,
        headlineSmall: CooklyTextStyles.headlineSm,
        bodyLarge: CooklyTextStyles.bodyLg,
        bodyMedium: CooklyTextStyles.bodyMd,
        bodySmall: CooklyTextStyles.bodySm,
        labelLarge: CooklyTextStyles.labelLg,
        labelMedium: CooklyTextStyles.labelMd,
        labelSmall: CooklyTextStyles.labelSm,
      ),
    );
  }
}
