# Tasks: Formulaire Abonnement (Flutter)

**Input**: Design documents from `/specs/045-flutter-subscription-form/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Organization**: Tasks groupées par user story. US4 (toggle fréquence, P2) est fusionnée avec US1 car le toggle est intrinsèque au formulaire de création.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ajouter les clés i18n nécessaires à toutes les user stories

- [X] T001 Add subscription form i18n keys to `flutter/lib/src/localization/app_fr.arb` — keys: subscriptionFormNameField, subscriptionFormAmountField, subscriptionFormDateField, subscriptionFormAccountPicker, subscriptionFormCategoryPicker, subscriptionFormActiveSwitch, subscriptionFormSaveButton, subscriptionFormUpdateButton, subscriptionFormDeleteButton, subscriptionFormDeleteConfirmTitle, subscriptionFormDeleteConfirmMessage, subscriptionFormNoAccounts, subscriptionFormNoCategories

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Créer le squelette du formulaire et son intégration dans le système modal

**Warning**: No user story work can begin until this phase is complete

- [X] T002 Create SubscriptionForm widget skeleton in `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` — ConsumerStatefulWidget with constructor params (subscription?, frequence, onSaved, onDeleted?, onCancelled), TextEditingControllers for nom and montant in initState/dispose, state variables (_selectedDate, _selectedAccountId, _selectedCategoryId, _isActif, _showErrors, _isSubmitting, _initialized), empty build() returning placeholder Column
- [X] T003 Add `else if (state.type == ModalType.subscription)` branch in `_buildModalChild()` within `flutter/lib/src/routing/app_router.dart` — create `_SubscriptionFormConsumer` (ConsumerWidget following `_TransactionFormConsumer` pattern L293-332: watch modalNotifierProvider for subType, wire onSaved → subscriptionNotifier.create/update, onDeleted → subscriptionNotifier.delete, onCancelled → pop()), return it from `_buildModalChild()`. Toggle header is already handled by `_ModalToggle` (generic for all types with hasToggle)

**Checkpoint**: Foundation ready — widget skeleton exists, modal integration routes subscription forms correctly

---

## Phase 3: User Story 1 + User Story 4 — Créer un abonnement avec toggle fréquence (Priority: P1) MVP

**Goal**: L'utilisateur peut créer un abonnement via le formulaire modal avec toggle Mensuel/Annuel en header

**Independent Test**: Ouvrir le formulaire via FAB, remplir nom + montant + date, sélectionner fréquence via toggle, sauvegarder et vérifier l'apparition dans la liste

### Implementation

- [X] T004 [US1] Implement form body layout in `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` — Row(AppFormField nom Expanded + AppFormField montant w/ keyboardType number), AppFormField date with GestureDetector + showDatePicker (default: DateTime.now()), SelectPicker for account (filter actif only + inclure le compte actuellement associé même s'il est inactif en mode édition, show icon+name+solde), CategoryPicker for category, Row with label + Switch for actif (default: true), Row with action buttons (Cancel outlined + Save filled). Empty state messages: subscriptionFormNoAccounts si aucun compte, subscriptionFormNoCategories si aucune catégorie
- [X] T005 [US1] Implement field validation in `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` — _validateNom() returns error if empty or > 255 chars, _validateMontant() returns error if empty/non-numeric/<=0, _isValid() checks all validators, _showErrors flag set to true on first submit attempt then real-time revalidation (after _showErrors = true, each TextEditingController change triggers setState() so validators re-evaluate immediately), error messages via AppLocalizations (validationRequired, validationAmountPositive, validationMaxLength)
- [X] T006 [US1] Implement save logic in `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` — _onSubmit(): validate → set _isSubmitting → build Subscription(id: widget.subscription?.id ?? 'pending-${DateTime.now().millisecondsSinceEpoch}', nom, montant, frequence from widget.frequence, dateDebut, currency from account or EUR, actif, categoryId, accountId) → call widget.onSaved(subscription) → catch Exception: reset _isSubmitting, show SnackBar with errorGeneric
- [X] T007 [P] [US1] Implement subscription list screen in `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` — convert to ConsumerStatefulWidget (like TransactionListScreen), call ref.watch(subscriptionNotifierProvider), call loadItems() in initState, display subscription items with ListItem widget (nom, montant formaté, fréquence badge, actif indicator), skeleton loading with shimmer while isLoading. Pattern: suivre transaction_list_screen.dart

**Checkpoint**: US1 complete — user can create subscriptions with all fields, validation feedback, and frequency toggle. MVP functional.

---

## Phase 4: User Story 2 — Modifier un abonnement existant (Priority: P2)

**Goal**: L'utilisateur peut ouvrir un abonnement existant en édition, voir ses données pré-remplies, modifier et sauvegarder

**Independent Test**: Créer un abonnement, le taper dans la liste, vérifier le pré-remplissage, modifier le montant, sauvegarder et vérifier la mise à jour

### Implementation

- [X] T008 [US2] Implement edit mode pre-fill in `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` — _initFromEntity() method called in build() with _initialized guard: populate _nomController.text, _montantController.text, _selectedDate, _selectedAccountId, _selectedCategoryId, _isActif from widget.subscription, set _initialized = true. Adjust _onSubmit to reuse existing subscription.id when in edit mode (widget.subscription != null)
- [X] T009 [US2] Add item tap to open edit modal in `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` — on subscription item tap, call ref.read(modalNotifierProvider.notifier).open(ModalType.subscription, entity: subscription) to open form pre-filled

**Checkpoint**: US2 complete — user can edit existing subscriptions with all fields pre-filled

---

## Phase 5: User Story 3 — Supprimer un abonnement (Priority: P3)

**Goal**: L'utilisateur peut supprimer un abonnement depuis le formulaire d'édition avec confirmation

**Independent Test**: Ouvrir un abonnement en édition, appuyer sur Supprimer, confirmer, vérifier la disparition de la liste

### Implementation

- [X] T010 [US3] Implement delete with confirmation in `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` — add Delete button (left-aligned, visible only when widget.subscription != null), on tap: show AlertDialog with subscriptionFormDeleteConfirmTitle/Message, on confirm: call widget.onDeleted!(subscription.id), on cancel: dismiss dialog and keep form open

**Checkpoint**: US3 complete — full CRUD operational (create, read via list, update, delete)

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Tests, analyse statique, validation finale

- [X] T011 Write widget tests in `flutter/test/src/features/subscriptions/presentation/widgets/subscription_form_test.dart` — test cases: should_render_all_fields_when_opened_in_creation_mode, should_show_validation_errors_when_submitting_empty_form, should_call_onSaved_with_valid_subscription_when_form_filled, should_prefill_fields_when_opened_in_edit_mode, should_show_delete_confirmation_when_delete_tapped, should_not_show_delete_button_in_creation_mode, should_default_frequency_to_mensuel_when_opened_in_creation_mode, should_pass_selected_frequency_to_subscription_when_saved. Use ProviderContainer with overrides for accountNotifier and categoryNotifier mocks
- [X] T012 Run `flutter analyze` in `flutter/` and fix any reported issues, then run `flutter test test/src/features/subscriptions/` to verify all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — T001 starts immediately
- **Foundational (Phase 2)**: T002 depends on T001 (i18n keys used in form). T003 depends on T002 (router references form widget)
- **US1+US4 (Phase 3)**: Depends on Phase 2 completion. T004/T005/T006 work on same file sequentially. T007 is independent (different file, list screen)
- **US2 (Phase 4)**: Depends on Phase 3 (form must exist with creation mode, list must display items). T008 and T009 are on different files but T009 logically follows T008
- **US3 (Phase 5)**: Depends on Phase 4 (edit mode must exist for delete button). T010 is a single task
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **US1 + US4 (P1)**: Can start after Phase 2 — No dependencies on other stories
- **US2 (P2)**: Depends on US1 (form widget must exist with base layout) + T007 (list must display items for tap-to-edit)
- **US3 (P3)**: Depends on US2 (edit mode must be implemented for delete button to appear)

### Parallel Opportunities

- T004, T005, T006 are sequential (same file) but T007 can run in parallel with them (different file)
- T011 and T012 can run in parallel (test file vs analyze command)

---

## Parallel Example: Phase 3

```bash
# T007 can run alongside T004-T006:
Task: "Implement form body layout in subscription_form.dart"        # sequential
Task: "Implement subscription list screen in subscription_list_screen.dart"  # parallel (different file)
```

---

## Implementation Strategy

### MVP First (US1 + US4 Only)

1. Complete Phase 1: Setup (i18n keys)
2. Complete Phase 2: Foundational (form skeleton + router integration)
3. Complete Phase 3: US1 + US4 (form layout, validation, save, FAB, toggle)
4. **STOP and VALIDATE**: Create a subscription via the modal, verify it appears in list
5. Commit and demo

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready
2. Phase 3 (US1 + US4) → Test creation + toggle → Commit (MVP!)
3. Phase 4 (US2) → Test edit pre-fill → Commit
4. Phase 5 (US3) → Test delete with confirmation → Commit
5. Phase 6 → Tests + analyze → Final commit

---

## Notes

- **Pattern de référence** : `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — suivre exactement la même structure
- **Widgets réutilisés** : AppFormField, SelectPicker, CategoryPicker, AppToggle, AppModal — aucun widget custom à créer
- **Backend** : API CRUD complète existante, aucune modification côté API
- **Modèle** : Subscription (Freezed) existant, aucune modification du modèle
- **Notifier** : SubscriptionNotifier existant avec create/update/delete, aucune modification
- Commit après chaque checkpoint de phase
- US4 (toggle fréquence) fusionnée avec US1 car le toggle est intégré au header modal et nécessaire dès la création
