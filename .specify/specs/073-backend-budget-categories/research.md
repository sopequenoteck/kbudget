# Research: Backend Budget Categories

**Feature**: 073-backend-budget-categories
**Date**: 2026-03-08

## Decisions

### 1. Conversion multi-devises

**Decision**: Le BudgetService effectue la conversion manuellement en fetching le taux depuis `ExchangeRateRepository`.
**Rationale**: `ExchangeRateService` n'expose pas de methode `convertAmount()`. Le service CRUD rates seulement (getAll, upsert, delete, rebaseRates). La conversion est simple : `amount * rate`.
**Alternatives**: Ajouter une methode `convertAmount()` a ExchangeRateService — rejete car ca ajoute une dependance circulaire potentielle et la logique est triviale.

### 2. Somme des depenses par categorie et mois

**Decision**: Ajouter une query native dans `TransactionRepository` pour sommer les transactions DEPENSE par category_id, user_id et plage de dates.
**Rationale**: Pas de methode existante pour sommer par categorie. `findByUserIdAndDateBetweenOrderByDateDesc` retourne des listes completes — inefficace pour une somme. Une query native `SUM()` est plus performante.
**Alternatives**: Charger toutes les transactions et filtrer en Java — rejete pour raisons de performance (SC-002).

### 3. Enum Frequency — ajout HEBDOMADAIRE

**Decision**: Ajouter `HEBDOMADAIRE` en premiere position dans l'enum `Frequency`.
**Rationale**: L'enum actuel ne contient que `MENSUEL, ANNUEL`. La spec exige trois frequences. L'ajout est backwards-compatible car les enums sont stockes en `VARCHAR` (`@Enumerated(EnumType.STRING)`).
**Alternatives**: Creer un enum BudgetFrequency separe — rejete car Frequency est le bon concept, reutilisable.

### 4. Enum Feature — ajout BUDGETS

**Decision**: Ajouter `BUDGETS` a l'enum `Feature` existante (`SUBSCRIPTIONS, DEBTS, SHOP, BUDGETS`).
**Rationale**: Pattern existant pour feature toggles. PreferenceService.isFeatureEnabled() fonctionne deja avec cet enum.
**Alternatives**: Aucune.

### 5. Migration Flyway — V17

**Decision**: Creer `V17__add_budgets.sql` avec tables `budgets` et `budget_snapshots`.
**Rationale**: Derniere migration existante = V16. Contraintes FK avec CASCADE sur category_id pour les deux tables (spec clarifiee : cascade complete a la suppression de categorie).
**Alternatives**: Deux migrations separees — rejete car les tables sont liees et creees ensemble.

### 6. Exception pour budget duplique

**Decision**: Utiliser `ConflictException` (existant) pour le cas d'un budget deja existant pour une categorie.
**Rationale**: Le projet a deja `ConflictException` mappee sur HTTP 409. C'est semantiquement correct (conflit d'unicite).
**Alternatives**: `IllegalArgumentException` (400) — rejete car 409 est plus precis pour un conflit d'unicite.

### 7. ExchangeRate — acces direct au repository

**Decision**: BudgetService injecte `ExchangeRateRepository` directement (pas `ExchangeRateService`).
**Rationale**: Pattern existant dans le projet (cf. MEMORY.md : PreferenceService accede a AccountRepository directement). Evite un couplage service-service inutile pour une simple lecture de taux. La conversion est une operation de lecture, pas de gestion de taux.
**Alternatives**: Injecter ExchangeRateService — risque de couplage excessif.

### 8. Snapshot — pas de FK vers Budget

**Decision**: `BudgetSnapshot` n'a PAS de FK vers `Budget`. Cle unique = (user_id, category_id, mois).
**Rationale**: FR-015 exige que les snapshots survivent a la suppression du budget. Une FK vers Budget avec CASCADE les detruirait. Les snapshots sont lies a la categorie, pas au budget lui-meme.
**Alternatives**: FK avec SET NULL — rejete car complexifie les queries sans benefice.

### 9. Pagination de la liste budgets

**Decision**: Liste simple sans pagination Spring (pas de `Page<>`) — retourner `List<BudgetResponse>`.
**Rationale**: Pattern existant dans le projet (CategoryController, AccountController retournent des `List<>`). Un utilisateur a typiquement 5-20 categories, donc 5-20 budgets max. La pagination serait de la sur-ingenierie.
**Alternatives**: Spring Data `Pageable` — rejete car YAGNI pour ce volume de donnees.
