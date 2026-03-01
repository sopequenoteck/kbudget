# Feature Specification: Formulaire Produit (creation/edition)

**Feature Branch**: `061-flutter-product-form`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "KKS-124 — Flutter: Formulaire Produit (creation/edition)"
**Linear**: [KKS-124](https://linear.app/kksdev/issue/KKS-124)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Creer un nouveau produit (Priority: P1)

L'utilisateur accede a la liste des produits dans le module Boutique. Il appuie sur le bouton d'ajout (+) pour ouvrir le formulaire de creation en modal (bottom sheet). Il remplit les champs obligatoires (nom, prix d'achat, prix de vente, stock initial) et optionnellement une description et une image produit (via selecteur photo camera/galerie). La marge calculee s'affiche en temps reel a mesure qu'il saisit les prix. Il valide et le produit est cree via l'API.

**Why this priority**: La creation de produit est le cas d'usage principal et prerequis a toute autre interaction avec le module Boutique.

**Independent Test**: Peut etre teste en ouvrant le formulaire, remplissant les champs et verifiant que le produit apparait dans la liste apres sauvegarde.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'ecran liste des produits, **When** il appuie sur le bouton d'ajout, **Then** le formulaire de creation s'ouvre en modal bottom sheet avec tous les champs vides.
2. **Given** le formulaire de creation est ouvert, **When** l'utilisateur remplit nom, prix d'achat (5.00), prix de vente (8.00) et stock (10), **Then** la marge affichee en temps reel indique 3.00.
3. **Given** tous les champs obligatoires sont remplis avec des valeurs valides, **When** l'utilisateur appuie sur "Enregistrer", **Then** le produit est cree via l'API, la modal se ferme et la liste se met a jour.
4. **Given** le formulaire de creation est ouvert, **When** l'utilisateur saisit un stock initial > 0 et enregistre, **Then** une transaction DEPENSE est generee automatiquement cote serveur (via l'endpoint restock).

---

### User Story 2 - Editer un produit existant (Priority: P2)

L'utilisateur selectionne un produit existant dans la liste pour l'editer. Le formulaire s'ouvre pre-rempli avec les donnees actuelles du produit. Le champ stock n'est pas editable (les ajustements de stock passent par restock/sell). L'utilisateur modifie les champs souhaites et enregistre.

**Why this priority**: L'edition est le second cas d'usage le plus frequent, indispensable pour corriger des erreurs ou mettre a jour les prix.

**Independent Test**: Peut etre teste en selectionnant un produit existant, modifiant un champ, sauvegardant et verifiant que les modifications sont persistees.

**Acceptance Scenarios**:

1. **Given** un produit existant avec nom "T-shirt", prix achat 5.00, prix vente 12.00, **When** l'utilisateur ouvre le formulaire d'edition, **Then** les champs sont pre-remplis avec ces valeurs et le champ stock est masque (absent du formulaire).
2. **Given** le formulaire d'edition est ouvert, **When** l'utilisateur modifie le prix de vente a 15.00, **Then** la marge affichee se met a jour en temps reel (15.00 - 5.00 = 10.00).
3. **Given** des modifications valides ont ete apportees, **When** l'utilisateur appuie sur "Enregistrer", **Then** le produit est mis a jour via l'API, la modal se ferme et la liste reflete les modifications.

---

### User Story 3 - Validation des saisies (Priority: P2)

Le formulaire empeche la soumission de donnees invalides et affiche des messages d'erreur clairs.

**Why this priority**: La validation garantit l'integrite des donnees et une bonne experience utilisateur, evitant les erreurs silencieuses.

**Independent Test**: Peut etre teste en tentant de soumettre le formulaire avec des donnees invalides et verifiant que les erreurs apparaissent.

**Acceptance Scenarios**:

1. **Given** le formulaire est ouvert, **When** l'utilisateur tente d'enregistrer avec le nom vide, **Then** un message d'erreur s'affiche sous le champ nom.
2. **Given** le formulaire est ouvert, **When** l'utilisateur saisit un prix d'achat de 0 ou negatif, **Then** un message d'erreur s'affiche indiquant que le prix doit etre superieur a 0.
3. **Given** le formulaire de creation est ouvert, **When** l'utilisateur saisit un stock initial negatif, **Then** un message d'erreur s'affiche indiquant que le stock doit etre >= 0.
4. **Given** le formulaire contient des erreurs de validation, **When** l'utilisateur appuie sur "Enregistrer", **Then** la soumission est bloquee et les champs en erreur sont mis en evidence.

---

### User Story 4 - Affichage de la marge en temps reel (Priority: P3)

Pendant la saisie, la marge (prix de vente - prix d'achat) est calculee et affichee dynamiquement pour aider l'utilisateur a ajuster ses prix.

**Why this priority**: Fonctionnalite d'aide a la decision, non bloquante mais ameliore significativement l'experience.

**Independent Test**: Peut etre teste en modifiant les champs prix et verifiant que l'indicateur de marge se met a jour instantanement.

**Acceptance Scenarios**:

1. **Given** le formulaire est ouvert avec prix d'achat = 10.00 et prix de vente = 25.00, **When** l'utilisateur consulte l'indicateur de marge, **Then** la marge affichee est 15.00.
2. **Given** le formulaire est ouvert, **When** le prix d'achat est superieur au prix de vente, **Then** la marge affichee est negative et visuellement distincte (couleur d'alerte).
3. **Given** le formulaire est ouvert, **When** un seul des deux champs de prix est rempli, **Then** la marge n'est pas affichee ou indique un etat incomplet.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur ferme la modal sans enregistrer ? La modal se ferme immediatement sans confirmation, les donnees saisies sont perdues (pas de brouillon).
- Que se passe-t-il si la requete API echoue lors de la sauvegarde ? Un message d'erreur s'affiche et le formulaire reste ouvert pour permettre une nouvelle tentative.
- Que se passe-t-il si l'utilisateur saisit un prix avec plus de 2 decimales ? Le systeme limite la saisie a 2 decimales.
- Que se passe-t-il si le nom du produit depasse une longueur raisonnable ? Le champ est limite a 100 caracteres.
- Que se passe-t-il en cas de perte de connexion pendant la sauvegarde ? Un message d'erreur reseau s'affiche, le formulaire reste ouvert.
- Que se passe-t-il quand l'utilisateur remplace ou supprime l'image d'un produit ? L'ancien fichier local est automatiquement supprime pour eviter les fichiers orphelins.
- Que se passe-t-il si l'utilisateur refuse la permission camera ou galerie ? Le selecteur se ferme silencieusement, aucun changement d'image n'est applique.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT afficher un formulaire modal (bottom sheet) pour la creation d'un produit avec les champs : nom (obligatoire), description (optionnel), image produit (optionnel, selecteur photo camera/galerie stockee en fichier local), prix d'achat (obligatoire), prix de vente (obligatoire), stock initial (obligatoire en creation uniquement).
- **FR-002**: Le systeme DOIT afficher le meme formulaire en mode edition, pre-rempli avec les donnees du produit existant. Le champ stock initial est masque (absent du formulaire) — les ajustements de stock passent par les flux restock/sell dedies. Le toggle actif/inactif est egalement exclu du formulaire (gere par une action dediee dans la liste).
- **FR-003**: Le systeme DOIT valider les saisies : nom non vide (max 100 caracteres), description max 500 caracteres (optionnel), prix d'achat > 0, prix de vente > 0, stock initial >= 0.
- **FR-004**: Le systeme DOIT calculer et afficher la marge (prix de vente - prix d'achat) en temps reel a chaque modification des champs de prix.
- **FR-005**: Le systeme DOIT afficher la marge negative avec un indicateur visuel distinct (couleur d'alerte) lorsque le prix d'achat depasse le prix de vente.
- **FR-006**: Le systeme DOIT persister le produit via l'API existante (creation ou mise a jour) et mettre a jour la liste des produits apres sauvegarde reussie.
- **FR-007**: Le systeme DOIT afficher un indicateur de chargement pendant la sauvegarde et empecher les soumissions multiples.
- **FR-008**: Le systeme DOIT afficher un message d'erreur utilisateur en cas d'echec de la requete API, sans fermer le formulaire.
- **FR-009**: Le systeme DOIT limiter la saisie des prix a 2 decimales maximum.
- **FR-010**: Le systeme DOIT supprimer automatiquement l'ancien fichier image local lorsque l'utilisateur remplace ou supprime l'image d'un produit, afin d'eviter l'accumulation de fichiers orphelins.
- **FR-011**: Le systeme DOIT afficher l'image produit (si disponible) dans la liste des produits, avec fallback sur l'icone emoji ou le placeholder par defaut.

### Key Entities

- **Product**: Represente un article en vente dans la boutique. Attributs principaux : nom, description, imageUrl (chemin fichier local envoye tel quel a l'API), prix d'achat, prix de vente, stock. Relation avec l'utilisateur (proprietaire) et optionnellement avec les transactions (achats de stock).

## Assumptions

- L'endpoint API pour creer et modifier un produit existe deja (CRUD Product — KKS-123 / feature 060).
- Le widget AppModal (bottom sheet modal) existe et est reutilisable.
- Le widget AppFormField supporte les types texte, multiline et numerique.
- Le package `image_picker` est disponible pour la selection photo (camera/galerie).
- Les images produit sont stockees en fichier local sur le device (pas d'upload serveur). Le champ `imageUrl` stocke le chemin du fichier local.
- En mode creation avec stock > 0, le backend genere automatiquement la transaction DEPENSE associee (endpoint restock) — ce comportement est cote serveur, pas cote formulaire. **A verifier** : confirmer que l'endpoint POST /products (feature 056-057) declenche bien le restock automatique.
- Les prix sont exprimes dans la devise de l'utilisateur (pas de gestion multi-devises dans ce formulaire).

## Clarifications

### Session 2026-03-01

- Q: En mode edition, le champ stock initial doit-il etre masque (absent) ou desactive (grise) ? → A: Masque — le champ n'apparait pas du tout en mode edition.
- Q: Faut-il afficher une confirmation quand l'utilisateur ferme la modal avec des modifications non sauvegardees ? → A: Non — fermeture immediate sans confirmation.
- Q: Le formulaire d'edition doit-il inclure un toggle actif/inactif pour le produit ? → A: Non — la desactivation est geree hors du formulaire (action dediee dans la liste).
- Q: Le champ imageUrl est absent du formulaire. Emoji ou image ? → A: Supprimer l'emoji, le remplacer par un selecteur photo (camera + galerie) avec stockage fichier local (pas d'upload serveur).
- Q: Que se passe-t-il avec l'ancien fichier image local lors du remplacement/suppression ? → A: Suppression automatique de l'ancien fichier pour eviter les fichiers orphelins.
- Q: Que se passe-t-il avec le champ `imageUrl` lors de l'envoi a l'API ? → A: Le chemin local du fichier image est envoye a l'API comme `imageUrl` (suffisant pour single-user/single-device).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut creer un produit en moins de 30 secondes en remplissant les champs obligatoires et en enregistrant.
- **SC-002**: L'utilisateur peut editer un produit existant en moins de 15 secondes.
- **SC-003**: 100% des tentatives de soumission avec des donnees invalides sont bloquees avec un message d'erreur clair sur le champ concerne.
- **SC-004**: La marge se met a jour en temps reel (moins de 100ms de delai percu) a chaque modification de prix.
- **SC-005**: Apres sauvegarde reussie, la liste des produits reflete immediatement la creation ou la modification.
