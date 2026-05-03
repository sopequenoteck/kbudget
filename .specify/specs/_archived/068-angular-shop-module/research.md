# Research: 068-angular-shop-module

**Date**: 2026-03-02 | **Branch**: `068-angular-shop-module`

## Decision Log

### D1: Backend — Filtre produits inactifs

**Decision** : Ajouter un `@RequestParam` `includeInactive` (default `false`) sur `GET /products`.

**Rationale** : L'API actuelle appelle `findByUserIdAndActifTrueOrderByCreatedAtDesc` en dur. La spec exige un filtre actifs/inactifs cote Angular. Sans modification backend, impossible de recuperer les produits inactifs en liste.

**Implementation** :
- `ProductController.getAll()` : ajouter `@RequestParam(defaultValue = "false") boolean includeInactive`
- `ProductRepository` : ajouter `findByUserIdOrderByCreatedAtDesc(UUID userId)` (tous les produits)
- `ProductService.getAllByUser()` : brancher sur le parametre — si `includeInactive=true`, utiliser la nouvelle methode

**Alternatives considered** :
- Filtrage frontend uniquement (charger tous via un endpoint non filtre) — rejete car l'endpoint actuel est filtre cote serveur et ne retourne que les actifs.
- Creer un endpoint separe `/products/all` — rejete car non RESTful et ajoute de la complexite inutile.

### D2: Angular — Pattern service ProductService

**Decision** : Suivre exactement le pattern `AccountService` : `inject(ApiService)`, `refreshTrigger = signal(0)`, methodes retournant `Observable<T>` avec `tap(() => this.refresh())` sur les mutations.

**Rationale** : Pattern etabli dans tous les services Angular du projet. Coherence maximale.

**Alternatives considered** : Aucune — le pattern est impose par la constitution (Simplicite & YAGNI) et les conventions projet.

### D3: Angular — Integration modal produit

**Decision** : Ajouter `'product'` dans `ModalType`, suivre le pattern existant du Shell (`@switch/@case`, handlers `onProductSaved`/`onProductDeleted`).

**Rationale** : FR-016 exige que le formulaire s'ouvre dans le modal global. Le pattern est identique pour les 6 types de modals existants (transaction, subscription, debt, category, account, transfer).

**Alternatives considered** :
- Dialog HTML natif pour le formulaire — rejete car la spec exige le modal global.
- Route dediee `/shop/new` et `/shop/:id/edit` — rejete car les autres formulaires utilisent tous le modal global.

### D4: Angular — Routing shop module

**Decision** : Convertir la route `/shop` de `loadComponent` (ShopPlaceholder) en `loadChildren` avec sous-routes : `''` → ShopList, `':id'` → ShopDetail.

**Rationale** : Le detail produit necessite sa propre route (`/shop/:id`). Le pattern `loadChildren` est utilise pour les features avec sous-navigation.

**Alternatives considered** :
- Garder `loadComponent` et gerer la navigation detail via un dialog — rejete car la page detail est trop riche pour un dialog (stats, actions, historique).

### D5: Angular — FAB sur /shop

**Decision** : Le FAB sur la page `/shop` propose deux actions conditionnelles : "Nouveau produit" (`modalService.openModal('product')`) et "Vente rapide" (`modalService.openModal('sell')`). Le FAB n'est PAS modifie sur les autres pages.

**Rationale** : Le FAB est le point d'entree principal pour les actions dans l'app. La vente rapide via le FAB (choix produit + quantite) est plus efficace que la navigation detail → bouton vendre pour chaque unite. Restreindre les actions a la route `/shop` evite de polluer les autres ecrans. L'etat vide de la liste garde un bouton CTA pour creer un premier produit.

**Alternatives considered** :
- Bouton uniquement dans l'en-tete de la page — rejete car incoherent avec le pattern FAB utilise partout ailleurs.
- Pas de FAB sell (vente uniquement depuis le detail) — rejete car l'utilisateur devrait naviguer vers le detail pour chaque vente, trop de clics pour l'usage quotidien.

### D6: Angular — Dialogs vente et restock

**Decision** : Le dialog "Vente rapide" (depuis FAB) et le dialog de restock (depuis detail) passent par le systeme modal global (`ModalType += 'sell'`). Le bouton "Vendre" sur la page detail reste une action rapide (1 unite, `window.confirm`).

**Rationale** : Le dialog de vente a besoin d'un selecteur produit et d'un champ quantite — assez riche pour justifier le modal global. Le restock a un champ quantite — coherent d'utiliser aussi le modal. La vente depuis le detail (1 unite) reste simple (confirmation) pour la rapidite.

**Alternatives considered** :
- Dialog HTML natif pour tout — rejete car le SellDialog a un selecteur produit qui beneficie du style modal global.
- Vente uniquement depuis le detail — rejete car le FAB sell est plus ergonomique pour l'usage quotidien.

### D7: Angular — Modele Product

**Decision** : Creer `product.model.ts` dans `app/src/app/core/models/` avec les interfaces `Product`, `ProductRequest`, `ProductUpdateRequest`, `RestockRequest`.

**Rationale** : Aucun modele Product n'existe cote Angular. Les interfaces mappent directement les DTOs backend.

## Patterns existants confirmes

### ListItem API (composant partage)

```
Inputs: icon (required), title (required), value (required), subtitle (optional), rightSubtitle (optional), valueClass (optional)
Output: pressed
```

Usage pour un produit :
- `icon` = `product.icone ?? '📦'`
- `title` = `product.nom`
- `value` = `product.prixVente | amount`
- `subtitle` = `'Stock: ' + product.stock`
- `rightSubtitle` = `product.totalVendu + ' ventes'` ou `'Rupture'`

### FormField API (composant partage)

```
Inputs: label (required), fieldId (required), errorMessage (optional), showError (optional)
Content projection: le champ input/select
```

### ModalService API

```
ModalType = 'transaction' | 'subscription' | 'debt' | 'category' | 'account' | 'transfer'
→ Ajouter: 'product'

openModal(type, entity?)
closeModal()
activeModal signal, editingEntity signal, modalOpen computed, modalTitle computed
```
