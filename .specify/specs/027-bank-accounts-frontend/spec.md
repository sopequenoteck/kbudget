# Feature Specification: Comptes bancaires — Frontend (UI + Integration)

**Feature Branch**: `027-bank-accounts-frontend`
**Created**: 2026-02-16
**Status**: Draft
**Input**: User description: "AccountService frontend, selection de compte dans les formulaires Transaction et Subscription, compte par defaut pre-selectionne. Dashboard enrichi avec solde par compte + solde total. Formulaire virement entre comptes."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter mes comptes et soldes sur le dashboard (Priority: P1)

L'utilisateur ouvre l'application et voit immediatement une vue d'ensemble de ses comptes bancaires en haut du dashboard, au-dessus des KPI mensuels. Le dashboard affiche le solde total (tous comptes confondus) ainsi que le solde individuel de chaque compte. Cela lui permet de connaitre sa situation financiere globale en un coup d'oeil avant de consulter le detail mensuel.

**Why this priority**: C'est la fonctionnalite la plus visible et la plus utilisee. Sans cette vue, l'utilisateur ne peut pas exploiter les comptes bancaires au quotidien. Elle apporte une valeur immediate des la premiere ouverture de l'app.

**Independent Test**: Peut etre teste en creant 2-3 comptes via l'API puis en ouvrant le dashboard. L'utilisateur voit les soldes individuels et le total sans avoir a naviguer ailleurs.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 2 comptes (Courant: 1500 EUR, Epargne: 3000 EUR), **When** il ouvre le dashboard, **Then** il voit le solde total de 4500 EUR et chaque compte avec son solde, icone et couleur.
2. **Given** l'utilisateur n'a aucun compte, **When** il ouvre le dashboard, **Then** la section comptes affiche un etat vide avec une invitation a creer un premier compte.
3. **Given** l'utilisateur a un compte inactif, **When** il ouvre le dashboard, **Then** seuls les comptes actifs sont affiches dans la vue d'ensemble.

---

### User Story 2 - Gerer mes comptes bancaires (Priority: P1)

L'utilisateur peut creer, modifier et supprimer ses comptes bancaires depuis la sous-page Settings > Comptes. Il peut definir un nom, un type (courant, epargne, especes), un solde initial, une icone et une couleur. Il peut egalement definir un compte par defaut et activer/desactiver un compte.

**Why this priority**: La gestion des comptes est un prerequis pour toutes les autres fonctionnalites (selection dans les formulaires, virements). Sans pouvoir creer et gerer ses comptes, aucune autre story ne fonctionne.

**Independent Test**: Peut etre teste en creant un compte, le modifiant puis le supprimant. Chaque operation est verifiable independamment.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur Settings > Comptes, **When** il clique sur le bouton (+) et remplit le formulaire (nom, type, solde initial), **Then** le compte est cree et apparait dans la liste.
2. **Given** un compte existe, **When** l'utilisateur le selectionne et modifie son nom, **Then** le nom est mis a jour et la liste se rafraichit.
3. **Given** un compte sans transactions ni abonnements, **When** l'utilisateur le supprime, **Then** le compte disparait de la liste.
4. **Given** un compte a des transactions, **When** l'utilisateur tente de le supprimer, **Then** un message l'informe que la suppression est impossible.
5. **Given** un compte est defini par defaut, **When** l'utilisateur definit un autre compte par defaut, **Then** l'ancien perd le statut et le nouveau le recoit.

---

### User Story 3 - Selectionner un compte dans le formulaire de transaction (Priority: P2)

Lors de la creation ou modification d'une transaction, l'utilisateur doit choisir sur quel compte elle s'applique. Le compte par defaut est pre-selectionne pour accelerer la saisie.

**Why this priority**: Associer une transaction a un compte est le coeur de la feature. Cependant, elle necessite que les comptes existent (US2), d'ou la priorite P2.

**Independent Test**: Peut etre teste en ouvrant le formulaire de transaction et en verifiant que la liste de comptes s'affiche avec le compte par defaut pre-selectionne.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a un compte par defaut, **When** il ouvre le formulaire de creation de transaction, **Then** le champ compte est pre-rempli avec le compte par defaut.
2. **Given** l'utilisateur a 3 comptes actifs, **When** il ouvre la liste de selection de compte, **Then** les 3 comptes actifs sont affiches avec leur icone, nom et solde.
3. **Given** l'utilisateur modifie une transaction existante liee au compte Epargne, **When** il ouvre le formulaire d'edition, **Then** le compte Epargne est pre-selectionne.
4. **Given** l'utilisateur n'a aucun compte, **When** il ouvre le formulaire de transaction, **Then** un message l'invite a creer un compte d'abord.

---

### User Story 4 - Selectionner un compte dans le formulaire d'abonnement (Priority: P2)

Lors de la creation ou modification d'un abonnement, l'utilisateur peut optionnellement associer un compte bancaire. Le compte par defaut est pre-selectionne mais peut etre change ou retire.

**Why this priority**: Meme logique que US3 mais pour les abonnements. L'association compte-abonnement est optionnelle (contrairement aux transactions), ce qui la rend legerement moins critique.

**Independent Test**: Peut etre teste en ouvrant le formulaire d'abonnement et en verifiant la presence du selecteur de compte avec le choix optionnel.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a un compte par defaut, **When** il ouvre le formulaire de creation d'abonnement, **Then** le champ compte est pre-rempli avec le compte par defaut.
2. **Given** l'utilisateur est en creation d'abonnement, **When** il retire la selection de compte, **Then** l'abonnement est cree sans compte associe.
3. **Given** l'utilisateur modifie un abonnement lie au compte Courant, **When** il ouvre le formulaire d'edition, **Then** le compte Courant est pre-selectionne.

---

### User Story 5 - Effectuer un virement entre comptes (Priority: P3)

L'utilisateur peut transferer de l'argent d'un de ses comptes vers un autre. Il specifie le compte source, le compte destination, le montant et eventuellement une note. Le virement cree automatiquement deux transactions liees (debit sur le source, credit sur le destination).

**Why this priority**: Fonctionnalite avancee qui depend de l'existence des comptes et de leur integration dans les transactions. C'est un "nice to have" qui complete l'experience mais n'est pas bloquant pour l'usage courant.

**Independent Test**: Peut etre teste en effectuant un virement entre deux comptes et en verifiant que les deux transactions sont creees et que les soldes sont mis a jour.

**Acceptance Scenarios**:

1. **Given** l'utilisateur a 2 comptes actifs (Courant: 1500 EUR, Epargne: 500 EUR), **When** il effectue un virement de 200 EUR du Courant vers Epargne, **Then** le Courant affiche 1300 EUR, l'Epargne affiche 700 EUR, et deux transactions apparaissent.
2. **Given** l'utilisateur est sur le formulaire de virement, **When** il selectionne le meme compte en source et destination, **Then** un message d'erreur l'informe que les comptes doivent etre differents.
3. **Given** l'utilisateur a un seul compte, **When** il tente d'acceder au formulaire de virement, **Then** un message l'informe qu'il faut au moins deux comptes actifs.
4. **Given** l'utilisateur a un compte inactif, **When** il ouvre le formulaire de virement, **Then** le compte inactif n'apparait pas dans les choix.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur supprime un compte qui est pre-selectionne par defaut dans un formulaire ouvert ? Le formulaire doit se mettre a jour.
- Comment gerer un compte dont le solde calcule est negatif ? L'affichage doit clairement indiquer un solde negatif (couleur rouge, signe moins).
- Que se passe-t-il si l'API retourne une erreur lors de la creation d'un virement ? Le formulaire doit afficher l'erreur et ne pas creer de transactions partielles.
- Comment afficher les comptes quand il y en a beaucoup (5+) sur le dashboard ? Utiliser un scroll horizontal des cartes individuelles.
- Que se passe-t-il quand le solde d'un compte change pendant que l'utilisateur est sur le dashboard ? Le solde doit se rafraichir apres chaque action (creation transaction, virement).
- Comment gerer les transactions/abonnements existants sans compte ? Ils s'affichent normalement sans indication de compte. L'utilisateur peut assigner un compte lors de l'edition.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: L'interface DOIT afficher la liste des comptes bancaires avec leur nom, type, icone, couleur et solde calcule.
- **FR-002**: L'interface DOIT permettre de creer un compte bancaire avec les champs : nom (obligatoire), type (obligatoire), solde initial (optionnel, defaut 0), icone (optionnel, defaut selon type), couleur (optionnel, defaut selon type).
- **FR-003**: L'interface DOIT permettre de modifier un compte existant (nom, icone, couleur, statut actif). Le solde initial ne doit pas etre modifiable apres creation.
- **FR-004**: L'interface DOIT permettre de supprimer un compte qui n'a ni transactions ni abonnements associes et qui n'est pas le compte par defaut, avec un message d'erreur clair sinon. Un compte par defaut ne peut etre ni supprime ni desactive — l'utilisateur doit d'abord definir un autre compte par defaut.
- **FR-005**: L'interface DOIT permettre de definir un compte comme compte par defaut, avec un indicateur visuel sur le compte actif par defaut.
- **FR-006**: Le dashboard DOIT afficher en premiere section (au-dessus des KPI mensuels) un solde total (somme de tous les comptes actifs) et le solde individuel de chaque compte actif.
- **FR-007**: Le formulaire de transaction DOIT inclure un selecteur de compte obligatoire, pre-rempli avec le compte par defaut.
- **FR-008**: Le formulaire d'abonnement DOIT inclure un selecteur de compte optionnel, pre-rempli avec le compte par defaut mais effacable.
- **FR-009**: L'interface DOIT proposer un formulaire de virement entre comptes avec : compte source, compte destination, montant (min 0.01) et note optionnelle.
- **FR-010**: Le formulaire de virement DOIT empecher de selectionner le meme compte en source et destination.
- **FR-011**: Le formulaire de virement DOIT n'afficher que les comptes actifs dans les selecteurs.
- **FR-012**: Apres un virement reussi, l'interface DOIT rafraichir les soldes des comptes concernes.
- **FR-013**: L'interface DOIT afficher des etats vides informatifs lorsqu'aucun compte n'existe (dashboard, selecteurs de formulaire).
- **FR-014**: L'interface DOIT afficher les erreurs de l'API de maniere comprehensible (echec suppression, echec virement, etc.).
- **FR-015**: L'interface DOIT afficher les transactions et abonnements existants sans compte associe normalement (champ compte vide), et permettre l'assignation optionnelle d'un compte lors de l'edition. Le selecteur de compte est obligatoire en creation mais optionnel en edition d'une transaction sans compte pre-existant.

### Key Entities

- **Compte bancaire** : Represente un compte financier de l'utilisateur. Attributs principaux : nom, type (courant/epargne/especes), solde initial (fige a la creation), solde calcule (solde initial + somme des transactions), icone, couleur, statut par defaut, statut actif. Un utilisateur peut avoir plusieurs comptes.
- **Transaction** : Enrichie d'une association obligatoire a un compte bancaire. Attribut supplementaire : identifiant de virement (pour lier les paires de transactions de virement).
- **Abonnement** : Enrichi d'une association optionnelle a un compte bancaire.
- **Virement** : Concept representant un transfert entre deux comptes. Se materialise par deux transactions liees (un debit et un credit) partageant un identifiant commun.

## Clarifications

### Session 2026-02-16

- Q: Comment gerer les transactions et abonnements existants sans compte associe ? → A: Les afficher normalement sans indication de compte (champ vide/absent), assignation possible lors de l'edition.
- Q: Comment l'utilisateur accede-t-il a la gestion des comptes ? → A: Sous-page dans Settings (Settings > Comptes).
- Q: Ou placer la section comptes sur le dashboard ? → A: En haut du dashboard, au-dessus des KPI mensuels (premiere section visible).

## Assumptions

- L'API backend est deja implementee et fonctionnelle (CRUD comptes, virement, mise a jour transaction/abonnement avec compte).
- Le design system SCSS et les tokens de couleur existants sont suffisants pour les nouveaux composants.
- Les comptes inactifs ne sont jamais affiches dans les selecteurs de formulaire ni sur le dashboard.
- Un utilisateur peut avoir un nombre illimite de comptes mais un cas typique est 2-5 comptes.
- Les icones par defaut par type de compte (courant, epargne, especes) sont fournies par l'API.
- Le virement est toujours instantane (pas de notion de virement en attente).
- Le solde d'un compte peut etre negatif (pas de contrainte de solde minimum).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut creer un compte bancaire en moins de 30 secondes (3 champs maximum a remplir).
- **SC-002**: Le dashboard affiche le solde total et les soldes individuels des qu'il y a au moins un compte, sans action supplementaire de l'utilisateur.
- **SC-003**: La creation d'une transaction avec selection de compte prend moins de 5 secondes de plus qu'avant (grace a la pre-selection du compte par defaut).
- **SC-004**: L'utilisateur peut effectuer un virement entre deux comptes en moins de 30 secondes.
- **SC-005**: 100% des erreurs retournees par l'API sont affichees de maniere comprehensible a l'utilisateur (pas de message technique brut).
- **SC-006**: Le rafraichissement des soldes apres une action (transaction, virement) est immediat et visible sans rechargement de page.
