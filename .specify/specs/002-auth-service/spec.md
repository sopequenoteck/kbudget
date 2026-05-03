# Feature Specification: Service d'authentification frontend

**Feature Branch**: `feature/002-auth-service`
**Created**: 2026-02-07
**Status**: Draft
**Input**: User description: "Implémenter le AuthService pour gérer l'authentification JWT côté frontend Angular 21"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Connexion utilisateur (Priority: P1)

L'utilisateur ouvre l'application et souhaite se connecter avec son email et mot de passe. Il saisit ses identifiants, soumet le formulaire, et accède à l'application. Son état de connexion est maintenu tant que sa session est valide.

**Why this priority**: La connexion est le point d'entrée obligatoire de l'application. Sans cette fonctionnalité, aucune feature authentifiée n'est accessible. C'est le fondement de toute la Phase 3 frontend.

**Independent Test**: Peut être testé en appelant le service de connexion avec des identifiants valides et en vérifiant que le token est stocké et que l'état d'authentification est mis à jour.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec un compte existant, **When** il fournit un email et mot de passe valides, **Then** le système stocke le token de session et l'état d'authentification passe à "connecté"
2. **Given** un utilisateur avec un compte existant, **When** il fournit un email ou mot de passe incorrect, **Then** le système affiche un message d'erreur clair et l'état reste "non connecté"
3. **Given** un utilisateur déjà connecté, **When** il revient sur l'application, **Then** sa session est restaurée automatiquement si le token est encore valide

---

### User Story 2 - Inscription utilisateur (Priority: P2)

Un nouvel utilisateur souhaite créer un compte. Il fournit son nom, email et mot de passe. Après inscription, il est automatiquement connecté et peut utiliser l'application.

**Why this priority**: L'inscription est nécessaire pour créer de nouveaux comptes, mais en phase de développement la connexion seule suffit (comptes créables via API directe ou Swagger).

**Independent Test**: Peut être testé en appelant le service d'inscription avec des données valides et en vérifiant que le token est stocké et que l'état passe à "connecté".

**Acceptance Scenarios**:

1. **Given** un visiteur sans compte, **When** il fournit nom, email et mot de passe valides, **Then** le système crée le compte, stocke le token et l'état passe à "connecté"
2. **Given** un visiteur, **When** il utilise un email déjà pris, **Then** le système affiche un message d'erreur indiquant que l'email est déjà utilisé
3. **Given** un visiteur, **When** il fournit un mot de passe trop court (< 6 caractères), **Then** le système refuse l'inscription avec un message d'erreur adapté

---

### User Story 3 - Déconnexion (Priority: P3)

L'utilisateur connecté souhaite se déconnecter. Il clique sur "Déconnexion" et est redirigé vers l'écran de connexion. Ses données de session sont supprimées.

**Why this priority**: La déconnexion est essentielle pour la sécurité mais moins critique que la connexion/inscription pour le développement initial.

**Independent Test**: Peut être testé en se connectant d'abord, puis en appelant la déconnexion et en vérifiant que le token est supprimé, l'état passe à "non connecté" et la redirection vers l'écran de connexion s'effectue.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il déclenche la déconnexion, **Then** le token est supprimé, l'état passe à "non connecté" et il est redirigé vers la page de connexion

---

### User Story 4 - Détection d'expiration de session (Priority: P4)

L'utilisateur est connecté depuis un moment. Son token expire. Lors de sa prochaine action, le système détecte l'expiration et nettoie la session. La redirection vers la page de connexion est assurée par le guard d'authentification (KKS-27).

**Why this priority**: Gère un cas d'usage réel mais moins fréquent en phase initiale (token JWT à durée de vie longue en dev).

**Independent Test**: Peut être testé en vérifiant que la méthode de vérification d'authentification retourne "non connecté" lorsque le token est expiré.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec un token expiré en storage, **When** le système vérifie l'état d'authentification, **Then** l'état passe à "non connecté" et le token expiré est supprimé
2. **Given** un utilisateur avec un token corrompu ou invalide, **When** le système tente de le décoder, **Then** le token est supprimé et l'état passe à "non connecté"

---

### Edge Cases

- Que se passe-t-il si le localStorage est indisponible (navigation privée sur certains navigateurs) ? Le système bascule en mode session volatile (état en mémoire uniquement, perdu au rechargement) et logge un `console.error` au démarrage. Pas de signalement UI — le service fonctionne normalement sans persistance.
- Que se passe-t-il si le serveur est injoignable lors de la connexion ? Le système doit afficher un message d'erreur réseau distinct du message d'identifiants invalides (message retourné : "Impossible de contacter le serveur") et logger `console.error` pour traçabilité.
- Que se passe-t-il si le token stocké a un format invalide (manipulation manuelle) ? Le système doit le supprimer, logger `console.error('Token corrompu')`, et considérer l'utilisateur comme non connecté.
- Que se passe-t-il si deux appels de connexion sont faits simultanément ? Le dernier token reçu doit être celui stocké, sans corruption. Limitation acceptée (single-user) : pas de mutex/debounce, pas de test automatisé pour ce cas.
- Que se passe-t-il si le quota localStorage est dépassé (QuotaExceededError) ? Le try/catch autour de `setItem` intercepte l'erreur, logge `console.error('localStorage quota dépassé')`, et le service continue en mode session volatile (signal mis à jour mais pas de persistance). Même comportement que localStorage indisponible.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT permettre à un utilisateur de se connecter en fournissant un email et un mot de passe
- **FR-002**: Le système DOIT permettre à un nouvel utilisateur de s'inscrire en fournissant un email, un mot de passe et optionnellement un nom
- **FR-003**: Le système DOIT stocker le token de session dans le localStorage sous la clé `budget_token` et les informations utilisateur (nom, email) sous la clé `budget_user` (JSON) après une connexion ou inscription réussie
- **FR-004**: Le système DOIT exposer un état d'authentification réactif (signal) qui se met à jour automatiquement lors de la connexion, déconnexion ou expiration
- **FR-005**: Le système DOIT permettre à un utilisateur connecté de se déconnecter, supprimant le token et redirigeant vers `/auth`
- **FR-006**: Le système DOIT décoder le token localement (sans appel serveur) pour vérifier son expiration. Si le payload décodé ne contient pas de champ `exp`, le token est considéré comme expiré (comportement défensif)
- **FR-007**: Le système DOIT fournir une méthode pour récupérer le token stocké (pour usage par l'intercepteur HTTP et le guard)
- **FR-008**: Le système DOIT mapper les erreurs backend en messages compréhensibles : HTTP 400 → `error.error.message` tel quel ("Email ou mot de passe incorrect", "Email déjà utilisé", ou concaténation Bean Validation "field: message; field: message"), erreur réseau (status 0) → "Impossible de contacter le serveur", HTTP 500+ → "Une erreur est survenue". Cf. SC-004 pour le critère mesurable
- **FR-009**: Le système DOIT vérifier l'état du token au démarrage de l'application et restaurer la session si le token est valide
- **FR-010**: Le système DOIT exposer les informations de l'utilisateur connecté (nom, email) extraites de la réponse d'authentification

### Key Entities

- **Credentials** : Données de connexion fournies par l'utilisateur (email, mot de passe). Utilisées uniquement en transit, jamais stockées.
- **Registration Data** : Données d'inscription (nom, email, mot de passe). Utilisées uniquement en transit, jamais stockées.
- **Auth Response** : Réponse du serveur après connexion/inscription réussie. Contient le token de session, le nom et l'email de l'utilisateur.
- **Auth State** : État réactif de l'authentification. Indique si l'utilisateur est connecté et contient ses informations de profil (nom, email). Se met à jour automatiquement.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'état d'authentification (signal `currentUser`) est mis à jour de manière synchrone dans `saveAuth()`/`clearAuth()` — c'est-à-dire que le signal reflète le nouvel état avant que l'Observable login/register ne complète côté appelant. Vérifiable via tests unitaires. La latence totale perçue (réseau + backend + frontend) est hors scope de cette feature.
- **SC-002**: L'utilisateur peut s'inscrire et être automatiquement connecté en une seule action
- **SC-003**: Le rechargement de la page restaure la session sans reconnexion si le token est valide
- **SC-004**: 100% des erreurs d'authentification affichent un message compréhensible pour l'utilisateur (pas de message technique brut)
- **SC-005**: Un token expiré ou corrompu est détecté et nettoyé automatiquement sans intervention utilisateur

## Test Framework

Le Principe V (Testabilité) de la constitution cible le backend Java (JUnit 5 + Spring Boot Test + Mockito). Pour le frontend Angular, les tests utilisent Karma/Jasmine (Angular CLI default), avec les mêmes exigences de qualité : pattern AAA, nommage `should_[résultat]_when_[condition]`, couverture des cas nominaux et d'erreur.

## Assumptions

- Le backend expose déjà les endpoints d'authentification (POST `/auth/register` et POST `/auth/login`) avec les DTOs décrits (confirmé : KKS-24 Done)
- Le proxy de développement est configuré pour rediriger `/api` vers le backend (confirmé : proxy.conf.json existant)
- Le service HTTP générique (ApiService) est disponible et fonctionnel (confirmé : existant dans `core/services/api.ts`)
- Le token JWT contient un champ d'expiration standard (`exp` en secondes epoch) décodable via base64
- La clé de stockage `budget_token` n'entre pas en conflit avec d'autres données de l'application
- L'application est single-user (une seule session active par navigateur)
- La durée de vie du JWT est gérée côté backend et n'est pas configurable côté frontend
- La route `/auth` sera créée dans KKS-28 (login screen) — le `router.navigate(['/auth'])` du logout sera fonctionnel une fois cette route définie
