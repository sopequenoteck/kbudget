// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

final class AppShadows {
  AppShadows._();

  // ===== sm (inchangé) =====
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  // ===== md (REFONTE — double-layer) =====
  /// Source: `_primitives.scss` `$shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)`.
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      spreadRadius: -1,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      spreadRadius: -2,
      offset: Offset(0, 2),
    ),
  ];

  // ===== lg (REFONTE — double-layer) =====
  /// Source: `_primitives.scss` `$shadow-lg`.
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 15,
      spreadRadius: -3,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      spreadRadius: -4,
      offset: Offset(0, 4),
    ),
  ];

  // ===== coloredPrimary — brightness-aware =====
  /// Colored shadow for dark theme — neutral black (cf. `_dark.scss` `--shadow-colored-primary: rgb(0 0 0 / 0.4)`).
  static const List<BoxShadow> coloredPrimaryDark = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];

  /// Colored shadow for light theme — amber glow (cf. `_primitives.scss` `$shadow-colored-primary: rgb(245 158 11 / 0.4)`).
  static const List<BoxShadow> coloredPrimaryLight = [
    BoxShadow(
      color: Color(0x66F59E0B),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];

  /// Returns the brightness-appropriate primary colored shadow.
  /// Use `Theme.of(context).brightness` as argument when needing it dynamically.
  static List<BoxShadow> coloredPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? coloredPrimaryDark : coloredPrimaryLight;

  // ===== DEPRECATED API =====
  @Deprecated(
    'Utiliser AppShadows.coloredPrimary(brightness) ou les constantes '
    'coloredPrimaryDark/Light. Cette API sera supprimée en KKS-240+.',
  )
  static List<BoxShadow> colored(Color color, {int alpha = 102}) => [
        BoxShadow(
          color: color.withAlpha(alpha),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];
}
