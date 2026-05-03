# Research: Guard d'authentification

**Feature**: 003-auth-guard | **Date**: 2026-02-08

## R1: Pattern de guard fonctionnel Angular 21

**Decision**: Utiliser `CanActivateFn` (functional guard) avec `inject()` pour accéder aux services.

**Rationale**: Angular 17+ favorise les guards fonctionnels plutôt que les guards basés sur des classes. Angular 21 poursuit cette direction. Le pattern est plus simple, plus testable et aligné avec les conventions du projet (inject() uniquement, pas de constructor injection).

**Alternatives considered**:
- Guard basé sur classe (`@Injectable` + `CanActivate` interface) : déprécié depuis Angular 15, plus verbeux
- Inline guard dans la config de routes : pas réutilisable, moins testable

## R2: Mécanisme de returnUrl

**Decision**: Passer le `returnUrl` en query parameter lors de la redirection vers `/auth`. Le composant de login (KKS-28) lira ce paramètre après connexion réussie.

**Rationale**: Pattern standard Angular. Le query parameter est visible dans l'URL, ce qui aide au debugging. L'alternative (stocker en service/sessionStorage) ajoute de la complexité sans bénéfice pour une app single-user.

**Alternatives considered**:
- Stockage dans un service Angular : état perdu en cas de refresh navigateur
- sessionStorage : complexité supplémentaire sans bénéfice

## R3: Validation du returnUrl (sécurité)

**Decision**: Vérifier que le `returnUrl` commence par `/` (route relative interne). Rejeter toute URL absolue (`http://`, `https://`, `//`).

**Rationale**: Prévient les attaques d'open redirect. Simple à implémenter et suffisant pour une app single-user self-hosted.

**Alternatives considered**:
- Whitelist de routes valides : trop rigide, nécessite maintenance à chaque nouvelle route
- Pas de validation : vulnérable aux open redirects

## R4: Placement du guard dans le routing

**Decision**: Appliquer le guard via `canActivate` sur chaque route protégée dans `app.routes.ts`, plutôt que sur une route parent englobante.

**Rationale**: Le routing actuel est plat (pas de route parent commune pour les routes protégées). Ajouter une route parent wrapper uniquement pour le guard serait du over-engineering. Le pattern actuel avec `canActivate` par route est explicite et facile à maintenir.

**Alternatives considered**:
- Route parent avec `canActivateChild` : nécessite de restructurer tout le routing, over-engineering pour 4 routes
- Interceptor HTTP : ne protège pas la navigation, seulement les appels API

## R5: Interaction avec AuthService existant

**Decision**: Utiliser `AuthService.isAuthenticated()` (computed signal qui retourne un boolean) pour vérifier l'état d'authentification. Pas de modification de l'AuthService.

**Rationale**: Le signal `isAuthenticated` est déjà implémenté et testé (KKS-25). Il vérifie la présence d'un currentUser non-null, qui est lui-même conditionné à un token valide et non-expiré dans localStorage.

**Alternatives considered**:
- Appeler `getToken()` directement dans le guard : duplique la logique de vérification déjà dans AuthService
- Ajouter une méthode spécifique au guard dans AuthService : YAGNI
