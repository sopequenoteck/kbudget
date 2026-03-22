# Feature Specification: Frontend Refresh Token

**Feature Branch**: `024-frontend-refresh-token`
**Created**: 2026-02-13
**Status**: Draft
**Input**: User description: "Implémenter le refresh token côté frontend (intercepteur + stockage)"
**Linear**: KKS-73

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Renouvellement transparent de session (Priority: P1)

L'utilisateur navigue dans l'application et son access token expire pendant sa session. Le système renouvelle automatiquement le token en arrière-plan sans interrompre l'utilisateur. La requête qui a déclenché le renouvellement est rejouée avec le nouveau token.

**Why this priority**: C'est la fonctionnalité centrale — sans elle, l'utilisateur est déconnecté dès que l'access token expire, ce qui dégrade fortement l'expérience.

**Independent Test**: Peut être testé en effectuant une requête API avec un access token expiré tout en ayant un refresh token valide. La requête doit aboutir sans intervention utilisateur.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté dont l'access token vient d'expirer, **When** il effectue une action (ex. charger la liste des transactions), **Then** le système renouvelle le token en arrière-plan et la requête aboutit normalement
2. **Given** plusieurs requêtes simultanées échouent avec un token expiré, **When** le renouvellement est en cours, **Then** toutes les requêtes en attente sont mises en file et rejouées avec le nouveau token (pas de requêtes de refresh concurrentes)

---

### User Story 2 - Déconnexion propre avec révocation (Priority: P2)

Quand l'utilisateur se déconnecte, le refresh token est révoqué côté serveur pour empêcher toute réutilisation.

**Why this priority**: Essentiel pour la sécurité — un refresh token non révoqué pourrait être utilisé même après déconnexion.

**Independent Test**: Peut être testé en se déconnectant puis en tentant manuellement d'utiliser l'ancien refresh token pour obtenir un nouveau token — la requête doit échouer.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il clique sur "Déconnexion", **Then** le refresh token est envoyé au serveur pour révocation, le stockage local est nettoyé, et l'utilisateur est redirigé vers l'écran de connexion
2. **Given** un utilisateur qui vient de se déconnecter, **When** l'ancien refresh token est utilisé, **Then** le serveur le rejette

---

### User Story 3 - Déconnexion forcée après échec du refresh (Priority: P2)

Si le refresh token est expiré, révoqué ou invalide, l'utilisateur est automatiquement déconnecté et redirigé vers l'écran de connexion.

**Why this priority**: Permet de gérer proprement la fin de vie d'une session longue, sans laisser l'utilisateur dans un état bloqué.

**Independent Test**: Peut être testé en effectuant une requête API avec un access token expiré et un refresh token invalide — l'utilisateur doit être redirigé vers la page de connexion.

**Acceptance Scenarios**:

1. **Given** un utilisateur dont l'access token et le refresh token sont tous deux expirés, **When** il effectue une action, **Then** il est déconnecté et redirigé vers l'écran de connexion
2. **Given** un utilisateur dont le refresh token a été révoqué par le serveur (détection de réutilisation), **When** il effectue une action, **Then** il est déconnecté et redirigé vers l'écran de connexion

---

### User Story 4 - Persistance du refresh token entre sessions (Priority: P3)

Le refresh token est stocké de manière persistante. À la réouverture de l'application, si l'access token est expiré mais le refresh token est encore valide, le système tente un renouvellement automatique avant de forcer une reconnexion.

**Why this priority**: Améliore l'expérience en évitant de demander une reconnexion à chaque ouverture de l'application quand le refresh token est encore valide.

**Independent Test**: Peut être testé en fermant l'application avec un access token expiré et un refresh token valide, puis en la rouvrant — l'utilisateur doit retrouver sa session sans se reconnecter.

**Acceptance Scenarios**:

1. **Given** un utilisateur qui rouvre l'application avec un access token expiré mais un refresh token valide, **When** l'application s'initialise, **Then** le système obtient un nouveau access token et restaure la session
2. **Given** un utilisateur qui rouvre l'application avec un refresh token expiré, **When** l'application s'initialise, **Then** l'utilisateur est redirigé vers l'écran de connexion

---

### Edge Cases

- Que se passe-t-il si le stockage local (localStorage) est indisponible ou plein ? Les méthodes de stockage utilisent un try/catch — si l'écriture échoue, les tokens ne sont pas persistés et l'utilisateur devra se reconnecter à la prochaine ouverture de l'application
- Que se passe-t-il si la requête de refresh échoue pour une erreur réseau (pas de connexion) ? L'erreur réseau est propagée à l'utilisateur, sans déconnexion (le refresh token reste valide)
- Que se passe-t-il si le refresh token est corrompu ou malformé en localStorage ? Le système traite cela comme un token absent et déconnecte l'utilisateur
- Que se passe-t-il si 10+ requêtes échouent simultanément avec un 401 ? Une seule requête de refresh est émise, toutes les autres attendent puis sont rejouées
- Que se passe-t-il si la requête de refresh retourne un 401 pendant qu'une requête initiale l'a déjà déclenchée ? Pas de boucle infinie — la requête de refresh elle-même ne déclenche jamais un nouveau refresh

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT stocker le refresh token reçu lors du login/register dans le stockage local (clé `budget_refresh_token`)
- **FR-002**: Le système DOIT envoyer le refresh token au serveur via l'endpoint dédié lorsqu'une requête échoue avec un statut 401
- **FR-003**: Le système DOIT rejouer la requête originale ayant échoué avec le nouveau access token obtenu
- **FR-004**: Le système DOIT sérialiser les requêtes de refresh : si un refresh est déjà en cours, les requêtes suivantes doivent attendre son résultat au lieu de déclencher un nouveau refresh
- **FR-005**: Le système DOIT déconnecter l'utilisateur et le rediriger vers l'écran de connexion si le renouvellement du token échoue (401 sur le refresh)
- **FR-006**: Le système DOIT envoyer le refresh token au serveur lors de la déconnexion pour le révoquer, puis nettoyer le stockage local
- **FR-007**: Le système DOIT mettre à jour le refresh token stocké si le serveur en renvoie un nouveau lors du renouvellement (rotation de tokens)
- **FR-008**: Le système NE DOIT PAS tenter de refresh sur les requêtes vers les endpoints publics (login, register) ni sur la requête de refresh elle-même
- **FR-009**: Le système DOIT tenter un renouvellement automatique au démarrage si l'access token est expiré mais qu'un refresh token existe en stockage local

### Key Entities

- **Access Token** : Token JWT de courte durée stocké localement (clé `budget_token`), envoyé dans chaque requête API authentifiée
- **Refresh Token** : Token opaque de longue durée stocké localement (clé `budget_refresh_token`), utilisé exclusivement pour obtenir un nouvel access token

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur ne perçoit aucune interruption de session tant que le refresh token est valide — les requêtes aboutissent sans intervention manuelle
- **SC-002**: Aucune requête de refresh concurrente n'est émise, même lorsque plusieurs requêtes API échouent simultanément (une seule requête de refresh à la fois)
- **SC-003**: Après déconnexion, le refresh token est révoqué côté serveur et supprimé du stockage local, empêchant toute réutilisation
- **SC-004**: L'utilisateur est redirigé vers l'écran de connexion en moins de 2 secondes lorsque le refresh token est invalide ou expiré
- **SC-005**: Le système ne génère jamais de boucle infinie de tentatives de refresh (la requête de refresh elle-même n'est jamais retentée automatiquement)

## Assumptions

- Le backend expose déjà les endpoints `/auth/refresh` (POST, body: `{ refreshToken }`) et `/auth/logout` (POST, body: `{ refreshToken }`) — confirmé par l'analyse du code existant
- La réponse `AuthResponse` du backend inclut déjà un champ `refreshToken` en plus du `token` (access token) — confirmé
- Le refresh token a une durée de vie plus longue que l'access token (configurée côté serveur)
- Le stockage local (localStorage) est le mécanisme de persistance pour les tokens, cohérent avec l'implémentation existante
- L'application est single-user (self-hosted), donc les contraintes de sécurité liées au XSS sur localStorage sont acceptées pour la v1
