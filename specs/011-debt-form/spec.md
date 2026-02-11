# Feature Specification: Formulaire Debt (modal)

**Feature Branch**: `011-debt-form`
**Created**: 2026-02-11
**Status**: Draft
**Input**: User description: "KKS-53 — Formulaire Debt (modal). Composant formulaire pour creer/editer une dette, affiche dans la modal du Shell."
**Linear**: KKS-53

## Clarifications

### Session 2026-02-11

- Q: Quels labels afficher sur le toggle segmente pour le sens de la dette ? → A: "Emprunt" / "Pret" (terminologie financiere)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Creer une dette (Priority: P1)

L'utilisateur ouvre la modal via le bouton flottant (+) et selectionne "Dette". Un formulaire s'affiche avec les champs necessaires pour saisir une nouvelle dette. Il remplit les informations, soumet le formulaire, et la dette est enregistree.

**Why this priority**: C'est le flux principal et la raison d'etre du composant. Sans creation, le formulaire n'a aucune utilite.

**Independent Test**: Peut etre teste en ouvrant la modal, remplissant tous les champs requis, et en verifiant que l'evenement `saved` emet un objet `DebtRequest` valide.

**Acceptance Scenarios**:

1. **Given** la modal est ouverte en mode creation (aucune dette existante passee en entree), **When** le formulaire s'affiche, **Then** les champs sont vides sauf la date (aujourd'hui), le sens (JE_DOIS par defaut) et rembourse (decoche par defaut)
2. **Given** l'utilisateur a rempli tous les champs requis (personne, montant, sens, date), **When** il soumet le formulaire, **Then** un evenement `saved` est emis avec un objet contenant les valeurs saisies
3. **Given** l'utilisateur a rempli les champs requis et laisse rembourse decoche, **When** il soumet le formulaire, **Then** l'objet emis contient `rembourse: false`

---

### User Story 2 - Validation des champs obligatoires (Priority: P1)

L'utilisateur tente de soumettre le formulaire sans remplir tous les champs requis. Le systeme affiche des messages d'erreur cibles pour chaque champ invalide et empeche la soumission.

**Why this priority**: La validation garantit l'integrite des donnees et evite des erreurs cote serveur. Indissociable de la creation.

**Independent Test**: Peut etre teste en soumettant un formulaire vide et en verifiant que les messages d'erreur apparaissent pour chaque champ requis.

**Acceptance Scenarios**:

1. **Given** le formulaire est affiche, **When** l'utilisateur soumet sans remplir le champ personne, **Then** un message d'erreur "Personne requise" s'affiche sous le champ
2. **Given** le formulaire est affiche, **When** l'utilisateur saisit un montant negatif ou zero, **Then** un message d'erreur "Le montant doit etre superieur a 0" s'affiche
3. **Given** le formulaire est affiche, **When** l'utilisateur efface la date, **Then** un message d'erreur "Date requise" s'affiche
4. **Given** le formulaire est affiche, **When** l'utilisateur saisit un nom de personne depassant 255 caracteres, **Then** un message d'erreur "255 caracteres maximum" s'affiche
5. **Given** un ou plusieurs champs sont invalides, **When** l'utilisateur tente de soumettre, **Then** le formulaire ne se soumet pas et tous les champs invalides sont mis en evidence

---

### User Story 3 - Editer une dette existante (Priority: P2)

L'utilisateur ouvre la modal pour modifier une dette existante. Le formulaire est pre-rempli avec les valeurs actuelles de la dette. Il modifie les champs souhaites et soumet pour enregistrer les changements.

**Why this priority**: L'edition est essentielle mais secondaire a la creation. Elle reutilise le meme formulaire avec un mode different.

**Independent Test**: Peut etre teste en passant une dette existante en entree et en verifiant que les champs sont pre-remplis, puis que la soumission emet les valeurs modifiees.

**Acceptance Scenarios**:

1. **Given** une dette existante est passee en entree du formulaire, **When** le formulaire s'affiche, **Then** tous les champs sont pre-remplis avec les valeurs de la dette (personne, montant, sens, date, rembourse)
2. **Given** le formulaire est pre-rempli en mode edition, **When** l'utilisateur modifie le montant et soumet, **Then** l'evenement `saved` emet un objet avec le nouveau montant et les autres valeurs inchangees
3. **Given** le formulaire est pre-rempli en mode edition avec une dette remboursee, **When** le formulaire s'affiche, **Then** la case rembourse est cochee

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

- Que se passe-t-il si le champ personne contient 255 caracteres (limite maximale) ? Le formulaire doit accepter exactement 255 caracteres et refuser au-dela.
- Que se passe-t-il si l'utilisateur saisit un montant avec plus de 2 decimales ? Le formulaire accepte la saisie (la troncature est geree cote serveur).
- Que se passe-t-il si l'utilisateur coche "rembourse" en mode creation ? Le formulaire accepte cette valeur et l'inclut dans l'objet emis.
- Que se passe-t-il si l'utilisateur change le sens de JE_DOIS a ON_ME_DOIT ? Le sens est mis a jour sans effet de bord sur les autres champs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le formulaire DOIT afficher les champs suivants : personne (texte), montant (numerique), sens (selection entre JE_DOIS et ON_ME_DOIT), date (date), rembourse (case a cocher), categorie (selection optionnelle)
- **FR-002**: Le champ personne DOIT etre obligatoire et limite a 255 caracteres maximum
- **FR-003**: Le montant DOIT etre obligatoire et strictement superieur a 0
- **FR-004**: Le sens DOIT etre obligatoire avec JE_DOIS comme valeur par defaut, presente sous forme de toggle segmente (2 boutons cote a cote : Emprunt = JE_DOIS, Pret = ON_ME_DOIT)
- **FR-005**: La date DOIT etre obligatoire avec la date du jour comme valeur par defaut
- **FR-006**: Le champ rembourse DOIT etre une case a cocher, decochee par defaut (rembourse = false)
- **FR-007**: En mode creation (aucune dette en entree), les champs DOIVENT etre initialises avec les valeurs par defaut (date = aujourd'hui, sens = JE_DOIS, rembourse = false, autres vides)
- **FR-008**: En mode edition (dette existante en entree), les champs DOIVENT etre pre-remplis avec les valeurs de la dette
- **FR-009**: La soumission DOIT etre bloquee tant que des champs requis sont invalides, avec affichage des messages d'erreur correspondants
- **FR-010**: Lors de la soumission reussie, le formulaire DOIT emettre un evenement `saved` contenant les donnees saisies au format attendu par le service
- **FR-011**: Le bouton d'annulation DOIT emettre un evenement `cancelled` sans donnees
- **FR-012**: Les messages d'erreur DOIVENT s'afficher uniquement apres que l'utilisateur a interagi avec le champ (touched) ou tente de soumettre

### Key Entities

- **Debt**: Dette entre l'utilisateur et une personne, caracterisee par un nom de personne, un montant, un sens (je dois / on me doit), une date, et un statut rembourse ou non
- **DebtRequest**: Objet de transfert contenant : personne, montant, sens (JE_DOIS ou ON_ME_DOIT), date, rembourse, categoryId (optionnel)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut creer une dette en remplissant le formulaire et en soumettant en moins de 15 secondes (3 champs requis + soumission)
- **SC-002**: 100% des champs invalides affichent un message d'erreur explicite avant la soumission
- **SC-003**: Le formulaire en mode edition affiche les valeurs existantes instantanement (pas de chargement visible)
- **SC-004**: L'annulation ferme le formulaire sans effet de bord ni perte de donnees ailleurs dans l'application
- **SC-005**: Le formulaire est utilisable sur mobile (ecran 360px de large minimum) sans defilement horizontal

## Assumptions

- Le composant modal parent (Shell) gere l'ouverture/fermeture de la modal ; le formulaire ne gere que son contenu
- Le formulaire n'appelle pas directement le service backend ; il emet un evenement avec les donnees, et le composant parent se charge de l'appel API
- Le sens par defaut est JE_DOIS car c'est le cas d'usage le plus frequent (noter ce qu'on doit a quelqu'un)
- Le champ rembourse est decoche par defaut car une nouvelle dette est typiquement en cours
- Le pattern est identique a celui des formulaires Transaction (KKS-51) et Subscription (KKS-52) : meme architecture composant, memes conventions
- Le modele Debt supporte les categories (champ `category: Category | null`). Le formulaire inclut un select categories optionnel, identique aux formulaires Transaction et Subscription
