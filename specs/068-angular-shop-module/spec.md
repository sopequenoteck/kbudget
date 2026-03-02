# Feature Specification: Module Boutique Angular

**Feature Branch**: `068-angular-shop-module`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "KKS-154 — Module Boutique Angular (liste, formulaire, detail, ventes/restock)"
**Linear**: [KKS-154](https://linear.app/kksdev/issue/KKS-154)

## Clarifications

### Session 2026-03-02

- Q: L'utilisateur doit-il pouvoir voir et filtrer les produits inactifs dans la liste ? → A: Oui. Filtre actifs/inactifs avec vue par defaut = actifs, toggle pour voir tous/inactifs. Modification backend si necessaire (parametre `?includeInactive=true`).
- Q: Quel layout pour la liste des produits (grille de cartes vs liste verticale) ? → A: Liste verticale avec ListItem, meme pattern que Flutter et les autres modules Angular (transactions, abonnements). Chaque item : icone/image, nom, stock, prix de vente, statut ventes/rupture.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter la liste des produits (Priority: P1)

L'utilisateur accede a la page Boutique pour voir ses produits. Par defaut, seuls les produits actifs sont affiches. Un filtre permet de basculer entre actifs, inactifs, ou tous. Il voit chaque produit avec son nom, son icone/image, son prix de vente et son stock actuel. Un indicateur visuel distingue les produits en rupture de stock (stock = 0). Les produits inactifs sont egalement visuellement differencies. Un skeleton loading s'affiche pendant le chargement. Un etat vide propose de creer un premier produit.

**Why this priority** : Sans la liste, aucune autre fonctionnalite du module n'est accessible. C'est le point d'entree obligatoire.

**Independent Test** : Peut etre teste en accedant a `/shop` apres avoir active la feature SHOP et cree au moins un produit via l'API.

**Acceptance Scenarios**:

1. **Given** la feature SHOP est activee et des produits existent, **When** l'utilisateur accede a `/shop`, **Then** la liste des produits actifs s'affiche par defaut avec nom, icone/image, prix de vente et stock.
2. **Given** la feature SHOP est activee et aucun produit n'existe, **When** l'utilisateur accede a `/shop`, **Then** un etat vide s'affiche avec un message et un bouton pour creer un premier produit.
3. **Given** la liste est en cours de chargement, **When** l'utilisateur attend, **Then** un skeleton loading s'affiche a la place des donnees.
4. **Given** un produit a un stock de 0, **When** la liste s'affiche, **Then** ce produit est visuellement attenue (opacite reduite) pour indiquer la rupture de stock.
5. **Given** la feature SHOP est desactivee, **When** l'utilisateur tente d'acceder a `/shop`, **Then** il est redirige vers le dashboard.
6. **Given** la liste affiche les produits actifs, **When** l'utilisateur active le filtre "inactifs" ou "tous", **Then** la liste se met a jour pour afficher les produits correspondants, avec les inactifs visuellement differencies.

---

### User Story 2 - Creer et modifier un produit (Priority: P1)

L'utilisateur cree un nouveau produit via un formulaire accessible depuis la liste. Il renseigne le nom, la description (optionnelle), l'icone (emoji, optionnel), l'URL d'image (optionnelle), le prix d'achat, le prix de vente et le stock initial. Un indicateur de marge s'affiche en temps reel (prix vente - prix achat). L'utilisateur peut aussi modifier un produit existant, avec les memes champs sauf le stock (non modifiable en edition).

**Why this priority** : La creation de produits est indispensable pour alimenter la boutique. La modification est necessaire pour corriger les erreurs.

**Independent Test** : Peut etre teste en ouvrant le formulaire, remplissant les champs et verifiant que le produit apparait dans la liste.

**Acceptance Scenarios**:

1. **Given** la liste des produits est affichee, **When** l'utilisateur clique sur le bouton d'ajout, **Then** le formulaire de creation s'ouvre dans le modal global.
2. **Given** le formulaire est ouvert, **When** l'utilisateur remplit les champs obligatoires (nom, prix achat, prix vente, stock) et valide, **Then** le produit est cree et la liste se rafraichit.
3. **Given** le formulaire est ouvert avec des prix renseignes, **When** l'utilisateur modifie prix achat ou prix vente, **Then** l'indicateur de marge se met a jour en temps reel.
4. **Given** le formulaire est ouvert, **When** l'utilisateur soumet avec des champs invalides (nom vide, prix negatif, etc.), **Then** des messages d'erreur de validation s'affichent sur les champs concernes.
5. **Given** un produit existant, **When** l'utilisateur ouvre le formulaire en mode edition, **Then** les champs sont pre-remplis et le champ stock est masque.
6. **Given** le formulaire en mode edition, **When** l'utilisateur modifie les champs et valide, **Then** le produit est mis a jour et la liste se rafraichit.
7. **Given** le formulaire en mode edition, **When** l'utilisateur choisit de supprimer le produit, **Then** une confirmation est demandee puis le produit est supprime.

---

### User Story 3 - Consulter le detail d'un produit (Priority: P2)

L'utilisateur accede a la page detail d'un produit en cliquant dessus dans la liste. Il y voit toutes les informations du produit, des statistiques calculees (marge unitaire, chiffre d'affaires, marge totale) et des actions rapides (vendre, restocker). L'historique des ventes est affiche en bas de page.

**Why this priority** : Le detail fournit une vue complete et les actions de vente/restock. Necessaire pour l'exploitation quotidienne mais la liste seule est deja fonctionnelle.

**Independent Test** : Peut etre teste en cliquant sur un produit dans la liste et verifiant les informations affichees et les stats calculees.

**Acceptance Scenarios**:

1. **Given** la liste des produits, **When** l'utilisateur clique sur un produit, **Then** la page detail s'affiche avec nom, description, icone/image, prix achat, prix vente, stock, total vendu, statut actif/inactif.
2. **Given** la page detail, **When** elle s'affiche, **Then** les statistiques calculees sont visibles : marge unitaire (prixVente - prixAchat), CA (totalVendu x prixVente), marge totale (totalVendu x margeUnitaire).
3. **Given** la page detail, **When** l'utilisateur clique sur "Modifier", **Then** le formulaire d'edition s'ouvre dans le modal global.

---

### User Story 4 - Vendre un produit (Priority: P2)

L'utilisateur peut vendre un produit de deux facons : (1) depuis la page detail, vente rapide de 1 unite via un bouton "Vendre" avec confirmation ; (2) depuis le FAB sur la page `/shop`, via un dialog "Vente rapide" permettant de choisir le produit et la quantite. La vente decremente le stock, incremente le total vendu et genere automatiquement une transaction de type RECETTE sur le compte Boutique.

**Why this priority** : La vente est la fonction principale de la boutique. Essentielle pour l'exploitation, mais depend de la page detail.

**Independent Test** : Peut etre teste en cliquant sur "Vendre" depuis le detail ou via le FAB, et verifiant que le stock decremente et une transaction apparait.

**Acceptance Scenarios**:

1. **Given** un produit avec stock > 0 sur la page detail, **When** l'utilisateur clique sur "Vendre", **Then** une confirmation est demandee, puis le stock decremente de 1, le total vendu augmente de 1, et la page se rafraichit.
2. **Given** un produit avec stock = 0 sur la page detail, **When** l'utilisateur essaie de vendre, **Then** le bouton "Vendre" est desactive et un message indique la rupture de stock.
3. **Given** un produit inactif, **When** l'utilisateur essaie de vendre, **Then** l'action est impossible (bouton desactive).
4. **Given** la page `/shop`, **When** l'utilisateur clique sur le FAB puis "Vente rapide", **Then** un dialog s'ouvre avec un selecteur de produit (produits actifs avec stock > 0) et un champ quantite. Apres validation, le stock decremente de N unites et la liste se rafraichit.

---

### User Story 5 - Restocker un produit (Priority: P2)

Depuis la page detail, l'utilisateur peut restocker un produit en indiquant une quantite. Le restock ajoute les unites au stock et genere automatiquement une transaction de type DEPENSE sur le compte Boutique.

**Why this priority** : Le restock permet de gerer l'inventaire. Complementaire a la vente.

**Independent Test** : Peut etre teste en cliquant sur "Restocker", en saisissant une quantite et verifiant que le stock augmente.

**Acceptance Scenarios**:

1. **Given** la page detail d'un produit, **When** l'utilisateur clique sur "Restocker", **Then** un dialog s'ouvre demandant la quantite a ajouter.
2. **Given** le dialog de restock ouvert, **When** l'utilisateur saisit une quantite valide (> 0) et confirme, **Then** le stock augmente de la quantite indiquee et la page se rafraichit.
3. **Given** le dialog de restock ouvert, **When** l'utilisateur saisit une quantite invalide (0 ou negative), **Then** la validation empeche la soumission.

---

### User Story 6 - Consulter l'historique des ventes (Priority: P3)

Sur la page detail d'un produit, l'utilisateur voit l'historique de toutes les transactions liees a ce produit (ventes et restocks), triees par date decroissante.

**Why this priority** : L'historique est utile pour le suivi mais pas indispensable au fonctionnement quotidien.

**Independent Test** : Peut etre teste en verifiant que les transactions affichees correspondent aux ventes et restocks effectues pour ce produit.

**Acceptance Scenarios**:

1. **Given** un produit avec des transactions, **When** la page detail s'affiche, **Then** l'historique des ventes est visible avec date, libelle, montant et type (RECETTE pour vente, DEPENSE pour restock).
2. **Given** un produit sans aucune transaction, **When** la page detail s'affiche, **Then** un message "Aucune transaction" s'affiche dans la section historique.

---

### Edge Cases

- Que se passe-t-il si l'utilisateur tente de vendre un produit dont le stock vient de passer a 0 (concurrence) ? Le serveur renvoie une erreur 409 et un message explicite est affiche.
- Que se passe-t-il si le serveur est injoignable lors d'une action ? Un message d'erreur s'affiche et l'utilisateur peut reessayer.
- Que se passe-t-il si un produit est supprime pendant qu'un autre onglet affiche son detail ? Une erreur 404 est geree gracieusement avec un retour a la liste.
- Que se passe-t-il avec des montants comportant beaucoup de decimales ? Les prix sont limites a 2 decimales.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** : Le systeme DOIT afficher la liste des produits en liste verticale (meme pattern que transactions/abonnements). Chaque item affiche : icone ou image, nom, stock, prix de vente, et statut (nombre de ventes ou "Rupture"). Par defaut, seuls les produits actifs sont affiches.
- **FR-001b** : Le systeme DOIT proposer un filtre permettant de basculer entre les produits actifs, inactifs, ou tous. Les produits inactifs sont visuellement differencies.
- **FR-002** : Le systeme DOIT afficher un skeleton loading pendant le chargement de la liste.
- **FR-003** : Le systeme DOIT afficher un etat vide lorsqu'aucun produit n'existe, avec un appel a l'action pour en creer un.
- **FR-004** : Le systeme DOIT afficher les produits en rupture de stock (stock = 0) avec une opacite reduite.
- **FR-005** : Le systeme DOIT permettre la creation d'un produit via un formulaire avec les champs : nom (obligatoire), description (optionnel), icone emoji (optionnel), URL image (optionnel), prix d'achat (obligatoire, > 0), prix de vente (obligatoire, > 0), stock initial (obligatoire, >= 0).
- **FR-006** : Le systeme DOIT afficher un indicateur de marge en temps reel (prix vente - prix achat) dans le formulaire.
- **FR-007** : Le systeme DOIT valider les champs du formulaire avant soumission : nom non vide (max 100 car.), prix positifs (max 2 decimales), stock >= 0.
- **FR-008** : Le systeme DOIT permettre la modification d'un produit existant, avec les memes champs sauf le stock (non editable) et un champ "actif" supplementaire.
- **FR-009** : Le systeme DOIT permettre la suppression d'un produit avec une confirmation prealable.
- **FR-010** : Le systeme DOIT afficher la page detail d'un produit avec toutes ses informations et des statistiques : marge unitaire, chiffre d'affaires total, marge totale.
- **FR-011** : Le systeme DOIT permettre de vendre N unites d'un produit : 1 unite via le bouton "Vendre" de la page detail (confirmation simple), ou N unites via le dialog "Vente rapide" du FAB (selecteur produit + quantite).
- **FR-012** : Le systeme DOIT desactiver l'action de vente si le stock est a 0 ou si le produit est inactif.
- **FR-018** : Le FAB sur la page `/shop` DOIT proposer deux actions : "Nouveau produit" (ouvre le formulaire modal) et "Vente rapide" (ouvre le dialog de vente avec selecteur produit et quantite).
- **FR-013** : Le systeme DOIT permettre de restocker un produit via un dialog demandant la quantite (entier > 0).
- **FR-014** : Le systeme DOIT afficher l'historique des transactions liees a un produit (ventes et restocks) sur la page detail.
- **FR-015** : Le systeme DOIT conditionner l'acces au module Boutique au feature toggle SHOP active.
- **FR-016** : Le formulaire de creation/edition DOIT s'ouvrir dans le systeme de modal global de l'application (meme pattern que les autres formulaires).
- **FR-017** : Le systeme DOIT afficher les erreurs serveur de maniere explicite (409 pour stock insuffisant, 404 pour produit introuvable, erreurs reseau).

### Key Entities

- **Produit** : nom, description, icone, URL image, prix d'achat, prix de vente, stock, total vendu, actif, dates de creation et mise a jour. Represente un article en vente dans la boutique.
- **Transaction liee** : montant, libelle, type (RECETTE pour vente, DEPENSE pour restock), date. Generee automatiquement lors d'une vente ou d'un restock.
- **Compte Boutique** : compte dedie cree automatiquement lors de la premiere operation de vente/restock. Parametre par les preferences utilisateur (shopAccountId).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** : L'utilisateur peut consulter la liste de ses produits en moins de 2 secondes apres navigation.
- **SC-002** : L'utilisateur peut creer un produit complet (nom, prix, stock) en moins de 30 secondes.
- **SC-003** : L'utilisateur peut effectuer une vente (clic + confirmation) en moins de 3 interactions.
- **SC-004** : L'utilisateur peut restocker un produit (clic + quantite + confirmation) en moins de 4 interactions.
- **SC-005** : Les statistiques du produit (marge, CA) sont visibles immediatement sur la page detail sans navigation supplementaire.
- **SC-006** : Le module Boutique n'est accessible que si la feature SHOP est activee, sans contournement possible.
- **SC-007** : Parite fonctionnelle avec le module Boutique Flutter : toutes les actions disponibles en Flutter sont realisables dans la version Angular.

## Assumptions

- L'API backend (ProductController) est deja complete et fonctionnelle (KKS-118, KKS-119).
- Le feature toggle SHOP et le feature guard Angular sont deja en place (KKS-150).
- Le champ `imageUrl` est une URL texte libre (pas d'upload de fichier cote Angular PWA, contrairement a Flutter qui stocke localement).
- Le compte Boutique est cree automatiquement cote serveur lors de la premiere operation — pas de gestion cote frontend.
- Le FAB sur la page `/shop` propose "Nouveau produit" et "Vente rapide". Sur les autres pages, le FAB reste dedie aux operations budgetaires.
- Le dialog de vente (depuis FAB) et le dialog de restock (depuis detail) utilisent le systeme de modal global. Le bouton "Vendre" sur la page detail reste une action rapide (1 unite, confirmation simple).
- Le backend `POST /products/{id}/sell` accepte un body optionnel `SellRequest { quantity }` (defaut 1) pour supporter la vente de N unites.

## Dependencies

- **KKS-150** (Feature toggles Angular) : prerequis, deja implemente.
- **KKS-118** (Backend Product CRUD) : API necessaire, deja implementee.
- **KKS-119** (Backend Product Sales) : endpoints vente/restock, deja implementes.
- Modification backend : ajout d'un parametre `?includeInactive=true` sur `GET /products` pour retourner aussi les produits inactifs.
- Modification backend : ajout de `SellRequest { quantity }` optionnel sur `POST /products/{id}/sell` pour supporter la vente de N unites.
