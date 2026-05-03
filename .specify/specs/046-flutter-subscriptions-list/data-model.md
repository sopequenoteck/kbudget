# Data Model: Flutter — Écran Abonnements Liste

**Date**: 2026-02-23 | **Branch**: `046-flutter-subscriptions-list`

## Entités existantes (aucune modification)

### Subscription (Freezed)

| Champ | Type | Description |
|-------|------|-------------|
| id | String | Identifiant unique |
| nom | String | Nom de l'abonnement |
| montant | double | Montant |
| frequence | Frequency | mensuel / annuel |
| dateDebut | DateTime | Date de début |
| currency | Currency | Devise (défaut: EUR) |
| actif | bool | Statut actif/inactif (défaut: true) |
| categoryId | String? | FK vers Category |
| accountId | String? | FK vers Account |
| updatedAt | DateTime? | Date dernière modification |

### Category (Freezed)

| Champ | Type | Description |
|-------|------|-------------|
| id | String | Identifiant unique |
| nom | String | Nom de la catégorie |
| icon | String | Emoji icône |
| color | String | Code couleur hex |

## Nouveaux modèles

### SubscriptionListState (Freezed — à créer)

| Champ | Type | Description |
|-------|------|-------------|
| items | List\<Subscription\> | Items filtrés paginés (affichés) |
| isLoading | bool | Chargement en cours |
| error | String? | Message d'erreur |
| activeFilter | SubscriptionStatusFilter | Filtre actif (défaut: all) |
| monthlyTotals | Map\<Currency, double\> | Total mensuel par devise (actifs uniquement) |
| currentPage | int | Page courante (pagination client) |
| hasMore | bool | Items restants à paginer |
| mutatingIds | Set\<String\> | IDs en cours de mutation (optimistic UI) |

### SubscriptionStatusFilter (enum — à créer)

| Valeur | Description |
|--------|-------------|
| all | Tous les abonnements |
| actif | Abonnements actifs uniquement |
| inactif | Abonnements inactifs uniquement |

## Valeurs dérivées (calculées, non persistées)

### Prochaine date de renouvellement

**Fonction** : `nextRenewalDate(DateTime dateDebut, Frequency frequence) → DateTime`

**Algorithme** :
1. `nextDate = dateDebut`
2. Tant que `nextDate <= today` :
   - Si `frequence == mensuel` : avancer de 1 mois
   - Si `frequence == annuel` : avancer de 1 an
3. Retourner `nextDate`

**Cas limites** :
- `dateDebut` dans le futur → retourner `dateDebut` directement
- Débordement de jour (ex: 31 janvier + 1 mois = 28/29 février) → géré nativement par `DateTime(y, m+1, d)`

### Total mensuel par devise

**Algorithme** :
1. Filtrer les abonnements actifs (`actif == true`)
2. Grouper par `currency`
3. Pour chaque groupe : `sum(montant si mensuel, montant/12 si annuel)`
4. Retourner `Map<Currency, double>`

## Relations

```
SubscriptionNotifier
  ├── state: SubscriptionListState
  │   ├── items: List<Subscription> (filtrés + paginés)
  │   ├── activeFilter: SubscriptionStatusFilter
  │   └── monthlyTotals: Map<Currency, double>
  └── _allItems: List<Subscription> (tous, non filtrés, interne)
       ├── → filtré par activeFilter → items
       └── → filtré par actif → monthlyTotals
```
