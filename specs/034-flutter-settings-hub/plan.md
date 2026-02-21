# Implementation Plan: Settings Hub Flutter

**Branch**: `034-flutter-settings-hub` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/034-flutter-settings-hub/spec.md`

## Summary

Refonte de la page Réglages Flutter en hub navigable avec 7 sections groupées (Général, Gestion, Autre). Les sections actives (Profil, Apparence, Comptes, Catégories, Données) naviguent vers des sous-pages. Les placeholders (Sécurité, À propos) affichent un badge "À venir". La sous-page Données permet de basculer entre mode local (SQLite) et serveur (API REST) avec saisie d'URL, dialog de confirmation, test de connectivité et redémarrage de l'app.

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, flutter_secure_storage, dio, freezed
**Storage**: FlutterSecureStorage (AppConfig : dataMode, serverUrl), Drift (SQLite local)
**Testing**: flutter_test (widget tests)
**Target Platform**: iOS, Android, macOS, Linux, Windows, Web
**Project Type**: mobile (Flutter)
**Performance Goals**: 60 fps, navigation instantanée (liste statique, pas de chargement réseau)
**Constraints**: Liste statique de 7 items, pas de données réseau sur le hub
**Scale/Scope**: Single-user, 7 sections settings, 1 sous-page active (Données), 4 sous-pages stubs

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature frontend-only, aucun nouvel endpoint API |
| II. Sécurité par défaut | PASS | URL serveur persistée dans FlutterSecureStorage (chiffré). Pas d'exposition de données sensibles |
| III. Simplicité & YAGNI | PASS | Hub = liste statique + navigation. Données = formulaire + dialog. Pas de pattern complexe |
| IV. Mobile-First UX | PASS | Liste verticale adaptée mobile. Navigation en 1 tap. Sous-page Données : switch + champ URL |
| V. Testabilité | PASS | Widget tests sur hub (7 items, navigation), item (active/placeholder), sous-page Données (switch, validation, dialog) |
| VI. Observabilité | N/A | Frontend-only, pas de logging serveur. `debugPrint` pour erreurs de connectivité |
| VII. Self-Hosted Ready | N/A | Pas de dépendance infra ajoutée |

**Post-design re-check** : Tous les gates restent PASS. Le `RestartWidget` est un pattern Flutter standard sans dépendance externe.

## Project Structure

### Documentation (this feature)

```text
specs/034-flutter-settings-hub/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── features/settings/
│   ├── domain/
│   │   └── settings_section.dart          # [NEW] Modèle SettingsSection + enum SettingsGroup + liste statique
│   ├── application/
│   │   ├── theme_notifier.dart            # [EXISTANT] Pas de modification
│   │   └── data_settings_notifier.dart    # [NEW] Notifier pour switch source de données
│   └── presentation/
│       ├── settings_hub_screen.dart        # [NEW] Remplace settings_screen.dart
│       ├── data_settings_screen.dart       # [NEW] Sous-page Données (switch + URL)
│       ├── stub_settings_screen.dart       # [NEW] Écran stub pour sous-pages non implémentées
│       └── widgets/
│           └── settings_item.dart          # [NEW] Widget d'item de section
├── common_widgets/
│   └── restart_widget.dart                # [NEW] Wrapper pour redémarrage app
├── routing/
│   ├── app_router.dart                    # [MODIFY] Sous-routes settings
│   └── route_names.dart                   # [MODIFY] Constantes sous-routes
├── data/
│   ├── remote/
│   │   └── api_client.dart                # [MODIFY] URL dynamique depuis AppConfig
│   └── data_mode_provider.dart            # [MODIFY] Watch FutureProvider<Dio> au lieu de Provider<Dio>
└── ...

flutter/test/src/features/settings/
├── presentation/
│   ├── settings_hub_screen_test.dart      # [NEW]
│   ├── data_settings_screen_test.dart     # [NEW]
│   └── widgets/
│       └── settings_item_test.dart        # [NEW]
└── domain/
    └── settings_section_test.dart         # [NEW]
```

**Structure Decision** : Feature-first dans `features/settings/` existant. Le `RestartWidget` dans `common_widgets/` car réutilisable par d'autres features. Pas de contracts/ (feature frontend-only).

## Key Design Decisions

### D1 — Widget SettingsItem dédié (vs extension de ListItem)

Le `ListItem` existant est orienté données financières (emoji icon + montant). Le hub settings nécessite `IconData` Material + description + badge. Créer `SettingsItem` séparé plutôt que surcharger `ListItem`.

Voir [research.md — R3](research.md#r3--widget-ditem-de-settings--listitem-existant-vs-nouveau-widget).

### D2 — RestartWidget pour le redémarrage

Pattern Flutter standard : wrapper avec `Key` unique qui reconstruit tout l'arbre widget (y compris `ProviderScope`). Plus fiable que `SystemNavigator.pop()` et cross-platform.

Voir [research.md — R2](research.md#r2--mécanisme-de-redémarrage-de-lapp-flutter).

### D3 — apiClientProvider avec URL dynamique

`apiClientProvider` doit lire `AppConfig.serverUrl` au lieu de `EnvConfig.apiBaseUrl`. Le redémarrage garantit la réinitialisation des providers.

Voir [research.md — R1](research.md#r1--url-serveur--envconfig-vs-appconfig).

### D4 — Sous-routes settings

Les sous-pages sont des enfants GoRouter de `/settings`. Les 4 sous-pages non implémentées (profile, appearance, accounts, categories) pointent vers un `StubSettingsScreen` générique avec titre.

Voir [research.md — R4](research.md#r4--structure-des-routes-settings).

## Complexity Tracking

> Aucune violation de la constitution détectée. Pas d'entrée nécessaire.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
