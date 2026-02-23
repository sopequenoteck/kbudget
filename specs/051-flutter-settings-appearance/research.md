# Research: Settings — Apparence

**Feature Branch**: `051-flutter-settings-appearance`
**Date**: 2026-02-23

## R1 — Infrastructure thème existante

**Decision**: Réutiliser l'infrastructure existante (ThemeNotifier + AppConfigRepository) pour le sélecteur de thème.

**Rationale**: L'infrastructure est complète et fonctionnelle :
- `ThemeNotifier` (Notifier<ThemeMode>) : `toggleTheme()`, `setThemeMode()`
- `AppTheme` enum : `light`, `dark`
- `AppConfigRepository` : `setTheme()`, `getTheme()` persistant dans FlutterSecureStorage via `AppConfig` (Freezed)
- `app.dart` : consomme `themeNotifierProvider` et applique `themeMode` sur `MaterialApp.router`

**Alternatives considered**: Aucune — l'infrastructure est déjà en place et testée.

## R2 — Mécanisme de text scaling global

**Decision**: Utiliser `MediaQuery` avec `TextScaler.linear()` wrappant le `MaterialApp.router` dans `app.dart`.

**Rationale**:
- `MediaQuery.withClampedTextScaling` ou override de `textScaler` via `MediaQuery` est le mécanisme natif Flutter pour appliquer un facteur d'échelle global.
- Fonctionne avec tous les widgets `Text` sans modification individuelle.
- Plus simple et maintenable qu'un `ThemeExtension` custom qui nécessiterait d'accéder à chaque `TextStyle`.
- Pattern utilisé par les apps accessibilité Flutter (ref: Flutter accessibility docs).

**Implementation**: Wrapper `Builder` dans `app.dart` qui override `MediaQuery.textScalerOf(context)` via un `TextScaleNotifier` (même pattern que `ThemeNotifier`).

**Alternatives considered**:
- `ThemeExtension<TextScaleExtension>` : rejeté car nécessiterait de modifier chaque `TextStyle` manuellement. Trop invasif.
- `textScaleFactor` dans `MaterialApp` : ce paramètre n'existe pas nativement. L'override via `MediaQuery` est la seule approche globale.

## R3 — Persistance de la taille texte

**Decision**: Ajouter un champ `textScale` (enum `TextScale`) au model `AppConfig` (Freezed) et des méthodes `setTextScale`/`getTextScale` à `AppConfigRepository`.

**Rationale**: Cohérent avec le pattern existant pour le thème. Un seul point de persistance (`AppConfig` JSON dans `FlutterSecureStorage`), un seul `build_runner` pour régénérer les fichiers Freezed.

**Alternatives considered**:
- `SharedPreferences` séparé : rejeté car incohérent avec le pattern existant (tout est dans `AppConfig`).
- Stockage dans `Drift` : rejeté car la config est déjà dans `FlutterSecureStorage` et n'a pas besoin de requêtes SQL.

## R4 — Enum TextScale et facteurs

**Decision**: Créer un enum `TextScale` avec 3 valeurs et getters pour le facteur et le label.

```dart
enum TextScale {
  small,  // scaleFactor = 0.85, label = 'Petit'
  medium, // scaleFactor = 1.0,  label = 'Normal'
  large;  // scaleFactor = 1.3,  label = 'Grand'
}
```

**Rationale**: Enum typé comme les autres enums du domaine (`AppTheme`, `Currency`, etc.). Les facteurs (0.85/1.0/1.3) sont issus de la clarification spec. Le getter `scaleFactor` encapsule la logique au bon endroit.

## R5 — Pattern UX tile cards

**Decision**: Tile cards sélectionnables avec icône + label, bordure colorée et/ou coche sur l'option active.

**Rationale**: Clarification spec — cohérent avec le pattern `_CurrencySelector` du ProfileSettingsScreen et les `SettingsItem` cards existantes. Zone de tap large, adaptée mobile-first.

**Implementation**:
- Thème : 2 tiles horizontales (icône soleil/lune + "Clair"/"Sombre")
- Taille texte : 3 tiles horizontales ("Aa" en taille variable + "Petit"/"Normal"/"Grand")
- Option active : bordure `primary` + coche
