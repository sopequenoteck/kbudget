# Feature Specification: Refresh Token JWT Backend

**Feature Branch**: `023-jwt-refresh-token`
**Created**: 2026-02-13
**Status**: Draft
**Input**: User description: "KKS-72 — Implémenter le refresh token JWT côté backend"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Renouvellement transparent de session (Priority: P1)

L'utilisateur se connecte à l'application Budget depuis son mobile. Après 15 minutes d'inactivité, il revient sur l'app. Au lieu d'être forcé à se reconnecter, le système renouvelle automatiquement sa session en arrière-plan grâce au refresh token. L'utilisateur continue son usage sans interruption.

**Why this priority**: C'est le besoin principal — éviter les déconnexions fréquentes sur une app mobile utilisée quotidiennement. Sans cela, l'expérience utilisateur est dégradée à chaque expiration du token court.

**Independent Test**: Peut être testé en appelant l'endpoint de refresh avec un refresh token valide et en vérifiant qu'un nouveau couple access/refresh token est retourné.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté avec un access token expiré et un refresh token valide, **When** le système demande un renouvellement de token, **Then** un nouvel access token et un nouveau refresh token sont retournés.
2. **Given** un utilisateur connecté avec un access token expiré et un refresh token valide, **When** le renouvellement réussit, **Then** l'ancien refresh token est invalidé (rotation).
3. **Given** un utilisateur qui se connecte, **When** le login réussit, **Then** la réponse contient à la fois un access token (courte durée) et un refresh token (longue durée).

---

### User Story 2 - Déconnexion sécurisée avec révocation (Priority: P2)

L'utilisateur se déconnecte volontairement de l'application. Le système invalide son refresh token pour empêcher tout renouvellement futur de session depuis cet appareil.

**Why this priority**: La révocation est essentielle pour la sécurité — sans elle, un refresh token volé resterait exploitable même après déconnexion.

**Independent Test**: Peut être testé en appelant l'endpoint de logout avec un refresh token valide, puis en tentant de l'utiliser pour un refresh — le système doit rejeter la demande.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté avec un refresh token valide, **When** il se déconnecte, **Then** son refresh token est invalidé côté serveur.
2. **Given** un refresh token qui a été révoqué via logout, **When** quelqu'un tente de l'utiliser pour obtenir un nouveau token, **Then** le système rejette la demande.

---

### User Story 3 - Protection contre le vol de refresh token (Priority: P3)

Un refresh token est compromis et utilisé par un tiers. Le système détecte la tentative de réutilisation d'un refresh token déjà consommé (rotation) et invalide toute la chaîne de tokens de l'utilisateur pour le forcer à se reconnecter.

**Why this priority**: Scénario de sécurité avancé — la rotation des tokens avec détection de réutilisation protège contre le vol de token.

**Independent Test**: Peut être testé en utilisant un refresh token qui a déjà été échangé (consommé par rotation) — le système doit rejeter la demande et révoquer les tokens actifs de l'utilisateur.

**Acceptance Scenarios**:

1. **Given** un refresh token qui a déjà été utilisé pour un renouvellement (consommé), **When** quelqu'un tente de le réutiliser, **Then** le système rejette la demande et invalide tous les refresh tokens de l'utilisateur concerné.
2. **Given** un refresh token expiré (plus de 30 jours), **When** quelqu'un tente de l'utiliser, **Then** le système rejette la demande.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur envoie une requête de refresh alors que le refresh token est expiré ? Le système retourne une erreur et l'utilisateur doit se reconnecter.
- Que se passe-t-il si deux requêtes de refresh sont envoyées simultanément avec le même token ? Seule la première réussit, la seconde échoue (le token a déjà été consommé par rotation).
- Que se passe-t-il si l'utilisateur n'a jamais eu de refresh token (ancien login avant cette feature) ? Il doit se reconnecter pour obtenir le couple access/refresh.
- Que se passe-t-il si le stockage des refresh tokens est indisponible ? Le login fonctionne toujours avec l'access token seul, mais le refresh échoue gracieusement.

## Clarifications

### Session 2026-02-13

- Q: Le endpoint de refresh doit-il retourner des réponses d'erreur différenciées selon la raison du rejet ? → A: Oui, réponses différenciées avec un code d'erreur distinct par raison (expiré, révoqué, réutilisation détectée).
- Q: Faut-il limiter le nombre de refresh tokens actifs simultanés par utilisateur ? → A: Non, illimité. Nettoyage des tokens expirés uniquement.
- Q: Par quel mécanisme de transport le refresh token est-il transmis au client ? → A: JSON body (comme l'access token actuel, stocké en localStorage côté client).
- Q: Le périmètre inclut-il les modifications frontend ? → A: Non, backend uniquement (endpoints REST, entité, migration Flyway). Le frontend sera traité dans une feature séparée.
- Q: Quelle méthode de génération pour la valeur opaque du refresh token ? → A: SecureRandom 32 bytes encodé Base64url (256 bits d'entropie, 43 chars).
- Q: Faut-il appliquer un rate limiting sur les endpoints publics refresh/logout ? → A: Non, hors périmètre. Ajout ultérieur si besoin.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT générer un refresh token opaque (non-JWT) via `SecureRandom` 32 bytes encodé en Base64url (256 bits d'entropie, 43 caractères) lors de chaque login ou register réussi, en plus de l'access token existant.
- **FR-002**: Le système DOIT retourner le refresh token dans le corps JSON de la réponse de login et de register, aux côtés de l'access token (même mécanisme de transport que l'access token).
- **FR-003**: Le système DOIT fournir un endpoint de renouvellement qui accepte un refresh token valide et retourne un nouveau couple access token + refresh token.
- **FR-004**: Le système DOIT implémenter la rotation des refresh tokens — chaque utilisation d'un refresh token l'invalide et en génère un nouveau.
- **FR-005**: Le système DOIT fournir un endpoint de déconnexion qui invalide le refresh token fourni.
- **FR-006**: Le système DOIT stocker les refresh tokens côté serveur avec leur statut (actif, révoqué, consommé). L'expiration est déterminée dynamiquement via le champ `expiresAt` (pas de statut "expiré" stocké).
- **FR-007**: Le système DOIT lier chaque refresh token à un utilisateur spécifique.
- **FR-008**: L'access token DOIT avoir une durée de vie de 15 minutes.
- **FR-009**: Le refresh token DOIT avoir une durée de vie de 30 jours.
- **FR-010**: Le système DOIT rejeter toute tentative d'utilisation d'un refresh token révoqué, consommé ou expiré, avec un code d'erreur distinct par raison de rejet : token expiré, token révoqué, ou réutilisation détectée.
- **FR-011**: Le système DOIT détecter la réutilisation d'un refresh token déjà consommé et révoquer tous les refresh tokens actifs de l'utilisateur concerné (protection contre le vol).
- **FR-012**: Le système DOIT permettre l'accès aux endpoints de refresh et logout sans access token valide (ces endpoints sont authentifiés par le refresh token lui-même).
- **FR-013**: Le système DOIT journaliser les événements de sécurité liés aux tokens (émission, renouvellement, révocation, tentative de réutilisation).

### Key Entities

- **Refresh Token**: Jeton de renouvellement lié à un utilisateur. Attributs clés : valeur opaque unique (SecureRandom 32 bytes, Base64url, 43 chars), utilisateur associé, date de création, date d'expiration, statut (actif / révoqué / consommé).
- **User** (existant): Utilisateur de l'application. Relation : un utilisateur peut avoir zéro ou plusieurs refresh tokens.

### Assumptions

- L'application est single-user en pratique, mais le mécanisme supporte techniquement plusieurs utilisateurs.
- Le refresh token est opaque (chaîne aléatoire) et non un JWT — il n'a pas besoin d'être auto-suffisant car il est vérifié côté serveur.
- La rotation est obligatoire : chaque refresh consomme l'ancien token et en émet un nouveau.
- Le nettoyage des tokens expirés peut être fait manuellement ou périodiquement — pas de contrainte temps-réel.
- Pas de limite sur le nombre de refresh tokens actifs simultanés par utilisateur. La table est nettoyée des tokens expirés uniquement.
- Les endpoints de refresh et logout sont publics (pas besoin d'un access token valide pour les appeler).
- **Hors périmètre** : toute modification frontend (intercepteur HTTP auto-refresh, stockage refresh token en localStorage, écran de logout). Le frontend sera traité dans une feature séparée.
- **Hors périmètre** : rate limiting sur les endpoints publics (refresh, logout). Pourra être ajouté ultérieurement si nécessaire.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut maintenir une session active pendant 30 jours sans se reconnecter, tant qu'il utilise l'application au moins une fois tous les 30 jours.
- **SC-002**: Le renouvellement de token est transparent — l'utilisateur ne voit jamais d'écran de login tant que son refresh token est valide.
- **SC-003**: Après déconnexion, aucun renouvellement de session n'est possible avec l'ancien refresh token.
- **SC-004**: En cas de vol détecté (réutilisation d'un token consommé), tous les tokens actifs de l'utilisateur sont révoqués en moins de 1 seconde.
- **SC-005**: Les opérations de renouvellement de token s'effectuent en moins de 500 ms.
