// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

/// Thèmes Material de l'app. Chaque couleur pointe un token sémantique de
/// k-design (via [AppColors]), comme le web : fond de page `bg-primary`,
/// chrome (en-tête, barre du bas) `surface-raised`, contenu `surface-default`,
/// action `color-primary` avec `color-primary-contrast` dessus (D2), texte
/// secondaire `text-secondary`, erreur `text-error` avec `text-inverse` sur
/// son aplat (KKS-600). Seul le secondaire indigo reste local.
class AppTheme {
  AppTheme._();

  /// Thème clair.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: AppTypography.fontFamily,
        // surface (surface-default, #ffffff) et onError (text-inverse,
        // #ffffff) valent le défaut de ColorScheme.light : non répétés,
        // vérifiés par app_theme_test.dart.
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryAmberLight,
          onPrimary: AppColors.primaryAmberContrastLight,
          primaryContainer: AppColors.primaryMutedLight,
          onPrimaryContainer: AppColors.textPrimaryLight,
          secondary: AppColors.indigo600,
          onSecondary: AppColors.textInverseLight,
          secondaryContainer: AppColors.indigo100,
          onSurface: AppColors.textPrimaryLight,
          onSurfaceVariant: AppColors.textSecondaryLight,
          surfaceContainerHighest: AppColors.surfaceRaisedLight,
          error: AppColors.textErrorLight,
          errorContainer: AppColors.errorLight,
          onErrorContainer: AppColors.textErrorLight,
          outline: AppColors.borderStrongLight,
          outlineVariant: AppColors.borderDefaultLight,
        ),
        scaffoldBackgroundColor: AppColors.bgPrimaryLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceRaisedLight,
          foregroundColor: AppColors.textPrimaryLight,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDefaultLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.borderDefaultLight),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceRaisedLight,
          selectedItemColor: AppColors.primaryAmberLight,
          unselectedItemColor: AppColors.textSecondaryLight,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryAmberLight,
          foregroundColor: AppColors.primaryAmberContrastLight,
          elevation: 4,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.borderDefaultLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.borderDefaultLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.primaryAmberLight, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAmberLight,
            foregroundColor: AppColors.primaryAmberContrastLight,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        extensions: const <ThemeExtension<dynamic>>[
          AppThemeExtension.light,
        ],
      );

  /// Thème sombre.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: AppTypography.fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryAmberDark,
          onPrimary: AppColors.primaryAmberContrastDark,
          primaryContainer: AppColors.primaryMutedDark,
          onPrimaryContainer: AppColors.textPrimaryDark,
          secondary: AppColors.indigo400,
          onSecondary: AppColors.textInverseDark,
          secondaryContainer: AppColors.indigo800,
          surface: AppColors.surfaceDefaultDark,
          onSurface: AppColors.textPrimaryDark,
          onSurfaceVariant: AppColors.textSecondaryDark,
          surfaceContainerHighest: AppColors.surfaceRaisedDark,
          surfaceContainer: AppColors.surfaceDefaultDark,
          error: AppColors.textErrorDark,
          onError: AppColors.textInverseDark,
          errorContainer: AppColors.bgErrorDark,
          onErrorContainer: AppColors.textErrorDark,
          outline: AppColors.borderStrongDark,
          outlineVariant: AppColors.borderDefaultDark,
        ),
        scaffoldBackgroundColor: AppColors.bgPrimaryDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceRaisedDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDefaultDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.borderDefaultDark),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceRaisedDark,
          selectedItemColor: AppColors.primaryAmberDark,
          unselectedItemColor: AppColors.textSecondaryDark,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryAmberDark,
          foregroundColor: AppColors.primaryAmberContrastDark,
          elevation: 4,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.borderDefaultDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.borderDefaultDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.primaryAmberDark, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAmberDark,
            foregroundColor: AppColors.primaryAmberContrastDark,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        extensions: const <ThemeExtension<dynamic>>[
          AppThemeExtension.dark,
        ],
      );
}
