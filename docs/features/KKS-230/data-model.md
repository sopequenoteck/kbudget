# Data Model — KKS-230

**Date** : 2026-04-13
**Feature** : Autocomplete sur le champ libellé de saisie des transactions

## Résumé

**Aucune nouvelle entité, aucune nouvelle colonne, aucun nouvel index.** La feature exploite exclusivement des lignes de la table `transactions` existante via une requête d'agrégation `GROUP BY libelle`. Seule évolution du schéma : activation d'une extension PostgreSQL.

## Entités impliquées

### `Transaction` (existante, inchangée)

Fichier : `api/src/main/java/fr/kksdev/budget/api/model/Transaction.java`

Champs pertinents pour la feature :

| Champ | Type Java | Colonne SQL | Contraintes |
|-------|-----------|-------------|-------------|
| `id` | `UUID` | `id` | PK |
| `libelle` | `String` | `libelle` | `NOT NULL`, `varchar(255)` par défaut |
| `date` | `LocalDate` | `date` | `NOT NULL` |
| `user` | `User` (LAZY) | `user_id` | `NOT NULL`, FK `users(id)` |

> ⚠️ La spec mentionne « label » — le champ réel est `libelle`. Toute référence à « label » dans le code de la feature doit être lue comme `libelle` (voir R1 dans `research.md`).

### `User` (existante, inchangée)

Le filtre d'isolation (constitution #2, FR-005) s'appuie sur `Authentication.getPrincipal()` → `UUID userId` → clause `WHERE t.user_id = :userId` dans la native query.

## Relations

Inchangées. La feature n'introduit aucune relation, aucun join supplémentaire au-delà du filtre `user_id` déjà indexé.

## Contraintes & index

### Existants (réutilisés)

- `idx_transactions_user_id` sur `transactions(user_id)` — défini dans `V1__init_schema.sql:43`. Suffisant pour cadrer le scan à ~10k lignes max / user.
- PK `id` (UUID).
- FK `user_id` → `users(id)`.

### Nouveaux

**Aucun nouvel index en v1.** Plan de contingence documenté dans `research.md` R4 :

1. Si NFR-001 (< 100ms) non tenu → index composite `(user_id, libelle)`.
2. Si filtre `contains` reste lent à plus grande échelle → index GIN `pg_trgm` sur `LOWER(UNACCENT(libelle))`.

## Évolutions de schéma

### V27 (ou prochain disponible) — activation extension `unaccent`

Fichier : `api/src/main/resources/db/migration/V27__enable_unaccent_extension.sql`

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
```

- Idempotent (`IF NOT EXISTS`).
- Aucune donnée modifiée, aucune table impactée.
- `unaccent` fait partie de `postgresql-contrib` (standard). Disponible sur tous les Postgres managés (RDS, Supabase, Neon) et self-hosted via le paquet contrib. Constitution #7 respectée.

### Aucune autre migration

- Pas de `CREATE TABLE`.
- Pas de `ALTER TABLE`.
- Pas de `CREATE INDEX`.
- Pas de nouvelle colonne sur `transactions`.

## Requête principale

Native query déclarée sur `TransactionRepository` (voir `plan.md` section Backend) :

```sql
SELECT t.libelle
FROM transactions t
WHERE t.user_id = :userId
  AND (:q IS NULL OR LOWER(UNACCENT(t.libelle)) LIKE '%' || LOWER(UNACCENT(CAST(:q AS TEXT))) || '%')
GROUP BY t.libelle
ORDER BY COUNT(*) DESC, MAX(t.date) DESC
LIMIT :limit
```

- Retour : `List<String>`.
- Couvre FR-002, FR-003, FR-004, FR-005, FR-017.
- La casse d'origine du `libelle` est préservée (seules les comparaisons sont normalisées).

## Impact sur le modèle Drift (Flutter)

Aucun. La requête équivalente côté local :

```sql
SELECT libelle FROM transactions
WHERE user_id = ?
GROUP BY libelle
ORDER BY COUNT(*) DESC, MAX(date) DESC
LIMIT ?
```

Le filtre accent-insensible s'applique en Dart sur le résultat (SQLite embarqué n'a pas `unaccent`).

## Ce qui N'EST PAS modélisé (rappel YAGNI)

- ❌ Entité `Merchant` / `Payee` / `Label`
- ❌ Table `transaction_labels` agrégée
- ❌ Colonne `libelle_normalized` dénormalisée
- ❌ Vue matérialisée `libelles_par_user`

Voir `research.md` section « Alternatives rejetées » pour le rationale.
