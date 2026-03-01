import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      spreadRadius: -1,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 15,
      spreadRadius: -3,
      offset: Offset(0, 10),
    ),
  ];

  /// Colored shadow with theme-aware alpha.
  /// [alpha] should be 102 for light theme, 89 for dark theme.
  static List<BoxShadow> colored(Color color, {int alpha = 102}) => [
    BoxShadow(
      color: color.withAlpha(alpha),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];
}
