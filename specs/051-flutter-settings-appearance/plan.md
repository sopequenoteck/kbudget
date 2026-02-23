# Implementation Plan: Settings — Apparence

**Branch**: `051-flutter-settings-appearance` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/051-flutter-settings-appearance/spec.md`

## Summary

Implémenter l'écran "Apparence" dans les paramètres Flutter, remplaçant le stub actuel. L'écran expose deux sélecteurs sous forme de tile cards : thème clair/sombre (infrastructure existante) et taille de texte 3 niveaux (nouveau — SM=0.85, MD=1.0, XL=1.3). Les changements sont appliqués immédiatement et persistent localement via `AppConfigRepository` (FlutterSecureStorage). Le text scaling utilise `MediaQuery` + `TextScaler.linear()` wrappant l'app pour un effet global.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, build_runner
**Storage**: FlutterSecureStorage (AppConfig JSON sérialisé)
**Testing**: flutter_test + ProviderContainer overrides
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: mobile-app (module Flutter du monorepo)
**Performance Goals**: Application immédiate du thème et text scale (< 16ms, 60fps)
**Constraints**: Purement local, offline-capable, pas de sync serveur
**Scale/Scope**: 1 écran, 1 enum, 1 notifier, modifications de 4-5 fichiers existants

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature purement locale (préférences UI), aucun endpoint API |
| II. Sécurité par défaut | PASS | Persistance via FlutterSecureStorage (existant), pas de données sensibles |
| III. Simplicité & YAGNI | PASS | 1 enum + 1 notifier + 1 écran. Réutilise l'infra existante. Pas d'abstraction prématurée |
| IV. Mobile-First UX | PASS | Tile cards avec large zone de tap, changement en 1 interaction, preview temps réel |
| V. Testabilité | PASS | Notifier testable via ProviderContainer + mock repository. Widget testable |
| VI. Observabilité | N/A | Préférences UI locales, pas de logging nécessaire |
| VII. Self-Hosted Ready | N/A | Aucune dépendance infra |

**Post-Phase 1 re-check**: Aucune violation introduite. Le design suit les patterns existants (ThemeNotifier, AppConfig).

## Project Structure

### Documentation (this feature)

```text
specs/051-flutter-settings-appearance/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — décisions techniques
├── data-model.md        # Phase 1 — entités et relations
├── quickstart.md        # Phase 1 — séquence de build
└── tasks.md             # Phase 2 — à générer via /speckit.tasks
```

### Source Code (fichiers impactés)

```text
flutter/lib/src/
├── domain/
│   └── enums/
│       ├── text_scale.dart              # NOUVEAU — enum TextScale (small/medium/large)
│       └── enums.dart                   # MODIFIER — ajouter export text_scale.dart
├── domain/
│   ├── models/
│   │   └── app_config.dart              # MODIFIER — ajouter champ textScale
│   └── repositories/
│       └── app_config_repository.dart   # MODIFIER — ajouter setTextScale/getTextScale
├── features/
│   ├── onboarding/
│   │   └── data/
│   │       └── app_config_repository_impl.dart  # MODIFIER — implémenter setTextScale/getTextScale
│   └── settings/
│       ├── application/
│       │   └── text_scale_notifier.dart          # NOUVEAU — Notifier<TextScale>
│       └── presentation/
│           └── appearance_settings_screen.dart    # NOUVEAU — écran complet (remplace stub)
├── routing/
│   └── app_router.dart                  # MODIFIER — pointer vers AppearanceSettingsScreen
└── app.dart                             # MODIFIER — wrapper MediaQuery pour textScaler

```

**Structure Decision**: Module Flutter uniquement. Tous les fichiers sont dans `flutter/lib/src/` suivant l'architecture feature-based existante. Le nouveau `TextScaleNotifier` est placé dans `features/settings/application/` aux côtés du `ThemeNotifier` existant. L'écran est dans `features/settings/presentation/`.

## Complexity Tracking

> Aucune violation de constitution détectée. Tableau non applicable.
