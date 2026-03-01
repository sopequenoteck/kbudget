# Implementation Plan: Virement entre comptes Angular

**Branch**: `066-angular-transfer-form` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/066-angular-transfer-form/spec.md`

## Summary

Formulaire de virement entre comptes dans l'application Angular (PWA). Le composant `TransferForm` permet de transférer de l'argent d'un compte source vers un compte destination via l'API existante `POST /accounts/transfer`. Intégré dans le système de modales via le FAB (speed dial), accessible uniquement si l'utilisateur a au moins 2 comptes actifs. Opération server-only (pas de stockage local).

## Technical Context

**Language/Version**: TypeScript 5.9
**Primary Dependencies**: Angular 21, Angular Reactive Forms, Angular Signals
**Storage**: N/A (server-only, pas de stockage local)
**Testing**: Vitest
**Target Platform**: PWA web mobile-first
**Project Type**: web-service (frontend PWA)
**Performance Goals**: Soumission du formulaire perçue comme instantanée (< 2s)
**Constraints**: Standalone components, OnPush, signals-first, inject() uniquement
**Scale/Scope**: Single-user, 1 composant formulaire + intégration shell/FAB

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | L'API `POST /accounts/transfer` existe déjà. Le frontend consomme l'endpoint via `AccountService.transfer()`. |
| II. Sécurité par défaut | PASS | Toutes les requêtes passent par le JWT interceptor existant. Pas d'exposition de données sensibles. |
| III. Simplicité & YAGNI | PASS | Un seul composant formulaire standalone. Pas de pattern complexe. Utilise les services existants (`AccountService`, `ModalService`). |
| IV. Mobile-First UX | PASS | Formulaire accessible via FAB (2-3 interactions). Modal plein écran sur mobile. |
| V. Testabilité | PASS | Tests unitaires avec Vitest. Validation cross-champ testable isolément. |
| VI. Observabilité | N/A | Frontend uniquement — le logging est côté backend. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée. |

## Project Structure

### Documentation (this feature)

```text
specs/066-angular-transfer-form/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── transfer-api.md  # Contrat API transfer
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── models/
│   │   └── account.model.ts         # TransferRequest, TransferResponse, TransactionRef
│   └── services/
│       ├── account.ts               # AccountService.transfer() + accounts signal
│       ├── modal.service.ts         # ModalService (ModalType inclut 'transfer')
│       └── transaction.ts           # TransactionService.refreshTrigger
├── shared/components/
│   ├── fab/
│   │   └── fab.ts                   # TRANSFER_ACTION + hasEnoughAccounts computed
│   ├── modal/
│   │   └── modal.ts                 # Composant modal réutilisable
│   ├── select-picker/
│   │   └── select-picker.ts         # Sélecteur de compte (réutilisable)
│   ├── shell/
│   │   ├── shell.ts                 # onTransferSaved() handler
│   │   └── shell.html               # @case ('transfer') → <app-transfer-form>
│   └── transfer-form/
│       ├── transfer-form.ts         # Composant principal (standalone, OnPush)
│       ├── transfer-form.html       # Template formulaire
│       ├── transfer-form.scss       # Styles
│       └── transfer-form.spec.ts    # Tests unitaires (Vitest)
```

**Structure Decision**: Feature frontend-only. Le composant `TransferForm` est dans `shared/components/` car il est invoqué depuis le Shell (pas une route dédiée). Les modèles et services sont dans `core/` conformément à la structure existante.

## Complexity Tracking

> Aucune violation de la constitution — pas de justification nécessaire.
