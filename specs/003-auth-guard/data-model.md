# Data Model: Guard d'authentification

**Feature**: 003-auth-guard | **Date**: 2026-02-08

## Entités

Cette feature n'introduit aucune nouvelle entité de données. Le guard est une fonction pure qui interroge l'état existant.

## Dépendances de données existantes

### AuthService (existant, non modifié)

| Propriété/Méthode | Type | Usage par le guard |
|-------------------|------|-------------------|
| `isAuthenticated` | `Signal<boolean>` (computed) | Vérifier si l'utilisateur a une session active |
| `currentUser` | `Signal<UserInfo \| null>` | Non utilisé directement par le guard |

### Route State

| Donnée | Source | Usage |
|--------|--------|-------|
| `state.url` | `RouterStateSnapshot` | URL demandée, devient le `returnUrl` |
| `returnUrl` | Query parameter sur `/auth` | Lu par le composant login (KKS-28) après connexion |

## Flux de données

```
Navigation vers route protégée
    │
    ▼
Guard vérifie AuthService.isAuthenticated()
    │
    ├── true → Accès autorisé (retourne true)
    │
    └── false → Redirige vers /auth?returnUrl={url demandée}
                  │
                  ▼
              Login (KKS-28, futur) lit returnUrl
              et redirige après connexion réussie
```
