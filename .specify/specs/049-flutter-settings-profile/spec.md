# Feature Specification: Settings — Profil

**Feature Branch**: `049-flutter-settings-profile`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "Flutter: Settings — Profil. Sous-page: nom, email, devise par défaut (SelectPicker). Appel PUT /users/me."
**Linear**: KKS-111
**Bloqué par**: KKS-110 (Settings hub refonte), KKS-96 (Widget SelectPicker)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter son profil (Priority: P1)

L'utilisateur accède à la sous-page Profil depuis le hub Paramètres pour consulter ses informations personnelles : nom, adresse email et devise par défaut. Les informations sont chargées depuis le serveur et affichées clairement.

**Why this priority**: L'affichage du profil est le prérequis à toute modification. Sans consultation, l'utilisateur ne peut pas vérifier ses données actuelles.

**Independent Test**: Peut être testé en naviguant vers /settings/profile et en vérifiant que les 3 champs (nom, email, devise) s'affichent correctement avec les données du serveur.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est authentifié et se trouve sur le hub Paramètres, **When** il tape sur la section "Profil", **Then** il voit un écran affichant son nom, son email et sa devise par défaut
2. **Given** l'écran Profil est en cours de chargement, **When** les données ne sont pas encore disponibles, **Then** un indicateur de chargement (skeleton) s'affiche à la place des valeurs
3. **Given** le chargement échoue (erreur réseau ou serveur), **When** l'écran Profil s'affiche, **Then** un message d'erreur est présenté avec la possibilité de réessayer

---

### User Story 2 - Modifier sa devise par défaut (Priority: P2)

L'utilisateur peut changer sa devise par défaut via un sélecteur dédié. Le changement est sauvegardé sur le serveur via l'API. La liste des devises disponibles est présentée dans un picker modal.

**Why this priority**: La modification de la devise est la seule donnée modifiable via l'API actuelle (PUT /users/me). C'est l'action principale de cet écran.

**Independent Test**: Peut être testé en sélectionnant une devise différente dans le picker, en sauvegardant, et en vérifiant que la nouvelle devise est persistée côté serveur.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran Profil, **When** il tape sur le champ devise, **Then** un picker modal s'ouvre listant toutes les devises disponibles (EUR, XOF, USD, GBP, CHF, CAD, MAD) avec leur symbole et nom complet
2. **Given** le picker de devises est ouvert, **When** l'utilisateur sélectionne une nouvelle devise, **Then** le champ devise se met à jour avec la nouvelle sélection
3. **Given** l'utilisateur a modifié sa devise, **When** il tape sur le bouton de sauvegarde, **Then** la modification est envoyée au serveur, un indicateur de chargement s'affiche pendant la requête, et un message de succès confirme la sauvegarde
4. **Given** l'utilisateur sauvegarde sa devise, **When** la requête serveur échoue, **Then** un message d'erreur s'affiche et la valeur précédente est restaurée

---

### User Story 3 - Consulter les champs en lecture seule (Priority: P3)

Le nom et l'email de l'utilisateur sont affichés en lecture seule. L'utilisateur comprend visuellement que ces champs ne sont pas modifiables depuis cette interface.

**Why this priority**: L'affichage en lecture seule informe l'utilisateur de ses données sans créer de confusion sur ce qui est éditable.

**Independent Test**: Peut être testé en vérifiant que les champs nom et email ne réagissent pas aux interactions tactiles et qu'ils ont un style visuel distinct des champs éditables.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran Profil, **When** il essaie de taper sur le champ nom ou email, **Then** rien ne se passe (pas de clavier, pas de modal, pas de navigation)
2. **Given** l'utilisateur consulte son profil, **When** il voit les champs nom et email, **Then** leur apparence visuelle indique clairement qu'ils sont en lecture seule (style atténué, pas d'icône d'édition)

---

### Edge Cases

- Que se passe-t-il si le nom de l'utilisateur est vide (null) ? L'écran doit afficher un placeholder comme "Non renseigné"
- Que se passe-t-il si l'utilisateur perd sa connexion pendant la sauvegarde ? Un message d'erreur réseau s'affiche et la valeur précédente est conservée
- Que se passe-t-il si le token JWT expire pendant la consultation ? Le mécanisme de refresh token existant s'applique automatiquement
- Que se passe-t-il si l'utilisateur navigue rapidement hors de l'écran pendant un chargement ? La requête en cours ne doit pas provoquer d'erreur

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher le nom de l'utilisateur, son email et sa devise par défaut sur l'écran Profil
- **FR-002**: Le système DOIT permettre la sélection de la devise par défaut via un picker modal listant les 7 devises supportées (EUR, XOF, USD, GBP, CHF, CAD, MAD)
- **FR-003**: Chaque devise dans le picker DOIT afficher son symbole et son nom complet (ex: "€ — Euro")
- **FR-004**: Le système DOIT persister le changement de devise sur le serveur via l'API dédiée
- **FR-005**: Les champs nom et email DOIVENT être en lecture seule (non modifiables par l'utilisateur)
- **FR-006**: Le système DOIT afficher un indicateur de chargement (skeleton) pendant le chargement initial des données
- **FR-007**: Le système DOIT afficher un indicateur de progression pendant la sauvegarde
- **FR-008**: Le système DOIT afficher un message de confirmation après une sauvegarde réussie
- **FR-009a**: Le système DOIT afficher un message d'erreur en cas d'échec de chargement, avec un bouton pour réessayer le chargement
- **FR-009b**: Le système DOIT afficher un message d'erreur (SnackBar) en cas d'échec de sauvegarde, et restaurer la valeur précédente
- **FR-010**: Le système DOIT afficher "Non renseigné" si le nom de l'utilisateur est absent
- **FR-011**: Le bouton de sauvegarde ne DOIT être actif que lorsqu'une modification a été effectuée

### Key Entities

- **Profil utilisateur** : Représente les informations personnelles de l'utilisateur connecté. Attributs : nom (lecture seule, optionnel), email (lecture seule), devise par défaut (modifiable). Lié à l'utilisateur authentifié.
- **Devise** : Représente une monnaie supportée par l'application. Attributs : code (identifiant unique), symbole d'affichage, nom complet, nombre de décimales. 7 devises supportées.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter ses informations de profil (nom, email, devise) en moins de 2 secondes après navigation vers l'écran (best effort — dépend du réseau/serveur)
- **SC-002**: L'utilisateur peut modifier sa devise par défaut en 3 interactions maximum (ouvrir picker → sélectionner → sauvegarder)
- **SC-003**: Le feedback visuel (succès ou erreur) est affiché dans les 3 secondes suivant l'action de sauvegarde
- **SC-004**: L'écran affiche correctement les données dans 100% des cas lorsque le serveur est joignable

## Assumptions

- L'API backend (GET /users/me et PUT /users/me) est déjà implémentée et fonctionnelle
- Le widget SelectPicker (KKS-96) sera disponible avant le développement de cette feature
- Le hub Settings refondu (KKS-110) fournira la navigation correcte vers /settings/profile
- Seule la devise est modifiable via l'API actuelle ; nom et email sont en lecture seule
- L'authentification JWT et le refresh token sont gérés par l'infrastructure existante
- Le mode data (local/remote) n'est pas pertinent pour cette feature : le profil utilisateur est toujours chargé depuis le serveur (pas de stockage local)
