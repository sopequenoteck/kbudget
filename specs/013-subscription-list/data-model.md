# Data Model: Écran Subscriptions (liste + filtre actif)

**Feature**: 013-subscription-list
**Date**: 2026-02-12

## Entités existantes (pas de modification)

### Subscription

| Attribut | Type | Requis | Description |
|----------|------|--------|-------------|
| id | string (UUID) | oui | Identifiant unique |
| nom | string | oui | Nom de l'abonnement |
| montant | number | oui | Montant de l'abonnement |
| frequence | Frequency | oui | MENSUEL ou ANNUEL |
| dateDebut | string (ISO date) | oui | Date de début/première échéance |
| actif | boolean | oui | Statut actif/inactif |
| category | Category \| null | non | Catégorie optionnelle |

### Category

| Attribut | Type | Requis | Description |
|----------|------|--------|-------------|
| id | string (UUID) | oui | Identifiant unique |
| nom | string | oui | Nom de la catégorie |
| icone | string | oui | Emoji de la catégorie |
| couleur | string | oui | Couleur hex |

### Frequency (enum)

| Valeur | Description |
|--------|-------------|
| MENSUEL | Abonnement mensuel |
| ANNUEL | Abonnement annuel |

## State Model (composant Subscriptions)

### Signals

| Signal | Type | Valeur initiale | Description |
|--------|------|-----------------|-------------|
| statusFilter | `'ALL' \| 'ACTIF' \| 'INACTIF'` | `'ALL'` | Filtre actif sélectionné |
| loading | boolean | true | Chargement en cours |
| error | boolean | false | Erreur de chargement |
| subscriptions | Subscription[] | [] | Liste des abonnements chargés |

### Computed Signals

| Computed | Type | Dérivé de | Description |
|----------|------|-----------|-------------|
| sortedSubscriptions | Subscription[] | subscriptions | Tri alphabétique par nom |
| monthlyTotal | number | subscriptions | Total mensuel des abonnements actifs (annuels / 12) |

### Relations

```
Subscriptions (composant)
  └── SubscriptionService.getAll(actif?)  →  API GET /subscriptions
  └── SubscriptionService.refreshTrigger  →  Recharge auto après CRUD
  └── ListItem (composant partagé)        →  Affichage de chaque abonnement
  └── AmountPipe                          →  Formatage montant EUR (pour le total)
```

## Pas de nouvelles entités

Cette feature ne crée aucune nouvelle entité, aucune migration, aucun DTO. Elle consomme les données existantes via le SubscriptionService.
