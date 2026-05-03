# Research: Intercepteur HTTP JWT

**Feature**: 004-jwt-interceptor
**Date**: 2026-02-08

## R1: Pattern d'intercepteur fonctionnel Angular 17+

**Decision**: Utiliser `HttpInterceptorFn` (functional interceptor) avec `inject()` pour accéder aux services.

**Rationale**: Angular 17+ recommande les intercepteurs fonctionnels plutôt que les intercepteurs basés sur des classes. Le pattern est plus simple, aligné avec la directive signals-first du projet, et s'enregistre via `withInterceptors()` dans `provideHttpClient()`.

**Alternatives considered**:
- Intercepteur class-based (`HttpInterceptor` interface) : déprécié dans Angular 17+, nécessite un provider supplémentaire.
- Middleware custom dans `ApiService` : viole le principe de séparation des responsabilités et nécessiterait de modifier chaque méthode HTTP.

## R2: Stratégie d'exclusion des routes publiques

**Decision**: Vérifier si l'URL de la requête contient `/auth/login` ou `/auth/register` avant d'injecter le token.

**Rationale**: L'API utilise le context path `/api` et les routes publiques sont `/api/auth/login` et `/api/auth/register`. Comme `ApiService` construit les URL avec `environment.apiUrl` (qui vaut `/api`), les URL finales seront `/api/auth/login` et `/api/auth/register`. Une vérification par `url.includes()` sur les chemins suffixés est simple et fiable.

**Alternatives considered**:
- Whitelist d'URL complètes : trop rigide, casse si l'URL de base change.
- Regex pattern matching : over-engineering pour 2 routes fixes.
- Décorateur/metadata sur les requêtes : complexité inutile.

## R3: Gestion des réponses 401

**Decision**: Intercepter les erreurs `HttpErrorResponse` avec status 401 dans le pipe `catchError` de la réponse. Appeler `AuthService.logout()` qui gère déjà la suppression du token et la redirection vers `/auth`.

**Rationale**: `AuthService.logout()` est déjà implémenté et fait exactement ce qu'il faut : supprime le token du localStorage, remet `currentUser` à null, et navigue vers `/auth`. Réutiliser cette méthode évite la duplication.

**Alternatives considered**:
- Gérer la déconnexion directement dans l'intercepteur : duplique la logique existante de `AuthService.logout()`.
- Émettre un événement/signal et laisser un autre composant réagir : complexité inutile pour un use case simple.

## R4: Protection contre les domaines tiers

**Decision**: Vérifier que l'URL de la requête commence par l'`apiUrl` configurée (relative `/api`) ou par un slash (requête relative). Ne pas injecter le token sur les URL absolues vers d'autres domaines.

**Rationale**: Comme toutes les requêtes API passent par `ApiService` qui préfixe avec `environment.apiUrl` (= `/api`), les URL sont relatives au domaine courant. Les URL absolues (commençant par `http://` ou `https://`) vers des domaines tiers ne doivent pas recevoir le token.

**Alternatives considered**:
- Comparer avec `window.location.origin` : plus complexe et fragile avec le proxy dev.
- Ne rien vérifier (toujours injecter) : risque de sécurité si une bibliothèque tierce fait des requêtes HTTP.

## R5: Gestion des 401 simultanés

**Decision**: Utiliser un flag booléen simple pour éviter les appels multiples à `logout()` lors de réponses 401 concurrentes. Le flag est réinitialisé après la redirection.

**Rationale**: Dans une app single-user avec ~10 endpoints, le scénario de 401 multiples simultanés est rare mais possible (ex: dashboard chargeant plusieurs données en parallèle et le token expire). Un flag simple suffit — pas besoin d'un mécanisme de refresh token ou de queue de retry.

**Alternatives considered**:
- Token refresh automatique : hors scope (YAGNI, pas de refresh token côté backend).
- RxJS `shareReplay` / `BehaviorSubject` pour centraliser : over-engineering pour ce cas simple.
- Ne rien faire (laisser les multiples redirections) : mauvaise UX, `Router.navigate` appelé N fois.

## R6: Tests avec Vitest et Angular TestBed

**Decision**: Tester l'intercepteur avec `HttpTestingController` d'Angular pour simuler les requêtes/réponses HTTP. Initialiser le TestBed dans chaque fichier `.spec.ts` (pas de `setupFiles`).

**Rationale**: D'après l'expérience du projet (voir MEMORY.md), les `setupFiles` de Vitest ne chargent pas correctement l'init TestBed Angular 21. L'init doit se faire dans le fichier de test. `HttpTestingController` permet de vérifier les headers envoyés et de simuler les réponses 401.

**Alternatives considered**:
- Mock complet de `HttpClient` : trop bas niveau, ne teste pas l'intégration avec le système d'intercepteurs Angular.
- Tests e2e uniquement : trop lents pour du feedback rapide sur la logique d'interception.
