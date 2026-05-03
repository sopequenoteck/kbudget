# Research: 065-angular-data-settings

**Date**: 2026-03-01

## R1. Comment obtenir l'URL du serveur au runtime

**Decision**: Construire l'URL via `window.location.origin + environment.apiUrl`

**Rationale**: L'URL API est configuree en relatif (`/api`) dans `environment.ts` et `environment.prod.ts`. En prod, le reverse proxy Caddy sert le frontend et l'API sur le meme domaine. L'URL complete est donc `window.location.origin + '/api'`. C'est la seule facon d'obtenir l'URL absolue sans ajouter une configuration supplementaire.

**Alternatives considered**:
- Ajouter une variable `serverUrl` dans environment.ts — sur-ingenierie, l'URL est toujours relative au meme host
- Hardcoder `https://budget.kksdev.fr` — non portable, casse en dev

## R2. Comment appeler `/actuator/health` depuis Angular

**Decision**: Utiliser `HttpClient.get()` directement avec l'URL `${window.location.origin}/actuator/health`

**Rationale**: L'endpoint Actuator est hors du context path `/api`, donc `ApiService` (qui prefixe `/api`) n'est pas adapte. L'`authInterceptor` Angular ajoutera le JWT en header mais l'endpoint Spring Actuator est configure public — le token sera simplement ignore. Pas besoin de bypass l'intercepteur.

**Alternatives considered**:
- Bypass l'intercepteur via `HttpContext` — complexite inutile, le JWT est ignore cote serveur
- Appeler via `ApiService` avec un path relatif `/../actuator/health` — fragile, URL mal formee
- Appeler via `fetch()` natif — perd les benefices d'HttpClient (observables, interceptors, testabilite)

## R3. Strategie de rechargement des donnees

**Decision**: `window.location.reload()` apres dialogue de confirmation

**Rationale**: Les services Angular (Transaction, Account, Category, etc.) utilisent un pattern `refreshTrigger = signal(0)` avec une methode `refresh()` privee. Il n'existe pas d'API publique pour forcer un re-fetch. Modifier 8+ services existants pour exposer un `reload()` serait invasif et contraire au principe YAGNI pour une action de maintenance rare.

Un `window.location.reload()` :
- Remet tous les signals a zero (etat initial)
- Re-declenche tous les fetches automatiquement
- Ne necessite aucune modification des services existants
- Est parfaitement adapte a une action de maintenance ponctuelle

**Alternatives considered**:
- Exposer `reload()` public sur chaque service — invasif, modifie 8+ fichiers sans benefice reel
- Navigation vers `/` puis retour — ne garantit pas le rechargement des donnees en cache dans les services singleton
- Creer un `DataReloadService` central qui injecte tous les services — couplage fort, anti-YAGNI

## R4. Mesure de la latence du health check

**Decision**: Mesurer via `Date.now()` avant et apres l'appel HTTP

**Rationale**: Simple, suffisant pour un diagnostic utilisateur (precision ~1ms). Pas besoin de `performance.now()` ou de l'API Performance Observer pour un simple affichage de latence.

**Alternatives considered**:
- `performance.now()` — plus precis (sous-milliseconde) mais surdimensionne pour l'usage
- Header HTTP `Server-Timing` — necessite une configuration backend, hors scope

## R5. Pattern de composant Angular

**Decision**: Suivre exactement le pattern du composant `Appearance` (le plus simple des settings existants)

**Rationale**: Structure validee, coherente avec le reste du module Settings :
- Standalone, `ChangeDetectionStrategy.OnPush`
- `inject()` pour la DI
- `RouterLink` pour la navigation retour
- Design tokens SCSS (`var(--*)`)
- Signals pour l'etat reactif

**Alternatives considered**: Aucune — le pattern est impose par la constitution et les conventions du projet.
