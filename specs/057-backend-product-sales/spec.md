# Feature Specification: Endpoints ventes et stock produits

**Feature Branch**: `057-backend-product-sales`
**Created**: 2026-02-28
**Status**: Draft
**Input**: KKS-119 — Backend: Endpoints ventes et stock produits

## Clarifications

### Session 2026-02-28

- Q: Comment le compte boutique est-il provisionne ? → A: Un compte dedie "Boutique" est cree automatiquement par defaut, mais l'utilisateur peut le remplacer par un compte existant de son choix.
- Q: Les transactions boutique sont-elles incluses par defaut dans le solde total ? → A: Non, exclues par defaut. Le solde boutique est separe. L'utilisateur active l'unification explicitement s'il le souhaite.
- Q: Quel est le perimetre de la redefinition du calcul des soldes ? → A: Complet — ajouter les preferences (compte boutique + toggle unification) ET modifier le calcul de solde existant pour exclure/inclure les transactions boutique selon la preference.
- Q: Comment le systeme identifie-t-il le compte boutique pour le calcul de solde ? → A: Via UserPreference — un champ `shopAccountId` reference le compte boutique. Pas de nouveau type de compte.
- Q: Comment le systeme lie-t-il une transaction a un produit pour l'historique des ventes ? → A: Via un champ nullable `productId` (FK) ajoute sur l'entite Transaction.
- Q: Quand le compte Boutique est-il cree automatiquement ? → A: Creation lazy — a la premiere operation boutique (vente ou restock), pas a l'inscription.
- Q: Que se passe-t-il si l'utilisateur supprime manuellement une transaction boutique ? → A: La suppression est autorisee et le stock est ajuste automatiquement (rollback : vente supprimee = stock +1/totalVendu -1, restock supprime = stock -N).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Vendre un produit (Priority: P1)

En tant qu'utilisateur, je veux pouvoir enregistrer une vente de produit pour que mon stock soit automatiquement mis a jour et qu'une transaction de recette soit creee dans mon budget.

**Why this priority**: La vente est l'action principale de la boutique. Sans elle, le module produit n'a pas de raison d'etre. C'est le coeur de la fonctionnalite.

**Independent Test**: Peut etre teste en creant un produit avec du stock, puis en appelant l'endpoint de vente et en verifiant que le stock diminue de 1, totalVendu augmente de 1, et qu'une transaction RECETTE est creee.

**Acceptance Scenarios**:

1. **Given** un produit avec stock = 5 et prixVente = 15.00, **When** l'utilisateur enregistre une vente, **Then** le stock passe a 4, totalVendu augmente de 1, et une transaction RECETTE de 15.00 est creee avec le libelle "Vente: {nom produit}"
2. **Given** un produit avec stock = 0, **When** l'utilisateur tente de vendre, **Then** le systeme refuse avec une erreur 409 Conflict et un message explicite
3. **Given** un produit inactif, **When** l'utilisateur tente de vendre, **Then** le systeme refuse avec une erreur 409 Conflict
4. **Given** un produit vendu, **When** on consulte la transaction generee, **Then** elle est de type RECETTE, associee a la categorie systeme "Boutique" et au compte boutique configure de l'utilisateur

---

### User Story 2 - Restocker un produit (Priority: P2)

En tant qu'utilisateur, je veux pouvoir ajouter du stock a un produit pour maintenir mon inventaire a jour, avec une transaction de depense automatique refletant le cout d'achat.

**Why this priority**: Le restockage est necessaire pour alimenter le stock avant de vendre. C'est la deuxieme action essentielle du cycle de vie produit.

**Independent Test**: Peut etre teste en creant un produit avec stock = 0, puis en appelant l'endpoint de restock avec quantity = 10, et en verifiant que le stock passe a 10 et qu'une transaction DEPENSE est creee.

**Acceptance Scenarios**:

1. **Given** un produit avec stock = 3 et prixAchat = 8.00, **When** l'utilisateur restock de 5 unites, **Then** le stock passe a 8 et une transaction DEPENSE de 40.00 (8.00 x 5) est creee avec le libelle "Stock: {nom produit} x5"
2. **Given** une quantite de restock = 0, **When** l'utilisateur tente le restockage, **Then** le systeme refuse avec une erreur de validation
3. **Given** une quantite de restock negative, **When** l'utilisateur tente le restockage, **Then** le systeme refuse avec une erreur de validation
4. **Given** un produit inactif, **When** l'utilisateur tente de restocker, **Then** le systeme refuse avec une erreur 409 Conflict

---

### User Story 3 - Consulter l'historique des ventes (Priority: P3)

En tant qu'utilisateur, je veux consulter l'historique des ventes d'un produit specifique pour suivre les performances de chaque produit.

**Why this priority**: L'historique est une fonctionnalite de consultation qui apporte de la visibilite mais n'est pas bloquante pour le fonctionnement de base (vente/restock).

**Independent Test**: Peut etre teste en creant un produit, en enregistrant plusieurs ventes, puis en appelant l'endpoint d'historique et en verifiant que toutes les transactions de vente sont retournees.

**Acceptance Scenarios**:

1. **Given** un produit avec 3 ventes enregistrees, **When** l'utilisateur consulte l'historique, **Then** les 3 transactions de vente sont retournees, triees par date decroissante
2. **Given** un produit sans vente, **When** l'utilisateur consulte l'historique, **Then** une liste vide est retournee
3. **Given** un produit d'un autre utilisateur, **When** l'utilisateur tente de consulter son historique, **Then** le systeme retourne 404 Not Found (isolation des donnees)

---

### Edge Cases

- Que se passe-t-il si le compte boutique dedie n'a pas encore ete cree ? Il est cree automatiquement (lazy) lors de la premiere operation boutique (vente ou restock).
- Que se passe-t-il si l'utilisateur change de compte boutique apres des ventes ? Les transactions passees restent sur l'ancien compte, les nouvelles utilisent le nouveau.
- Que se passe-t-il si l'utilisateur active/desactive l'unification des soldes ? Le changement est retroactif : toutes les transactions boutique passees et futures sont incluses ou exclues du solde total selon la preference courante.
- Que se passe-t-il si le produit a un prixVente ou prixAchat tres faible (ex: 0.01) ? La transaction est creee avec le montant calcule. Note : prixAchat et prixVente sont strictement positifs (`@Positive`, > 0) — la valeur 0 est rejetee a la creation/modification du produit.
- Que se passe-t-il si la categorie systeme "Boutique" n'existe pas encore ? Elle est creee automatiquement par migration.
- Que se passe-t-il si un produit n'existe pas (ID invalide) ? Erreur 404 Not Found.
- Que se passe-t-il si le produit appartient a un autre utilisateur ? Erreur 404 Not Found (isolation des donnees).
- Que se passe-t-il si l'utilisateur supprime une transaction de vente ou de restock ? Le stock est ajuste automatiquement (rollback). Suppression vente : stock +1, totalVendu -1. Suppression restock : stock -N (N = montant / prixAchat actuel).
- Que se passe-t-il si le prixAchat a ete modifie entre le restock et la suppression de la transaction ? Le rollback utilise le prixAchat actuel pour recalculer la quantite (N = montant / prixAchat). Si le prix a change, la quantite rollbackee peut differer de la quantite initiale. Limitation acceptee pour une app mono-utilisateur — le cas est rare et l'impact faible.
- Que se passe-t-il si le stock devient negatif apres un rollback de suppression de restock (ex: restock +10, vente de 8, suppression du restock → stock = 2 - 10 = -8) ? La valeur negative est acceptee. Limitation documentee — le cas est rare pour une app mono-utilisateur et l'utilisateur peut corriger manuellement via un nouveau restock.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT permettre d'enregistrer la vente d'un produit, decrementant le stock de 1, incrementant totalVendu de 1, et creant une transaction RECETTE automatique.
- **FR-002**: Le systeme DOIT permettre le restockage d'un produit avec une quantite positive, incrementant le stock de N unites et creant une transaction DEPENSE automatique.
- **FR-003**: Le systeme DOIT permettre de consulter l'historique des ventes d'un produit specifique via le champ `productId` (FK nullable) present sur les transactions auto-generees.
- **FR-004**: Le systeme DOIT creer une categorie systeme "Boutique" lors de la migration de base de donnees, au meme titre que les categories "Abonnement" et "Dette" existantes.
- **FR-005**: Le systeme DOIT refuser une vente si le stock du produit est a 0, avec une erreur HTTP 409 Conflict.
- **FR-006**: Le systeme DOIT valider que la quantite de restockage est strictement superieure a 0.
- **FR-007**: Le systeme DOIT refuser les operations de vente et restockage sur un produit inactif.
- **FR-008**: Lors de la premiere operation boutique (vente ou restock), si aucun `shopAccountId` n'est configure dans les preferences, un compte dedie "Boutique" DOIT etre cree automatiquement (creation lazy). L'utilisateur PEUT remplacer ce compte par un compte existant de son choix via ses preferences.
- **FR-009**: Les transactions auto-generees DOIVENT etre associees au compte reference par `shopAccountId` dans les preferences de l'utilisateur.
- **FR-010**: Les transactions auto-generees DOIVENT utiliser la categorie systeme "Boutique".
- **FR-011**: Le systeme DOIT proposer une preference permettant d'inclure ou exclure les transactions boutique du calcul du solde total des comptes. Par defaut, les transactions boutique sont exclues (le compte boutique a son propre solde visible separement).
- **FR-012**: Le backend DOIT exposer les informations necessaires (`isShopAccount` sur AccountResponse, `includeShopInBalance` sur UserPreferenceResponse) pour que le frontend puisse inclure ou exclure les transactions du compte boutique du solde total selon la preference d'unification. Le calcul effectif du solde total est delegue au frontend (pas de endpoint "solde total" backend).
- **FR-013**: Le systeme DOIT garantir l'isolation des donnees : chaque utilisateur n'accede qu'a ses propres produits et transactions.
- **FR-014**: Lorsqu'une transaction liee a un produit (`productId` non null) est supprimee, le systeme DOIT ajuster automatiquement le stock du produit : suppression d'une vente = stock +1 et totalVendu -1, suppression d'un restock = stock -N (N = montant / prixAchat).

### Key Entities

- **Product** (existant) : Entite deja creee (KKS-118). Attributs cles pour cette feature : stock, totalVendu, prixAchat, prixVente, actif, nom.
- **Transaction** (existant, a enrichir) : Entite existante. Ajout d'un champ nullable `productId` (FK vers Product) pour lier les transactions auto-generees au produit source. Attributs cles : montant, libelle, type (DEPENSE/RECETTE), date, category, account, productId.
- **Category** (existant) : Ajout d'une categorie systeme "Boutique" par migration, sur le meme modele que "Abonnement" et "Dette".
- **Account** (existant) : Un compte dedie "Boutique" est cree automatiquement a l'activation du module. L'utilisateur peut le remplacer par un compte existant.
- **UserPreference** (existant, a enrichir) : Ajout de `shopAccountId` (reference vers le compte boutique) et `includeShopInBalance` (toggle d'unification, defaut = false).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'enregistrement d'une vente met a jour le stock et cree la transaction en une seule operation coherente.
- **SC-002**: Le restockage met a jour le stock et cree la transaction en une seule operation coherente.
- **SC-003**: 100% des tentatives de vente sur un produit a stock 0 sont rejetees avec un message d'erreur clair.
- **SC-004**: L'historique des ventes retourne toutes les transactions de vente liees au produit, triees par date.
- **SC-005**: La categorie systeme "Boutique" est disponible pour tous les utilisateurs apres migration.
- **SC-006**: Le backend expose `isShopAccount` sur AccountResponse et `includeShopInBalance` sur UserPreferenceResponse, permettant au frontend d'inclure ou exclure les transactions boutique du solde total selon la preference d'unification (verification effective dans le ticket frontend).
- **SC-007**: Les operations sont isolees par utilisateur — aucun utilisateur ne peut acceder aux produits ou ventes d'un autre.

## Assumptions

- L'entite Product et son CRUD existent deja (KKS-118).
- Les categories systeme "Abonnement" et "Dette" existent deja et servent de modele pour "Boutique".
- Le compte boutique est stocke dans les preferences utilisateur (UserPreference) via un champ dedie.
- Un produit inactif (`actif = false`) ne peut etre ni vendu ni restocke.
- La date de la transaction auto-generee est la date courante.
- L'application est mono-utilisateur (self-hosted), les problemes de concurrence ne sont pas une preoccupation majeure.

## Out of Scope

- Gestion des remises ou prix promotionnels sur les ventes.
- Vente en lot (plusieurs unites a la fois) — chaque vente decremente de 1 unite.
- Annulation ou remboursement de ventes.
- Dashboard ou statistiques de ventes (futur).
- Pagination de l'historique des ventes (non necessaire pour un usage mono-utilisateur avec un nombre limite de produits).
- Endpoints Flutter ou Angular — cette feature est uniquement backend.
