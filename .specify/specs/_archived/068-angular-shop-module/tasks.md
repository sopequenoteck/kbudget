# Tasks: Module Boutique Angular

**Input**: Design documents from `/specs/068-angular-shop-module/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/product-api.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Creer le modele de donnees et le service Angular Product — prerequis pour tous les composants.

- [x] T001 [P] Create Product model interfaces (Product, ProductRequest, ProductUpdateRequest, RestockRequest, SellRequest) in app/src/app/core/models/product.model.ts — mapper exactement les DTOs backend (voir data-model.md). Product : id (string), nom, description (string|null), icone (string|null), imageUrl (string|null), prixAchat (number), prixVente (number), stock (number), totalVendu (number), actif (boolean), createdAt (string), updatedAt (string). ProductUpdateRequest extends ProductRequest + actif: boolean. RestockRequest : quantity: number. SellRequest : quantity: number.
- [x] T002 [P] Create ProductService in app/src/app/core/services/product.ts — pattern identique a AccountService : inject(ApiService), refreshTrigger = signal(0), methodes Observable : getAll(includeInactive?: boolean), getById(id: string), create(req: ProductRequest), update(id: string, req: ProductUpdateRequest), delete(id: string), sell(id: string, quantity?: number) (POST avec body SellRequest si quantity > 1, sans body si 1), restock(id: string, req: RestockRequest), getSalesHistory(id: string). Mutations (create/update/delete/sell/restock) avec tap(() => this.refresh()). getAll passe ?includeInactive=true si parametre true.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Modification backend pour le filtre inactifs + vente N unites + preparation du systeme modal Angular.

- [x] T003 Backend modifications (3+1 fichiers) — (1) api/src/main/java/fr/kksdev/budget/api/controller/ProductController.java : ajouter @RequestParam(defaultValue = "false") boolean includeInactive sur getAll(), passer au service ; modifier sell() pour accepter @RequestBody(required = false) SellRequest et passer la quantity au service. (2) api/src/main/java/fr/kksdev/budget/api/repository/ProductRepository.java : ajouter findByUserIdOrderByCreatedAtDesc(UUID userId). (3) api/src/main/java/fr/kksdev/budget/api/service/ProductService.java : modifier getAllByUser() pour brancher sur includeInactive ; modifier sell() pour accepter un parametre quantity (defaut 1), decrementer stock de N, incrementer totalVendu de N, creer transaction avec montant = prixVente * N. (4) Creer api/src/main/java/fr/kksdev/budget/api/dto/SellRequest.java : record SellRequest(@Positive Integer quantity) avec default 1 si null.
- [x] T004 [P] Add 'product' and 'sell' to ModalType, EditableEntity union, CREATE_TITLES ('Nouveau produit' pour product, 'Vente rapide' pour sell), EDIT_TITLES ('Modifier le produit' pour product) in app/src/app/core/services/modal.service.ts — ajouter Product a l'import depuis product.model.ts.

**Checkpoint**: Backend supporte le filtre inactifs et la vente N unites. ModalService pret pour le formulaire produit et le dialog vente.

---

## Phase 3: User Story 1 — Consulter la liste des produits (Priority: P1) MVP

**Goal**: L'utilisateur peut voir la liste de ses produits avec filtre actifs/inactifs, skeleton loading, et etat vide.

**Independent Test**: Acceder a `/shop` avec la feature SHOP activee → la liste s'affiche avec les produits actifs.

### Implementation for User Story 1

- [x] T005 [US1] Create ShopList component in app/src/app/features/shop/shop-list/ (shop-list.ts, shop-list.html, shop-list.scss) — standalone, OnPush. Signals : products signal<Product[]>, loading signal<boolean>, error signal<boolean>, filter signal<'active'|'inactive'|'all'> (default 'active'). Computed : filteredProducts derive de products + filter (active=actif true, inactive=actif false, all=tous). Effect abonne au productService.refreshTrigger pour recharger. Charger via firstValueFrom(productService.getAll(true)) pour avoir tous les produits, filtrer cote client. Template : skeleton loading (5x ListItem.skeleton), etat vide (message + bouton creer → modalService.openModal('product')), @for sur filteredProducts avec ListItem (icon=product.icone??'📦', title=product.nom, value=product.prixVente|amount, subtitle='Stock: '+product.stock, rightSubtitle=product.stock===0?'Rupture':product.totalVendu+' ventes'). Opacite 0.5 sur items stock=0 ou actif=false. Filtre en haut de page (3 boutons ou segmented control : Actifs/Inactifs/Tous). Navigation vers /shop/:id au clic sur un item.
- [x] T006 [US1] Create shop.routes.ts in app/src/app/features/shop/shop.routes.ts with route '' → ShopList. Update app/src/app/app.routes.ts : replace loadComponent ShopPlaceholder with loadChildren → shop.routes SHOP_ROUTES. Delete app/src/app/features/shop/shop-placeholder.ts.

**Checkpoint**: `/shop` affiche la liste des produits avec filtre, skeleton, etat vide. MVP fonctionnel.

---

## Phase 4: User Story 2 — Creer et modifier un produit (Priority: P1)

**Goal**: L'utilisateur peut creer et modifier un produit via le modal global, avec validation et indicateur de marge.

**Independent Test**: Ouvrir le formulaire via le FAB → remplir les champs → valider → le produit apparait dans la liste.

### Implementation for User Story 2

- [x] T007 [US2] Create ProductForm component in app/src/app/features/shop/components/product-form/ (product-form.ts, product-form.html, product-form.scss) — standalone, OnPush. Inputs : product = input<Product|null>(null). Outputs : saved = output<ProductRequest|ProductUpdateRequest>(), cancelled = output<void>(), deleted = output<string>(). FormBuilder.nonNullable.group : nom ['', [required, maxLength(100)]], description ['', [maxLength(500)]], icone [''], imageUrl ['', [maxLength(500)]], prixAchat ['', [required, min(0.01)]], prixVente ['', [required, min(0.01)]], stock [0, [required, min(0)]], actif [true]. isEditMode = computed(() => product() !== null). marge = computed() derive des valeurs prixVente - prixAchat du formulaire (mettre a jour en temps reel via valueChanges ou effect). Effect pour patchValue en mode edition. Masquer le champ stock en mode edition. Afficher le champ actif uniquement en mode edition. Bouton supprimer en mode edition avec confirmation (window.confirm). Helper isInvalid(controlName). IMPORTANT en mode edition : le DTO ProductUpdateRequest emis par saved DOIT inclure product().stock (valeur actuelle non modifiee) car le backend exige le champ stock dans le PUT.
- [x] T008 [US2] Integrate ProductForm in Shell — modifier app/src/app/shared/components/shell/shell.ts : ajouter import ProductForm, inject ProductService, handlers async onProductSaved(request) et async onProductDeleted(id) suivant le pattern existant (firstValueFrom, create/update selon editingEntity, closeModal). Modifier app/src/app/shared/components/shell/shell.html : ajouter @case('product') dans le @switch(modalService.activeModal()) avec <app-product-form [product]="$any(modalService.editingEntity())" (saved)="onProductSaved($event)" (cancelled)="onModalClose()" (deleted)="onProductDeleted($event)" />.

**Checkpoint**: Creation et edition de produits fonctionnelles via le modal global. Marge affichee en temps reel.

---

## Phase 5: User Story 3 — Consulter le detail d'un produit (Priority: P2)

**Goal**: L'utilisateur voit toutes les informations d'un produit, les statistiques calculees, et peut naviguer vers l'edition.

**Independent Test**: Cliquer sur un produit dans la liste → la page detail affiche les infos completes + stats (marge, CA, marge totale).

### Implementation for User Story 3

- [x] T009 [US3] Create ShopDetail component in app/src/app/features/shop/shop-detail/ (shop-detail.ts, shop-detail.html, shop-detail.scss) — standalone, OnPush. Injecter ActivatedRoute, Router, ProductService, ModalService. Extraire l'id depuis route.paramMap. Signals : product signal<Product|null>, loading signal<boolean>. Computed stats : margeUnitaire = prixVente - prixAchat, ca = totalVendu * prixVente, margeTotal = totalVendu * margeUnitaire. Charger via firstValueFrom(productService.getById(id)). Effect sur productService.refreshTrigger pour recharger. Afficher : nom, description, icone/image, prixAchat, prixVente, stock, totalVendu, actif (badge), createdAt. Section stats : 3 cartes (marge unitaire, CA, marge totale) formatees avec AmountPipe. Bouton retour (router.navigate(['/shop'])). Bouton "Modifier" → modalService.openModal('product', product()). Gerer erreur 404 → navigation vers /shop. Add ':id' route → ShopDetail in app/src/app/features/shop/shop.routes.ts.

**Checkpoint**: Navigation liste → detail fonctionnelle. Stats calculees visibles.

---

## Phase 6: User Story 4 — Vendre un produit (Priority: P2)

**Goal**: L'utilisateur peut vendre 1 unite depuis la page detail (confirmation rapide) ou N unites depuis le FAB via le dialog "Vente rapide" (selecteur produit + quantite).

**Independent Test**: (1) Cliquer sur "Vendre" sur le detail d'un produit avec stock > 0 → confirmation → stock decremente de 1. (2) Depuis /shop, cliquer sur FAB → "Vente rapide" → choisir produit + quantite → valider → stock decremente de N.

### Implementation for User Story 4

- [x] T010 [US4] Add sell action to ShopDetail — ajouter dans app/src/app/features/shop/shop-detail/shop-detail.ts : methode async onSell() avec window.confirm('Confirmer la vente ?'), appel firstValueFrom(productService.sell(id)), recharger le produit. Bouton "Vendre" dans le template : disabled si product().stock === 0 ou !product().actif. Afficher indication "Rupture de stock" si stock = 0. Gerer erreur 409 (stock epuise entre-temps) avec message explicite.
- [x] T011 [P] [US4] Create SellDialog component in app/src/app/features/shop/components/sell-dialog/ (sell-dialog.ts, sell-dialog.html, sell-dialog.scss) — standalone, OnPush. Inputs : products = input<Product[]>([]). Outputs : confirmed = output<{productId: string, quantity: number}>(), cancelled = output<void>(). Formulaire : selecteur produit (dropdown/select des produits actifs avec stock > 0, afficher nom + stock dispo), champ quantity (number, required, min(1), max dynamique = stock du produit selectionne). Validation : empecher soumission si invalid ou aucun produit selectionne. Boutons Confirmer / Annuler.
- [x] T012 [US4] Integrate SellDialog in Shell + FAB — (1) modifier app/src/app/shared/components/shell/shell.ts : ajouter import SellDialog, handler async onSellConfirmed(event: {productId, quantity}) avec firstValueFrom(productService.sell(event.productId, event.quantity)), closeModal. Injecter ProductService si pas deja fait. Ajouter signal sellableProducts (produits actifs avec stock > 0) charge quand modal 'sell' s'ouvre. (2) modifier app/src/app/shared/components/shell/shell.html : ajouter @case('sell') avec <app-sell-dialog [products]="sellableProducts()" (confirmed)="onSellConfirmed($event)" (cancelled)="onModalClose()" />. (3) modifier app/src/app/shared/components/fab/fab.ts : sur la route /shop, ajouter deux actions conditionnelles au FAB : "Nouveau produit" → modalService.openModal('product'), "Vente rapide" → modalService.openModal('sell'). Les deux actions sont conditionnees a la feature SHOP activee.

**Checkpoint**: Vente fonctionnelle depuis le detail (1 unite) et depuis le FAB (N unites via SellDialog).

---

## Phase 7: User Story 5 — Restocker un produit (Priority: P2)

**Goal**: L'utilisateur peut restocker N unites via un dialog avec champ quantite.

**Independent Test**: Cliquer sur "Restocker" → saisir une quantite → confirmer → stock augmente.

### Implementation for User Story 5

- [x] T013 [P] [US5] Create RestockDialog component in app/src/app/features/shop/components/restock-dialog/ (restock-dialog.ts, restock-dialog.html, restock-dialog.scss) — standalone, OnPush. Inputs : visible = input<boolean>(false). Outputs : confirmed = output<RestockRequest>(), cancelled = output<void>(). Formulaire simple : champ quantity (number, required, min(1)). Boutons Confirmer / Annuler. Style dialog (overlay + card centree ou <dialog> HTML natif). Validation : empecher soumission si invalid.
- [x] T014 [US5] Integrate RestockDialog in ShopDetail — ajouter dans app/src/app/features/shop/shop-detail/shop-detail.ts : signal showRestockDialog = signal(false), methode async onRestock(req: RestockRequest) avec firstValueFrom(productService.restock(id, req)), fermer dialog, recharger produit. Template : bouton "Restocker" ouvre le dialog, <app-restock-dialog [visible]="showRestockDialog()" (confirmed)="onRestock($event)" (cancelled)="showRestockDialog.set(false)" />.

**Checkpoint**: Restock fonctionnel via dialog avec validation.

---

## Phase 8: User Story 6 — Consulter l'historique des ventes (Priority: P3)

**Goal**: L'utilisateur voit l'historique des transactions (ventes et restocks) sur la page detail.

**Independent Test**: Apres des ventes et restocks, la section historique affiche les transactions avec date, libelle, montant et type.

### Implementation for User Story 6

- [x] T015 [US6] Add sales history section to ShopDetail — ajouter dans app/src/app/features/shop/shop-detail/shop-detail.ts : signal salesHistory signal<Transaction[]>([]), charger via firstValueFrom(productService.getSalesHistory(id)) apres chargement du produit, recharger apres sell/restock. Template : section "Historique" avec @if (salesHistory().length === 0) message "Aucune transaction" @else @for sur salesHistory() afficher date (formatee), libelle, montant (AmountPipe), type (badge RECETTE vert / DEPENSE rouge). Importer Transaction depuis core/models/transaction.model.ts.

**Checkpoint**: Historique complet visible sur la page detail. Toutes les user stories implementees.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Verification build, formatage, documentation.

- [x] T016 Run Prettier formatting on all new and modified files in app/src/app/features/shop/ and app/src/app/core/ and app/src/app/shared/components/shell/ and app/src/app/shared/components/fab/
- [x] T017 Run ng build and ng lint — fix any compilation or lint errors in app/
- [x] T018 Sync CLAUDE.md — ajouter dans Active Technologies : "TypeScript 5.9, Angular 21 + Angular Reactive Forms, Angular Signals, Angular Router (068-angular-shop-module)" et "Server-only (API REST, pas de stockage local) (068-angular-shop-module)". Ajouter dans Recent Changes : "068-angular-shop-module: ProductService + ShopList + ProductForm + ShopDetail + SellDialog + RestockDialog; backend GET /products?includeInactive + POST sell with SellRequest; ModalType +product +sell; routes /shop, /shop/:id; filtre actifs/inactifs; sell (detail 1u + FAB Nu) / restock actions; sales history; FAB conditionnel /shop"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: T003 (backend) independent de Phase 1. T004 depends on T001 (Product import).
- **US1 (Phase 3)**: Depends on T001 (model) + T002 (service). T006 depends on T005 (ShopList must exist).
- **US2 (Phase 4)**: Depends on T001 (model) + T004 (ModalType). T008 depends on T007 (ProductForm must exist).
- **US3 (Phase 5)**: Depends on T002 (service) + T006 (routes). Navigation from ShopList.
- **US4 (Phase 6)**: T010 depends on T009 (ShopDetail). T011 (SellDialog) independent — can run in parallel. T012 depends on T011 (SellDialog) + T004 (ModalType 'sell') + T008 (Shell pattern).
- **US5 (Phase 7)**: Depends on T009 (ShopDetail must exist). T014 depends on T013.
- **US6 (Phase 8)**: Depends on T009 (ShopDetail must exist).
- **Polish (Phase 9)**: Depends on all previous phases.

### User Story Dependencies

- **US1 (P1)**: Independent after Setup — MVP standalone
- **US2 (P1)**: Independent after Setup + T004 — can run in parallel with US1
- **US3 (P2)**: Depends on US1 (navigation from list to detail)
- **US4 (P2)**: Depends on US3 (sell on detail) + US2 phase complete (Shell pattern for SellDialog)
- **US5 (P2)**: Depends on US3 (restock action lives on detail page)
- **US6 (P3)**: Depends on US3 (history section lives on detail page)

### Within Each User Story

- Models before services
- Services before components
- Core component before integration (Shell, routes)
- Story complete before moving to next priority

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- T003 and T004 can run in parallel (backend vs frontend)
- US1 and US2 can run in parallel after Setup (different components, no file overlap)
- T011 (SellDialog) can run in parallel with T010 (different files)
- T013 (RestockDialog) can run in parallel with any non-ShopDetail task
- US4, US5, US6 share ShopDetail file — sequential recommended for T010, T014, T015

---

## Parallel Example: Setup Phase

```bash
# Launch both setup tasks in parallel (different files):
Task T001: "Create Product model in app/src/app/core/models/product.model.ts"
Task T002: "Create ProductService in app/src/app/core/services/product.ts"
```

## Parallel Example: Foundational Phase

```bash
# Backend and frontend foundational tasks in parallel:
Task T003: "Backend modifications (includeInactive + SellRequest + sell quantity)"
Task T004: "Add 'product' + 'sell' to ModalType in modal.service.ts"
```

## Parallel Example: P1 Stories

```bash
# After Setup completes, US1 and US2 can run in parallel:
Task T005+T006: "ShopList + routes (US1)"
Task T007+T008: "ProductForm + Shell integration (US2)"
```

## Parallel Example: US4 Phase

```bash
# SellDialog can be created in parallel with detail sell action:
Task T010: "Add sell action to ShopDetail (detail page)"
Task T011: "Create SellDialog component (separate directory)"
# Then sequential:
Task T012: "Integrate SellDialog in Shell + FAB (depends on T011)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001, T002)
2. Complete Phase 2: Foundational (T003, T004)
3. Complete Phase 3: US1 (T005, T006)
4. **STOP and VALIDATE**: `/shop` affiche la liste, skeleton, filtre, etat vide
5. Commit and test

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 (liste) → MVP testable → Commit
3. US2 (formulaire) → Creation/edition fonctionnelles → Commit
4. US3 (detail) → Navigation complete → Commit
5. US4 (vente detail + SellDialog + FAB) → Vente operationnelle → Commit
6. US5 (restock) → Restock operationnel → Commit
7. US6 (historique) → Module complet → Commit
8. Polish → Build clean → Commit final

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Each user story is independently testable after its phase
- Commit after each phase or logical group
- Backend modification (T003) requires `cd api && mvn clean compile` pour verifier
- Frontend verification : `cd app && ng build` apres chaque phase Angular
- SellRequest backend : le body est optionnel sur POST /products/{id}/sell — si absent, defaut a 1 unite
