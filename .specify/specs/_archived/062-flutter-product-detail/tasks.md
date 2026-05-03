# Tasks: Detail Produit — Actions vente, restock et historique

**Input**: Design documents from `/specs/062-flutter-product-detail/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Non demandes dans la spec — pas de taches de test generees.

**Organization**: Taches groupees par user story pour implementation et test independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut tourner en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story associee (US1, US2, US3, US4, US5)
- Chemins exacts dans chaque description

---

## Phase 1: Setup

**Purpose**: Pas de setup projet — le projet Flutter et le backend existent deja. Cette phase couvre uniquement le fix backend prerequis.

- [x] T001 Fix `ProductService.getSalesHistory()` pour retourner RECETTE + DEPENSE (supprimer le filtre Java `.filter(t -> t.getType() == TransactionType.RECETTE)`) dans `api/src/main/java/fr/kksdev/budget/api/service/ProductService.java`

---

## Phase 2: Foundational (Data Layer Flutter)

**Purpose**: Extensions du data layer Flutter necessaires a TOUTES les user stories. DOIT etre complete avant toute implementation UI.

**CRITICAL**: Aucune tache de Phase 3+ ne peut demarrer avant la fin de cette phase.

- [x] T002 [P] Ajouter `RestockRequest` DTO (classe `@JsonSerializable` avec champ `quantity`) dans `flutter/lib/src/data/remote/dtos/product_dtos.dart`
- [x] T003 [P] Ajouter les methodes `sell(id)`, `restock(id, request)`, `getSales(id)` a `ProductRemoteDataSource` dans `flutter/lib/src/data/remote/data_sources/product_remote_data_source.dart` — endpoints: `POST /products/{id}/sell`, `POST /products/{id}/restock`, `GET /products/{id}/sales`
- [x] T004 [P] Ajouter les methodes `sell(id)`, `restock(id, quantity)`, `getSales(id)` a l'interface `ProductRepository` dans `flutter/lib/src/domain/repositories/product_repository.dart`
- [x] T005 Implementer `sell()`, `restock()`, `getSales()` dans `ProductRepositoryRemote` dans `flutter/lib/src/features/shop/data/product_repository_remote.dart` (depends on T002, T003, T004)
- [x] T006 Ajouter `sellProduct(id)` et `restockProduct(id, quantity)` au `ProductNotifier` + creer `productSalesProvider` (FutureProvider.family) dans `flutter/lib/src/features/shop/application/product_notifier.dart` — sellProduct/restockProduct mettent a jour le produit dans `allItems` et invalident `productSalesProvider(id)` (depends on T005)
- [x] T007 [P] Ajouter la sous-route `/shop/:id` dans go_router avec `builder` pointant vers `ProductDetailScreen` et recevant `Product` via `state.extra` dans `flutter/lib/src/routing/app_router.dart`
- [x] T008 Executer `dart run build_runner build --delete-conflicting-outputs` dans `flutter/` pour generer les fichiers `.g.dart` apres ajout du DTO (depends on T002)

**Checkpoint**: Data layer complet — toutes les methodes sell/restock/getSales disponibles via le notifier et les providers.

---

## Phase 3: User Story 1 - Consulter le detail d'un produit (Priority: P1) MVP

**Goal**: L'utilisateur voit un ecran de detail complet avec header (image/icone, nom, description) et statistiques (prix achat/vente, marge unitaire, stock, total vendu, chiffre d'affaires, marge totale).

**Independent Test**: Naviguer vers un produit depuis la liste → verifier que toutes les informations sont affichees correctement.

### Implementation

- [x] T009 [US1] Creer `ProductDetailScreen` (ConsumerWidget) dans `flutter/lib/src/features/shop/presentation/product_detail_screen.dart` — Scaffold avec AppBar (titre = nom du produit), body scrollable avec : 1) Section header (image locale via `File.existsSync()` ou icone/emoji fallback, nom, description si presente), 2) Section stats en grille (prix achat, prix vente, marge unitaire, stock, total vendu, CA, marge totale) — utiliser `AmountFormatter.format()` pour les montants, design tokens `AppSpacing`, `AppRadius`, `AppColors` — watch `productNotifierProvider` pour trouver le produit dans `state.items` par id, fallback sur le product passe en `extra` — etats loading (shimmer) et erreur geres
- [x] T010 [US1] Modifier `ProductListScreen` pour naviguer vers le detail au tap sur un produit (`context.push('/shop/${product.id}', extra: product)`) au lieu d'ouvrir la modale edition dans `flutter/lib/src/features/shop/presentation/product_list_screen.dart` (depends on T009)

**Checkpoint**: US1 fonctionnel — l'utilisateur peut consulter le detail d'un produit avec toutes ses stats.

---

## Phase 4: User Story 2 - Vendre un produit (Priority: P1)

**Goal**: L'utilisateur appuie sur "Vendre" pour decrementez le stock de 1, avec feedback immediat et desactivation si stock = 0 ou produit inactif.

**Independent Test**: Vendre un produit avec du stock → verifier que le stock decremente, le total vendu augmente, les stats se recalculent, et un snackbar confirme la vente.

### Implementation

- [x] T011 [US2] Ajouter le bouton "Vendre" (prominent, style `FilledButton` ou equivalent) dans `ProductDetailScreen` dans `flutter/lib/src/features/shop/presentation/product_detail_screen.dart` — desactive si `stock == 0` ou `!actif`, appelle `productNotifier.sellProduct(id)`, affiche snackbar succes ("Vente enregistree") ou erreur, gere l'etat loading pendant l'appel (indicator sur le bouton), le bouton se desactive immediatement quand stock passe a 0 (depends on T009)

**Checkpoint**: US1 + US2 fonctionnels — consultation et vente operationnelles.

---

## Phase 5: User Story 3 - Restocker un produit (Priority: P2)

**Goal**: L'utilisateur appuie sur "Ajouter stock", saisit une quantite dans un dialogue, et le stock augmente avec creation automatique d'une transaction DEPENSE.

**Independent Test**: Restocker un produit → verifier que le stock augmente, snackbar confirme, et le dialogue valide les saisies invalides.

### Implementation

- [x] T012 [P] [US3] Creer `RestockDialog` (StatefulWidget) dans `flutter/lib/src/features/shop/presentation/widgets/restock_dialog.dart` — `showDialog()` avec `AlertDialog` contenant : titre "Ajouter du stock", un `AppFormField` avec `TextField` (keyboardType: number, inputFormatters: digits only), validation (entier > 0, message erreur si invalide), boutons "Annuler" (`Navigator.pop(null)`) et "Confirmer" (`Navigator.pop(quantity)`), style coherent avec design tokens
- [x] T013 [US3] Ajouter le bouton "Ajouter stock" dans `ProductDetailScreen` dans `flutter/lib/src/features/shop/presentation/product_detail_screen.dart` — desactive si `!actif`, ouvre `RestockDialog`, si resultat non-null appelle `productNotifier.restockProduct(id, quantity)`, affiche snackbar succes ou erreur (depends on T012, T009)

**Checkpoint**: US1 + US2 + US3 fonctionnels — consultation, vente et restock operationnels.

---

## Phase 6: User Story 4 - Historique des transactions liees (Priority: P2)

**Goal**: L'utilisateur voit la liste des transactions associees au produit (ventes et restocks) dans une section dediee en bas de l'ecran de detail.

**Independent Test**: Verifier que les transactions liees s'affichent avec type, montant et date — et que l'etat vide affiche "Aucune transaction".

### Implementation

- [x] T014 [US4] Ajouter la section "Historique" dans `ProductDetailScreen` dans `flutter/lib/src/features/shop/presentation/product_detail_screen.dart` — titre de section "Historique", watch `productSalesProvider(id)` (AsyncValue), etats: loading (shimmer), erreur (message + retry), vide ("Aucune transaction"), data (liste de transactions triees par date desc avec : icone type RECETTE/DEPENSE, libelle, montant formate avec `AmountFormatter.format()` et couleur semantique income/expense, date formatee) — la section se rafraichit automatiquement apres sell/restock grace a l'invalidation du provider (depends on T009)

**Checkpoint**: US1 + US2 + US3 + US4 fonctionnels — ecran de detail complet avec historique.

---

## Phase 7: User Story 5 - Modifier un produit depuis le detail (Priority: P3)

**Goal**: L'utilisateur appuie sur "Modifier" pour ouvrir le formulaire d'edition du produit (KKS-124). Les modifications sont refletees au retour.

**Independent Test**: Modifier un produit depuis le detail → verifier que les changements sont visibles au retour.

### Implementation

- [x] T015 [US5] Ajouter le bouton "Modifier" dans `ProductDetailScreen` (en action AppBar ou bouton dans la section actions) dans `flutter/lib/src/features/shop/presentation/product_detail_screen.dart` — appelle `ref.read(modalNotifierProvider.notifier).open(ModalType.product, entity: product)` — les donnees se mettent a jour au retour grace au watch du `productNotifierProvider` (depends on T009)

**Checkpoint**: Toutes les user stories fonctionnelles — ecran de detail complet.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, etats limites, et verification finale

- [x] T016 Gerer les edge cases dans `ProductDetailScreen` dans `flutter/lib/src/features/shop/presentation/product_detail_screen.dart` — produit avec prixAchat = 0 (marge = prixVente, pas de division), produit inactif (boutons vendre et restock desactives avec indication visuelle), produit supprime pendant consultation (erreur si le produit disparait de `productNotifierProvider.items`)
- [x] T017 Executer `flutter analyze` dans `flutter/` et corriger les warnings eventuels

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Pas de dependance — demarrer immediatement
- **Phase 2 (Foundational)**: T008 depend de T002, T005 depend de T002+T003+T004, T006 depend de T005. BLOQUE toutes les phases suivantes.
- **Phase 3 (US1)**: Depend de Phase 2 complete
- **Phase 4 (US2)**: Depend de Phase 3 (US1) — le bouton est sur l'ecran cree en US1
- **Phase 5 (US3)**: Depend de Phase 3 (US1) — le bouton est sur l'ecran cree en US1
- **Phase 6 (US4)**: Depend de Phase 3 (US1) — la section est sur l'ecran cree en US1
- **Phase 7 (US5)**: Depend de Phase 3 (US1) — le bouton est sur l'ecran cree en US1
- **Phase 8 (Polish)**: Depend de toutes les phases precedentes

### User Story Dependencies

- **US1 (P1)**: Apres Phase 2 — aucune dependance inter-story
- **US2 (P1)**: Apres US1 — modifie le meme fichier (`product_detail_screen.dart`)
- **US3 (P2)**: Apres US1 — `RestockDialog` est un fichier separe [P], mais l'integration dans l'ecran depend de US1
- **US4 (P2)**: Apres US1 — modifie le meme fichier
- **US5 (P3)**: Apres US1 — modifie le meme fichier

**Note**: US2, US3, US4, US5 dependent toutes de US1 car elles ajoutent des elements au meme ecran. Elles sont sequentielles par nature (meme fichier).

### Parallel Opportunities

```text
Phase 2: T002 ∥ T003 ∥ T004 ∥ T007 (fichiers differents)
Phase 5: T012 (RestockDialog) ∥ autres taches sur d'autres fichiers
Phase 1: T001 (backend) ∥ Phase 2 T002-T004 (Flutter) — stacks differentes
```

---

## Parallel Example: Phase 2

```bash
# Lancer en parallele (fichiers differents) :
Task T002: "Ajouter RestockRequest DTO dans product_dtos.dart"
Task T003: "Ajouter sell/restock/getSales a ProductRemoteDataSource"
Task T004: "Ajouter sell/restock/getSales a ProductRepository interface"
Task T007: "Ajouter sous-route /shop/:id dans app_router.dart"

# Puis sequentiellement :
Task T008: "build_runner" (apres T002)
Task T005: "Implementer dans ProductRepositoryRemote" (apres T002+T003+T004)
Task T006: "Ajouter au ProductNotifier" (apres T005)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Fix backend (T001)
2. Complete Phase 2: Data layer Flutter (T002-T008)
3. Complete Phase 3: US1 — ecran detail avec stats (T009-T010)
4. **STOP and VALIDATE**: Naviguer vers un produit depuis la liste → verifier toutes les stats
5. Commit et verifier `/sync-doc`

### Incremental Delivery

1. Phase 1 + Phase 2 → Foundation complete
2. US1 (detail + stats) → Validation → Commit
3. US2 (vente) → Validation → Commit
4. US3 (restock) → Validation → Commit
5. US4 (historique) → Validation → Commit
6. US5 (modifier) → Validation → Commit
7. Phase 8 (polish) → Validation finale → Commit

---

## Notes

- Les taches modifient principalement un seul nouveau fichier (`product_detail_screen.dart`) de maniere incrementale
- L'ordre d'execution est naturellement sequentiel (US1 → US2 → US3 → US4 → US5) car tout s'ajoute au meme ecran
- Seul `RestockDialog` (T012) est un fichier separe pouvant etre developpe en parallele
- Le fix backend (T001) peut etre fait en parallele avec tout le travail Flutter
- Commiter apres chaque checkpoint (US complete)
