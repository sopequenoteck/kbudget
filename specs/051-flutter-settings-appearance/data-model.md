# Data Model: Settings — Apparence

**Feature Branch**: `051-flutter-settings-appearance`
**Date**: 2026-02-23

## Entités

### TextScale (enum — nouveau)

| Champ | Type | Description |
|-------|------|-------------|
| `small` | valeur enum | Facteur d'échelle 0.85, label "Petit" |
| `medium` | valeur enum | Facteur d'échelle 1.0, label "Normal" (défaut) |
| `large` | valeur enum | Facteur d'échelle 1.3, label "Grand" |

**Getters** : `scaleFactor` (double), `label` (String)

**Fichier** : `flutter/lib/src/domain/enums/text_scale.dart`

### AppConfig (modification — existant)

| Champ | Type | Existant | Description |
|-------|------|----------|-------------|
| `dataMode` | `DataMode` | oui | Mode données |
| `serverUrl` | `String?` | oui | URL serveur |
| `theme` | `AppTheme` | oui | Thème light/dark |
| **`textScale`** | **`TextScale`** | **non** | **Taille texte (défaut: medium)** |
| `lockEnabled` | `bool` | oui | Verrou activé |
| `lockMethod` | `LockMethod?` | oui | Méthode de verrou |
| `hashedPin` | `String?` | oui | PIN hashé |
| `onboardingCompleted` | `bool` | oui | Onboarding complété |

**Impact** : Ajout `@Default(TextScale.medium) TextScale textScale` → rebuild Freezed requis.

## Relations

```
AppConfig ──contains──▸ AppTheme (light/dark)
AppConfig ──contains──▸ TextScale (small/medium/large)  ← NOUVEAU

ThemeNotifier ──reads/writes──▸ AppConfigRepository (theme)
TextScaleNotifier ──reads/writes──▸ AppConfigRepository (textScale)  ← NOUVEAU

KBudgetApp ──watches──▸ themeNotifierProvider
KBudgetApp ──watches──▸ textScaleNotifierProvider  ← NOUVEAU
```

## Persistance

- **Stockage** : `FlutterSecureStorage` (JSON sérialisé via `AppConfig.toJson()`)
- **Clé** : `app_config` (existante, partagée)
- **Sérialisation** : Automatique via `json_serializable` (build_runner)
- **Migration** : Aucune nécessaire — `@Default(TextScale.medium)` gère les configs existantes sans champ `textScale`

## Providers Riverpod

| Provider | Type | État | Nouveau |
|----------|------|------|---------|
| `themeNotifierProvider` | `NotifierProvider<ThemeNotifier, ThemeMode>` | `ThemeMode` | non |
| `textScaleNotifierProvider` | `NotifierProvider<TextScaleNotifier, TextScale>` | `TextScale` | **oui** |
| `appConfigRepositoryProvider` | `Provider<AppConfigRepository>` | - | non |
