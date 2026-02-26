# Implementation Plan: Formulaire Abonnement (Flutter)

**Branch**: `045-flutter-subscription-form` | **Date**: 2026-02-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/045-flutter-subscription-form/spec.md`

## Summary

Implémenter le formulaire de création, édition et suppression d'abonnements dans l'app Flutter. Le formulaire est une modal adaptative (bottom sheet mobile / dialog tablette) avec un toggle Mensuel/Annuel en header. Il réutilise les widgets communs existants (AppFormField, SelectPicker, CategoryPicker, AppToggle, AppModal) et suit le pattern exact du formulaire de transaction existant (`transaction_form.dart`).

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, intl
**Storage**: Drift (SQLite local) / Dio (API REST) via strategy pattern `dataModeProvider`
**Testing**: flutter_test + mockito
**Target Platform**: iOS / Android (mobile-first)
**Project Type**: mobile-app (module Flutter du monorepo)
**Performance Goals**: 60 fps, ouverture du formulaire < 200ms
**Constraints**: Offline-capable (Drift local), responsive (bottom sheet < 768px, dialog >= 768px)
**Scale/Scope**: Single-user, ~1 écran (formulaire modal), ~5 fichiers à créer/modifier

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | L'API REST pour les abonnements existe déjà (CRUD complet via `SubscriptionController`). Le formulaire consomme les endpoints existants via `SubscriptionRemoteDataSource`. |
| II. Sécurité par défaut | PASS | JWT appliqué sur tous les endpoints. Filtrage par user authentifié déjà en place côté backend. Aucun changement côté sécurité. |
| III. Simplicité & YAGNI | PASS | Réutilisation des widgets communs existants. Pattern identique au formulaire de transaction. Pas d'abstraction nouvelle. |
| IV. Mobile-First UX | PASS | Modal adaptative (bottom sheet mobile). Toggle fréquence pour saisie rapide. Champs optimisés pour mobile. |
| V. Testabilité | PASS | Widget tests avec `ProviderContainer` + mocks des repositories. Pattern Arrange-Act-Assert. Nommage `should_X_when_Y`. |
| VI. Observabilité | PASS | Pas de changement backend. Logs existants suffisants pour les opérations CRUD. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée. |

**Résultat** : Tous les principes respectés. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/045-flutter-subscription-form/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — recherche et décisions
├── data-model.md        # Phase 1 — modèle de données
├── quickstart.md        # Phase 1 — guide démarrage rapide
├── contracts/           # Phase 1 — non applicable (API existante)
└── tasks.md             # Phase 2 — tâches (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── features/subscriptions/
│   ├── application/
│   │   └── subscription_notifier.dart       # EXISTANT — pas de modification
│   ├── data/
│   │   ├── subscription_repository_local.dart   # EXISTANT
│   │   └── subscription_repository_remote.dart  # EXISTANT
│   └── presentation/
│       ├── subscription_list_screen.dart     # MODIFIER — implémenter liste complète + ouverture modal
│       └── widgets/
│           └── subscription_form.dart        # CRÉER — formulaire principal
├── localization/
│   └── app_fr.arb                           # MODIFIER — ajouter clés i18n
├── routing/
│   └── app_router.dart                      # MODIFIER — ajouter gestion modal subscription
└── common_widgets/                          # EXISTANT — réutilisé tel quel
    ├── app_modal.dart
    ├── app_form_field.dart
    ├── app_toggle.dart
    ├── select_picker.dart
    └── category_picker.dart

flutter/test/src/features/subscriptions/
└── presentation/widgets/
    └── subscription_form_test.dart           # CRÉER — widget tests
```

**Structure Decision** : Module Flutter uniquement. Pas de changement backend (API CRUD complète existante). Suit la structure feature-based existante (`features/subscriptions/presentation/widgets/`).

## Complexity Tracking

> Aucune violation de la constitution. Tableau vide.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
