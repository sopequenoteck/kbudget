# Data Model: Système de Feature Toggles — Backend

**Branch**: `055-backend-feature-toggles` | **Date**: 2026-02-27

## Entités

### Feature (enum)

Ensemble fermé des fonctionnalités optionnelles.

| Valeur | Description |
|--------|-------------|
| `SUBSCRIPTIONS` | Abonnements |
| `DEBTS` | Dettes |
| `SHOP` | Boutique |

**Note** : Dashboard et Transactions ne sont PAS dans cet enum — ils sont toujours actifs.

### UserPreference (entité)

Préférences de personnalisation d'un utilisateur.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK, auto-generated | Identifiant unique |
| `user` | User | FK unique, non-null | Relation 1:1 vers User |
| `enabledFeatures` | List\<Feature\> | non-null | Features optionnelles activées (stocké en VARCHAR via converter) |
| `navOrder` | List\<Feature\> | non-null | Ordre des onglets de navigation (stocké en VARCHAR via converter, préserve l'ordre) |
| `updatedAt` | LocalDateTime | auto-updated | Date de dernière modification |

**Relation** : `UserPreference` ↔ `User` = One-to-One (chaque user a exactement une préférence).

## Schéma SQL (migration V9)

```sql
CREATE TABLE user_preferences (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    enabled_features VARCHAR(255) NOT NULL DEFAULT 'SUBSCRIPTIONS,DEBTS,SHOP',
    nav_order        VARCHAR(255) NOT NULL DEFAULT 'SUBSCRIPTIONS,DEBTS,SHOP',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialisation pour les utilisateurs existants
INSERT INTO user_preferences (id, user_id, enabled_features, nav_order)
SELECT gen_random_uuid(), id, 'SUBSCRIPTIONS,DEBTS,SHOP', 'SUBSCRIPTIONS,DEBTS,SHOP'
FROM users;
```

## Règles de validation

### enabledFeatures
- Doit être une liste de valeurs de l'enum Feature (SUBSCRIPTIONS, DEBTS, SHOP)
- Peut être vide (toutes les features optionnelles désactivées)
- Pas de doublons
- Toute valeur inconnue → erreur 400

### navOrder
- Doit contenir exactement les features présentes dans enabledFeatures (ni plus, ni moins)
- Pas de doublons
- L'ordre est significatif (premier élément = premier onglet)
- Quand navOrder est auto-géré (non fourni dans la requête PUT) :
  - Les features désactivées sont retirées
  - Les features nouvellement activées sont ajoutées en dernière position

## Converter JPA

`FeatureListConverter` : `AttributeConverter<List<Feature>, String>`
- Base → Java : split sur `,`, map vers `Feature.valueOf()`, filtre les vides
- Java → Base : join avec `,` des `name()` de chaque enum
- Colonne vide ou null → liste vide
