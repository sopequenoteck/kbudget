# Data Model: Ajustement de solde

**Feature**: 032-balance-adjustment
**Date**: 2026-02-19

## Entités impactées

### Transaction (modification)

Entité existante — ajout d'une valeur à l'enum `TransactionType`.

| Champ | Type | Changement | Notes |
|-------|------|------------|-------|
| `type` | `TransactionType` | **Modifié** | Ajout valeur `AJUSTEMENT` |
| `montant` | `BigDecimal` | **Sémantique modifiée** | Signé (+/-) pour type AJUSTEMENT ; toujours positif pour DEPENSE/RECETTE |

#### TransactionType (enum)

```
DEPENSE    — montant toujours positif, déduit du solde
RECETTE    — montant toujours positif, ajouté au solde
AJUSTEMENT — montant signé (+/-), ajouté directement au solde (NOUVEAU)
```

#### Règles de validation pour AJUSTEMENT

- `montant` : peut être positif, négatif ou zéro (pas de contrainte `@Positive`)
- `libelle` : toujours `"Ajustement de solde"` (fixé par le système)
- `category` : toujours la catégorie système "Ajustement"
- `date` : date du jour (fixée par le système)
- `account` : obligatoire (le compte ajusté)
- `transferId` : toujours `null`
- `note` : `null`

#### Contraintes d'immutabilité

- Les transactions de type `AJUSTEMENT` **ne peuvent pas** être modifiées (HTTP 403)
- Les transactions de type `AJUSTEMENT` **ne peuvent pas** être supprimées (HTTP 403)

### Category "Ajustement" (création lazy)

Nouvelle catégorie système, créée à la demande lors du premier ajustement de chaque utilisateur.

| Champ | Valeur |
|-------|--------|
| `nom` | `"Ajustement"` |
| `icone` | `"⚖️"` (U+2696 balance) |
| `couleur` | `"#6b7280"` (gray-500, neutre) |
| `isSystem` | `true` |
| `user` | FK vers l'utilisateur courant |

#### Cycle de vie

1. Premier appel `POST /accounts/{id}/adjust-balance` pour un utilisateur
2. `CategoryService.findSystemCategoryByNom("Ajustement", userId)` retourne `null`
3. Création automatique de la catégorie avec les valeurs ci-dessus
4. Appels suivants : la catégorie est réutilisée

## Formule de calcul du solde

### Avant (actuel)

```sql
solde = soldeInitial + SUM(
  CASE WHEN type = 'RECETTE' THEN montant ELSE -montant END
)
```

### Après (avec AJUSTEMENT)

```sql
solde = soldeInitial + SUM(
  CASE
    WHEN type = 'RECETTE' THEN montant
    WHEN type = 'AJUSTEMENT' THEN montant
    ELSE -montant
  END
)
```

## Résumé mensuel (MonthlySummary)

### Impact sur le calcul

| Champ | DEPENSE | RECETTE | AJUSTEMENT |
|-------|---------|---------|------------|
| `totalRecettes` | — | +montant | — |
| `totalDepenses` | +montant | — | — |
| `solde` | -montant | +montant | +montant (signé) |

## Aucune migration Flyway requise

- `transactions.type` est `VARCHAR(50)` — pas de contrainte CHECK
- `transactions.montant` est `NUMERIC(19,2)` — supporte les négatifs
- La catégorie "Ajustement" est créée lazy en Java
