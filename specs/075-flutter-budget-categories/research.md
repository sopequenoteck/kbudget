# Research — 075-flutter-budget-categories

## R1: Librairie graphique (pie chart)

**Decision**: `fl_chart` (dernière version stable)
**Rationale**: Librairie Flutter la plus populaire pour les graphiques, support Material 3, PieChart interactif avec touch callbacks. Pas de chart library actuellement dans le projet.
**Alternatives considered**:
- `charts_flutter` (Google) — moins maintenu, API plus complexe
- Canvas custom — trop de travail pour un camembert standard

## R2: Data layer pattern (local + remote)

**Decision**: Réutiliser le strategy pattern `dataModeProvider` existant avec `BudgetRepositoryLocal` (Drift) + `BudgetRepositoryRemote` (Dio)
**Rationale**: Cohérent avec transactions, subscriptions, debts. Deux tables Drift (`budgets`, `budget_snapshots`) miroir du backend.
**Alternatives considered**:
- Remote-only (comme products/accounts) — rejeté car la spec exige le mode local+remote

## R3: CRUD Notifier pattern

**Decision**: `BudgetNotifier extends Notifier<BudgetListState>` avec `BudgetListState` custom (ListState<Budget> + champs overview/history)
**Rationale**: Pattern éprouvé (subscriptions, debts). BudgetListState custom nécessaire car l'état doit gérer à la fois la liste CRUD et les données d'overview/history pour le mois sélectionné.
**Alternatives considered**:
- Deux notifiers séparés (CRUD + overview) — plus simple mais duplique le state management du mois sélectionné

## R4: Form presentation

**Decision**: Modal bottom sheet via `ModalNotifier` + `ModalType.budget`
**Rationale**: Pattern existant pour toutes les entités (transactions, subscriptions, debts, products). Cohérent UX.
**Alternatives considered**:
- Écran dédié — incohérent avec le reste de l'app

## R5: Navigation et routing

**Decision**: Routes `/budgets` (liste) et `/budgets/details` (camembert détail) dans ShellRoute. Query param `month=YYYY-MM` pour le détail.
**Rationale**: Cohérent avec l'implémentation Angular. `/budgets` dans la bottom nav conditionnelle (feature BUDGETS).
**Alternatives considered**:
- `/budgets/history` — renommé en `/budgets/details` pour cohérence Angular

## R6: Dashboard integration

**Decision**: Nouvelle section `BudgetSummarySection` dans le dashboard, conditionnelle (feature BUDGETS activée + au moins 1 budget actif). Top 5 catégories par % dépensé décroissant.
**Rationale**: Pattern identique à Angular (BudgetSummary component). Utilise l'endpoint `GET /budgets/overview`.
**Alternatives considered**:
- Mini-card dans la grille existante — pas assez d'espace pour les barres de progression

## R7: Backend API contracts

**Decision**: 7 endpoints existants réutilisés tels quels (backend 073 déjà implémenté)
**Rationale**: Pas de modification backend nécessaire. DTOs Flutter calqués sur les réponses API.
**Endpoints**:
- POST `/budgets` — create
- GET `/budgets` — list (param: includeInactive)
- GET `/budgets/overview` — current month dashboard
- GET `/budgets/history` — past month (param: month=YYYY-MM)
- GET `/budgets/{id}` — get by ID
- PUT `/budgets/{id}` — update
- DELETE `/budgets/{id}` — delete

## R8: Bottom sheet catégorie (tap camembert)

**Decision**: Bottom sheet avec détail catégorie (nom, icône, montant dépensé, pourcentage, liste transactions filtrées côté client)
**Rationale**: Les transactions du mois sont déjà disponibles localement. Filtrage par categoryId sans nouvel endpoint.
**Alternatives considered**:
- Nouvel endpoint API avec filtre catégorie — over-engineering, données déjà disponibles
