# Implementation Plan: Flutter Setup & Architecture

**Branch**: `031-flutter-setup` | **Date**: 2026-02-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/031-flutter-setup/spec.md`

## Summary

Initialisation du projet Flutter dans le monorepo (`flutter/`) avec l'architecture fondamentale : gestion d'etat Riverpod, routing go_router, BDD locale Drift, client HTTP dio, theming porte du design system Angular existant. L'app supporte deux modes de donnees (local et serveur) avec une couche d'abstraction repository. Cible iOS 15+, Android API 24+, et Web. Phase 1 delivre des ecrans shells architecturaux (pas de CRUD complet).

## Technical Context

**Language/Version**: Dart >= 3.6 / Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, drift, dio, flutter_secure_storage, local_auth, firebase_crashlytics, freezed, json_serializable
**Storage**: Drift (SQLite local, multi-plateforme), flutter_secure_storage (tokens/PIN), API REST existante (mode serveur)
**Testing**: flutter_test (unit + widget), integration_test (integration), mockito (mocks)
**Target Platform**: iOS 15+, Android API 24 (7.0), Web (navigateurs evergreen)
**Project Type**: Mobile + Web (Flutter multi-plateforme)
**Performance Goals**: Lancement < 3s, operations locales < 200ms, connexion serveur < 5s (3G), changement theme < 100ms
**Constraints**: Offline-capable (mode local), francais uniquement (infrastructure i18n prete), pas de chiffrement applicatif
**Scale/Scope**: Single-user, ~7 ecrans shells + onboarding + settings, 7 entites metier portees du backend

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Notes |
|----------|--------|-------|
| I. API-First | DEVIATION JUSTIFIEE | Le mode local fonctionne sans API par design. En mode serveur, l'API REST existante est la source de verite. Voir Complexity Tracking. |
| II. Securite par defaut | PASS | JWT en mode serveur (refresh transparent via dio interceptor). Biometrie/PIN en mode local. Tokens dans flutter_secure_storage. |
| III. Simplicite & YAGNI | DEVIATION JUSTIFIEE | Repository pattern necessaire pour abstraire local vs serveur. Pas de DDD/CQRS. Voir Complexity Tracking. |
| IV. Mobile-First UX | DEVIATION JUSTIFIEE | Flutter remplace Angular PWA. Mobile-first par nature. FAB sur tous les ecrans. Navigation adaptative (bottom bar < 768px, sidebar >= 768px). Voir Complexity Tracking. |
| V. Testabilite | PASS | 3 niveaux de tests (unit, widget, integration). Structure miroir. Riverpod injectable/mockable. |
| VI. Observabilite | DEVIATION JUSTIFIEE | Firebase Crashlytics (SaaS) pour crash reporting mobile. Web utilise les mecanismes existants cote serveur. Voir Complexity Tracking. |
| VII. Self-Hosted Ready | DEVIATION JUSTIFIEE | Firebase Crashlytics est une dependance SaaS optionnelle (crash reporting uniquement, pas fonctionnel). L'app fonctionne sans. Voir Complexity Tracking. |

**Gate result: PASS avec deviations justifiees** (4 deviations documentees dans Complexity Tracking)

## Project Structure

### Documentation (this feature)

```text
specs/031-flutter-setup/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── api-client.md    # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/
├── lib/
│   ├── main.dart                          # Entry point + ProviderScope
│   ├── app.dart                           # MaterialApp.router + theme
│   └── src/
│       ├── common_widgets/                # Widgets partages cross-feature
│       │   ├── adaptive_scaffold.dart     # Shell responsive (bottom nav / sidebar)
│       │   ├── fab_menu.dart              # Bouton flottant (+) avec menu
│       │   └── loading_indicator.dart     # Indicateur de chargement
│       ├── constants/
│       │   ├── app_colors.dart            # Palettes Amber, Gray, feedback
│       │   ├── app_typography.dart        # Inter font, tailles, poids
│       │   ├── app_spacing.dart           # Grille 4px
│       │   ├── app_radius.dart            # Border radius tokens
│       │   ├── app_shadows.dart           # Ombres
│       │   └── app_durations.dart         # Durees d'animation
│       ├── routing/
│       │   ├── app_router.dart            # GoRouter config + redirect
│       │   └── route_names.dart           # Constantes de routes
│       ├── localization/
│       │   ├── app_fr.arb                 # Strings francais
│       │   └── l10n.dart                  # Generated
│       ├── theme/
│       │   ├── app_theme.dart             # ThemeData light + dark
│       │   └── app_theme_extension.dart   # ThemeExtension (tokens metier)
│       ├── utils/
│       │   └── env_config.dart            # Variables d'environnement
│       └── features/
│           ├── onboarding/
│           │   ├── data/
│           │   │   └── app_config_repository_impl.dart
│           │   ├── application/
│           │   │   └── onboarding_notifier.dart
│           │   └── presentation/
│           │       ├── onboarding_screen.dart
│           │       └── server_setup_screen.dart
│           ├── auth/
│           │   ├── data/
│           │   │   ├── auth_remote_data_source.dart   # dio → /auth/*
│           │   │   └── auth_repository_impl.dart
│           │   ├── domain/
│           │   │   └── auth_repository.dart            # abstract
│           │   ├── application/
│           │   │   └── auth_notifier.dart              # + Listenable
│           │   └── presentation/
│           │       ├── login_screen.dart
│           │       ├── register_screen.dart            # Inscription via invitation
│           │       └── lock_screen.dart                # biometrie/PIN
│           ├── dashboard/
│           │   └── presentation/
│           │       └── dashboard_screen.dart           # Shell placeholder
│           ├── transactions/
│           │   ├── data/
│           │   │   ├── transaction_remote_data_source.dart
│           │   │   ├── transaction_local_data_source.dart
│           │   │   └── transaction_repository_impl.dart
│           │   ├── domain/
│           │   │   ├── transaction.dart
│           │   │   └── transaction_repository.dart
│           │   ├── application/
│           │   │   └── transaction_notifier.dart
│           │   └── presentation/
│           │       └── transaction_list_screen.dart    # Shell placeholder
│           ├── subscriptions/
│           │   ├── data/
│           │   ├── domain/
│           │   ├── application/
│           │   └── presentation/
│           │       └── subscription_list_screen.dart   # Shell placeholder
│           ├── debts/
│           │   ├── data/
│           │   ├── domain/
│           │   ├── application/
│           │   └── presentation/
│           │       └── debt_list_screen.dart           # Shell placeholder
│           └── settings/
│               └── presentation/
│                   └── settings_screen.dart            # Theme + lock + mode
├── test/
│   ├── src/
│   │   ├── features/
│   │   │   ├── onboarding/
│   │   │   │   └── application/
│   │   │   │       └── onboarding_notifier_test.dart
│   │   │   ├── auth/
│   │   │   │   ├── application/
│   │   │   │   │   └── auth_notifier_test.dart
│   │   │   │   ├── data/
│   │   │   │   │   └── auth_repository_impl_test.dart
│   │   │   │   └── presentation/
│   │   │   │       └── register_screen_test.dart
│   │   │   └── transactions/
│   │   │       └── data/
│   │   │           └── transaction_repository_impl_test.dart
│   │   ├── routing/
│   │   │   └── app_router_test.dart
│   │   └── theme/
│   │       └── app_theme_test.dart
│   ├── helpers/
│   │   ├── mocks.dart
│   │   ├── pump_app.dart
│   │   └── fixtures/
│   └── widget_test.dart
├── integration_test/
│   ├── onboarding_flow_test.dart
│   └── navigation_flow_test.dart
├── config/
│   ├── env.example.json
│   ├── env.dev.json                       # gitignored
│   └── env.prod.json                      # gitignored
├── web/
│   ├── index.html
│   ├── sqlite3.wasm                       # Drift web support
│   └── drift_worker.dart.js               # Drift web worker
├── assets/
│   └── fonts/
│       └── Inter/                         # Font bundled
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
└── README.md
```

**Structure Decision**: Projet Flutter dans `flutter/` a la racine du monorepo (coexistence avec `api/` et `app/`). Architecture feature-first avec 4 couches (data, domain, application, presentation). Le code partage (widgets, constantes, theme, routing) est dans `src/` au niveau racine.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| API-First : mode local sans API | Le mode local est un pilier fonctionnel (offline, contexte Togo). L'abstraction repository garantit que le mode serveur reste API-first. | Un mode serveur-only forcerait une connexion permanente, inutilisable dans les zones a faible connectivite. |
| Repository pattern (abstraction) | Necessaire pour abstraire local (Drift) vs remote (dio) derriere une interface commune. Les ecrans ne connaissent que l'interface. | L'acces direct aux data sources depuis les notifiers couplerait la logique UI au mode de stockage, rendant le changement de mode impossible sans modifier tous les ecrans. |
| Firebase Crashlytics (SaaS) | Crash reporting natif Flutter pour iOS/Android. Gratuit, leger, pas de dependance fonctionnelle. L'app fonctionne sans. | Le logging local uniquement ne permet pas de diagnostiquer les crashes en production sur les appareils des utilisateurs (Togo/France). |
| Self-Hosted : dependance Firebase | Crashlytics est opt-in et non fonctionnel (reporting uniquement). Le backend et la BDD restent 100% self-hosted. La constitution interdit les SaaS "en v1" du backend — Flutter Phase 1 est une nouvelle application, pas le backend v1. | Sentry self-hosted serait une alternative mais ajoute une dependance infra lourde pour un seul utilisateur. |
| Mobile-First : Flutter remplace Angular PWA | Flutter offre un binaire natif iOS/Android + Web depuis un seul codebase. Acces natif biometrie, deep links, distribution store. L'Angular PWA coexiste pendant la transition (`app/` et `flutter/`). | Rester en Angular PWA limiterait l'experience mobile native (pas de biometrie native, pas de deep links, pas de store). |
