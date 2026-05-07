import 'package:flutter/material.dart';
import 'package:k_budget/src/theme/app_theme.dart';

/// Itère [body] sur les thèmes [AppTheme.dark] et [AppTheme.light].
///
/// Usage typique :
/// ```dart
/// forEachTheme((theme, themeName) {
///   testWidgets('should_render_correctly_when_$themeName', (tester) async {
///     // pumpWidget avec un MaterialApp(theme: theme, ...)
///   });
/// });
/// ```
void forEachTheme(void Function(ThemeData theme, String themeName) body) {
  body(AppTheme.dark, 'dark');
  body(AppTheme.light, 'light');
}
