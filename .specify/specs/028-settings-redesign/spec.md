# Feature Specification: Refonte page Settings (8 sections)

**Feature Branch**: `028-settings-redesign`
**Created**: 2026-02-16
**Status**: Draft
**Input**: User description: "Restructurer la page Settings en 8 sections : Comptes bancaires, Categories, Budget, Notifications, Profil, Apparence (theme light/dark), Donnees (export CSV/PDF, purge), A propos. Navigation par sections. Chaque section se remplit au fur et a mesure des features V2."
**Linear**: [KKS-83](https://linear.app/kksdev/issue/KKS-83/refonte-page-settings-8-sections)

## Clarifications

### Session 2026-02-16

- Q: Perimetre de la section Profil (FR-010/FR-011 vs absence d'endpoints API profil) ? → A: Profil lecture seule — afficher nom/email depuis les donnees existantes, reporter les modifications (update nom, email, mot de passe) a une feature V2 dediee.
- Q: Quel pattern UI pour le selecteur de theme dans la section Apparence (FR-007) ? → A: Segmented control (toggle group a 3 segments : Clair, Sombre, Automatique).
- Q: Quel layout pour la grille des 8 cartes de section sur le hub Settings ? → A: Colonne unique (liste verticale) sur toutes les tailles d'ecran (mobile-first, 8 items).
- Q: Section "A propos" : pur placeholder ou contenu minimal ? → A: Contenu minimal hardcode frontend (nom de l'app, version, auteur).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigation par sections (Priority: P1)

L'utilisateur accede a la page Settings et voit une liste claire des 8 sections disponibles. Chaque section est representee par une carte avec une icone, un titre et une breve description. L'utilisateur clique sur une section pour y acceder. Un bouton retour permet de revenir a la liste des sections.

**Why this priority**: La navigation par sections est le socle de toute la refonte. Sans elle, les 8 sections ne sont pas accessibles. C'est le prerequis pour tout le reste.

**Independent Test**: Peut etre teste en naviguant vers /settings et en verifiant que les 8 cartes de section s'affichent, que chaque carte est cliquable et mene a la bonne sous-page, et que le retour fonctionne.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est connecte, **When** il accede a /settings, **Then** il voit une liste de 8 sections avec icone, titre et description pour chacune
2. **Given** l'utilisateur est sur la page settings, **When** il clique sur une section, **Then** il est redirige vers la sous-page de cette section
3. **Given** l'utilisateur est sur une sous-page de section, **When** il clique sur le bouton retour, **Then** il revient a la liste des sections

---

### User Story 2 - Section Comptes bancaires (Priority: P2)

L'utilisateur accede a la section "Comptes bancaires" pour gerer ses comptes. Cette section reprend la fonctionnalite existante de gestion des comptes (liste, ajout, modification, suppression, definir par defaut) dans le nouveau cadre de navigation.

**Why this priority**: La gestion des comptes existe deja et doit etre migree dans la nouvelle structure. C'est la section la plus mature fonctionnellement.

**Independent Test**: Peut etre teste en accedant a Settings > Comptes bancaires et en verifiant que toutes les operations CRUD sur les comptes fonctionnent comme avant.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la page settings, **When** il clique sur "Comptes bancaires", **Then** il voit la liste de ses comptes avec les memes fonctionnalites qu'actuellement
2. **Given** l'utilisateur est dans la section Comptes bancaires, **When** il effectue une operation (ajout, modification, suppression, defaut), **Then** l'operation se comporte comme dans la version actuelle

---

### User Story 3 - Section Categories (Priority: P2)

L'utilisateur accede a la section "Categories" pour gerer ses categories de transactions. Cette section reprend la fonctionnalite existante de gestion des categories (categories systeme et personnalisees, ajout, modification, suppression) dans le nouveau cadre.

**Why this priority**: Comme les comptes, les categories existent deja et doivent etre migrees.

**Independent Test**: Peut etre teste en accedant a Settings > Categories et en verifiant que la gestion des categories systeme et personnalisees fonctionne comme avant.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur la page settings, **When** il clique sur "Categories", **Then** il voit ses categories systeme et personnalisees
2. **Given** l'utilisateur est dans la section Categories, **When** il ajoute, modifie ou supprime une categorie personnalisee, **Then** l'operation fonctionne comme dans la version actuelle

---

### User Story 4 - Section Apparence (Priority: P3)

L'utilisateur accede a la section "Apparence" pour choisir le theme visuel de l'application : clair (light), sombre (dark), ou automatique (suit les preferences systeme). Le choix est persiste localement et applique immediatement.

**Why this priority**: Le theme light/dark est une fonctionnalite attendue et impactante visuellement. C'est la premiere section reellement nouvelle qui apporte de la valeur.

**Independent Test**: Peut etre teste en changeant le theme et en verifiant que l'interface bascule immediatement entre les modes clair et sombre.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est dans la section Apparence, **When** il selectionne le theme "Sombre", **Then** l'interface passe immediatement en mode sombre
2. **Given** l'utilisateur est dans la section Apparence, **When** il selectionne le theme "Clair", **Then** l'interface passe immediatement en mode clair
3. **Given** l'utilisateur a selectionne "Automatique", **When** le systeme est en mode sombre, **Then** l'application s'affiche en mode sombre
4. **Given** l'utilisateur change de theme et ferme l'application, **When** il revient, **Then** le theme choisi est toujours actif

---

### User Story 5 - Section Profil en lecture seule (Priority: P3)

L'utilisateur accede a la section "Profil" pour consulter ses informations personnelles : nom et email. La section affiche ces donnees en lecture seule. Les modifications (nom, email, mot de passe) seront ajoutees dans une feature V2 dediee.

**Why this priority**: Afficher les informations du profil donne de la coherence a la page Settings sans necessiter de travail backend supplementaire.

**Independent Test**: Peut etre teste en accedant a Settings > Profil et en verifiant que le nom et l'email de l'utilisateur connecte s'affichent correctement.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est dans la section Profil, **When** la page se charge, **Then** il voit son nom et email actuels en lecture seule
2. **Given** l'utilisateur est dans la section Profil, **When** il consulte la page, **Then** il ne voit aucun bouton de modification (fonctionnalite reportee)

---

### User Story 6 - Sections placeholder (Budget, Notifications, Donnees) (Priority: P4)

Les sections Budget, Notifications et Donnees sont accessibles depuis la navigation mais affichent un etat "a venir" avec un message indiquant que la fonctionnalite sera disponible dans une prochaine version. Cela permet de montrer la structure complete sans bloquer la livraison.

**Why this priority**: Ces sections seront remplies au fur et a mesure des features V2. Les placeholders garantissent la coherence de la navigation sans bloquer le developpement.

**Independent Test**: Peut etre teste en cliquant sur chaque section placeholder et en verifiant qu'un message "a venir" s'affiche proprement.

**Acceptance Scenarios**:

1. **Given** l'utilisateur clique sur "Budget", **When** la sous-page se charge, **Then** il voit un message "Fonctionnalite a venir" avec une illustration ou icone
2. **Given** l'utilisateur navigue entre sections placeholder, **When** il utilise le bouton retour, **Then** il revient a la liste des sections sans erreur

---

### User Story 7 - Section A propos (Priority: P4)

L'utilisateur accede a la section "A propos" pour consulter les informations de base de l'application : nom, version et auteur. Ces donnees sont hardcodees dans le frontend.

**Why this priority**: Faible effort, donne un aspect fini a la page Settings des la V1.

**Independent Test**: Peut etre teste en accedant a Settings > A propos et en verifiant que le nom de l'app, la version et l'auteur s'affichent.

**Acceptance Scenarios**:

1. **Given** l'utilisateur clique sur "A propos", **When** la sous-page se charge, **Then** il voit le nom de l'application, la version et l'auteur
2. **Given** l'utilisateur est dans la section A propos, **When** il clique sur le bouton retour, **Then** il revient a la liste des sections

---

### Edge Cases

- Que se passe-t-il si l'utilisateur accede directement a une URL de section (ex: /settings/apparence) via un lien externe ? Il doit voir la section directement avec le bouton retour fonctionnel.
- Que se passe-t-il si la persistence locale du theme echoue (storage plein) ? Le theme par defaut (clair) est applique.
- Que se passe-t-il si les donnees du profil ne sont pas disponibles (token invalide) ? La section affiche un message d'erreur et propose de se reconnecter.
- Comment se comporte la page sur ecran tres petit (< 320px) ? La liste des sections est en colonne unique avec des cartes pleine largeur (meme layout que sur ecrans plus larges, mobile-first).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT afficher une page Settings avec une liste de 8 sections navigables : Comptes bancaires, Categories, Budget, Notifications, Profil, Apparence, Donnees, A propos
- **FR-002**: Chaque section DOIT etre representee par une carte contenant une icone, un titre et une breve description, disposees en liste verticale (colonne unique) sur toutes les tailles d'ecran
- **FR-003**: Le systeme DOIT permettre la navigation vers chaque section via un clic sur sa carte
- **FR-004**: Le systeme DOIT afficher un bouton retour sur chaque sous-page de section pour revenir a la liste
- **FR-005**: La section Comptes bancaires DOIT reprendre toutes les fonctionnalites existantes de gestion des comptes (lister, ajouter, modifier, supprimer, definir par defaut)
- **FR-006**: La section Categories DOIT reprendre toutes les fonctionnalites existantes de gestion des categories (categories systeme et personnalisees, CRUD)
- **FR-007**: La section Apparence DOIT permettre de choisir entre 3 modes via un segmented control (toggle group a 3 segments) : Clair, Sombre, Automatique (preferences systeme)
- **FR-008**: Le choix de theme DOIT etre persiste localement et applique immediatement sans rechargement de page
- **FR-009**: Le mode Automatique DOIT suivre les preferences systeme de l'utilisateur (prefers-color-scheme)
- **FR-010**: La section Profil DOIT afficher le nom et l'email de l'utilisateur en lecture seule (donnees issues de la session authentifiee)
- **FR-011**: La section Profil NE DOIT PAS proposer de modification (nom, email, mot de passe) — fonctionnalite reportee a une feature V2 dediee
- **FR-012**: Les sections Budget, Notifications et Donnees DOIVENT afficher un etat placeholder "Fonctionnalite a venir"
- **FR-015**: La section A propos DOIT afficher un contenu minimal hardcode : nom de l'application, version et auteur
- **FR-013**: L'acces direct par URL a une section (ex: /settings/apparence) DOIT fonctionner et afficher la section avec la navigation retour
- **FR-014**: L'ordre d'affichage des sections DOIT etre fixe : Comptes bancaires, Categories, Budget, Notifications, Profil, Apparence, Donnees, A propos

### Key Entities

- **Section Settings**: Represente un bloc fonctionnel de la page Settings. Attributs : identifiant, titre, description, icone, statut (actif ou placeholder), route associee.
- **Theme Preference**: Represente le choix visuel de l'utilisateur. Valeurs possibles : clair, sombre, automatique. Persiste localement sur l'appareil.
- **Profil Utilisateur**: Nom, email. Donnees issues du signal `AuthService.currentUser()` (alimente au login, restaure depuis localStorage au demarrage). Lecture seule dans cette feature.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut acceder a n'importe laquelle des 8 sections en 2 interactions maximum depuis n'importe quel ecran de l'application (menu utilisateur > Settings > section)
- **SC-002**: Le changement de theme (clair/sombre) est percu instantanement par l'utilisateur (< 100ms de delai visuel)
- **SC-003**: Les fonctionnalites existantes (comptes et categories) fonctionnent de maniere identique apres la migration dans la nouvelle structure
- **SC-004**: 100% des sous-pages de section sont accessibles par URL directe (deep linking)
- **SC-005**: La page Settings se charge et affiche les 8 sections en moins de 1 seconde sur connexion mobile standard
- **SC-006**: La navigation dans les sections fonctionne sans rechargement complet de la page

## Assumptions

- La section Profil est en lecture seule dans cette feature. Les endpoints API de mise a jour du profil (nom, email, mot de passe) seront crees dans une feature V2 dediee.
- Le theme light/dark est gere uniquement cote frontend via des variables CSS et stockage local (localStorage). Aucune API backend n'est necessaire pour cette fonctionnalite.
- L'application dispose deja d'un systeme de themes (tokens CSS light/dark) dans les styles globaux qui sera exploite pour la bascule de theme.
- Les sections placeholder seront enrichies progressivement via des features V2 dediees (Budget, Notifications, Donnees).
- L'ordre des sections est celui defini dans l'issue Linear et ne changera pas sans decision explicite.
