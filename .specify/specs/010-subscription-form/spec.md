# Feature Specification: Formulaire Subscription (modal)

**Feature Branch**: `010-subscription-form`
**Created**: 2026-02-09
**Status**: Draft
**Input**: User description: "KKS-52 — Formulaire Subscription (modal). Composant formulaire pour creer/editer un abonnement, affiche dans la modal du Shell."
**Linear**: KKS-52

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Creer un abonnement (Priority: P1)

L'utilisateur ouvre la modal via le bouton flottant (+) et selectionne "Abonnement". Un formulaire s'affiche avec les champs necessaires pour saisir un nouvel abonnement. Il remplit les informations, soumet le formulaire, et l'abonnement est enregistre.

**Why this priority**: C'est le flux principal et la raison d'etre du composant. Sans creation, le formulaire n'a aucune utilite.

**Independent Test**: Peut etre teste en ouvrant la modal, remplissant tous les champs requis, et en verifiant que l'evenement `saved` emet un objet `SubscriptionRequest` valide.

**Acceptance Scenarios**:

1. **Given** la modal est ouverte en mode creation (aucun abonnement existant passe en entree), **When** le formulaire s'affiche, **Then** les champs sont vides sauf la date de debut (aujourd'hui), la frequence (MENSUEL par defaut) et le statut actif (coche par defaut)
2. **Given** l'utilisateur a rempli tous les champs requis (nom, montant, frequence, date de debut), **When** il soumet le formulaire, **Then** un evenement `saved` est emis avec un objet contenant les valeurs saisies
3. **Given** l'utilisateur a rempli les champs requis et optionnels (categorie, actif decoche), **When** il soumet le formulaire, **Then** l'objet emis contient aussi `categoryId` et `actif: false`

---

### User Story 2 - Validation des champs obligatoires (Priority: P1)

L'utilisateur tente de soumettre le formulaire sans remplir tous les champs requis. Le systeme affiche des messages d'erreur cibles pour chaque champ invalide et empeche la soumission.

**Why this priority**: La validation garantit l'integrite des donnees et evite des erreurs cote serveur. Indissociable de la creation.

**Independent Test**: Peut etre teste en soumettant un formulaire vide et en verifiant que les messages d'erreur apparaissent pour chaque champ requis.

**Acceptance Scenarios**:

1. **Given** le formulaire est affiche, **When** l'utilisateur soumet sans remplir le nom, **Then** un message d'erreur "Nom requis" s'affiche sous le champ
2. **Given** le formulaire est affiche, **When** l'utilisateur saisit un montant negatif ou zero, **Then** un message d'erreur "Le montant doit etre superieur a 0" s'affiche
3. **Given** le formulaire est affiche, **When** l'utilisateur efface la date de debut, **Then** un message d'erreur "Date de debut requise" s'affiche
4. **Given** un ou plusieurs champs sont invalides, **When** l'utilisateur tente de soumettre, **Then** le formulaire ne se soumet pas et tous les champs invalides sont mis en evidence

---

### User Story 3 - Editer un abonnement existant (Priority: P2)

L'utilisateur ouvre la modal pour modifier un abonnement existant. Le formulaire est pre-rempli avec les valeurs actuelles de l'abonnement. Il modifie les champs souhaites et soumet pour enregistrer les changements.

**Why this priority**: L'edition est essentielle mais secondaire a la creation. Elle reutilise le meme formulaire avec un mode different.

**Independent Test**: Peut etre teste en passant un abonnement existant en entree et en verifiant que les champs sont pre-remplis, puis que la soumission emet les valeurs modifiees.

**Acceptance Scenarios**:

1. **Given** un abonnement existant est passe en entree du formulaire, **When** le formulaire s'affiche, **Then** tous les champs sont pre-remplis avec les valeurs de l'abonnement (nom, montant, frequence, date de debut, categorie, actif)
2. **Given** le formulaire est pre-rempli en mode edition, **When** l'utilisateur modifie le montant et soumet, **Then** l'evenement `saved` emet un objet avec le nouveau montant et les autres valeurs inchangees

---

### User Story 4 - Annuler la saisie (Priority: P2)

L'utilisateur decide d'annuler la saisie en cours. Il clique sur le bouton d'annulation et la modal se ferme sans enregistrer de donnees.

**Why this priority**: L'annulation est un flux standard necessaire pour une bonne experience utilisateur.

**Independent Test**: Peut etre teste en cliquant sur le bouton annuler et en verifiant que l'evenement `cancelled` est emis sans aucune donnee.

**Acceptance Scenarios**:

1. **Given** le formulaire est affiche (creation ou edition), **When** l'utilisateur clique sur "Annuler", **Then** un evenement `cancelled` est emis
2. **Given** l'utilisateur a rempli des champs, **When** il clique sur "Annuler", **Then** les donnees saisies sont perdues et aucun evenement `saved` n'est emis

---

### Edge Cases

- Que se passe-t-il si le nom contient 255 caracteres (limite maximale) ? Le formulaire doit accepter exactement 255 caracteres et refuser au-dela.
- Que se passe-t-il si l'utilisateur saisit un montant avec plus de 2 decimales ? Le formulaire accepte la saisie (la troncature est geree cote serveur).
- Que se passe-t-il si aucune categorie n'est disponible ? Le champ categorie affiche uniquement l'option par defaut "Aucune categorie".
- Que se passe-t-il si l'abonnement passe en mode edition a une categorie qui n'existe plus ? Le champ categorie revient a l'option par defaut "Aucune categorie".
- Que se passe-t-il si l'utilisateur change la frequence de MENSUEL a ANNUEL en mode edition ? La frequence est mise a jour sans effet de bord sur les autres champs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le formulaire DOIT afficher les champs suivants : nom (texte), montant (numerique), frequence (selection entre MENSUEL et ANNUEL), date de debut (date), categorie (selection optionnelle), actif (case a cocher)
- **FR-002**: Le nom DOIT etre obligatoire et limite a 255 caracteres maximum
- **FR-003**: Le montant DOIT etre obligatoire et strictement superieur a 0
- **FR-004**: La frequence DOIT etre obligatoire avec MENSUEL comme valeur par defaut, presentee sous forme de toggle segmente (2 boutons cote a cote : Mensuel / Annuel)
- **FR-005**: La date de debut DOIT etre obligatoire avec la date du jour comme valeur par defaut
- **FR-006**: La categorie DOIT etre un champ optionnel presentant la liste des categories disponibles
- **FR-007**: Le champ actif DOIT etre une case a cocher, cochee par defaut (actif = true)
- **FR-008**: En mode creation (aucun abonnement en entree), les champs DOIVENT etre initialises avec les valeurs par defaut (date = aujourd'hui, frequence = MENSUEL, actif = true, autres vides)
- **FR-009**: En mode edition (abonnement existant en entree), les champs DOIVENT etre pre-remplis avec les valeurs de l'abonnement
- **FR-010**: La soumission DOIT etre bloquee tant que des champs requis sont invalides, avec affichage des messages d'erreur correspondants
- **FR-011**: Lors de la soumission reussie, le formulaire DOIT emettre un evenement `saved` contenant les donnees saisies au format attendu par le service
- **FR-012**: Le bouton d'annulation DOIT emettre un evenement `cancelled` sans donnees
- **FR-013**: Les messages d'erreur DOIVENT s'afficher uniquement apres que l'utilisateur a interagi avec le champ (touched) ou tente de soumettre

### Key Entities

- **Subscription**: Abonnement recurrent caracterise par un nom, un montant, une frequence (mensuel ou annuel), une date de debut, un statut actif/inactif, et une categorie optionnelle
- **Categorie**: Classification d'un abonnement, identifiee par un nom, une icone et une couleur. Selectionnee par l'utilisateur dans une liste deroulante
- **SubscriptionRequest**: Objet de transfert contenant : nom, montant, frequence, dateDebut, actif (optionnel, defaut true), categoryId (optionnel)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut creer un abonnement en remplissant le formulaire et en soumettant en moins de 15 secondes (3 champs requis + soumission)
- **SC-002**: 100% des champs invalides affichent un message d'erreur explicite avant la soumission
- **SC-003**: Le formulaire en mode edition affiche les valeurs existantes instantanement (pas de chargement visible)
- **SC-004**: L'annulation ferme le formulaire sans effet de bord ni perte de donnees ailleurs dans l'application
- **SC-005**: Le formulaire est utilisable sur mobile (ecran 360px de large minimum) sans defilement horizontal

## Assumptions

- Les categories sont deja disponibles via un service existant et chargees dans le composant
- Le composant modal parent (Shell) gere l'ouverture/fermeture de la modal ; le formulaire ne gere que son contenu
- Le formulaire n'appelle pas directement le service backend ; il emet un evenement avec les donnees, et le composant parent se charge de l'appel API
- La frequence par defaut est MENSUEL car c'est le cas d'usage le plus frequent pour les abonnements recurrents
- Le champ actif est coche par defaut car un nouvel abonnement est typiquement actif
- Le pattern est identique a celui du formulaire Transaction (KKS-51) : meme architecture composant, memes conventions
