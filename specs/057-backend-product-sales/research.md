# Research: 057-backend-product-sales

**Date**: 2026-02-28

## R1 — Liaison Transaction ↔ Product

**Decision**: Ajouter un champ nullable `product` (`@ManyToOne LAZY`) sur l'entite `Transaction`, avec FK `product_id` en base.

**Rationale**: Permet des requetes performantes (`findByProductIdAndUserId`) pour l'historique des ventes. Le champ est nullable car la majorite des transactions ne sont pas liees a un produit.

**Alternatives considered**:
- Entite intermediaire `ProductSale` — sur-ingenierie pour un lien simple 1:N
- Pattern matching sur le libelle — fragile (renommage produit, format changeant), non-indexable

## R2 — Gestion du stock sur suppression de transaction

**Decision**: Intercepter la suppression dans `TransactionService.delete()`. Si `productId != null`, ajuster le stock du produit avant de supprimer.

**Rationale**: Le code de delete existe deja et gere les cascades (transferId). Ajouter la logique stock au meme endroit est coherent avec le pattern existant.

**Alternatives considered**:
- Event listener JPA (`@PreRemove`) — couple la logique metier a l'entite, moins lisible
- Interdire la suppression des transactions produit — trop restrictif pour l'utilisateur

## R3 — Erreur 409 Conflict (stock epuise)

**Decision**: Creer une exception `ConflictException` et l'ajouter au `GlobalExceptionHandler` avec mapping HTTP 409.

**Rationale**: Le pattern existant utilise `IllegalArgumentException` → 400, mais la spec exige explicitement 409 pour le cas "stock = 0". Semantiquement, 409 est correct : l'etat actuel de la ressource (stock = 0) empeche l'operation.

**Alternatives considered**:
- Reutiliser `IllegalArgumentException` → 400 — ne correspond pas a la semantique HTTP (c'est un conflit d'etat, pas un input invalide)

## R4 — Creation lazy du compte Boutique

**Decision**: Lors de la premiere operation boutique (vente/restock), si `shopAccountId` est null dans `UserPreference`, creer automatiquement un compte "Boutique" de type `COURANT` avec icone 🛍️ et couleur #f59e0b.

**Rationale**: Suit le pattern lazy-create existant de `PreferenceService.getOrCreate()`. Evite de creer un compte inutile pour les utilisateurs n'utilisant pas la boutique.

**Alternatives considered**:
- Creation a l'inscription — pollue les comptes des utilisateurs non-boutique
- Creation a la premiere creation de produit — ne garantit pas que le compte existe avant la premiere vente

## R5 — Categorie systeme "Boutique"

**Decision**: Ajouter via migration Flyway (V11) pour les utilisateurs existants + dans `CategoryService.seedSystemCategories()` pour les nouveaux utilisateurs. Icone 🛍️, couleur #f59e0b.

**Rationale**: Suit exactement le pattern des categories "Abonnement", "Dette" et "Virement".

**Alternatives considered**: Aucune — le pattern est etabli.

## R6 — Modification du calcul de solde

**Decision**: Le solde est calcule per-account dans `AccountService.toResponse()`. Pour le "solde total", le frontend additionne les soldes de chaque compte. Il suffit donc que le endpoint `GET /accounts` renvoie un flag `isShopAccount` dans `AccountResponse` ET que `UserPreference` expose `includeShopInBalance`. Le frontend peut alors exclure ou inclure le compte boutique du total.

**Rationale**: Pas de endpoint "solde total" cote backend. Le calcul est deja delegue au frontend. Ajouter un champ `isShopAccount` au response et exposer la preference suffit.

**Alternatives considered**:
- Nouveau endpoint `/accounts/total-balance` — sur-ingenierie, le frontend sait deja additionner
- Filtrer les transactions dans la requete SQL — modifie la logique existante sans necessite

## R7 — Enrichissement UserPreference

**Decision**: Ajouter `shopAccountId` (UUID nullable, FK → accounts) et `includeShopInBalance` (boolean, defaut false) a `UserPreference`. Migration Flyway V11 pour ajouter les colonnes.

**Rationale**: Suit le pattern existant de `UserPreference` avec des champs simples + migration.

**Alternatives considered**: Aucune — la spec est explicite.
