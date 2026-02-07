# Feature Specification: Guard d'authentification

**Feature Branch**: `003-auth-guard`
**Created**: 2026-02-08
**Status**: Draft
**Input**: User description: "KKS-27 - Implémenter le guard d'authentification Angular pour protéger les routes authentifiées"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Accès refusé sans authentification (Priority: P1)

Un utilisateur non authentifié tente d'accéder à une page protégée (dashboard, transactions, abonnements, dettes). Le système le redirige automatiquement (sans délai perceptible, < 50ms) vers la page de connexion en conservant l'URL demandée, afin qu'il puisse y être redirigé après connexion.

**Why this priority**: Sans cette protection, n'importe qui pourrait accéder aux données financières de l'utilisateur. C'est le fondement de la sécurité côté frontend.

**Independent Test**: Peut être testé en ouvrant directement une URL protégée sans être connecté et en vérifiant la redirection vers la page de connexion.

**Acceptance Scenarios**:

1. **Given** un utilisateur non authentifié, **When** il accède à `/dashboard`, **Then** il est redirigé vers `/auth` avec le paramètre `returnUrl=/dashboard`
2. **Given** un utilisateur non authentifié, **When** il accède à `/transactions`, **Then** il est redirigé vers `/auth` avec le paramètre `returnUrl=/transactions`
3. **Given** un utilisateur non authentifié, **When** il accède à `/subscriptions`, **Then** il est redirigé vers `/auth` avec le paramètre `returnUrl=/subscriptions`
4. **Given** un utilisateur non authentifié, **When** il accède à `/debts`, **Then** il est redirigé vers `/auth` avec le paramètre `returnUrl=/debts`

---

### User Story 2 - Accès autorisé avec authentification (Priority: P1)

Un utilisateur authentifié accède normalement à toutes les pages protégées sans aucune interruption.

**Why this priority**: Le guard ne doit pas bloquer les utilisateurs légitimes. C'est indissociable de la P1 précédente.

**Independent Test**: Se connecter puis naviguer vers toutes les routes protégées et vérifier que l'accès est accordé.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié, **When** il accède à `/dashboard`, **Then** la page s'affiche normalement
2. **Given** un utilisateur authentifié, **When** il navigue entre les pages protégées, **Then** aucune redirection n'intervient

---

### User Story 3 - Routes publiques accessibles sans authentification (Priority: P1)

Les pages de connexion et d'inscription restent accessibles sans authentification, évitant une boucle de redirection.

**Why this priority**: Si les routes publiques sont protégées, l'utilisateur ne pourrait jamais se connecter.

**Independent Test**: Accéder à `/auth` sans être connecté et vérifier que la page s'affiche.

**Acceptance Scenarios**:

1. **Given** un utilisateur non authentifié, **When** il accède à `/auth`, **Then** la page s'affiche sans redirection
2. **Given** un utilisateur authentifié, **When** il accède à `/auth`, **Then** la page s'affiche normalement (pas de redirection forcée vers le dashboard)

---

### User Story 4 - Redirection post-login via returnUrl (Priority: P2)

Après s'être connecté, l'utilisateur est redirigé vers la page qu'il tentait d'atteindre initialement, plutôt que vers le dashboard par défaut.

**Why this priority**: Améliore l'expérience utilisateur en évitant de perdre le contexte de navigation, mais n'est pas bloquant pour la sécurité.

**Independent Test**: Tenter d'accéder à `/transactions` sans authentification, se connecter, puis vérifier la redirection vers `/transactions`.

**Implementation Note**: Le guard (KKS-27) pose le `returnUrl` en query param. La lecture et l'utilisation de ce paramètre seront implémentées dans le composant login (KKS-28, hors scope de cette feature).

**Acceptance Scenarios**:

1. **Given** un utilisateur redirigé vers `/auth?returnUrl=/transactions`, **When** il se connecte avec succès, **Then** il est redirigé vers `/transactions`
2. **Given** un utilisateur qui accède directement à `/auth` (sans returnUrl), **When** il se connecte, **Then** il est redirigé vers `/dashboard` (comportement par défaut)

---

### User Story 5 - Session expirée (Priority: P2)

Un utilisateur dont la session a expiré est redirigé vers la page de connexion lorsqu'il tente de naviguer.

**Why this priority**: Gère un cas courant (token JWT expiré) qui impacte la continuité d'utilisation.

**Independent Test**: Simuler un token expiré en storage et tenter d'accéder à une page protégée.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec un token expiré, **When** il accède à une page protégée, **Then** il est redirigé vers `/auth` avec le `returnUrl` approprié

---

### Edge Cases

- Que se passe-t-il si le `returnUrl` contient une route invalide (ex: `/zzzinvalid`) ? Le returnUrl est conservé tel quel — si la route n'existe pas, Angular affichera la page 404 après login.
- Que se passe-t-il si le `returnUrl` est une URL externe malveillante (ex: `https://evil.com`) ? Le système rejette l'URL externe : le returnUrl n'est PAS passé au query param. L'utilisateur est redirigé vers `/auth` sans returnUrl, ce qui déclenchera une redirection par défaut vers `/dashboard` après login.
- Que se passe-t-il si l'utilisateur accède à une route wildcard (`/**`) sans authentification ? Il est redirigé vers `/auth`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT vérifier l'état d'authentification de l'utilisateur avant chaque accès à une route protégée
- **FR-002**: Le système DOIT rediriger les utilisateurs non authentifiés vers `/auth`
- **FR-003**: Le système DOIT conserver l'URL demandée dans un paramètre query `returnUrl` lors de la redirection vers `/auth`
- **FR-004**: Le système DOIT autoriser l'accès aux routes publiques (`/auth` et ses sous-routes) sans authentification
- **FR-005**: Le système DOIT protéger les routes suivantes : dashboard, transactions, abonnements, dettes
- **FR-006**: Le système DOIT considérer un token expiré comme une absence d'authentification
- **FR-007**: Le système DOIT valider que le `returnUrl` est une route interne à l'application (pas d'URL externe)

### Key Entities

- **Guard d'authentification** : Mécanisme de protection qui intercepte la navigation vers les routes protégées et vérifie l'état d'authentification
- **Route protégée** : Toute route nécessitant une session active (dashboard, transactions, abonnements, dettes)
- **Route publique** : Route accessible sans authentification (auth/login, auth/register)
- **returnUrl** : Paramètre de redirection conservant la destination initiale de l'utilisateur

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des tentatives d'accès non authentifiées aux routes protégées résultent en une redirection vers la page de connexion
- **SC-002**: 100% des accès authentifiés aux routes protégées sont autorisés sans délai perceptible
- **SC-003**: Les routes publiques restent accessibles sans authentification dans tous les cas
- **SC-004**: Après connexion, l'utilisateur est redirigé vers sa destination initiale dans 100% des cas où un `returnUrl` valide est présent
- **SC-005**: Les URLs externes dans le `returnUrl` sont ignorées dans 100% des cas

## Assumptions

- Le service d'authentification (AuthService) est déjà implémenté et expose un signal `isAuthenticated` réactif
- Le token JWT est stocké en localStorage et sa validité (expiration) est déjà gérée par AuthService
- La route de connexion est `/auth` (comme défini dans le routing existant)
- La destination par défaut après connexion sans `returnUrl` est `/dashboard`
