# Research: Frontend Refresh Token

**Feature**: 024-frontend-refresh-token
**Date**: 2026-02-13

## R1: Pattern de refresh token dans un intercepteur Angular

**Decision**: Utiliser un `BehaviorSubject<boolean>` pour tracker l'état du refresh en cours, et `filter` + `switchMap` pour sérialiser les requêtes concurrentes.

**Rationale**: C'est le pattern standard pour les intercepteurs Angular avec refresh token. Un `BehaviorSubject` permet de :
- Signaler qu'un refresh est en cours (`false` = en cours, `true` = prêt)
- Faire attendre les requêtes concurrentes via `filter(ready => ready)` puis `switchMap` pour rejouer avec le nouveau token
- Éviter les Subject qui nécessitent un `complete()` explicite

**Alternatives considered**:
- `Subject` + queue manuelle : plus verbeux, risque de fuite mémoire si pas de `complete()`
- Mutex/lock pattern : sur-ingénierie pour un single-user app
- `shareReplay(1)` sur l'Observable de refresh : viable mais moins lisible que le BehaviorSubject

## R2: Exclusion de la requête de refresh de l'interception

**Decision**: Ajouter `/auth/refresh` à la liste `PUBLIC_PATHS` existante dans l'intercepteur, et ajouter un flag `_retry` sur les requêtes rejouées pour éviter les boucles infinies.

**Rationale**: L'intercepteur actuel a déjà un mécanisme `PUBLIC_PATHS` pour exclure `/auth/login` et `/auth/register`. Ajouter `/auth/refresh` est cohérent. Le flag `_retry` sur la requête clonée permet de ne jamais retenter un refresh sur une requête déjà rejouée.

**Alternatives considered**:
- Utiliser `HttpContext` d'Angular pour marquer les requêtes : plus élégant mais ajoute de la complexité pour un cas simple
- Vérifier l'URL dans le `catchError` : fragile, dépend de l'ordre d'exécution

## R3: Gestion du logout avec appel API

**Decision**: Le `logout()` d'AuthService devient asynchrone — il appelle `POST /auth/logout` avec le refresh token, puis nettoie le stockage et redirige. Si l'appel API échoue (réseau, token déjà révoqué), le nettoyage local se fait quand même (fire-and-forget).

**Rationale**: Le logout doit toujours aboutir côté client, même si le serveur est injoignable. Le refresh token sera de toute façon inutilisable après expiration naturelle. Le pattern fire-and-forget évite de bloquer l'utilisateur.

**Alternatives considered**:
- Attendre la réponse du serveur avant de nettoyer : risque de bloquer l'utilisateur si le serveur est down
- Ne pas appeler le serveur : le refresh token resterait valide jusqu'à expiration, risque de sécurité

## R4: Restauration de session au démarrage avec refresh token

**Decision**: Modifier `restoreSession()` dans AuthService : si l'access token est expiré mais qu'un refresh token existe, tenter un refresh automatique via `POST /auth/refresh`. Si le refresh réussit, restaurer la session. Si il échoue, nettoyer et rediriger vers login.

**Rationale**: Améliore significativement l'UX en évitant les reconnexions inutiles quand le refresh token est encore valide. Cohérent avec le comportement attendu d'une PWA mobile.

**Alternatives considered**:
- Toujours rediriger vers login si l'access token est expiré (comportement actuel) : simple mais mauvaise UX
- Refresh proactif avant expiration : plus complexe (timer, calcul du TTL), prématuré pour v1

## R5: Mise à jour du modèle AuthResponse frontend

**Decision**: Ajouter le champ `refreshToken` à l'interface `AuthResponse` existante dans `auth.model.ts`.

**Rationale**: Le backend renvoie déjà `refreshToken` dans sa réponse `AuthResponse` (record Java). Le frontend l'ignore actuellement. Il suffit d'ajouter le champ à l'interface TypeScript pour le typer correctement.

**Alternatives considered**:
- Créer un nouveau type `TokenPair` : sur-ingénierie, le champ fait naturellement partie de la réponse d'authentification
