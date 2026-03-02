# Tasks: Formulaire Produit (creation/edition)

**Input**: Design documents from `/specs/061-flutter-product-form/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: Non demandes dans la spec. Non inclus.

**Organization**: US3 (validation) et US4 (marge) sont integres dans US1 car les acceptance scenarios de US1 exigent la validation et la marge pour etre fonctionnels. US2 (edition) est un phase separee.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Ajouter les dependances et creer les utilitaires partages

- [X] T001 Add `image_picker` and `path_provider` dependencies to `flutter/pubspec.yaml` and run `flutter pub get`
- [X] T002 [P] Create `DecimalTextInputFormatter` (extends TextInputFormatter) that limits input to N decimal places (default 2) in `flutter/lib/src/utils/decimal_input_formatter.dart` — regex `^\d*[.,]?\d{0,N}$`, replace comma with dot, reject invalid input
- [X] T003 [P] Add `ModalType.product` to enum and all maps (modalCreateTitles: "Nouveau produit", modalEditTitles: "Modifier le produit", modalDefaultSubTypes: null, modalToggleLabels: null, modalToggleValues: null) in `flutter/lib/src/domain/enums/modal_type.dart`

---

## Phase 2: User Story 1 + 3 + 4 — Creer un produit avec validation et marge (Priority: P1) MVP

**Goal**: L'utilisateur peut ouvrir le formulaire de creation, remplir les champs (nom, description, image, prix achat, prix vente, stock), voir la marge en temps reel, et enregistrer le produit via l'API.

**Independent Test**: Ouvrir le formulaire depuis la liste vide, remplir les champs obligatoires, verifier la marge, enregistrer et constater le produit dans la liste.

**Covers**: US1 (creation), US3 (validation — FR-003, FR-009), US4 (marge — FR-004, FR-005)

### Implementation

- [X] T004 [US1] [US3] Create `ProductForm` ConsumerStatefulWidget with: controllers (_nomController, _descriptionController, _prixAchatController, _prixVenteController, _stockController), state vars (_showErrors, _isSubmitting, _initialized, _localImagePath), validation methods (_validateNom, _validateDescription, _validatePrixAchat, _validatePrixVente, _validateStock) with error messages from data-model.md, _isValid() aggregator, dispose, and form layout using AppFormField for each field — nom (text, maxLength 100, MaxLengthEnforcement.enforced), description (multiline, maxLength 500), prix achat (decimal, keyboardType numberWithOptions, DecimalTextInputFormatter + FilteringTextInputFormatter), prix vente (same), stock (integer, keyboardType number, create only) — with _showErrors pattern and FilledButton "Enregistrer" in `flutter/lib/src/features/shop/presentation/widgets/product_form.dart`
- [X] T005 Add `ModalType.product` case in `_buildModalChild()` — build `ProductForm` widget with `product: state.entity as Product?`, `onSaved` callback calling `ProductNotifier.create()` or `update()` based on mode, `onCancelled` calling `modalNotifier.close()` in `flutter/lib/src/routing/app_router.dart`
- [X] T006 [US1] [US4] Add real-time margin indicator `_buildMargeIndicator()` between prix vente field and stock field — compute marge = prixVente - prixAchat from controller values, display formatted amount via `AmountFormatter.format()`, use `AppThemeExtension` colors: green (income) when marge >= 0, red (expense) when marge < 0, hidden when either price field is empty or unparseable in `flutter/lib/src/features/shop/presentation/widgets/product_form.dart`
- [X] T007a [US1] Configure native permissions for image_picker: add `NSCameraUsageDescription` ("Prendre une photo du produit") and `NSPhotoLibraryUsageDescription` ("Choisir une photo du produit") in `flutter/ios/Runner/Info.plist` — add `<uses-permission android:name="android.permission.CAMERA"/>` in `flutter/android/app/src/main/AndroidManifest.xml`
- [X] T007b [US1] Implement image picker area at top of form: tappable container (120x120, rounded, surfaceContainerHighest background) showing Image.file when _localImagePath is set or placeholder icon (Icons.add_a_photo) — on tap show `showModalBottomSheet` action sheet with Camera/Galerie options (+ Supprimer if image exists) — use `ImagePicker().pickImage(source: ..., maxWidth: 1024, imageQuality: 85)`, copy file to `<getApplicationDocumentsDirectory()>/products/<uuid>.<ext>`, delete old file if replacing, setState _localImagePath — handle permission denied gracefully (silent no-op) in `flutter/lib/src/features/shop/presentation/widgets/product_form.dart`
- [X] T008 [US1] Implement `_onSubmit()`: set `_showErrors = true`, check `_isValid()`, set `_isSubmitting = true`, build Product object (id: '' for create, nom, description, icone: null, imageUrl: _localImagePath, prixAchat, prixVente, stock, defaults for totalVendu/actif), call `widget.onSaved(product)`, catch Exception → show SnackBar error + set `_isSubmitting = false` — FilledButton shows CircularProgressIndicator(strokeWidth: 2) when submitting, onPressed: null when submitting in `flutter/lib/src/features/shop/presentation/widgets/product_form.dart`
- [X] T009 [US1] Wire ProductListScreen: replace empty state No-op `onPressed` with `ref.read(modalNotifierProvider.notifier).open(ModalType.product)` — add import for ModalNotifier and ModalType in `flutter/lib/src/features/shop/presentation/product_list_screen.dart`

**Checkpoint**: Creation de produit fonctionnelle — formulaire avec validation, marge temps reel, image picker, et sauvegarde API

---

## Phase 3: User Story 2 — Editer un produit existant (Priority: P2)

**Goal**: L'utilisateur tape sur un produit dans la liste, le formulaire s'ouvre pre-rempli, le stock est masque, et il peut modifier et sauvegarder.

**Independent Test**: Taper sur un produit existant, verifier les champs pre-remplis et le stock masque, modifier le prix de vente, verifier la marge mise a jour, enregistrer.

### Implementation

- [X] T010 [US2] Add edit mode support to ProductForm: `_isEditMode` getter (`widget.product != null`), `_initFromEntity()` method to pre-fill all controllers from widget.product (called in build with `_initialized` guard), hide stock AppFormField when `_isEditMode`, load existing image (if product.imageUrl is non-null and file exists set _localImagePath), build Product for update keeping existing id/stock/totalVendu/actif values in `flutter/lib/src/features/shop/presentation/widgets/product_form.dart`
- [X] T011 [US2] Wire ProductListScreen item tap: replace No-op `onPressed` with `ref.read(modalNotifierProvider.notifier).open(ModalType.product, entity: product)` for each list item in `flutter/lib/src/features/shop/presentation/product_list_screen.dart`

**Checkpoint**: Edition de produit fonctionnelle — pre-remplissage, stock masque, sauvegarde API

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Ameliorations visuelles et validation finale

- [X] T012 [P] [FR-011] Update ProductListScreen to display product image when imageUrl is non-null and file exists: replace `ListItem` with inline widget showing ClipRRect + Image.file (40x40, cover) or fallback to emoji circle (product.icone ?? '📦') in `flutter/lib/src/features/shop/presentation/product_list_screen.dart`
- [X] T013 Run `flutter analyze` in `flutter/` and fix any issues

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **US1+US3+US4 (Phase 2)**: Depends on Phase 1 complete (T001 image_picker, T002 DecimalTextInputFormatter, T003 ModalType.product)
- **US2 (Phase 3)**: Depends on Phase 2 complete (form must exist before adding edit mode)
- **Polish (Phase 4)**: Depends on Phase 3 complete

### User Story Dependencies

- **US1+US3+US4 (P1)**: Can start after Phase 1
- **US2 (P2)**: Requires US1 complete (form must exist before adding edit mode)

### Within Phase 2 (US1)

```
T004 (form skeleton + fields + validation)
  → T005 (router integration — needs ProductForm class to exist)
  → T006 (margin indicator — needs price field controllers from T004)
  → T007a (native permissions — needs image_picker dep from T001)
  → T007b (image picker widget — needs form layout from T004 + permissions from T007a)
  → T008 (submit — needs validation + fields from T004-T007b)
  → T009 (wire list — needs form + router to exist)
```

T007a touches platform config files (Info.plist, AndroidManifest.xml). T005, T006 and T007b are sequential (T005 touches a different file but depends on T004; T006 and T007b touch the same file as T004).

### Parallel Opportunities

- **Phase 1**: T002 and T003 can run in parallel (different files)
- **Phase 4**: T012 can run in parallel with T013 (different concerns)

---

## Parallel Example: Phase 1

```
# Launch in parallel:
Task T002: "Create DecimalTextInputFormatter in flutter/lib/src/utils/decimal_input_formatter.dart"
Task T003: "Add ModalType.product to flutter/lib/src/domain/enums/modal_type.dart"
```

---

## Implementation Strategy

### MVP First (US1 + US3 + US4)

1. Complete Phase 1: Setup (3 tasks)
2. Complete Phase 2: US1 + US3 + US4 (7 tasks)
3. **STOP and VALIDATE**: Tester la creation de produit (SC-001, SC-003, SC-004, SC-005)
4. Commit MVP

### Incremental Delivery

1. Phase 1 (Setup) → Infrastructure prete
2. Phase 2 (US1+US3+US4) → Creation fonctionnelle → Commit MVP
3. Phase 3 (US2) → Edition fonctionnelle → Commit
4. Phase 4 (Polish) → Image dans la liste + analyze → Commit final

---

## Notes

- [P] tasks = different files, no dependencies
- US3 (validation) et US4 (marge) sont integres dans Phase 2 car les acceptance scenarios de US1 les exigent
- Le Product model et le ProductNotifier existants ne necessitent aucune modification
- Le ProductRequest/ProductUpdateRequest DTOs existants supportent deja tous les champs necessaires
- L'endpoint restock (stock > 0 en creation) est gere cote serveur — pas de logique formulaire
- Commit apres chaque phase complete
