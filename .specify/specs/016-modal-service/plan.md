# Implementation Plan: ModalService et câblage édition/suppression

**Branch**: `016-modal-service` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-modal-service/spec.md`

## Summary

Créer un `ModalService` injectable qui centralise la gestion de l'état de la modale (type actif, entité en édition). Migrer la logique modale du Shell vers ce service. Câbler les écrans de liste (transactions, abonnements, dettes) pour ouvrir la modale en mode édition au clic sur un élément. Ajouter un bouton "Supprimer" avec confirmation dans les 3 formulaires en mode édition.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: Angular (Signals, standalone, OnPush), @angular/cdk (overlay, a11y), @angular/router
**Storage**: N/A (utilise les services REST existants — TransactionService, SubscriptionService, DebtService)
**Testing**: Vitest 4.x via `npx vitest run` (config: `app/vitest.config.ts`)
**Target Platform**: PWA mobile-first (navigateurs modernes)
**Project Type**: Web application (monorepo api/ + app/)
**Performance Goals**: N/A (app single-user)
**Constraints**: Signals-first, OnPush, standalone components, inject() uniquement
**Scale/Scope**: Single-user, 4 écrans (dashboard, transactions, abonnements, dettes)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature frontend-only, utilise les endpoints REST existants (CRUD déjà implémenté) |
| II. Sécurité par défaut | PASS | Pas de nouveau endpoint, JWT existant protège toutes les routes |
| III. Simplicité & YAGNI | PASS | Service simple avec signals, pas d'abstraction complexe. Un seul service au lieu de 3 signaux éparpillés dans le Shell |
| IV. Mobile-First UX | PASS | Tap sur item = édition en 1 interaction, suppression en 2 interactions (tap + confirm) |
| V. Testabilité | PASS | ModalService testable en isolation, pas de dépendance DOM |
| VI. Observabilité | N/A | Frontend-only, pas de logging serveur nécessaire |
| VII. Self-Hosted Ready | N/A | Aucune dépendance infra ajoutée |

**Résultat** : PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/016-modal-service/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   └── services/
│       └── modal.service.ts          # NOUVEAU — ModalService
├── shared/
│   └── components/
│       └── shell/
│           ├── shell.ts              # MODIFIER — utiliser ModalService
│           └── shell.html            # MODIFIER — bindings vers ModalService
└── features/
    ├── transactions/
    │   ├── transactions.ts           # MODIFIER — (pressed) → openModal
    │   ├── transactions.html         # MODIFIER — ajouter (pressed) binding
    │   └── components/
    │       └── transaction-form/
    │           ├── transaction-form.ts    # MODIFIER — output deleted
    │           └── transaction-form.html  # MODIFIER — bouton Supprimer
    ├── subscriptions/
    │   ├── subscriptions.ts          # MODIFIER — (pressed) → openModal
    │   ├── subscriptions.html        # MODIFIER — ajouter (pressed) binding
    │   └── components/
    │       └── subscription-form/
    │           ├── subscription-form.ts   # MODIFIER — output deleted
    │           └── subscription-form.html # MODIFIER — bouton Supprimer
    └── debts/
        ├── debts.ts                  # MODIFIER — (pressed) → openModal
        ├── debts.html                # MODIFIER — ajouter (pressed) binding
        └── components/
            └── debt-form/
                ├── debt-form.ts          # MODIFIER — output deleted
                └── debt-form.html        # MODIFIER — bouton Supprimer
```

**Structure Decision** : Feature frontend-only. 1 fichier créé (ModalService), 12 fichiers modifiés (Shell + 3 écrans + 3 formulaires, chacun TS + HTML).

## Complexity Tracking

> Aucune violation — tableau non applicable.
