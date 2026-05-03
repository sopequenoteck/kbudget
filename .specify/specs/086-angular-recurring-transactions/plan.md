# Implementation Plan: Transactions récurrentes & abonnements — Angular

**Branch**: `086-angular-recurring-transactions` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/086-angular-recurring-transactions/spec.md`

## Summary

Implémenter côté Angular l'écran des transactions récurrentes (liste + actions valider/passer/désactiver), enrichir le détail abonnement avec le suivi des paiements (historique + total cumulé + bouton payer), et ajouter des actions contextuelles dans le panneau de notifications pour les récurrences et abonnements. Feature frontend-only consommant les endpoints backend KKS-085.

## Technical Context

**Language/Version**: TypeScript 5.9
**Primary Dependencies**: Angular 21, Angular Router, Angular Signals, @ng-icons/phosphor-icons
**Storage**: N/A (server-only, consomme API REST)
**Testing**: Vitest (Angular testing)
**Target Platform**: Web (PWA mobile-first, responsive)
**Project Type**: Web application (frontend Angular PWA)
**Performance Goals**: Affichage instantané des listes, feedback toast < 500ms après action
**Constraints**: Mobile-first (< 768px), design tokens existants, signals-first, OnPush
**Scale/Scope**: Single-user, ~3 nouveaux composants, ~2 services enrichis, ~1 nouveau service

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Feature frontend-only, consomme endpoints backend existants (KKS-085) |
| II. Sécurité par défaut | PASS | JWT géré par HttpInterceptor existant, pas de nouvelle route publique |
| III. Simplicité & YAGNI | PASS | Pas de nouveau pattern — réutilise signal-based services, computed, OnPush |
| IV. Mobile-First UX | PASS | Responsive, actions accessibles en 1-3 interactions, design tokens |
| V. Testabilité | PASS | Tests unitaires prévus pour services et composants |
| VI. Observabilité | N/A | Frontend-only, logging côté backend déjà en place |
| VII. Self-Hosted Ready | PASS | Pas de nouvelle dépendance infrastructure |

**Post-Phase 1 re-check**: Aucune violation détectée.

## Project Structure

### Documentation (this feature)

```text
specs/086-angular-recurring-transactions/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── api-endpoints.md
└── tasks.md
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── models/
│   │   ├── recurring-transaction.model.ts    # NOUVEAU — interface RecurringTransactionResponse
│   │   ├── subscription-payment.model.ts     # NOUVEAU — interface SubscriptionPaymentResponse
│   │   └── notification.model.ts             # UPDATE — +RECURRING_TRANSACTION_DUE, +RECURRING_TRANSACTION EntityType
│   └── services/
│       ├── recurring-transaction.ts           # NOUVEAU — RecurringTransactionService (signal-based)
│       └── subscription.ts                    # UPDATE — +pay(), +getPayments(), +getTotalPaid()
├── features/
│   ├── transactions/
│   │   ├── transactions.ts                    # UPDATE — +lien vers /transactions/recurring
│   │   ├── transactions.html                  # UPDATE — +bouton/lien récurrences
│   │   ├── transactions.routes.ts             # UPDATE — +route 'recurring'
│   │   └── components/
│   │       └── recurring-list/
│   │           ├── recurring-list.ts          # NOUVEAU — RecurringListComponent
│   │           └── recurring-list.html        # NOUVEAU — template
│   └── subscriptions/
│       ├── subscriptions.routes.ts            # UPDATE — +route ':id'
│       └── components/
│           └── subscription-detail/
│               ├── subscription-detail.ts     # NOUVEAU — SubscriptionDetailComponent
│               └── subscription-detail.html   # NOUVEAU — template (paiements + bouton payer)
└── shared/
    └── components/
        └── notification-panel/
            ├── notification-panel.ts           # UPDATE — +actions récurrence/abonnement
            └── notification-panel.html         # UPDATE — +boutons Valider/Passer/Payer
```

**Structure Decision**: Frontend Angular uniquement. Nouveaux composants dans les features existantes (`transactions/`, `subscriptions/`). Nouveau service `RecurringTransactionService` dans `core/services/`. Enrichissement des services et modèles existants.

## Complexity Tracking

> Aucune violation détectée — pas de tracking nécessaire.
