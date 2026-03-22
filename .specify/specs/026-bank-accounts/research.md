# Research: Comptes Bancaires

**Branch**: `026-bank-accounts` | **Date**: 2026-02-15

## R1 — Next Flyway Migration Version

- **Decision**: V7
- **Rationale**: Migrations existantes V1 à V6. V6 = `V6__add_refresh_tokens.sql`.
- **Alternatives considered**: Aucune — versionnement séquentiel Flyway imposé.

## R2 — Pattern de création du compte par défaut à l'inscription

- **Decision**: Appeler `accountService.createDefaultAccount(user)` dans `AuthService.register()`, juste après `categoryService.seedSystemCategories(user)`.
- **Rationale**: Pattern identique à celui de `CategoryService.seedSystemCategories()` déjà utilisé dans `AuthService.register()` (ligne 40). Même approche `@Transactional` avec log + propagation d'erreur.
- **Alternatives considered**: Listener JPA `@PostPersist` sur User — rejeté car le projet n'utilise pas ce pattern et cela cacherait la logique d'initialisation.

## R3 — Type Java pour le solde initial (BigDecimal)

- **Decision**: `BigDecimal` avec colonne PostgreSQL `NUMERIC(19,2)`.
- **Rationale**: Même type que `montant` sur Transaction/Subscription/Debt. Évite les erreurs d'arrondi IEEE 754.
- **Alternatives considered**: `double` — rejeté pour imprécision sur les calculs financiers.

## R4 — Calcul du solde à la volée

- **Decision**: Requête `@Query` JPQL/SQL dans `TransactionRepository` avec `SUM(CASE WHEN type = 'RECETTE' THEN montant ELSE -montant END)` filtrée par `account_id`.
- **Rationale**: Spec impose calcul SUM SQL. Volume single-user rend le calcul performant sans cache. Le résultat est ajouté au DTO response via le service.
- **Alternatives considered**: Champ `balance` persisté sur Account — rejeté par spec (clarification session).

## R5 — Gestion atomique des virements

- **Decision**: Les deux transactions du virement sont créées dans une même méthode `@Transactional`. Un UUID partagé (`transferId`) est généré via `UUID.randomUUID()` et assigné aux deux transactions.
- **Rationale**: Spring `@Transactional` garantit l'atomicité. Le `transferId` permet l'identification des paires sans table de liaison.
- **Alternatives considered**: Table `transfers` séparée — rejeté car la spec dit explicitement que les virements sont des transactions normales avec un champ supplémentaire.

## R6 — Catégorie système "Virement"

- **Decision**: Ajoutée via migration V7 pour les utilisateurs existants (même pattern que V5 pour "Abonnement" et "Dette"). Ajoutée dans `CategoryService.seedSystemCategories()` pour les nouveaux utilisateurs.
- **Rationale**: Cohérent avec le pattern existant. `isSystem=true` empêche modification/suppression.
- **Alternatives considered**: Catégorie créée à la volée au premier virement — rejeté car incohérent avec le pattern existant de seeding.

## R7 — Contrainte NOT NULL sur account_id dans transactions

- **Decision**: Migration en 3 étapes dans V7 : (1) ajouter `account_id` nullable, (2) rattacher les transactions existantes au compte par défaut, (3) ajouter contrainte `NOT NULL`.
- **Rationale**: Migration atomique Flyway. Les transactions existantes doivent d'abord être rattachées avant de poser la contrainte.
- **Alternatives considered**: Deux migrations V7 + V8 — rejeté car une seule migration atomique suffit.

## R8 — Pattern d'erreur pour les comptes

- **Decision**: Réutiliser `EntityNotFoundException` (404) et `IllegalArgumentException` (400) via le `GlobalExceptionHandler` existant. Pas de nouvelle classe d'exception.
- **Rationale**: Le handler existant gère déjà ces deux exceptions avec les bons codes HTTP. Les messages d'erreur suffisent à distinguer les cas (ex: "Impossible de supprimer un compte avec des transactions rattachées").
- **Alternatives considered**: Exception custom `AccountException` — rejeté car sur-ingénierie pour des cas déjà couverts.

## R9 — Valeurs par défaut icone/couleur selon le type de compte

- **Decision**: Défauts définis dans le service Java (pas en base). Map statique `AccountType → (icone, couleur)` :
  - COURANT: `🏦` / `#3b82f6` (bleu)
  - EPARGNE: `🐷` / `#22c55e` (vert)
  - ESPECES: `💵` / `#f59e0b` (amber)
- **Rationale**: Logique applicative simple, pas besoin de table de référence. Les valeurs sont modifiables par l'utilisateur après création.
- **Alternatives considered**: Table de config en base — rejeté (YAGNI).

## R10 — Solde initial figé après création

- **Decision**: Le champ `soldeInitial` est ignoré dans le endpoint PUT. Il n'est pris en compte qu'au POST (création). Pour corriger un solde, l'utilisateur crée une transaction d'ajustement.
- **Rationale**: Garantit la traçabilité — chaque modification de solde est matérialisée par une transaction auditable. Simplifie la logique de mise à jour.
- **Alternatives considered**: Solde initial modifiable librement — rejeté par clarification utilisateur (option B choisie).

## R11 — Suppression en cascade des transactions de virement

- **Decision**: Quand une transaction avec `transferId` non-null est supprimée, `TransactionService.delete()` recherche et supprime automatiquement la transaction liée (même `transferId`, `id` différent).
- **Rationale**: Un virement est une opération atomique. Garder un seul côté fausserait les soldes. L'opération est dans une même `@Transactional`.
- **Alternatives considered**: Interdire la suppression individuelle — rejeté car trop contraignant. Suppression libre — rejeté car incohérent.

## R12 — Propagation de modification des transactions de virement

- **Decision**: Quand le montant d'une transaction avec `transferId` non-null est modifié, `TransactionService.update()` propage le nouveau montant à la transaction liée. Seul le montant est propagé.
- **Rationale**: Le montant doit rester synchronisé entre les deux côtés du virement. Les autres champs (date, note) restent indépendants.
- **Alternatives considered**: Propagation de tous les champs — trop rigide. Interdire la modification — rejeté par clarification utilisateur (option A choisie).
