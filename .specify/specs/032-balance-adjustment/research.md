# Research: Ajustement de solde

**Feature**: 032-balance-adjustment
**Date**: 2026-02-19

## R1 — Stockage du montant pour AJUSTEMENT

**Decision**: Le montant des transactions AJUSTEMENT est stocké **signé** (positif ou négatif) dans la colonne `montant` existante (NUMERIC(19,2)).

**Rationale**: La colonne `montant` supporte déjà les valeurs négatives côté DB. Le type AJUSTEMENT n'a pas de notion recette/dépense — le signe du montant encode directement la direction. Cela simplifie le calcul de solde : on additionne directement le montant sans CASE.

**Alternatives considered**:
- Stocker en valeur absolue + champ séparé de direction → ajout colonne inutile, complexité accrue
- Réutiliser DEPENSE/RECETTE avec catégorie "Ajustement" → pas de distinction sémantique claire, mélange dans les résumés mensuels

## R2 — Impact sur la requête de calcul de solde

**Decision**: Modifier la query native `calculateBalanceByAccountId` pour gérer AJUSTEMENT.

**Rationale**: La query actuelle `CASE WHEN type = 'RECETTE' THEN montant ELSE -montant END` traite tout non-RECETTE comme négatif. Avec AJUSTEMENT signé, la query devient :
```sql
CASE
  WHEN t.type = 'RECETTE' THEN t.montant
  WHEN t.type = 'AJUSTEMENT' THEN t.montant
  ELSE -t.montant
END
```

**Alternatives considered**:
- Créer une view SQL → over-engineering pour single-user
- Calculer côté Java → moins performant, N+1 potentiel

## R3 — Migration Flyway

**Decision**: **Aucune migration Flyway nécessaire** (V9 non requise).

**Rationale**:
- `type` est VARCHAR(50) — pas de contrainte CHECK sur les valeurs, donc l'ajout de `AJUSTEMENT` côté Java suffit
- `montant` est NUMERIC(19,2) — supporte nativement les négatifs
- La catégorie "Ajustement" est créée lazy (pas de seed en migration)

**Alternatives considered**:
- V9 pour ajouter une contrainte CHECK sur type → rigidité inutile, le Java enum suffit
- V9 pour seed la catégorie → contredit la décision de création lazy

## R4 — Emplacement du code métier adjust-balance

**Decision**: Méthode `adjustBalance()` dans `AccountService` existant.

**Rationale**: Le pattern `transfer()` dans AccountService montre le précédent : opérations cross-entity (account + transaction) centralisées dans AccountService. L'ajustement suit le même modèle. AccountService a déjà les dépendances nécessaires (TransactionRepository, CategoryService).

**Alternatives considered**:
- Nouveau service dédié `BalanceAdjustmentService` → over-engineering pour une seule méthode
- Dans TransactionService → l'opération est centrée sur le compte, pas sur la transaction

## R5 — Protection immutabilité des transactions AJUSTEMENT

**Decision**: Guards dans `TransactionService.update()` et `delete()` + vérification du type.

**Rationale**: Le pattern existe déjà pour les virements (cascade delete via `transferId`). Ajouter un guard `if (type == AJUSTEMENT) throw 403` au début de update/delete est cohérent et minimal.

**Alternatives considered**:
- Annotation custom `@Immutable` → over-engineering
- Flag booléen sur Transaction → colonne supplémentaire inutile quand le type suffit

## R6 — Catégorie système "Ajustement" — création lazy

**Decision**: `CategoryService.findOrCreateAdjustmentCategory(UUID userId)` — lookup puis création si absente.

**Rationale**: Pattern similaire à `findSystemCategoryByNom()` existant. La création lazy évite une migration Flyway et fonctionne même pour les utilisateurs créés avant cette feature.

**Alternatives considered**:
- Ajout dans `seedSystemCategories()` uniquement → ne couvre pas les users existants
- Migration Flyway V9 → contredit la spec, rigide

## R7 — Résumé mensuel (MonthlySummary)

**Decision**: Les transactions AJUSTEMENT ne comptent ni dans `totalRecettes` ni dans `totalDepenses`. Elles impactent le `solde` du résumé.

**Rationale**: Un ajustement corrige un écart, ce n'est ni une recette ni une dépense. L'inclure dans l'un des deux fausserait les statistiques. Le solde mensuel doit refléter la réalité : `recettes - dépenses + ajustements`.

**Alternatives considered**:
- Inclure dans recettes/dépenses selon signe → fausse les stats
- Exclure complètement du résumé → le solde ne reflèterait plus la réalité

## R8 — UX : point d'entrée dans le formulaire d'édition de compte

**Decision**: Ajouter un champ "Solde actuel" (lecture seule) + champ "Nouveau solde" (éditable) dans le formulaire d'édition de compte Angular existant.

**Rationale**: La spec exige que l'ajustement se fasse via le formulaire d'édition (FR-009). Le solde actuel est déjà disponible via `AccountResponse.solde`. L'ajout de deux champs dans le formulaire existant est minimal.

**Alternatives considered**:
- Écran dédié "Ajuster le solde" → navigation supplémentaire, plus de 3 interactions
- Bottom-sheet séparé → complexité UI non justifiée
