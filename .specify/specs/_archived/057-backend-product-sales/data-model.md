# Data Model: 057-backend-product-sales

**Date**: 2026-02-28

## Entites modifiees

### Transaction (enrichie)

Ajout d'un champ nullable pour lier une transaction a un produit source.

| Champ | Type | Nullable | Contrainte | Description |
|-------|------|----------|------------|-------------|
| `product` | `Product` (`@ManyToOne LAZY`) | oui | FK `product_id` → `products(id)` SET NULL ON DELETE | Produit source (vente/restock) |

**Regles**:
- `product_id` est `NULL` pour toutes les transactions classiques (manuelles, abonnements, dettes, virements)
- `product_id` est renseigne uniquement pour les transactions auto-generees par vente ou restock
- Si le produit est supprime, `product_id` passe a `NULL` (SET NULL)

### UserPreference (enrichie)

Ajout de deux champs pour la gestion du compte boutique.

| Champ | Type | Nullable | Default | Contrainte | Description |
|-------|------|----------|---------|------------|-------------|
| `shopAccountId` | `UUID` | oui | `NULL` | FK → `accounts(id)` SET NULL ON DELETE | Compte utilise pour les transactions boutique |
| `includeShopInBalance` | `Boolean` | non | `false` | - | Inclure le compte boutique dans le solde total |

**Regles**:
- `shopAccountId = NULL` signifie qu'aucun compte boutique n'est configure → creation lazy a la premiere operation
- Si le compte reference par `shopAccountId` est supprime, la valeur passe a `NULL` (SET NULL) → le prochain appel recree un compte
- `includeShopInBalance = false` par defaut : le solde boutique est separe

### AccountResponse (enrichi)

Ajout d'un flag dans le DTO de reponse.

| Champ | Type | Description |
|-------|------|-------------|
| `isShopAccount` | `boolean` | `true` si ce compte est le compte boutique de l'utilisateur |

### TransactionResponse (enrichi)

Ajout du lien produit dans le DTO de reponse.

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| `productId` | `UUID` | oui | ID du produit source (si transaction auto-generee) |
| `productName` | `String` | oui | Nom du produit au moment de la consultation |

## Migration Flyway V11

```sql
-- V11__add_shop_support.sql

-- 1. Categorie systeme "Boutique" pour chaque utilisateur existant
INSERT INTO categories (id, nom, icone, couleur, is_system, user_id)
SELECT gen_random_uuid(), 'Boutique', '🛍️', '#f59e0b', true, id
FROM users;

-- 2. FK product_id sur transactions
ALTER TABLE transactions ADD COLUMN product_id UUID;
ALTER TABLE transactions ADD CONSTRAINT fk_transaction_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL;
CREATE INDEX idx_transactions_product_id ON transactions(product_id);

-- 3. Preferences boutique sur user_preferences
ALTER TABLE user_preferences ADD COLUMN shop_account_id UUID;
ALTER TABLE user_preferences ADD COLUMN include_shop_in_balance BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE user_preferences ADD CONSTRAINT fk_preference_shop_account
    FOREIGN KEY (shop_account_id) REFERENCES accounts(id) ON DELETE SET NULL;
```

## Etats et transitions

### Cycle de vie produit (operations boutique)

```
[Produit cree]
    │
    ├── actif = true, stock > 0  ──→ VENTE possible
    │       │                           │
    │       │                           ├── stock -= 1
    │       │                           ├── totalVendu += 1
    │       │                           └── Transaction RECETTE creee (productId set)
    │       │
    │       └── stock = 0          ──→ VENTE refusee (409 Conflict)
    │
    ├── actif = true               ──→ RESTOCK possible
    │       │                           │
    │       │                           ├── stock += N
    │       │                           └── Transaction DEPENSE creee (productId set)
    │       │
    │       └── SUPPRESSION Transaction (productId != null)
    │               │
    │               ├── Type RECETTE : stock += 1, totalVendu -= 1
    │               └── Type DEPENSE : stock -= N (N = montant / prixAchat)
    │
    └── actif = false              ──→ VENTE et RESTOCK refuses
```

### Creation lazy du compte Boutique

```
[Premiere operation boutique]
    │
    ├── shopAccountId != null  ──→ Utiliser le compte existant
    │
    └── shopAccountId == null  ──→ Creer compte "Boutique"
            │                       (type COURANT, icone 🛍️, couleur #f59e0b)
            │
            └── Sauvegarder shopAccountId dans UserPreference
```
