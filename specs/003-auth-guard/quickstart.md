# Quickstart: Guard d'authentification

**Feature**: 003-auth-guard | **Date**: 2026-02-08

## Fichiers à créer

| Fichier | Description |
|---------|-------------|
| `app/src/app/core/guards/auth.guard.ts` | Guard fonctionnel `CanActivateFn` |
| `app/src/app/core/guards/auth.guard.spec.ts` | Tests unitaires du guard |

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `app/src/app/app.routes.ts` | Ajouter `canActivate: [authGuard]` sur les routes protégées (dashboard, transactions, subscriptions, debts) |

## Implémentation du guard

Le guard est une fonction exportée qui :
1. Injecte `AuthService` et `Router` via `inject()`
2. Vérifie `authService.isAuthenticated()`
3. Si authentifié : retourne `true`
4. Si non authentifié : redirige vers `/auth` avec `returnUrl` en query param et retourne `false`

### Validation du returnUrl

Le `returnUrl` passé en query parameter doit :
- Commencer par `/` (route relative)
- Ne pas être une URL absolue (`http://`, `https://`, `//`)

## Application sur les routes

Routes protégées (avec guard) :
- `/dashboard`
- `/transactions`
- `/subscriptions`
- `/debts`
- `/**` (wildcard)

Routes publiques (sans guard) :
- `/auth` et sous-routes

## Tests à couvrir

1. Utilisateur authentifié → accès autorisé (retourne `true`)
2. Utilisateur non authentifié → redirection vers `/auth`
3. returnUrl correctement passé en query param
4. URL externe dans returnUrl → ignorée / redirigée vers `/dashboard`
5. Token expiré → traité comme non authentifié (via AuthService)

## Commandes

```bash
# Lancer les tests
cd app && npx vitest run

# Lancer le dev server pour tester manuellement
cd app && ng serve
```

## Séquence de build

1. Créer `auth.guard.ts`
2. Écrire les tests `auth.guard.spec.ts`
3. Modifier `app.routes.ts` pour appliquer le guard
4. Vérifier que les tests passent
5. Tester manuellement la redirection
