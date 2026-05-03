import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: AppTypography.fontFamily,
        colorScheme: const ColorScheme.light(
          // primary: amber600 (#d97706) — conforme _light.scss `--color-primary`
          primary: AppColors.amber600,
          onPrimary: Colors.white,
          primaryContainer: AppColors.amber100,
          onPrimaryContainer: AppColors.amber900,
          secondary: AppColors.indigo600,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.indigo100,
          surface: Colors.white,
          onSurface: AppColors.gray900,
          error: AppColors.error,
          onError: Colors.white,
          outline: AppColors.gray300,
          outlineVariant: AppColors.gray200,
          // surfaceContainerHighest: gray100 (#f5f5f5) — palette propriétaire v5
          surfaceContainerHighest: AppColors.gray100,
        ),
        scaffoldBackgroundColor: AppColors.gray50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray900,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.gray200),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          // selectedItemColor: amber600 — sémantique primary light
          selectedItemColor: AppColors.amber600,
          unselectedItemColor: AppColors.gray400,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          // backgroundColor: amber600 — sémantique primary light
          backgroundColor: AppColors.amber600,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.gray300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.gray300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            // focusedBorder: amber600 — sémantique primary light
            borderSide: const BorderSide(color: AppColors.amber600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // backgroundColor: amber600 — sémantique primary light
            backgroundColor: AppColors.amber600,
            foregroundColor: Colors.white,
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

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: AppTypography.fontFamily,
        colorScheme: const ColorScheme.dark(
          // primary: primaryAmberDark (#e0a820) — sémantique v5, conforme _dark.scss `--color-primary`
          // (était amber400 #FBBF24 — Tailwind)
          primary: AppColors.primaryAmberDark,
          // onPrimary: gray900 (#0a0a0a) — palette propriétaire v5
          onPrimary: AppColors.gray900,
          // primaryContainer/onPrimaryContainer: conservation usages structurels Material
          primaryContainer: AppColors.amber800,
          onPrimaryContainer: AppColors.amber100,
          secondary: AppColors.indigo400,
          onSecondary: AppColors.gray900,
          secondaryContainer: AppColors.indigo800,
          // surface: gray800 (#141414) — palette propriétaire v5
          surface: AppColors.gray800,
          onSurface: AppColors.gray50,
          error: Color(0xFFF87171),
          onError: Colors.white,
          outline: AppColors.gray600,
          outlineVariant: AppColors.gray700,
          // surfaceContainerHighest: gray700 (#1e1e1e) — palette propriétaire v5
          surfaceContainerHighest: AppColors.gray700,
          // surfaceContainer: gray800 (#141414)
          surfaceContainer: AppColors.gray800,
        ),
        // scaffoldBackgroundColor: gray900 (#0a0a0a) — palette propriétaire v5
        scaffoldBackgroundColor: AppColors.gray900,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.gray900,
          foregroundColor: AppColors.gray50,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          color: AppColors.gray800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.gray700),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.gray800,
          // selectedItemColor: primaryAmberDark (#e0a820) — sémantique primary dark
          // (était amber400 #FBBF24 — Tailwind)
          selectedItemColor: AppColors.primaryAmberDark,
          unselectedItemColor: AppColors.gray500,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          // backgroundColor: primaryAmberDark (#e0a820) — sémantique primary dark
          // (était amber400 #FBBF24 — Tailwind)
          backgroundColor: AppColors.primaryAmberDark,
          foregroundColor: AppColors.gray900,
          elevation: 4,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.gray600),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.gray600),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            // focusedBorder: primaryAmberDark (#e0a820) — sémantique primary dark
            // (était amber400 #FBBF24 — Tailwind)
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
            // backgroundColor: primaryAmberDark (#e0a820) — sémantique primary dark
            // (était amber400 #FBBF24 — Tailwind)
            backgroundColor: AppColors.primaryAmberDark,
            foregroundColor: AppColors.gray900,
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
