# Quickstart: Frontend Refresh Token

**Feature**: 024-frontend-refresh-token
**Date**: 2026-02-13

## Prérequis

- Backend lancé avec les endpoints `/auth/refresh` et `/auth/logout` disponibles (feature KKS-73 backend, commit `5793e8f`)
- Node.js + Angular CLI installés
- Un compte utilisateur existant dans la base de données

## Fichiers à modifier

| Fichier | Changement |
|---------|------------|
| `app/src/app/core/models/auth.model.ts` | Ajouter `refreshToken` à `AuthResponse` |
| `app/src/app/core/services/auth.ts` | Stocker/récupérer le refresh token, ajouter `refreshToken()`, modifier `logout()` et `restoreSession()` |
| `app/src/app/core/interceptors/auth.interceptor.ts` | Ajouter logique de refresh sur 401, sérialisation avec BehaviorSubject |
| `app/src/app/core/services/auth.spec.ts` | Nouveaux tests pour refresh token storage, logout API, restore session |
| `app/src/app/core/interceptors/auth.interceptor.spec.ts` | Nouveaux tests pour refresh sur 401, sérialisation, anti-boucle |

## Ordre d'implémentation

1. **Modèle** : `auth.model.ts` — ajouter le champ `refreshToken`
2. **Service** : `auth.ts` — modifier `saveAuth()`, `clearAuth()`, `getRefreshToken()`, `logout()`, `restoreSession()`
3. **Intercepteur** : `auth.interceptor.ts` — logique refresh + sérialisation
4. **Tests service** : `auth.spec.ts` — couvrir les nouveaux comportements
5. **Tests intercepteur** : `auth.interceptor.spec.ts` — couvrir refresh, sérialisation, anti-boucle

## Vérification rapide

```bash
# Lancer les tests
cd app && npx vitest run

# Lancer le serveur de dev
cd app && ng serve

# Tester manuellement :
# 1. Se connecter → vérifier budget_refresh_token dans localStorage (DevTools > Application)
# 2. Supprimer manuellement budget_token dans localStorage
# 3. Naviguer dans l'app → le token doit se renouveler automatiquement
# 4. Se déconnecter → vérifier que les deux tokens sont supprimés du localStorage
```

## Points d'attention

- L'intercepteur doit exclure `/auth/refresh` des requêtes interceptées (sinon boucle infinie)
- Le logout doit être fire-and-forget (ne pas bloquer la redirection si le serveur est down)
- `restoreSession()` est appelé dans le constructor d'AuthService — le refresh au démarrage est asynchrone, il faut gérer le cas où l'app démarre avant que le refresh ne soit terminé
