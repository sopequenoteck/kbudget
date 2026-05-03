# Feature Specification: Écran de login et fondations UI

**Feature Branch**: `005-login-screen`
**Created**: 2026-02-08
**Status**: Draft
**Input**: User description: "Créer l'écran de login avec fondations UI (composants shared, layout shell, styles globaux)"

## Clarifications

### Session 2026-02-08

- Q: Navigation — bottom nav fixe ou sidebar ? → A: Sidebar (drawer) accessible via bouton hamburger dans le header, se ferme après navigation. Libère le bas de l'écran pour le futur bouton flottant (+).
- Q: Sidebar — overlay partout ou responsive ? → A: Responsive. Drawer overlay sur mobile (< 768px), sidebar fixe toujours visible sur desktop (>= 768px).
- Q: Sidebar overlay mobile — fermeture au clic extérieur ? → A: Oui, backdrop semi-transparent + fermeture au clic dessus.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Connexion à l'application (Priority: P1)

L'utilisateur arrive sur l'application et voit un écran de connexion. Il saisit son email et son mot de passe, puis clique sur "Se connecter". Si les identifiants sont corrects, il est redirigé vers le tableau de bord. Si les identifiants sont incorrects, un message d'erreur clair s'affiche.

**Why this priority**: C'est le point d'entrée de l'application. Sans cet écran, aucune autre fonctionnalité n'est accessible.

**Independent Test**: Peut être testé en accédant à l'application — l'écran de connexion s'affiche, les validations fonctionnent, et la connexion réussie redirige vers le tableau de bord.

**Acceptance Scenarios**:

1. **Given** un utilisateur non authentifié accède à l'application, **When** il arrive sur la page, **Then** il voit un formulaire de connexion avec les champs email et mot de passe
2. **Given** l'utilisateur saisit un email valide et un mot de passe correct, **When** il clique sur "Se connecter", **Then** il est redirigé vers le tableau de bord
3. **Given** l'utilisateur saisit des identifiants invalides, **When** il clique sur "Se connecter", **Then** un message d'erreur s'affiche sur le formulaire
4. **Given** l'utilisateur soumet le formulaire, **When** la requête est en cours, **Then** le bouton est désactivé et affiche un état de chargement

---

### User Story 2 - Navigation dans l'application authentifiée (Priority: P2)

Après s'être connecté, l'utilisateur voit une interface avec un en-tête affichant le nom de l'application, son identité, et un bouton hamburger pour ouvrir la sidebar de navigation. La sidebar permet d'accéder aux différentes sections : Accueil, Transactions, Abonnements, Dettes. Elle se ferme automatiquement après sélection d'une section sur mobile. Le bas de l'écran reste libre pour le futur bouton flottant (+).

**Why this priority**: Le layout shell est nécessaire pour naviguer entre les sections une fois authentifié. C'est le conteneur de toutes les pages protégées.

**Independent Test**: Peut être testé après connexion — l'utilisateur voit le header et la navigation, peut naviguer entre les sections, et la section active est visuellement indiquée.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifié, **When** il accède au tableau de bord, **Then** il voit un en-tête avec le nom de l'application, son nom d'utilisateur, et un bouton hamburger
2. **Given** un utilisateur authentifié sur mobile, **When** il clique sur le bouton hamburger, **Then** une sidebar s'ouvre en overlay avec les 4 sections de navigation
3. **Given** la sidebar est ouverte sur mobile, **When** l'utilisateur clique sur une section, **Then** il est redirigé vers cette section et la sidebar se ferme automatiquement
4. **Given** un utilisateur sur la page Transactions, **When** il ouvre la sidebar, **Then** la section "Transactions" est visuellement active
5. **Given** un utilisateur authentifié, **When** il clique sur "Déconnexion" dans la sidebar, **Then** il est redirigé vers l'écran de connexion
6. **Given** un utilisateur authentifié sur desktop (>= 768px), **When** il accède à l'application, **Then** la sidebar est toujours visible à côté du contenu sans bouton hamburger

---

### User Story 3 - Validation du formulaire de connexion (Priority: P1)

L'utilisateur remplit le formulaire de connexion. Le système valide les champs en temps réel : l'email doit être au format valide, le mot de passe doit contenir au moins 6 caractères. Les messages d'erreur de validation apparaissent après que l'utilisateur a interagi avec un champ puis l'a quitté.

**Why this priority**: La validation côté client est indispensable pour guider l'utilisateur et éviter les soumissions inutiles au serveur.

**Independent Test**: Peut être testé en interagissant avec les champs du formulaire — laisser un champ vide, saisir un email invalide, saisir un mot de passe trop court.

**Acceptance Scenarios**:

1. **Given** le champ email est vide, **When** l'utilisateur quitte le champ, **Then** un message d'erreur "Email requis ou invalide" s'affiche
2. **Given** le champ email contient "abc", **When** l'utilisateur quitte le champ, **Then** un message d'erreur "Email requis ou invalide" s'affiche
3. **Given** le champ mot de passe contient "abc", **When** l'utilisateur quitte le champ, **Then** un message d'erreur "6 caractères minimum" s'affiche
4. **Given** des champs invalides, **When** l'utilisateur clique sur "Se connecter", **Then** les champs invalides sont marqués et le formulaire n'est pas soumis

---

### User Story 4 - Redirection après tentative d'accès non authentifié (Priority: P2)

Un utilisateur non authentifié tente d'accéder directement à une page protégée (ex: /transactions). Il est redirigé vers l'écran de connexion. Après une connexion réussie, il est automatiquement redirigé vers la page qu'il avait initialement demandée.

**Why this priority**: Améliore l'expérience utilisateur en évitant de perdre le contexte de navigation après la connexion.

**Independent Test**: Peut être testé en accédant directement à une URL protégée sans être connecté, puis en se connectant.

**Acceptance Scenarios**:

1. **Given** un utilisateur non authentifié, **When** il accède à /transactions, **Then** il est redirigé vers l'écran de connexion
2. **Given** un utilisateur redirigé vers le login depuis /transactions, **When** il se connecte avec succès, **Then** il est redirigé vers /transactions (et non vers le tableau de bord)

---

### User Story 5 - Support du thème sombre (Priority: P3)

L'ensemble de l'interface (écran de connexion, layout shell, composants de formulaire) s'adapte automatiquement au thème sombre lorsque celui-ci est activé. Les couleurs, contrastes et surfaces s'ajustent pour une lecture confortable.

**Why this priority**: Le support du thème sombre est une fonctionnalité de confort. Le mécanisme de basculement sera implémenté ultérieurement, mais le rendu doit être correct dès maintenant.

**Independent Test**: Peut être testé en activant manuellement le thème sombre et en vérifiant que tous les éléments sont lisibles et esthétiques.

**Acceptance Scenarios**:

1. **Given** le thème sombre est activé, **When** l'utilisateur voit l'écran de connexion, **Then** les couleurs de fond, texte et composants sont adaptées au mode sombre
2. **Given** le thème sombre est activé, **When** l'utilisateur est dans le layout shell, **Then** l'en-tête et la navigation utilisent les couleurs du thème sombre

---

### Edge Cases

- Que se passe-t-il si le serveur est injoignable ? Un message d'erreur réseau clair doit s'afficher.
- Que se passe-t-il si l'utilisateur double-clique rapidement sur le bouton de connexion ? Une seule requête doit être envoyée (bouton désactivé pendant le chargement).
- Que se passe-t-il si le token JWT expire pendant la navigation ? L'utilisateur est redirigé vers l'écran de connexion.
- Que se passe-t-il sur un écran très étroit (< 320px) ? Le formulaire reste utilisable avec un scroll si nécessaire.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher un formulaire de connexion avec les champs email et mot de passe
- **FR-002**: Le système DOIT valider le champ email (requis, format email valide) avant soumission
- **FR-003**: Le système DOIT valider le champ mot de passe (requis, 6 caractères minimum) avant soumission
- **FR-004**: Le système DOIT afficher les erreurs de validation par champ après interaction utilisateur (touch + blur)
- **FR-005**: Le système DOIT désactiver le bouton de soumission pendant le traitement de la connexion et afficher un état de chargement
- **FR-006**: Le système DOIT afficher un message d'erreur global en cas d'échec de connexion (identifiants invalides, erreur réseau)
- **FR-007**: Le système DOIT rediriger vers le tableau de bord après une connexion réussie, ou vers l'URL initialement demandée si applicable
- **FR-008**: Le système DOIT fournir un layout commun (en-tête + sidebar) pour toutes les pages authentifiées
- **FR-009**: Le header DOIT afficher le nom de l'application, le nom de l'utilisateur connecté, et un bouton hamburger sur mobile (< 768px)
- **FR-010**: La sidebar DOIT comporter 4 sections : Accueil, Transactions, Abonnements, Dettes avec indication visuelle de la section active, et un lien de déconnexion en bas
- **FR-015**: Sur mobile (< 768px), la sidebar DOIT se fermer automatiquement après sélection d'une section
- **FR-016**: Sur mobile (< 768px), le header DOIT afficher un bouton hamburger pour ouvrir la sidebar en overlay avec un backdrop semi-transparent
- **FR-018**: Sur mobile, un clic sur le backdrop DOIT fermer la sidebar
- **FR-017**: Sur desktop (>= 768px), la sidebar DOIT être toujours visible (fixe) à côté du contenu
- **FR-011**: L'écran de connexion NE DOIT PAS afficher le layout commun (pas de header/nav)
- **FR-012**: Le système DOIT fournir des composants de formulaire réutilisables (wrapper champ avec label et message d'erreur)
- **FR-013**: Le système DOIT fournir des styles globaux pour les éléments de formulaire natifs (inputs, boutons)
- **FR-014**: Toute l'interface DOIT supporter les thèmes clair et sombre via les tokens de design existants

### Key Entities

- **Formulaire de connexion** : email (chaîne, format email), mot de passe (chaîne, min 6 caractères), état de chargement, message d'erreur
- **Layout shell** : en-tête (nom app, identité utilisateur, bouton hamburger), sidebar (4 sections de navigation + déconnexion), zone de contenu
- **Composant champ de formulaire** : libellé, identifiant, message d'erreur, état d'affichage de l'erreur

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Le temps de traitement technique de la connexion (depuis le clic sur "Se connecter" jusqu'à la redirection) est inférieur à 2 secondes en conditions normales
- **SC-002**: 100% des erreurs de validation sont visibles avant soumission du formulaire
- **SC-003**: L'utilisateur identifie immédiatement la section active dans la navigation
- **SC-004**: L'interface est utilisable sur un écran de 375px de large sans scroll horizontal
- **SC-005**: Le passage au thème sombre ne produit aucun élément illisible (contraste texte/fond suffisant)
- **SC-006**: Le composant champ de formulaire est réutilisable dans d'autres écrans sans modification

## Assumptions

- Le service d'authentification (login, logout, gestion du token JWT) est déjà implémenté et fonctionnel
- Le guard d'authentification et l'intercepteur JWT sont déjà en place
- Les tokens de design (couleurs, spacing, typographie, thèmes) sont déjà définis
- L'application est single-user (pas de gestion de rôles)
- La page d'inscription et la fonctionnalité "Mot de passe oublié" sont hors scope
- Le mécanisme de basculement de thème (clair/sombre) est hors scope — seul le rendu correct dans les deux thèmes est requis
- Les icônes dans la navigation sont hors scope (texte seul)
