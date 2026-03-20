# Implementation Plan: Améliorations dettes Angular

**Branch**: `078-angular-debt-enhancements` | **Date**: 2026-03-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/078-angular-debt-enhancements/spec.md`

## Summary

Enrichissement de l'interface dettes Angular : formulaire avec compte bancaire, rappels et toggle patrimoine ; écran de détail avec remboursement (total/partiel), barre de progression et historique des paiements ; actions notification (reporter/rembourser) ; système toast. Backend déjà disponible (KKS-077).

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21
**Primary Dependencies**: Angular Reactive Forms, Angular Signals, Angular Router, @ng-icons/phosphor-icons
**Storage**: N/A (server-only, pas de stockage local)
**Testing**: Vitest (existant dans le projet Angular)
**Target Platform**: PWA mobile-first, navigateurs modernes
**Project Type**: Web application (frontend Angular)
**Performance Goals**: Interaction remboursement < 15s, mise à jour UI instantanée post-mutation
**Constraints**: Signals-first, standalone components, OnPush, inject() uniquement, design tokens CSS
**Scale/Scope**: Single-user, ~5 écrans impactés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Backend KKS-077 terminé, tous les endpoints disponibles. Frontend consomme uniquement. |
| II. Sécurité par défaut | PASS | JWT sur toutes les routes, filtrage par user authentifié côté API. Aucun changement de sécurité côté Angular. |
| III. Simplicité & YAGNI | PASS | Enrichissement de composants existants + 1 nouvel écran détail + 2 dialogs. Pas d'abstraction nouvelle. |
| IV. Mobile-First UX | PASS | Dialog remboursement compact, formulaire enrichi progressif (champs conditionnels). |
| V. Testabilité | PASS | Tests unitaires pour chaque composant nouveau/modifié. |
| VI. Observabilité | N/A | Frontend uniquement, logging côté API déjà en place. |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée. |

## Project Structure

### Documentation (this feature)

```text
specs/078-angular-debt-enhancements/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-contracts.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── models/
│   │   └── debt.model.ts              # UPDATE: +8 champs (montantRestant, account, reminder*, includeInBalance, dueDate)
│   └── services/
│       └── debt.ts                    # UPDATE: +repay(), +getPayments(), +snooze()
├── features/
│   └── debts/
│       ├── debts.ts                   # UPDATE: navigation vers détail au tap
│       ├── debts.routes.ts            # UPDATE: +route /debts/:id
│       └── components/
│           ├── debt-form/
│           │   └── debt-form.ts       # UPDATE: +champs compte, rappel, patrimoine
│           ├── debt-detail/
│           │   ├── debt-detail.ts     # NEW: écran détail (montant restant, barre, historique, actions)
│           │   └── debt-detail.scss   # NEW
│           ├── repay-dialog/
│           │   ├── repay-dialog.ts    # NEW: dialog remboursement (compte source + montant)
│           │   └── repay-dialog.scss  # NEW
│           └── snooze-dialog/
│               ├── snooze-dialog.ts   # NEW: dialog report rappel (date + heure)
│               └── snooze-dialog.scss # NEW
├── shared/
│   └── components/
│       ├── notification-panel/
│       │   └── notification-panel.ts  # UPDATE: +actions Reporter/Rembourser pour DEBT_DUE/DEBT_REMINDER
│       ├── toast/
│       │   ├── toast.ts               # NEW: composant toast réutilisable
│       │   ├── toast.scss             # NEW
│       │   └── toast.service.ts       # NEW: service signal-based (success/error/info)
│       └── shell/
│           └── shell.ts              # UPDATE: intégration toast + dialog debt actions
```

**Structure Decision**: Enrichissement de l'architecture existante. Nouveaux composants dans `features/debts/components/`. Toast dans `shared/` car réutilisable. Dialogs spécifiques à la dette dans le module debts.

## Complexity Tracking

> Aucune violation de constitution détectée. Pas de complexité supplémentaire justifiée.

## Design Decisions

### D1 — Écran détail dette (nouveau)

Actuellement, les dettes n'ont qu'une vue liste + modal d'édition. L'écran détail est nécessaire pour afficher le montant restant, la barre de progression, l'historique des paiements et le bouton rembourser. Route : `/debts/:id`.

### D2 — Dialogs remboursement et report

Deux dialogs séparés (pas de ModalType) car ils sont contextuels à l'écran détail et aux notifications, pas au système modal global existant. Ils utilisent un pattern standalone dialog (overlay + backdrop) plutôt que le ModalService existant (réservé aux formulaires CRUD).

**Alternative rejetée** : Ajouter `ModalType.repay` et `ModalType.snooze` au ModalService. Rejeté car ces dialogs sont simples (2-3 champs) et ne suivent pas le pattern CRUD.

### D3 — Système toast

Aucun système toast n'existe. Création d'un `ToastService` signal-based (`toasts: signal<Toast[]>`) avec un composant `Toast` intégré dans le Shell. Pattern : `toastService.success('message')` / `toastService.error('message')`. Auto-dismiss après 4 secondes.

### D4 — Navigation liste → détail

Le tap sur une dette dans la liste navigue vers `/debts/:id` (au lieu d'ouvrir le modal d'édition). L'édition se fait depuis l'écran détail via un bouton "Modifier" qui ouvre le modal existant.

### D5 — Actions notification

Les boutons "Reporter" et "Rembourser" dans le `NotificationPanel` ouvrent directement les dialogs respectifs. Le `NotificationPanel` charge la dette via `DebtService.getById()` pour pré-remplir les dialogs.
