# Implementation Plan: Settings — Profil

**Branch**: `049-flutter-settings-profile` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/049-flutter-settings-profile/spec.md`

## Summary

Implémenter l'écran Profil dans les paramètres Flutter, permettant à l'utilisateur de consulter ses informations (nom, email) et de modifier sa devise par défaut via SelectPicker. L'écran remplace le stub actuel à `/settings/profile` et consomme les endpoints existants GET/PUT `/users/me`.

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, freezed, json_serializable, go_router, dio, shimmer
**Storage**: Serveur uniquement (pas de Drift/SQLite pour le profil — données toujours fraîches depuis l'API)
**Testing**: flutter_test + ProviderContainer avec overrides
**Target Platform**: iOS & Android (mobile-first)
**Project Type**: Mobile app (module Flutter du monorepo)
**Performance Goals**: Chargement profil < 2s, feedback sauvegarde < 3s
**Constraints**: Dépend de KKS-110 (Settings hub) et KKS-96 (SelectPicker) — code rédigé pour fonctionner avec les versions actuelles
**Scale/Scope**: 1 écran, 1 notifier, 1 repository, 1 data source, DTOs, tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | ✅ PASS | Backend déjà implémenté (GET/PUT `/users/me`). DTOs Flutter séparent API de domaine. |
| II. Sécurité par défaut | ✅ PASS | JWT géré par `authenticatedDioProvider` + `JwtInterceptor`. Données filtrées par user authentifié côté backend. |
| III. Simplicité & YAGNI | ✅ PASS | Architecture simple : Screen → Notifier → Repository → DataSource. Pas de pattern complexe. |
| IV. Mobile-First UX | ✅ PASS | Modification de devise en 3 interactions max (picker → select → save). Champs lecture seule clairement distingués. |
| V. Testabilité | ✅ PASS | Notifier testable via ProviderContainer + mock repository. Widget tests avec ProviderScope. |
| VI. Observabilité | ✅ N/A | Feature frontend uniquement. Le backend logge déjà les actions PUT. |
| VII. Self-Hosted Ready | ✅ PASS | Aucune dépendance externe ajoutée. Consomme l'API existante. |

## Project Structure

### Documentation (this feature)

```text
specs/049-flutter-settings-profile/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── data/remote/
│   ├── data_sources/
│   │   └── user_remote_data_source.dart     # NEW — GET/PUT /users/me
│   └── dtos/
│       └── user_dtos.dart                    # NEW — UserResponse, UserUpdateRequest
├── domain/
│   ├── models/
│   │   └── user.dart                         # EXISTS — aucune modification
│   └── repositories/
│       └── user_repository.dart              # NEW — interface abstraite
├── features/
│   ├── settings/
│   │   └── presentation/
│   │       ├── settings_hub_screen.dart       # EXISTS — aucune modification
│   │       └── stub_settings_screen.dart      # EXISTS — ne plus importer pour profil
│   └── user_profile/                          # NEW — feature module
│       ├── application/
│       │   ├── user_profile_notifier.dart     # NEW — Notifier<AsyncValue<User>>
│       │   └── user_profile_providers.dart    # NEW — providers (repo, data source, notifier)
│       ├── data/
│       │   └── user_repository_remote.dart    # NEW — implémentation remote
│       └── presentation/
│           ├── screens/
│           │   └── profile_settings_screen.dart  # NEW — écran principal
│           └── widgets/
│               └── profile_settings_skeleton.dart # NEW — skeleton loading
├── routing/
│   └── app_router.dart                        # MODIFY — remplacer StubSettingsScreen par ProfileSettingsScreen
```

**Structure Decision** : Feature module `user_profile/` séparé de `settings/` car le profil utilisateur est un domaine distinct (entité User, repository dédié). Le hub settings reste dans `settings/` et délègue la navigation vers `user_profile/`.

**Provider Location Decision** : Le `userRepositoryProvider` est déclaré dans `features/user_profile/application/user_profile_providers.dart` (et non dans `data/data_mode_provider.dart` comme les autres repositories) car le profil est server-only — pas de `UserRepositoryLocal`, donc pas de strategy pattern `dataModeProvider`. Centraliser dans `data_mode_provider.dart` ajouterait du code inutile.

## Complexity Tracking

> Aucune violation de la constitution détectée. Pas de complexité additionnelle requise.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
