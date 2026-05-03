# Research: 062-flutter-product-detail

**Date**: 2026-03-01

## R1: API Sales History — filtre RECETTE uniquement

**Contexte**: La spec demande l'historique des "ventes + restocks" mais l'API `GET /products/{id}/sales` filtre en Java pour ne retourner que les transactions de type `RECETTE`.

**Decision**: Modifier `ProductService.getSalesHistory()` pour retourner toutes les transactions liees (RECETTE + DEPENSE). Le repository `findByProductIdAndUserIdOrderByDateDesc` retourne deja les deux types — il suffit de supprimer le filtre Java `.filter(t -> t.getType() == TransactionType.RECETTE)`.

**Rationale**: L'issue KKS-125 demande explicitement "ventes + restocks" dans l'historique. L'endpoint s'appelle `/sales` mais represente de facto tout l'historique d'activite du produit. Renommer l'endpoint serait un breaking change inutile.

**Alternatives considered**:
- Ajouter un query param `?type=ALL|RECETTE|DEPENSE` — over-engineering pour un single-user app
- Creer un nouvel endpoint `/products/{id}/history` — duplication inutile
- Accepter l'API telle quelle (RECETTE only) — contredit la spec et l'issue

## R2: Navigation vers le detail — route push vs modal

**Contexte**: Le codebase utilise des modales pour creation/edition. Aucun "ecran de detail" n'existe. Le detail produit necessite un ecran complet (header + stats + actions + historique).

**Decision**: Utiliser une sous-route go_router `/shop/:id` avec `context.push()`. Le detail est trop riche pour une modale (scroll multiple sections, actions, historique). C'est le premier "detail screen" du projet.

**Rationale**: Une modale est limitee a 90% de hauteur et optimisee pour les formulaires courts. Le detail produit combine affichage informatif, actions interactives et liste historique — un ecran complet est plus adapte.

**Alternatives considered**:
- Modale fullscreen — pas le pattern du projet, complexite de navigation
- Dialog tablette + push mobile — inconsistance UX

## R3: State management — extend ProductNotifier vs provider separe

**Contexte**: `ProductNotifier` gere la liste des produits. Le detail necessite des actions supplementaires (sell, restock) et un state pour l'historique.

**Decision**: Ajouter `sellProduct(id)` et `restockProduct(id, quantity)` au `ProductNotifier` existant (met a jour le produit dans `allItems`). Creer un `productSalesProvider(id)` separe (FutureProvider.family) pour l'historique des transactions.

**Rationale**: Les actions sell/restock modifient le produit (stock, totalVendu) — elles appartiennent naturellement au `ProductNotifier` qui gere deja `allItems`. L'historique est une donnee read-only separee, mieux geree par un provider dedie qui se reinvalide apres chaque action.

**Alternatives considered**:
- Notifier dedie `ProductDetailNotifier` — duplication de state produit, synchronisation complexe avec la liste
- Tout dans un seul notifier — l'historique (liste de transactions) n'a pas la meme forme que le produit

## R4: Refresh de l'historique apres sell/restock

**Contexte**: Apres une vente ou un restock, l'historique doit se mettre a jour pour afficher la nouvelle transaction.

**Decision**: Apres `sellProduct()` ou `restockProduct()`, invalider le `productSalesProvider(id)` via `ref.invalidate()`. Le provider se recharge automatiquement.

**Rationale**: Pattern Riverpod standard pour les donnees derivees. Pas de gestion manuelle d'etat — le framework gere le refresh.

**Alternatives considered**:
- Ajouter la transaction localement sans re-fetch — risque d'inconsistance avec le serveur, la transaction est creee cote API
- WebSocket pour push — over-engineering massif pour single-user

## R5: Dialogue restock — widget dedie vs AlertDialog

**Contexte**: Le restock necessite un dialogue de saisie de quantite (entier > 0).

**Decision**: Widget `RestockDialog` dedie utilisant `showDialog()` avec un `TextField` numerique, validation, et boutons annuler/confirmer. Style coherent avec le design system (AppFormField, AppRadius, AppSpacing).

**Rationale**: Un `AlertDialog` standard suffit pour une saisie simple. Le projet utilise deja `showDialog` pour les confirmations. Pas besoin d'une modale `AppModal` pour un seul champ.

**Alternatives considered**:
- AppModal (bottom sheet) — trop lourd pour un seul champ numerique
- Inline editing sur l'ecran — complexite UX, conflits avec le scroll

## R6: Produit passe au detail — extra vs re-fetch

**Contexte**: Comment passer les donnees du produit au detail screen depuis la liste.

**Decision**: Passer le `Product` via `state.extra` dans go_router (pattern existant : `AccountFormScreen`, `CategoryFormScreen`). Utiliser le produit comme donnee initiale, puis `ref.watch(productNotifierProvider)` pour les mises a jour en temps reel.

**Rationale**: Pattern etabli dans le codebase. Le produit est deja en memoire dans la liste. Le watch du notifier assure la coherence apres sell/restock.

**Alternatives considered**:
- Re-fetch via `getById(id)` — latence inutile, produit deja en memoire
- Provider family avec cache — over-engineering pour un single-user
