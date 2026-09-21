import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cookly_colors.dart';

/// Typography scale extracted from the Cookly Stitch design system.
/// Headlines/display use Epilogue, body/label text uses Plus Jakarta Sans.
class CooklyTextStyles {
  CooklyTextStyles._();

  static TextStyle get displayLg => GoogleFonts.epilogue(
        fontSize: 40,
        height: 48 / 40,
        letterSpacing: -0.02 * 40,
        fontWeight: FontWeight.w700,
        color: CooklyColors.onSurface,
      );

  static TextStyle get headlineLg => GoogleFonts.epilogue(
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.015 * 32,
        fontWeight: FontWeight.w600,
        color: CooklyColors.onSurface,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.epilogue(
        fontSize: 26,
        height: 34 / 26,
        letterSpacing: -0.01 * 26,
        fontWeight: FontWeight.w600,
        color: CooklyColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.epilogue(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: CooklyColors.onSurface,
      );

  static TextStyle get headlineSm => GoogleFonts.epilogue(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: CooklyColors.onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        height: 26 / 17,
        fontWeight: FontWeight.w400,
        color: CooklyColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
        color: CooklyColors.onSurfaceVariant,
      );

  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: CooklyColors.onSurfaceVariant,
      );

  static TextStyle get labelLg => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.01 * 14,
        fontWeight: FontWeight.w600,
        color: CooklyColors.onSurface,
      );

  static TextStyle get labelMd => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.02 * 12,
        fontWeight: FontWeight.w600,
        color: CooklyColors.onSurface,
      );

  static TextStyle get labelSm => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        height: 14 / 11,
        letterSpacing: 0.04 * 11,
        fontWeight: FontWeight.w700,
        color: CooklyColors.onSurfaceVariant,
      );
}
