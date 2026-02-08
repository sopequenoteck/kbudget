# Feature Specification: Intercepteur HTTP JWT

**Feature Branch**: `004-jwt-interceptor`
**Created**: 2026-02-08
**Status**: Draft
**Input**: User description: "KKS-26 — Implémenter l'intercepteur HTTP JWT : Créer un intercepteur HTTP fonctionnel qui gère le JWT automatiquement."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Requêtes authentifiées automatiques (Priority: P1)

En tant qu'utilisateur connecté, lorsque je navigue dans l'application et que des requêtes sont envoyées vers l'API, mon jeton d'authentification doit être automatiquement inclus dans chaque requête. Je ne dois pas avoir à m'en soucier manuellement : l'application s'en charge de manière transparente.

**Why this priority**: C'est la fonctionnalité fondamentale de l'intercepteur. Sans l'injection automatique du token, aucune requête authentifiée ne peut fonctionner.

**Independent Test**: Peut être testé en effectuant une requête vers un endpoint protégé après connexion et en vérifiant que le header d'autorisation est présent dans la requête sortante.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté avec un token valide, **When** une requête est envoyée vers un endpoint protégé de l'API, **Then** le header `Authorization: Bearer <token>` est automatiquement ajouté à la requête.
2. **Given** un utilisateur connecté avec un token valide, **When** plusieurs requêtes sont envoyées simultanément, **Then** chaque requête contient le header d'autorisation avec le même token.
3. **Given** un utilisateur non connecté (pas de token stocké), **When** une requête est envoyée vers un endpoint protégé, **Then** la requête est envoyée sans header d'autorisation.

---

### User Story 2 - Exclusion des routes publiques (Priority: P2)

En tant qu'utilisateur non connecté, lorsque je me connecte ou je m'inscris, les requêtes vers les endpoints d'authentification ne doivent pas inclure de header d'autorisation, même si un token existe en mémoire. Cela évite des interférences avec le processus d'authentification.

**Why this priority**: Essentiel pour que le flux de connexion/inscription fonctionne correctement. Si le token est envoyé sur ces routes, cela peut provoquer des erreurs côté serveur.

**Independent Test**: Peut être testé en déclenchant une requête de connexion ou d'inscription et en vérifiant l'absence du header d'autorisation.

**Acceptance Scenarios**:

1. **Given** un token présent en mémoire, **When** une requête est envoyée vers l'endpoint de connexion, **Then** aucun header d'autorisation n'est ajouté.
2. **Given** un token présent en mémoire, **When** une requête est envoyée vers l'endpoint d'inscription, **Then** aucun header d'autorisation n'est ajouté.
3. **Given** un token présent en mémoire, **When** une requête est envoyée vers tout autre endpoint de l'API, **Then** le header d'autorisation est ajouté.

---

### User Story 3 - Déconnexion automatique sur session expirée (Priority: P3)

En tant qu'utilisateur dont la session a expiré côté serveur, lorsque le serveur répond avec une erreur d'authentification (401), je suis automatiquement déconnecté et redirigé vers la page de connexion. Cela m'évite de rester bloqué sur un écran avec des données inaccessibles.

**Why this priority**: Améliore l'expérience utilisateur en cas de session expirée. Sans cette gestion, l'utilisateur verrait des erreurs incompréhensibles.

**Independent Test**: Peut être testé en simulant une réponse 401 du serveur et en vérifiant que le token est supprimé et que l'utilisateur est redirigé vers la page de connexion.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** le serveur répond avec un statut 401 à une requête, **Then** le token est supprimé de la mémoire locale.
2. **Given** un utilisateur connecté, **When** le serveur répond avec un statut 401, **Then** l'utilisateur est redirigé vers la page de connexion.
3. **Given** un utilisateur connecté, **When** le serveur répond avec un statut 401, **Then** l'état d'authentification de l'application est mis à jour (utilisateur considéré comme déconnecté).
4. **Given** un utilisateur connecté, **When** le serveur répond avec un statut 403 (accès interdit, pas expiration), **Then** l'utilisateur n'est PAS déconnecté et l'erreur est propagée normalement.

---

### Edge Cases

- Que se passe-t-il si le token est supprimé du stockage local entre deux requêtes (par un autre onglet ou manuellement) ? L'intercepteur doit envoyer la requête sans header plutôt que planter.
- Que se passe-t-il si une requête est envoyée vers une URL externe (pas l'API) ? Le token ne doit jamais être envoyé vers des domaines tiers.
- Que se passe-t-il si plusieurs réponses 401 arrivent simultanément ? La déconnexion et la redirection ne doivent se produire qu'une seule fois, pas en cascade.
- Que se passe-t-il si l'utilisateur est déjà sur la page de connexion et reçoit une 401 ? Pas de boucle de redirection infinie.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT ajouter automatiquement le header `Authorization: Bearer <token>` à toutes les requêtes HTTP sortantes vers l'API lorsqu'un token est disponible.
- **FR-002**: Le système NE DOIT PAS ajouter le header d'autorisation aux requêtes vers les endpoints publics d'authentification (connexion et inscription).
- **FR-003**: Le système DOIT supprimer le token stocké et rediriger l'utilisateur vers la page de connexion lorsqu'une réponse 401 est reçue du serveur.
- **FR-004**: Le système DOIT mettre à jour l'état d'authentification de l'application (marquer l'utilisateur comme déconnecté) lors d'une réponse 401.
- **FR-005**: Le système NE DOIT PAS ajouter le header d'autorisation aux requêtes vers des URL externes (en dehors du domaine de l'API).
- **FR-006**: Le système DOIT gérer gracieusement l'absence de token (pas d'erreur, requête envoyée sans header).
- **FR-007**: Le système DOIT éviter les redirections multiples vers la page de connexion lorsque plusieurs réponses 401 arrivent simultanément.
- **FR-008**: Le système DOIT être enregistré dans la configuration globale de l'application pour intercepter toutes les requêtes HTTP.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des requêtes vers l'API protégée contiennent le header d'autorisation lorsque l'utilisateur est connecté.
- **SC-002**: 0% des requêtes vers les endpoints publics d'authentification contiennent le header d'autorisation.
- **SC-003**: L'utilisateur est redirigé vers la page de connexion en moins de 1 seconde après une réponse 401.
- **SC-004**: Aucun token n'est envoyé vers des domaines externes à l'API.
- **SC-005**: L'intercepteur fonctionne de manière transparente : aucun code applicatif existant ne nécessite de modification pour bénéficier de l'injection automatique du token.

## Assumptions

- Le service d'authentification existant (`AuthService`) expose une méthode pour récupérer le token courant et une méthode de déconnexion.
- Les routes publiques sont limitées à `/api/auth/login` et `/api/auth/register`. Si de nouvelles routes publiques sont ajoutées à l'avenir, la liste d'exclusion devra être mise à jour.
- L'URL de base de l'API est configurée via la configuration d'environnement de l'application.
- Le guard d'authentification (`authGuard`) est déjà implémenté et gère la redirection vers `/auth` avec un paramètre `returnUrl`.
