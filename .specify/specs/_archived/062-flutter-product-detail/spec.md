# Feature Specification: Detail Produit — Actions vente, restock et historique

**Feature Branch**: `062-flutter-product-detail`
**Created**: 2026-03-01
**Status**: Draft
**Input**: KKS-125 — Ecran de detail d'un produit avec actions rapides (vendre, restocker) et historique des ventes

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consulter le detail d'un produit (Priority: P1)

L'utilisateur accede a l'ecran de detail d'un produit depuis la liste des produits. Il voit un recapitulatif complet : image/icone, nom, description, et toutes les statistiques financieres et de stock du produit.

**Why this priority**: C'est la base de l'ecran — sans l'affichage des informations, aucune action n'est possible. L'utilisateur doit pouvoir evaluer la performance d'un produit d'un coup d'oeil.

**Independent Test**: Peut etre teste en naviguant vers le detail d'un produit existant et en verifiant que toutes les informations sont affichees correctement.

**Acceptance Scenarios**:

1. **Given** un produit existant avec toutes ses donnees, **When** l'utilisateur ouvre le detail, **Then** le header affiche l'image/icone, le nom et la description du produit
2. **Given** un produit avec prixAchat=10, prixVente=15, stock=20, totalVendu=5, **When** l'ecran se charge, **Then** les stats affichent : prix d'achat (10), prix de vente (15), marge unitaire (5), stock disponible (20), total vendu (5), chiffre d'affaires (75), marge totale (25)
3. **Given** un produit sans image ni description, **When** l'ecran se charge, **Then** l'icone par defaut est affichee et la description est absente (pas de placeholder vide)

---

### User Story 2 - Vendre un produit (Priority: P1)

L'utilisateur appuie sur le bouton "Vendre" pour enregistrer une vente unitaire. Le stock diminue de 1, une transaction de type RECETTE est creee automatiquement, et les stats se mettent a jour en temps reel.

**Why this priority**: C'est l'action principale de l'ecran — la raison d'etre du module boutique. La vente rapide en un tap est critique pour l'usage quotidien.

**Independent Test**: Peut etre teste en vendant un produit avec du stock et en verifiant la mise a jour du stock, du total vendu et la creation de la transaction.

**Acceptance Scenarios**:

1. **Given** un produit avec stock=5, **When** l'utilisateur appuie sur "Vendre", **Then** le stock passe a 4, le total vendu augmente de 1, le chiffre d'affaires et la marge totale sont recalcules, et un feedback visuel confirme la vente
2. **Given** un produit avec stock=0, **When** l'ecran se charge, **Then** le bouton "Vendre" est desactive (grise) et ne peut pas etre presse
3. **Given** un produit avec stock=1, **When** l'utilisateur vend le dernier exemplaire, **Then** le stock passe a 0 et le bouton "Vendre" se desactive immediatement
4. **Given** une erreur reseau lors de la vente, **When** l'appel echoue, **Then** un message d'erreur est affiche et le stock reste inchange

---

### User Story 3 - Restocker un produit (Priority: P2)

L'utilisateur appuie sur le bouton "Ajouter stock" pour augmenter le stock. Un dialogue demande la quantite a ajouter. Une transaction de type DEPENSE est creee automatiquement.

**Why this priority**: Le restock est essentiel pour maintenir l'inventaire, mais moins frequent que la vente au quotidien. Il necessite une interaction supplementaire (saisie quantite).

**Independent Test**: Peut etre teste en restockant un produit, en verifiant la mise a jour du stock et la creation de la transaction DEPENSE.

**Acceptance Scenarios**:

1. **Given** un produit avec stock=3, **When** l'utilisateur appuie sur "Ajouter stock" et saisit 10, **Then** le stock passe a 13 et les stats sont mises a jour
2. **Given** le dialogue de restock ouvert, **When** l'utilisateur saisit 0 ou une valeur negative, **Then** la validation empeche la soumission
3. **Given** le dialogue de restock ouvert, **When** l'utilisateur annule, **Then** rien ne change
4. **Given** une erreur reseau lors du restock, **When** l'appel echoue, **Then** un message d'erreur est affiche et le stock reste inchange

---

### User Story 4 - Consulter l'historique des transactions liees (Priority: P2)

L'utilisateur voit la liste des transactions associees au produit (ventes et restocks) dans une section dediee de l'ecran de detail.

**Why this priority**: L'historique donne du contexte sur l'activite du produit. Important pour le suivi mais pas bloquant pour les actions principales.

**Independent Test**: Peut etre teste en verifiant que les transactions liees a un produit s'affichent correctement avec leur type, montant et date.

**Acceptance Scenarios**:

1. **Given** un produit avec 5 transactions liees, **When** l'ecran se charge, **Then** l'historique affiche les transactions triees par date decroissante avec type (vente/restock), montant et date
2. **Given** un produit sans aucune transaction, **When** l'ecran se charge, **Then** un message "Aucune transaction" est affiche
3. **Given** un produit avec des transactions, **When** l'utilisateur effectue une vente ou un restock, **Then** la nouvelle transaction apparait en haut de l'historique

---

### User Story 5 - Modifier un produit depuis le detail (Priority: P3)

L'utilisateur appuie sur le bouton "Modifier" pour ouvrir le formulaire d'edition du produit (KKS-124). Les modifications sont refletees au retour sur l'ecran de detail.

**Why this priority**: La modification est deja implementee via KKS-124. Cette story ne fait que fournir un point d'acces depuis le detail.

**Independent Test**: Peut etre teste en modifiant un produit et en verifiant que les changements sont visibles au retour.

**Acceptance Scenarios**:

1. **Given** l'ecran de detail d'un produit, **When** l'utilisateur appuie sur "Modifier", **Then** le formulaire d'edition s'ouvre avec les donnees du produit pre-remplies
2. **Given** le formulaire d'edition ouvert depuis le detail, **When** l'utilisateur sauvegarde et revient, **Then** l'ecran de detail affiche les donnees mises a jour

---

### Edge Cases

- Que se passe-t-il si le produit est supprime par ailleurs pendant la consultation du detail ? Un message d'erreur adapte doit etre affiche.
- Que se passe-t-il si le stock passe a 0 pendant une tentative de vente concurrente (race condition) ? L'erreur API doit etre geree gracieusement.
- Que se passe-t-il si le produit a un prixAchat de 0 ? La marge unitaire est egale au prixVente, les calculs restent corrects.
- Que se passe-t-il si le produit est desactive (inactif) ? Les actions vente et restock doivent etre desactivees.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT afficher les informations completes du produit : image/icone, nom, description, prix d'achat, prix de vente, marge unitaire, stock disponible, total vendu, chiffre d'affaires et marge totale
- **FR-002**: Le systeme DOIT calculer et afficher la marge unitaire (prixVente - prixAchat), le chiffre d'affaires (totalVendu x prixVente) et la marge totale (totalVendu x (prixVente - prixAchat))
- **FR-003**: Le systeme DOIT permettre de vendre un produit en un seul tap, decrementant le stock de 1 et creant une transaction RECETTE automatique
- **FR-004**: Le systeme DOIT desactiver le bouton "Vendre" lorsque le stock est a 0
- **FR-005**: Le systeme DOIT permettre d'ajouter du stock via un dialogue de saisie de quantite, creant une transaction DEPENSE automatique
- **FR-006**: Le systeme DOIT valider que la quantite de restock est un entier strictement positif
- **FR-007**: Le systeme DOIT afficher l'historique des transactions liees au produit, triees par date decroissante
- **FR-008**: Le systeme DOIT permettre de naviguer vers le formulaire d'edition du produit (KKS-124)
- **FR-009**: Le systeme DOIT mettre a jour les statistiques et l'historique en temps reel apres une vente ou un restock
- **FR-010**: Le systeme DOIT desactiver les actions vente et restock si le produit est inactif
- **FR-011**: Le systeme DOIT afficher un feedback visuel (confirmation ou erreur) apres chaque action vente ou restock

### Key Entities

- **Product**: Entite centrale — nom, description, icone, imageUrl, prixAchat, prixVente, stock, totalVendu, actif. Les stats derivees (marge, CA) sont calculees cote client.
- **Transaction**: Transaction liee au produit via productId — type RECETTE (vente) ou DEPENSE (restock), montant, date. Represente l'historique d'activite du produit.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut consulter toutes les statistiques d'un produit en moins de 2 secondes apres navigation
- **SC-002**: L'utilisateur peut effectuer une vente en un seul tap avec feedback immediat (< 1 seconde pour le retour visuel)
- **SC-003**: Le restock d'un produit se fait en 3 interactions maximum (tap bouton + saisie quantite + confirmation)
- **SC-004**: L'historique des transactions liees est visible sans navigation supplementaire
- **SC-005**: 100% des actions (vente/restock) produisent un feedback visuel clair (succes ou erreur)
- **SC-006**: Le bouton vendre est immediatement desactive lorsque le stock atteint 0, empechant toute vente impossible

## Assumptions

- L'API backend expose deja les endpoints `POST /products/{id}/sell` et `POST /products/{id}/restock` (KKS-057)
- L'API backend expose `GET /products/{id}/sales` pour l'historique des transactions liees
- Le formulaire d'edition produit (KKS-124) est deja implemente et accessible via le systeme de navigation
- Le module boutique est active via le feature toggle (KKS-058)
- Les transactions creees automatiquement utilisent le compte boutique configure dans les preferences utilisateur
- La devise affichee suit les preferences de l'utilisateur
