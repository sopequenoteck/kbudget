# Quickstart: Refonte Dashboard Flutter

**Feature**: 096-flutter-dashboard-refonte | **Date**: 2026-03-20

## Prerequis

- Flutter >= 3.27 installe
- Serveur API lance (`cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev`)
- Au moins 1 compte cree avec des transactions

## Lancer l'app

```bash
cd flutter && flutter run
```

## Fichiers cles a modifier

### State management
- `flutter/lib/src/features/dashboard/application/dashboard_state.dart` — Ajouter currentSummary/previousSummary, supprimer champs MiniCards/MonthSelector
- `flutter/lib/src/features/dashboard/application/dashboard_notifier.dart` — Charger mois courant + precedent, supprimer chargement subscriptions/debts

### Nouveaux widgets
- `flutter/lib/src/features/dashboard/presentation/widgets/dashboard_header.dart` — Salutation + cloche + avatar menu
- `flutter/lib/src/features/dashboard/presentation/widgets/patrimoine_card.dart` — Carte patrimoine total + variation + conversion
- `flutter/lib/src/features/dashboard/presentation/widgets/income_expense_cards.dart` — 2 cartes cote-a-cote revenus/depenses + delta

### Widgets a modifier
- `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — Restructurer layout avec nouveaux widgets
- `flutter/lib/src/features/dashboard/presentation/widgets/recent_transactions_section.dart` — Ajouter badges devise + conversion
- `flutter/lib/src/features/dashboard/presentation/widgets/budget_summary_section.dart` — Tri par %, max 4 items

### Widgets a supprimer
- `flutter/lib/src/features/dashboard/presentation/widgets/hero_account_section.dart`
- `flutter/lib/src/features/dashboard/presentation/widgets/monthly_summary_section.dart`
- `flutter/lib/src/features/dashboard/presentation/widgets/mini_cards_section.dart`

## Tests

```bash
cd flutter && flutter test test/src/features/dashboard/
```

## Verification rapide

1. Ouvrir l'app → le dashboard affiche la carte Patrimoine Total
2. Verifier que revenus/depenses montrent les bons montants
3. Taper sur l'avatar → menu avec Parametres + Deconnexion
4. Changer de devise via le pill selector → patrimoine se recalcule
5. Pull-to-refresh → toutes les donnees se rechargent

## Design tokens a utiliser

- Couleurs : `AppColors.primary` (amber), `AppColors.warning`, `AppThemeExtension` (incomeColor, expenseColor)
- Spacing : `AppSpacing.space1` a `space12`
- Typography : `AppTypography.sizeXs` a `size3xl`, `fontWeight` variants
- Radius : `AppRadius.sm`, `md`, `lg`, `xl`
- Icons : `PhosphorIconsRegular` / `PhosphorIconsFill`
