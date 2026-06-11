import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  // Sizes
  /// Extra-extra-small font size — for uppercase labels.
  /// Source: `_primitives.scss` `--font-size-2xs: 0.625rem`.
  static const double size2Xs = 10.0;
  static const double sizeXs = 12.0;
  static const double sizeSm = 14.0;
  static const double sizeMd = 16.0;
  static const double sizeLg = 18.0;
  static const double sizeXl = 20.0;
  static const double size2xl = 24.0;
  static const double size3xl = 30.0;
  /// Hero font size — **réservé exclusivement au montant patrimoine total du dashboard**.
  /// Pour tout autre contexte hero, utiliser [size3xl] (30px), conforme à `--font-size-3xl` Angular.
  /// Source: `_dark.scss` `--font-size-hero: 2.25rem`.
  static const double sizeHero = 36.0;

  // Weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Line heights
  static const double lineHeightTight = 1.25;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Monospace font
  static const String fontMono = 'monospace';

  // Letter-spacing pour labels uppercase
  /// Multiplicative factor for uppercase label letter-spacing
  /// (CSS `letter-spacing: 0.05em` equivalent).
  /// Usage: `Text(label, style: TextStyle(fontSize: size, letterSpacing: size * AppTypography.labelLetterSpacingFactor))`.
  static const double labelLetterSpacingFactor = 0.05;

  /// Pre-computed letter-spacing for `size2Xs` (10px × 0.05).
  static const double labelLetterSpacingForSize10 = 0.5;
  /// Pre-computed letter-spacing for `sizeXs` (12px × 0.05).
  static const double labelLetterSpacingForSize12 = 0.6;
  /// Pre-computed letter-spacing for `sizeSm` (14px × 0.05).
  static const double labelLetterSpacingForSize14 = 0.7;
}
