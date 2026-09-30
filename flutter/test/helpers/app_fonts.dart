// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/services.dart';
import 'package:k_budget/src/constants/app_typography.dart';

/// Loads the Inter font declared in `pubspec.yaml`.
///
/// Widget tests otherwise render text with the `FlutterTest` font, whose
/// square glyphs are far wider than Inter: a width check, such as an overflow
/// test at 360 px, is only meaningful with the real font.
Future<void> loadAppFonts() async {
  final loader = FontLoader(AppTypography.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter/Inter-$weight.ttf'));
  }
  await loader.load();
}
