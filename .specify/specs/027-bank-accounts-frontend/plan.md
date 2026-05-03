# Implementation Plan: Comptes bancaires — Frontend (UI + Integration)

**Branch**: `027-bank-accounts-frontend` | **Date**: 2026-02-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/027-bank-accounts-frontend/spec.md`

## Summary

Integrer les comptes bancaires dans le frontend Angular : AccountService, modeles, section comptes sur le dashboard (solde total + individuels), selecteur de compte dans les formulaires transaction/abonnement, page de gestion des comptes dans Settings, et formulaire de virement entre comptes. L'API backend est deja implementee — cette feature est purement frontend.

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21
**Primary Dependencies**: Angular 21, RxJS, Angular Reactive Forms
**Storage**: N/A (frontend consomme l'API REST existante)
**Testing**: Karma/Jasmine (`ng test`)
**Target Platform**: PWA mobile-first (navigateur)
**Project Type**: Web (module frontend du monorepo `app/`)
**Performance Goals**: Rafraichissement immediat des soldes apres chaque action (SC-006)
**Constraints**: Signals-first, OnPush, standalone components, pas de `subscribe()` manuel, `inject()` uniquement
**Scale/Scope**: Single user, 2-5 comptes typiques

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Le frontend consomme l'API REST existante. Les modeles TS refletent les DTOs backend. Aucune logique metier cote frontend. |
| II. Securite par defaut | PASS | L'auth JWT est deja geree par `AuthInterceptor`. Aucun changement de securite necessaire. |
| III. Simplicite & YAGNI | PASS | Suit les patterns existants : Service → Component → Template. Pas de nouvelle abstraction. |
| IV. Mobile-First UX | PASS | Dashboard enrichi en haut de page, formulaires avec pre-selection du compte par defaut, saisie rapide. |
| V. Testabilite | PASS | Tests unitaires sur le service, tests composants pour les formulaires. Pattern existant suivi. |
| VI. Observabilite | PASS | Pattern `isDevMode() + console.error` deja en place, replique sur les nouveaux composants. |
| VII. Self-Hosted Ready | PASS | Aucune nouvelle dependance infrastructure. |

**Resultat** : Tous les gates passent. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/027-bank-accounts-frontend/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── account-api.md   # Endpoints consommes par le frontend
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   ├── models/
│   │   └── account.model.ts          # NEW — Account, AccountRequest, TransferRequest, etc.
│   └── services/
│       └── account.ts                # NEW — AccountService (CRUD, transfer, default)
├── features/
│   ├── dashboard/
│   │   ├── dashboard.ts              # MODIFY — ajouter section comptes en haut
│   │   ├── dashboard.html            # MODIFY — template section comptes
│   │   └── dashboard.scss            # MODIFY — styles section comptes
│   └── settings/
│       ├── settings.ts               # MODIFY — ajouter navigation vers sous-page comptes
│       ├── settings.html             # MODIFY — ajouter lien vers comptes
│       ├── settings.routes.ts        # MODIFY — ajouter route enfant comptes
│       └── components/
│           └── accounts/
│               ├── accounts.ts       # NEW — page liste des comptes
│               ├── accounts.html     # NEW — template liste des comptes
│               └── accounts.scss     # NEW — styles liste des comptes
├── shared/
│   └── components/
│       ├── account-picker/
│       │   ├── account-picker.ts     # NEW — composant selecteur de compte reutilisable
│       │   ├── account-picker.html   # NEW — template selecteur
│       │   └── account-picker.scss   # NEW — styles selecteur
│       ├── account-form/
│       │   ├── account-form.ts       # NEW — formulaire creation/edition compte
│       │   ├── account-form.html     # NEW — template formulaire compte
│       │   └── account-form.scss     # NEW — styles formulaire compte
│       ├── transfer-form/
│       │   ├── transfer-form.ts      # NEW — formulaire virement entre comptes
│       │   ├── transfer-form.html    # NEW — template formulaire virement
│       │   └── transfer-form.scss    # NEW — styles formulaire virement
│       ├── shell/
│       │   ├── shell.ts              # MODIFY — ajouter cas 'account' et 'transfer' dans le modal
│       │   └── shell.html            # MODIFY — template modal account/transfer
│       └── fab/
│           └── fab.ts                # MODIFY — ajouter option Virement dans le speed dial
└── features/
    ├── transactions/
    │   └── components/
    │       └── transaction-form/
    │           ├── transaction-form.ts    # MODIFY — ajouter accountId au formulaire
    │           └── transaction-form.html  # MODIFY — ajouter AccountPicker
    └── subscriptions/
        └── components/
            └── subscription-form/
                ├── subscription-form.ts   # MODIFY — ajouter accountId optionnel
                └── subscription-form.html # MODIFY — ajouter AccountPicker
```

**Structure Decision** : Les nouveaux fichiers suivent exactement les conventions existantes. Le `AccountService` va dans `core/services/`, le modele dans `core/models/`, la page comptes est une sous-route de `settings/`, et le `AccountPicker` est un composant partage reutilisable (comme `CategoryPicker`). Le formulaire de virement sera un type de modal (`transfer`) gere par le `ModalService`.

## Complexity Tracking

> Aucune violation de constitution a justifier.
