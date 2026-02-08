# Quickstart: Intercepteur HTTP JWT

**Feature**: 004-jwt-interceptor
**Date**: 2026-02-08

## Prérequis

- Node.js installé
- Dépendances du projet installées (`cd app && npm install`)
- AuthService existant dans `app/src/app/core/services/auth.ts`

## Fichiers à créer

| Fichier | Description |
|---------|-------------|
| `app/src/app/core/interceptors/auth.interceptor.ts` | Intercepteur HTTP fonctionnel |
| `app/src/app/core/interceptors/auth.interceptor.spec.ts` | Tests unitaires |

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `app/src/app/app.config.ts` | Ajouter `withInterceptors([authInterceptor])` dans `provideHttpClient()` |

## Vérification rapide

```bash
# Lancer les tests
cd app && npx vitest run

# Vérifier le lint
cd app && npx ng lint
```

## Points d'attention

1. L'intercepteur doit utiliser `inject()` (pas de constructor injection)
2. L'intercepteur doit être une fonction exportée (`HttpInterceptorFn`)
3. Ne pas modifier `AuthService` — réutiliser `getToken()` et `logout()`
4. Les routes publiques à exclure : `/auth/login`, `/auth/register`
5. Le token ne doit jamais être envoyé vers des URL absolues externes
