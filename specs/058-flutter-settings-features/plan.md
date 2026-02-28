# Implementation Plan: Page Fonctionnalités (Feature Toggles) — Flutter

**Branch**: `058-flutter-settings-features` | **Date**: 2026-02-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/058-flutter-settings-features/spec.md`

## Summary

Ajouter une page "Fonctionnalités" dans les Settings Flutter permettant d'activer/désactiver les modules optionnels (Abonnements, Dettes, Boutique). L'activation a un effet immédiat sur la barre de navigation (bottom nav dynamique), le FAB menu, et les routes accessibles. Les préférences sont persistées localement (AppConfig/FlutterSecureStorage) et synchronisées avec le backend (`GET/PUT /users/me/preferences`) en mode serveur.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, dio, flutter_secure_storage
**Storage**: FlutterSecureStorage (AppConfig JSON) + API REST (mode serveur)
**Testing**: flutter_test, mockito
**Target Platform**: iOS, Android (mobile-first)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Toggle → impact nav < 1 seconde, 60 fps
**Constraints**: Offline-capable (mode local), persistance locale obligatoire
**Scale/Scope**: 3 features toggleables, 1 écran settings, ~6 fichiers à créer, ~6 fichiers à modifier

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Backend KKS-117 expose `GET/PUT /users/me/preferences`. Flutter consomme en mode serveur. DTOs séparés (request/response). |
| II. Sécurité par défaut | PASS | Endpoint protégé JWT. Données isolées par user (backend). Pas de secrets côté client. |
| III. Simplicité & YAGNI | PASS | Un notifier, une datasource, un écran. Pas d'abstraction repository (le notifier gère local + remote directement). |
| IV. Mobile-First UX | PASS | SwitchListTile standard, effet immédiat, pas de rechargement. Dialogue de confirmation pour protection UX. |
| V. Testabilité | PASS | Notifier testable via ProviderContainer + mock datasource. Widget test avec ProviderScope. |
| VI. Observabilité | N/A | Pas de logging côté Flutter pour cette feature (pas de backend modifié). |
| VII. Self-Hosted Ready | PASS | Aucune dépendance SaaS ajoutée. Mode local fonctionne sans serveur. |

**Re-check post-design**: Tous les principes respectés. Pas de violation.

## Project Structure

### Documentation (this feature)

```text
specs/058-flutter-settings-features/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── preferences-api.md  # API contract
├── checklists/
│   └── requirements.md     # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── domain/
│   └── enums/
│       ├── feature.dart                          # CRÉER — enum Feature
│       └── enums.dart                            # MODIFIER — export feature.dart
│   └── models/
│       └── app_config.dart                       # MODIFIER — ajout enabledFeatures
│   └── repositories/
│       └── app_config_repository.dart            # MODIFIER — ajout getter/setter
├── data/
│   └── remote/
│       ├── dtos/
│       │   ├── user_preference_response.dart     # CRÉER — DTO réponse
│       │   └── user_preference_request.dart      # CRÉER — DTO requête
│       └── data_sources/
│           └── preference_remote_data_source.dart # CRÉER — datasource Dio
├── features/
│   ├── onboarding/
│   │   └── data/
│   │       └── app_config_repository_impl.dart   # MODIFIER — implémentation getter/setter
│   └── settings/
│       ├── application/
│       │   └── feature_config_notifier.dart       # CRÉER — notifier + state
│       └── presentation/
│           └── feature_settings_screen.dart        # CRÉER — écran toggles
│       └── domain/
│           └── settings_section.dart               # MODIFIER — ajout section
├── routing/
│   ├── app_router.dart                            # MODIFIER — nav dynamique + route features + guard
│   └── route_names.dart                           # MODIFIER — constantes routes
└── common_widgets/
    ├── adaptive_scaffold.dart                     # MODIFIER — destinations dynamiques
    └── fab_menu.dart                              # MODIFIER — filtrage items

flutter/test/src/features/settings/                    # Tests non inclus dans cette itération

```

**Structure Decision**: Feature Flutter uniquement. Pas de modification backend. Les nouveaux fichiers suivent la structure existante du projet (`domain/enums/`, `data/remote/dtos/`, `data/remote/data_sources/`, `features/settings/application/`, `features/settings/presentation/`).

## Design Decisions

### D1. Pas de Repository abstrait pour les préférences

Contrairement aux features existantes (transactions, comptes) qui utilisent le strategy pattern `RepositoryLocal` / `RepositoryRemote` via `dataModeProvider`, les préférences feature toggles n'ont pas besoin d'un repository abstrait.

**Raison** : la persistance locale (AppConfig) est **toujours** utilisée (c'est la source immédiate). Le sync serveur est un effet de bord optionnel, pas un remplacement. Le notifier gère les deux directement.

### D2. AppConfig plutôt qu'un stockage séparé

Les features activées sont stockées dans `AppConfig` (Freezed + FlutterSecureStorage), aux côtés de `theme`, `textScale`, `dataMode`. Un nouveau champ `@Default([Feature.subscriptions, Feature.debts]) List<Feature> enabledFeatures`.

**Raison** : migration JSON automatique (champ absent dans l'ancien JSON → valeur par défaut Freezed appliquée). Stockage unifié.

### D3. Navigation dynamique par provider

`_ShellScaffold` et `AdaptiveScaffold` deviennent réactifs : les destinations et paths sont calculés à partir du provider `featureConfigNotifierProvider`. Les `static const` sont remplacés par des données dérivées.

**Mapping Feature → Navigation** :

| Feature | Route | Icône | Icône sélectionnée | Label |
|---------|-------|-------|-------------------|-------|
| (noyau) Dashboard | `/dashboard` | `home_outlined` | `home` | Accueil |
| (noyau) Transactions | `/transactions` | `receipt_long_outlined` | `receipt_long` | Transactions |
| SUBSCRIPTIONS | `/subscriptions` | `autorenew_outlined` | `autorenew` | Abonnements |
| DEBTS | `/debts` | `handshake_outlined` | `handshake` | Dettes |
| SHOP | `/shop` | `storefront_outlined` | `storefront` | Boutique |

### D4. Sync serveur — stratégie optimiste

1. Toggle modifie `state` immédiatement (optimiste)
2. Persiste dans AppConfig (synchrone, local)
3. Si mode serveur → `PUT /users/me/preferences` en arrière-plan
4. Si PUT échoue → snackbar d'erreur, état local conservé (pas de rollback)
5. Au chargement (mode serveur) → `GET /users/me/preferences` → server wins (écrase local)

### D5. Route shop — placeholder

La route `/shop` est ajoutée dans le `ShellRoute` mais pointe vers un écran placeholder (réutilisation du pattern `StubSettingsScreen` existant) tant que la feature Shop Flutter n'est pas implémentée.

## Complexity Tracking

> Aucune violation de la constitution. Tableau vide.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
