# Data Model: 053-flutter-settings-accounts

**Date**: 2026-02-23

## Entités

### Account (existant — `domain/models/account.dart`)

Modèle Freezed existant, aucune modification nécessaire.

| Champ | Type | Requis | Défaut | Description |
|-------|------|--------|--------|-------------|
| id | String | oui | - | UUID |
| nom | String | oui | - | Nom du compte (1-50 car.) |
| type | AccountType | oui | - | courant / epargne / especes |
| soldeInitial | double | oui | 0 | Solde à la création |
| solde | double | non | 0 | Solde courant (calculé par le serveur) |
| icone | String | oui | - | Emoji (ex: 🏦) |
| couleur | String | oui | - | Hex (#RRGGBB) |
| isDefault | bool | non | false | Compte par défaut |
| actif | bool | non | true | Actif / inactif |
| currency | Currency | non | eur | Devise du compte |
| updatedAt | DateTime? | non | null | Dernier update |

**Règles d'unicité** : `nom` unique par utilisateur (case-insensitive, comptes actifs uniquement).

**Contraintes d'état** :
- Un seul `isDefault = true` par utilisateur
- Le compte par défaut ne peut pas avoir `actif = false`
- `type` et `currency` sont immutables après création

### AccountType (existant — `domain/enums/account_type.dart`)

| Valeur | Icône défaut | Couleur défaut |
|--------|-------------|----------------|
| courant | 🏦 | #3b82f6 |
| epargne | 🐷 | #22c55e |
| especes | 💵 | #f59e0b |

### AdjustBalanceRequest (nouveau DTO)

| Champ | Type | Description |
|-------|------|-------------|
| newBalance | double | Nouveau solde souhaité |

## Relations

```
User (1) ──── (N) Account
Account (1) ──── (N) Transaction
Account (1) ──── (N) Subscription (optionnel)
```

## Transitions d'état

```
             create
  ∅ ─────────────────► ACTIF (actif=true)
                          │
                ┌─────────┴─────────┐
                │                   │
            setDefault          désactiver
                │                   │ (si non-défaut)
                ▼                   ▼
         ACTIF+DÉFAUT           INACTIF (actif=false)
                │                   │
                │              réactiver
                │                   │
                └─────────┬─────────┘
                          │
                       delete
                          │ (si pas de transactions/abonnements liés)
                          ▼
                          ∅
```
