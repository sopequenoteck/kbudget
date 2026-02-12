# Implementation Plan: Écran Dashboard

**Branch**: `015-dashboard` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-dashboard/spec.md`

## Summary

Implémenter l'écran dashboard de l'application Budget avec bilan mensuel (sélecteur mois + 3 cartes financières) et résumés des 3 entités (transactions, abonnements, dettes). Feature purement frontend : le composant Dashboard agrège les données des 3 services existants et réutilise les composants partagés (ListItem, AmountPipe, RelativeDatePipe). L'édition au clic sur un item nécessite de remonter l'événement au Shell qui centralise les modales.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: Angular (Signals, standalone, OnPush), RxJS (HTTP uniquement), composants existants (ListItem, AmountPipe, RelativeDatePipe, Shell, Fab, Modal)
**Storage**: N/A (données via services REST existants)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: PWA mobile-first (navigateur)
**Project Type**: web (monorepo api/ + app/)
**Performance Goals**: Dashboard chargé en < 2 secondes
**Constraints**: Chaque section charge indépendamment, pas de nouvelle API backend
**Scale/Scope**: Single-user, 1 écran, 3 sections de résumé

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Commentaire |
| -------- | ------ | ----------- |
| I. API-First | PASS | Pas de nouveau endpoint. Utilise les services existants (getSummary, getAll) |
| II. Sécurité par défaut | PASS | Route protégée par authGuard (existant). Données filtrées par user côté API |
| III. Simplicité & YAGNI | PASS | Composant unique, pas d'abstraction. Réutilise les patterns existants |
| IV. Mobile-First UX | PASS | Dashboard affiche bilan + résumés comme spécifié dans la constitution. FAB accessible |
| V. Testabilité | PASS | Composant testable unitairement via mock des 3 services |
| VI. Observabilité | PASS | Frontend uniquement — erreurs loggées via `isDevMode()` (pattern existant) |
| VII. Self-Hosted Ready | PASS | Pas de nouvelle dépendance infra |

## Project Structure

### Documentation (this feature)

```text
specs/015-dashboard/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── features/
│   └── dashboard/
│       ├── dashboard.ts         # Composant principal (à implémenter)
│       ├── dashboard.html       # Template (à créer)
│       ├── dashboard.scss       # Styles (à créer)
│       └── dashboard.routes.ts  # Routes (existant)
└── shared/
    └── components/
        └── shell/
            └── shell.ts         # Ajout méthodes d'édition publiques (à modifier)
```

**Structure Decision**: Feature purement frontend dans le composant existant `dashboard/`. Le Shell nécessite une modification mineure pour exposer les méthodes d'édition aux enfants.

## Design Decisions

### DD-001: Communication Dashboard → Shell pour l'édition

**Problème** : Le Shell centralise les modales d'édition (signals `editingTransaction`, `editingSubscription`, `editingDebt`). Le dashboard doit pouvoir ouvrir une modale d'édition au clic sur un item, mais les écrans enfants n'ont actuellement aucun moyen de communiquer avec le Shell.

**Options considérées** :
1. **Service partagé** : créer un `ModalService` avec des signaux partagés → introduit une nouvelle abstraction (viole YAGNI)
2. **Router avec state** : naviguer vers la liste avec un paramètre d'édition → complexe, indirection inutile
3. **Injection du Shell** : injecter le Shell dans le Dashboard via `inject(Shell)` → pattern Angular valide pour la communication parent-enfant à travers un RouterOutlet

**Décision** : Le Dashboard injecte le Shell parent via `inject(Shell)` et appelle 3 méthodes publiques ajoutées au Shell (`openEditTransaction(t)`, `openEditSubscription(s)`, `openEditDebt(d)`). Chaque méthode setter le signal `editing*` correspondant et active la modale. C'est minimal, sans nouvelle abstraction, et suit le principe de simplicité (Constitution III).

### DD-002: Chargement indépendant des sections

**Décision** : Chaque section a ses propres signaux `loading`/`error`/`data`. Les 3 appels HTTP sont lancés en parallèle mais gérés indépendamment (pas de `forkJoin` global). Cela permet à une section de s'afficher même si une autre échoue.

### DD-003: Pas de nouveau fichier de service

**Décision** : Le dashboard injecte directement les 3 services existants. Pas de `DashboardService` intermédiaire — ce serait une abstraction sans valeur ajoutée.
