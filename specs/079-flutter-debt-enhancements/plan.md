# Implementation Plan: Améliorations dettes Flutter

**Branch**: `079-flutter-debt-enhancements` | **Date**: 2026-03-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/079-flutter-debt-enhancements/spec.md`

## Summary

Enrichissement de l'interface dettes Flutter : formulaire enrichi (compte bancaire, rappels, patrimoine), écran détail avec barre de progression et historique des paiements, bottom sheet de remboursement, dialogue de report de rappel, et actions notification push avec deep link. Le data layer est étendu (model Debt enrichi, DebtPayment nouveau model, repository enrichi avec repay/getPayments/snooze). Mode serveur uniquement (pas de Drift). Alignement complet sur l'implémentation Angular (KKS-078).

## Technical Context

**Language/Version**: Dart >= 3.6, Flutter >= 3.27 (stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, json_serializable, dio, shimmer, intl, phosphor_flutter
**Storage**: API REST uniquement (pas de Drift/SQLite pour cette feature)
**Testing**: flutter_test + ProviderContainer avec overrides
**Target Platform**: iOS + Android (mobile natif)
**Project Type**: Mobile app (Flutter module d'un monorepo)
**Performance Goals**: 60 fps, interactions en < 300ms
**Constraints**: Offline non supporté (server-only), single-user
**Scale/Scope**: 5 écrans/composants modifiés/créés, ~15 fichiers impactés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Consomme les endpoints backend existants (KKS-077). DTOs séparés (DebtRequest/DebtResponse enrichis). |
| II. Sécurité par défaut | PASS | JWT via Dio interceptor existant. Données filtrées par user côté API. |
| III. Simplicité & YAGNI | PASS | Pattern CrudNotifier existant étendu. Pas de nouvelle abstraction. |
| IV. Mobile-First UX | PASS | Bottom sheet pour remboursement (2-3 interactions). Formulaire enrichi sans surcharge. |
| V. Testabilité | PASS | Tests unitaires notifier avec ProviderContainer + mocks. Widget tests pour écran détail. |
| VI. Observabilité | N/A | Feature Flutter, pas de logging serveur. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance cloud ajoutée. |

**Gate result**: PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/079-flutter-debt-enhancements/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
flutter/lib/src/
├── domain/
│   ├── models/
│   │   ├── debt.dart                    # MODIFY — enrichir avec nouveaux champs
│   │   └── debt_payment.dart            # CREATE — nouveau model Freezed
│   └── repositories/
│       └── debt_repository.dart         # MODIFY — ajouter repay, getPayments, snooze
├── data/
│   └── remote/
│       ├── data_sources/
│       │   └── debt_remote_data_source.dart  # MODIFY — nouveaux endpoints Dio
│       └── dtos/
│           └── debt_dtos.dart           # MODIFY — enrichir DTOs + RepayRequest + SnoozeRequest + PaymentResponse
├── features/
│   └── debts/
│       ├── application/
│       │   └── debt_notifier.dart       # MODIFY — repay, snooze + debtPaymentsProvider
│       ├── data/
│       │   └── debt_repository_remote.dart  # MODIFY — implémenter repay, getPayments, snooze
│       └── presentation/
│           ├── debt_detail_screen.dart   # CREATE — écran détail avec progression + historique
│           └── widgets/
│               ├── debt_form.dart        # MODIFY — compte, rappel, patrimoine
│               ├── repay_bottom_sheet.dart  # CREATE — bottom sheet remboursement
│               └── snooze_dialog.dart    # CREATE — dialogue report rappel
├── routing/
│   ├── app_router.dart                  # MODIFY — route /debts/:id
│   └── route_names.dart                 # MODIFY — debtDetail
└── features/
    └── notifications/
        └── presentation/
            └── notification_list_screen.dart  # MODIFY — actions debt (deep link)
```

**Structure Decision**: Extension du module `features/debts/` existant. 3 nouveaux fichiers, ~10 fichiers modifiés. Pattern CrudNotifier conservé.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Pas de Drift/SQLite (Constitution IV — offline) | Les données dettes enrichies (remainingAmount, payments) doivent être fraîches depuis l'API. Pas de sync locale pertinente pour du suivi de remboursement temps réel. | Aligné sur les features récentes (053-accounts, 054-categories, 060-shop) qui utilisent aussi le mode serveur uniquement. |
