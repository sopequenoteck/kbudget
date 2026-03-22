# Data Model: Feature Toggles Angular

**Branch**: `064-angular-feature-toggles` | **Date**: 2026-03-01

## Entities

### Feature (enum)

Miroir client du `Feature` enum backend. 3 valeurs fixes.

| Value | Label | Icon | Description |
|-------|-------|------|-------------|
| `SUBSCRIPTIONS` | Abonnements | 🔄 | Gérer vos abonnements récurrents |
| `DEBTS` | Dettes | 🤝 | Suivre vos prêts et emprunts |
| `SHOP` | Boutique | 🏪 | Gérer vos ventes de produits |

Chaque valeur porte : `label`, `icon` (emoji, cohérent avec le reste de l'app), `description`, `route` (chemin sidebar associé).

> **Note** : Le backend crée les préférences par défaut avec les 3 features activées (`SUBSCRIPTIONS`, `DEBTS`, `SHOP`). Le champ `defaultEnabled` n'existe pas côté client — l'état réel provient toujours de l'API.

### UserPreference (interface)

Représentation côté client de la réponse API `GET /users/me/preferences`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `enabledFeatures` | `Feature[]` | oui | Features activées par l'utilisateur |
| `navOrder` | `Feature[]` | oui | Ordre d'affichage dans la navigation |
| `shopAccountId` | `string \| null` | non | UUID du compte boutique |
| `includeShopInBalance` | `boolean` | oui | Inclure boutique dans le solde global |

### UserPreferenceRequest (interface)

Corps du `PUT /users/me/preferences`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `enabledFeatures` | `Feature[]` | oui | Features activées |
| `navOrder` | `Feature[]` | non | Ordre de navigation (auto-calculé si absent) |
| `shopAccountId` | `string \| null` | non | UUID du compte boutique |
| `includeShopInBalance` | `boolean \| null` | non | Inclure boutique dans le solde |

## Relationships

```
User 1──1 UserPreference
UserPreference ──* Feature (enabledFeatures: array)
UserPreference ──* Feature (navOrder: array)
UserPreference ──? Account (shopAccountId: FK nullable)
```

## State Transitions

### Feature toggle lifecycle

```
[Page load] → GET /users/me/preferences → signal(enabledFeatures, navOrder)
     │
     ▼
[User toggles feature]
     │
     ├─ Has data? → Confirmation dialog → Confirmed? → Continue / Abort
     │
     ▼
[Optimistic update] → signal updated → sidebar + FAB react
     │
     ▼
[PUT /users/me/preferences] → fire-and-forget
     │
     ├─ Success → no action (already updated)
     └─ Error → show error message (state may diverge until next load)
```

## Validation Rules

- `enabledFeatures` : valeurs doivent être dans l'enum `Feature` (`SUBSCRIPTIONS`, `DEBTS`, `SHOP`)
- `navOrder` (si fourni) : doit contenir exactement les mêmes features qu'`enabledFeatures`, sans doublon
- `navOrder` (si absent) : le backend auto-gère (conserve l'ordre existant, ajoute les nouvelles en fin)
- `shopAccountId` : validé côté backend uniquement (doit exister et appartenir à l'utilisateur)
