# Data Model: 065-angular-data-settings

**Date**: 2026-03-01

## Entites

Cette feature ne cree aucune entite persistante. Les donnees sont ephemeres (etat en memoire uniquement).

### HealthCheckResult (type frontend)

Represente le resultat d'un test de connectivite serveur.

| Champ | Type | Description |
|-------|------|-------------|
| status | `'online' \| 'offline' \| 'checking'` | Etat de connexion |
| responseTimeMs | `number \| null` | Temps de reponse en millisecondes (null si offline ou checking) |
| error | `string \| null` | Message d'erreur (null si online ou checking) |
| checkedAt | `Date \| null` | Horodatage du dernier test (null si jamais teste) |

**Transitions d'etat** :

```
[initial] → checking → online (succes)
                     → offline (echec)
online → checking → online | offline
offline → checking → online | offline
```

### ServerInfo (type frontend)

Informations statiques sur la configuration serveur.

| Champ | Type | Description |
|-------|------|-------------|
| apiUrl | `string` | URL complete du serveur API (ex: `https://budget.kksdev.fr/api`) |
| environment | `string` | Environnement (`production` ou `development`) |

**Source** : Derive au runtime de `window.location.origin + environment.apiUrl` et `environment.production`.

## Relations

Aucune relation avec les entites existantes du domaine. Le `HealthService` est un service autonome sans dependance sur les services metier (Transaction, Account, etc.).

## Regles de validation

- `responseTimeMs` : >= 0, affiche uniquement si `status === 'online'`
- `error` : affiche uniquement si `status === 'offline'`
- `apiUrl` : lecture seule, non modifiable par l'utilisateur
