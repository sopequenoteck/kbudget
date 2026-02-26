# Tasks: Flutter Settings — Gestion Comptes

**Input**: Design documents from `/specs/053-flutter-settings-accounts/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-endpoints.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- Exact file paths included in descriptions

---

## Phase 1: Setup

**Purpose**: Localization, routes et configuration de base

- [X] T001 Add localization keys for account management screens (list labels, form labels, validation messages, error messages, button texts, badge texts, confirmation dialogs) in flutter/lib/src/localization/app_fr.arb (seul fichier ARB existant — app FR-only)
- [X] T002 [P] Add route constants settingsAccountsNew and settingsAccountsEdit (with named routes) in flutter/lib/src/routing/route_names.dart
- [X] T003 Configure account routes in flutter/lib/src/routing/app_router.dart: replace StubSettingsScreen(title: 'Comptes') with AccountListScreen for /settings/accounts, add GoRoute for /settings/accounts/new (AccountFormScreen create) and /settings/accounts/:id (AccountFormScreen edit with Account via state.extra), all with parentNavigatorKey: _rootNavigatorKey

---

## Phase 2: Foundational (adjustBalance Pipeline)

**Purpose**: Extension du pipeline data Account pour supporter l'ajustement de solde. Modifie les fichiers partagés AVANT la création des écrans pour éviter les conflits.

- [X] T004 Create AdjustBalanceRequest DTO with json_serializable (single field: double newBalance) in flutter/lib/src/data/remote/dtos/adjust_balance_request.dart, then run `dart run build_runner build --delete-conflicting-outputs` from flutter/ directory
- [X] T005 Add adjustBalance(String id, double newBalance) method to AccountRepository abstract interface in flutter/lib/src/domain/repositories/account_repository.dart (returns Future\<Account\>)
- [X] T006 Add adjustBalance() to AccountRemoteDataSource (POST /accounts/{id}/adjust-balance with AdjustBalanceRequest body, returns AccountResponse) in flutter/lib/src/data/remote/data_sources/account_remote_data_source.dart
- [X] T007 Implement adjustBalance() in AccountRepositoryRemote (call _dataSource.adjustBalance, map response via _toDomain) in flutter/lib/src/features/accounts/data/account_repository_remote.dart
- [X] T008 Add adjustBalance() to AccountNotifier (follow setDefault pattern: mutatingIds tracking, update _allItems with result, _refreshPage, error handling) in flutter/lib/src/features/accounts/application/account_notifier.dart

**Checkpoint**: adjustBalance disponible dans le notifier. Les tests existants doivent toujours passer.

---

## Phase 3: User Story 1 — Consulter la liste des comptes (Priority: P1) MVP

**Goal**: Afficher tous les comptes avec icône, nom, type, solde, devise, badges "Défaut"/"Inactif", skeleton loading, états vide/erreur.

**Independent Test**: Naviguer vers Settings > Comptes et vérifier que les comptes s'affichent correctement avec tous les états (loading, error, empty, data).

### Implementation

- [X] T009 [P] [US1] Create AccountListSkeleton widget (5 shimmer items with icon circle, text lines, amount placeholder — follow ListItem.skeleton() pattern with Shimmer.fromColors) in flutter/lib/src/features/accounts/presentation/widgets/account_list_skeleton.dart
- [X] T010 [P] [US1] Create AccountListTile widget (ConsumerWidget: leading emoji icon with colored circle background, title=nom, subtitle=type label, trailing=formatted balance with currency via AmountFormatter, badges row for "Défaut" and "Inactif", opacity 0.5 for inactive accounts, PopupMenuButton trailing icon ⋮ with empty actions placeholder, onTap callback for navigation) in flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart
- [X] T011 [US1] Create AccountListScreen (ConsumerStatefulWidget: initState loads accountNotifier.loadItems() via addPostFrameCallback if empty, build uses RefreshIndicator + CustomScrollView with slivers, _buildContent returns loading→skeleton / error→retry button / empty→icon+message / data→SliverList of AccountListTile, onTap navigates to /settings/accounts/:id with account as extra, AppBar title "Comptes", FAB or AppBar action "+" button navigates to /settings/accounts/new) in flutter/lib/src/features/accounts/presentation/screens/account_list_screen.dart

**Checkpoint**: La liste des comptes est navigable depuis Settings. Skeleton, erreur, vide et données fonctionnent. Le FAB et le tap sur un item naviguent (vers des écrans vides pour l'instant).

---

## Phase 4: User Story 2 — Créer un nouveau compte (Priority: P1) MVP

**Goal**: Formulaire full-screen de création avec sélection type, emoji, couleur, nom, solde initial, devise. Aperçu temps réel. Validation. Création via API.

**Independent Test**: Depuis la liste, appuyer sur "+", remplir le formulaire, valider, vérifier le retour à la liste avec le nouveau compte.

### Implementation

- [X] T012 [P] [US2] Create ColorPalettePicker widget (StatelessWidget: grid of 12 color circles from predefined hex palette [#3b82f6, #10b981, #f59e0b, #ef4444, #f97316, #84cc16, #22c55e, #06b6d4, #6366f1, #8b5cf6, #ec4899, #6b7280], selected state with border + scale, onChanged callback with hex string, support for custom initial color not in palette — si initialColor n'est pas dans la palette, l'afficher comme cercle sélectionné supplémentaire en première position) in flutter/lib/src/features/accounts/presentation/widgets/color_palette_picker.dart
- [X] T013 [P] [US2] Create AccountTypeSelector widget (StatelessWidget: Row of 3 cards for Courant/Épargne/Espèces, each shows default emoji + label, selected card has primary color background, disabled state for edit mode with reduced opacity, onChanged callback with AccountType, provides default icon/color per type: courant=🏦/#3b82f6, epargne=🐷/#22c55e, especes=💵/#f59e0b) in flutter/lib/src/features/accounts/presentation/widgets/account_type_selector.dart
- [X] T014 [P] [US2] Create AccountPreviewCard widget (StatelessWidget: container with left border colored by selected couleur, shows emoji icon + account name or placeholder, updates in real-time from parent state) in flutter/lib/src/features/accounts/presentation/widgets/account_preview_card.dart
- [X] T015 [US2] Create AccountFormScreen in CREATE mode (ConsumerStatefulWidget: Scaffold with AppBar title "Nouveau compte" and save IconButton, ListView body with sections: AccountPreviewCard, AccountTypeSelector, EmojiInput + ColorPalettePicker row, AppFormField for nom (required 1-50 chars), SelectPicker for currency (from Currency enum), AppFormField for solde initial (decimal keyboard, default "0"), validation methods _validateNom/_validateMontant, _showErrors flag, _isSubmitting with spinner in AppBar, _onSubmit builds Account and calls accountNotifier.create(), on success context.pop(), on error SnackBar + form preserved, type selection auto-fills icon+color defaults) in flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart

**Checkpoint**: Création de compte fonctionnelle de bout en bout. Sélection de type pré-remplit icône/couleur. Validation empêche la soumission invalide. Le nouveau compte apparaît dans la liste après retour.

---

## Phase 5: User Story 3 — Modifier un compte existant (Priority: P2)

**Goal**: Formulaire d'édition pré-rempli, type/devise en lecture seule, switch actif/inactif, sauvegarde via API.

**Independent Test**: Taper sur un compte dans la liste, modifier le nom et l'icône, sauvegarder, vérifier les changements dans la liste.

**Dependencies**: US2 (AccountFormScreen doit exister)

### Implementation

- [X] T016 [US3] Extend AccountFormScreen with edit mode: accept optional Account parameter (null=create, non-null=edit), AppBar title "Modifier le compte", lazy init from account (populate controllers + state), AccountTypeSelector disabled=true, currency SelectPicker disabled, hide soldeInitial field and show it as _ReadOnlyField instead, add Switch for actif (disabled with hint text if isDefault), on save call accountNotifier.update() with modified Account, preserve form data on error in flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart

**Checkpoint**: Modification de compte fonctionnelle. Type/devise non modifiables. Compte par défaut ne peut pas être désactivé.

---

## Phase 6: User Story 4 — Ajuster le solde d'un compte (Priority: P2)

**Goal**: En mode édition, afficher le solde actuel et permettre la saisie d'un nouveau solde. L'ajustement est déclenché au save si le solde a changé.

**Independent Test**: Ouvrir un compte en édition, saisir un nouveau solde, sauvegarder, vérifier que le solde est mis à jour.

**Dependencies**: US3 (edit mode doit exister), Phase 2 (adjustBalance pipeline)

### Implementation

- [X] T017 [US4] Add balance adjustment to AccountFormScreen edit mode: display current solde as _ReadOnlyField (formatted with AmountFormatter + currency), add AppFormField "Nouveau solde" (decimal keyboard, initially empty, suffix with currency symbol), on _onSubmit: if newBalance field is non-empty and differs from account.solde, call accountNotifier.adjustBalance(id, newBalance) after update(), skip adjustment if values are equal in flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart

**Checkpoint**: Ajustement de solde fonctionnel. Le solde actuel est visible. Un nouveau solde différent crée un ajustement.

---

## Phase 7: User Story 5 + 6 — Supprimer + Définir par défaut (Priority: P3)

**Goal**: Actions contextuelles dans le menu popup (⋮) de chaque item de la liste : "Définir par défaut" (conditionnel) et "Supprimer" (avec confirmation).

**Independent Test**: US6: Définir un compte non-défaut comme défaut et vérifier le changement de badge. US5: Supprimer un compte sans transactions et vérifier sa disparition.

**Dependencies**: US1 (AccountListTile doit exister)

### Implementation

- [X] T018 [US6] Add "Définir par défaut" action to AccountListTile PopupMenuButton: PopupMenuItem visible only if account.actif && !account.isDefault, on tap call ref.read(accountNotifierProvider.notifier).setDefault(account.id), show SnackBar on error in flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart
- [X] T019 [US5] Add "Supprimer" action to AccountListTile PopupMenuButton: PopupMenuItem always visible, on tap show AlertDialog confirmation (title + message), on confirm call ref.read(accountNotifierProvider.notifier).delete(account.id), catch error and show SnackBar with API error message (default account, linked transactions/subscriptions) in flutter/lib/src/features/accounts/presentation/widgets/account_list_tile.dart
- [X] T020 [P] [US5] Add delete button to AccountFormScreen edit mode: red IconButton(Icons.delete_outline) at bottom-left of form actions row, on tap show AlertDialog confirmation, on confirm call accountNotifier.delete(account.id) then context.pop(), catch error and show SnackBar in flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart

**Checkpoint**: Toutes les 6 user stories fonctionnelles. CRUD complet + set default + adjust balance.

---

## Phase 8: Tests

**Purpose**: Tests unitaires (notifier) et widget tests (écrans et widgets) suivant les conventions projet.

- [X] T021 [P] Add adjustBalance tests to existing account_notifier_test.dart: should_updateBalance_when_adjustBalanceCalled, should_setError_when_adjustBalanceFails, should_trackMutatingId_when_adjustBalanceInProgress in flutter/test/src/features/accounts/application/account_notifier_test.dart
- [X] T022 [P] Create account_list_screen_test.dart: should_showSkeleton_when_loading, should_showError_when_loadFails, should_showEmptyState_when_noAccounts, should_showAccountList_when_dataLoaded, should_navigateToForm_when_fabTapped, should_navigateToEdit_when_accountTapped (use ProviderScope + overrides with mock AccountNotifier) in flutter/test/src/features/accounts/presentation/screens/account_list_screen_test.dart
- [X] T023 [P] Create account_form_screen_test.dart: should_showCreateMode_when_noAccount, should_showEditMode_when_accountProvided, should_prefillDefaults_when_typeSelected, should_showValidationError_when_nameEmpty, should_callCreate_when_submitInCreateMode, should_callUpdate_when_submitInEditMode in flutter/test/src/features/accounts/presentation/screens/account_form_screen_test.dart
- [X] T024 [P] Create color_palette_picker_test.dart: should_showAllColors_when_rendered, should_highlightSelected_when_colorChosen, should_callOnChanged_when_colorTapped in flutter/test/src/features/accounts/presentation/widgets/color_palette_picker_test.dart
- [X] T025 [P] Create account_type_selector_test.dart: should_showThreeTypes_when_rendered, should_highlightSelected_when_typeTapped, should_beDisabled_when_disabledTrue in flutter/test/src/features/accounts/presentation/widgets/account_type_selector_test.dart
- [X] T026 [P] Create account_list_tile_test.dart: should_showAccountInfo_when_rendered, should_showDefaultBadge_when_isDefault, should_showInactiveBadge_when_inactive, should_applyReducedOpacity_when_inactive, should_showPopupMenu_when_menuTapped, should_hideSetDefaultOption_when_alreadyDefault in flutter/test/src/features/accounts/presentation/widgets/account_list_tile_test.dart

---

## Phase 9: Polish & Cross-Cutting

**Purpose**: Vérification finale, analyse statique, cohérence

- [X] T027 Run `flutter analyze` from flutter/ directory and fix any warnings or errors
- [X] T028 Run `flutter test` from flutter/ directory and ensure all tests pass (existing + new)
- [X] T029 Verify end-to-end flow: Settings > Comptes > Create > Edit > Adjust Balance > Set Default > Delete (inclut validation qualitative SC-001 création < 30s et SC-003 liste < 2s)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T004 for DTO — BLOCKS US4 (balance adjustment)
- **US1 (Phase 3)**: Depends on Phase 1 (routes, i18n) — No dependency on Phase 2
- **US2 (Phase 4)**: Depends on US1 (list screen must exist for navigation)
- **US3 (Phase 5)**: Depends on US2 (form screen must exist)
- **US4 (Phase 6)**: Depends on US3 (edit mode) + Phase 2 (adjustBalance pipeline)
- **US5+US6 (Phase 7)**: Depends on US1 (list tile must exist)
- **Tests (Phase 8)**: Depends on all story phases being complete
- **Polish (Phase 9)**: Depends on Tests

### User Story Dependencies

```
Phase 1 (Setup) ──────┬──────────────────────────────────────────┐
                       │                                          │
Phase 2 (Foundation) ──┤                                          │
                       │                                          │
                       ├──► US1 (List) ──┬──► US2 (Create) ──► US3 (Edit) ──► US4 (Adjust)
                       │                 │
                       │                 └──► US5+US6 (Delete + Default)
                       │
                       └──► (Phase 2 blocks US4 only)
```

### Within Each User Story

- Widgets ([P]) before screens
- Screen creation before screen extension
- Core functionality before edge case handling

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- T009 and T010 can run in parallel (different widget files)
- T012, T013, T014 can run in parallel (different widget files)
- T021–T026 can ALL run in parallel (different test files)
- US5+US6 (Phase 7) can run in parallel with US3/US4 (Phase 5/6) if US1 is complete

---

## Parallel Example: User Story 2

```bash
# Launch all widgets for US2 together (3 parallel tasks):
Task T012: "Create ColorPalettePicker in .../widgets/color_palette_picker.dart"
Task T013: "Create AccountTypeSelector in .../widgets/account_type_selector.dart"
Task T014: "Create AccountPreviewCard in .../widgets/account_preview_card.dart"

# Then sequentially:
Task T015: "Create AccountFormScreen (depends on T012, T013, T014)"
```

---

## Implementation Strategy

### MVP First (US1 + US2 = Phase 1–4)

1. Phase 1: Setup (i18n + routes)
2. Phase 2: Foundational (adjustBalance pipeline)
3. Phase 3: US1 — Account list screen
4. Phase 4: US2 — Account form (create mode)
5. **STOP and VALIDATE**: Naviguer vers Settings > Comptes, créer un compte, vérifier la liste

### Incremental Delivery

1. Setup + Foundation → Infrastructure prête
2. US1 → Liste des comptes visible (MVP lecture)
3. US2 → Création fonctionnelle (MVP écriture)
4. US3 → Édition fonctionnelle
5. US4 → Ajustement de solde
6. US5 + US6 → Suppression + défaut par défaut
7. Tests + Polish → Qualité

---

## Notes

- Mode serveur uniquement : pas de Drift/SQLite pour cette feature
- Le modèle Account et le AccountNotifier existent déjà — seule extension nécessaire : adjustBalance
- Le formulaire est full-screen (Scaffold + AppBar) et non modal (conformément au pattern settings)
- Les 12 couleurs de la palette sont identiques à l'implémentation Angular
- Commit recommandé après chaque checkpoint de phase
