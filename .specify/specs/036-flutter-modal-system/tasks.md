# Tasks: Flutter — Système Modal / Bottom Sheet

**Input**: Design documents from `/specs/036-flutter-modal-system/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Créer la structure de fichiers et les dépendances pour la feature modale

- [X] T001 Create feature directory structure `flutter/lib/src/features/modal/application/` and test directories `flutter/test/features/modal/application/`, `flutter/test/common_widgets/`

---

## Phase 2: Foundational (State Management)

**Purpose**: Implémenter le modèle de données et l'état centralisé de la modale. Couvre les acceptances de US4 (état global, unicité, fermeture reflétée). DOIT être terminé avant toute implémentation de user story.

- [X] T002 [P] Create ModalType enum (transaction, subscription, debt, transfer, category, account) and ModalMode enum (create, edit) with title maps (create/edit titles) and default subType map in `flutter/lib/src/domain/enums/modal_type.dart`
- [X] T003 [P] Create ModalState freezed sealed class (ModalClosed, ModalOpen with type/mode/entity/subType) in `flutter/lib/src/features/modal/application/modal_state.dart`
- [X] T004 Run `dart run build_runner build --delete-conflicting-outputs` from `flutter/` to generate freezed code for ModalState
- [X] T005 Create ModalNotifier (Riverpod Notifier<ModalState>) with open(type), close(), setSubType(value) methods in `flutter/lib/src/features/modal/application/modal_notifier.dart`. Open (create-only pour cette phase): set mode=create, initialize subType from ModalType default map, guarantee single modal (close before open if already open). Close must: reset to ModalClosed. Note: le support edit mode (entity parameter) sera ajouté dans T015 (US3).
- [X] T006 Update enums barrel export to include modal_type.dart in `flutter/lib/src/domain/enums/enums.dart`
- [X] T007 Write ModalNotifier unit tests (create mode + state management) in `flutter/test/features/modal/application/modal_notifier_test.dart`: should_beModalClosed_when_created, should_openTransaction_when_openCalledWithTransaction, should_defaultToDepense_when_openTransactionInCreateMode, should_defaultToMensuel_when_openSubscriptionInCreateMode, should_defaultToEmprunt_when_openDebtInCreateMode, should_haveNullSubType_when_openTransfer, should_closePrevious_when_openCalledWhileAlreadyOpen, should_beModalClosed_when_closeCalled, should_updateSubType_when_setSubTypeCalled

**Checkpoint**: ModalNotifier fonctionne — ouverture, fermeture, setSubType, unicité. US4 validé.

---

## Phase 3: User Story 1 — Ouvrir une modale de création depuis le FAB (Priority: P1)

**Goal**: L'utilisateur appuie sur le FAB, sélectionne un type, et une modale s'ouvre en bottom sheet (mobile) ou dialog (tablette) avec le titre correct et un bouton de fermeture.

**Independent Test**: Appuyer sur FAB → sélectionner "Transaction" → vérifier bottom sheet ouvert avec titre "Nouvelle transaction" et bouton ×.

### Implementation

- [X] T008 [US1] Create AppModal widget in `flutter/lib/src/common_widgets/app_modal.dart`. Static method `show(BuildContext, {required Widget child, required String title, Widget? headerActions, required VoidCallback onClose})` qui affiche `showModalBottomSheet` si largeur < 768px, `showDialog` sinon. Bottom sheet: max 90% hauteur, `isScrollControlled: true`, scroll interne via SingleChildScrollView, `padding: MediaQuery.of(context).viewInsets` pour repositionnement clavier (FR-012), handle drag, border radius top. Dialog: centré, overlay sombre, max width 480px, border radius. Header commun: titre (h2), bouton × (fermeture), slot headerActions. Animation: slide-up bottom sheet, fade+scale dialog. Note: FR-011 (survie rotation/arrière-plan) et FR-012 (repositionnement clavier) sont gérés nativement par `showModalBottomSheet`/`showDialog` — aucun code custom nécessaire.
- [X] T009 [US1] Modify FabMenu to open modal via ModalNotifier in `flutter/lib/src/common_widgets/fab_menu.dart`. Replace SnackBar placeholders with `ref.read(modalNotifierProvider.notifier).open(ModalType.transaction)` etc. for each speed dial item. Convert to ConsumerWidget if needed.
- [X] T010 [US1] Integrate modal display in shell by modifying `_ShellScaffold` in `flutter/lib/src/routing/app_router.dart`. Convert to ConsumerStatefulWidget. Use `ref.listen(modalNotifierProvider, ...)` to react to state changes: when ModalOpen → call `AppModal.show(...)` with title from ModalType, when modal dismissed → call notifier.close(). Pass child slot as placeholder body (empty Container or Text "Formulaire à venir").
- [X] T011 [US1] Write AppModal widget tests in `flutter/test/common_widgets/app_modal_test.dart`: should_showBottomSheet_when_screenWidthBelow768, should_showDialog_when_screenWidthAbove768, should_displayTitle_when_modalOpened, should_closeModal_when_closeButtonTapped, should_closeModal_when_swipeDown (bottom sheet), should_closeModal_when_overlayTapped (dialog)

**Checkpoint**: FAB → type → modale ouverte avec titre et fermeture fonctionnelle. US1 validé.

---

## Phase 4: User Story 2 — Toggle type dans le header (Priority: P1)

**Goal**: Un toggle 2 options apparaît dans le header pour transaction (Dépense/Recette), abonnement (Mensuel/Annuel), dette (Emprunt/Prêt). Pas de toggle pour virement/catégorie/compte.

**Independent Test**: Ouvrir modale "Transaction" → toggle visible avec "Dépense" actif → appuyer "Recette" → bascule visuellement.

### Implementation

- [X] T012 [US2] Create AppToggle widget in `flutter/lib/src/common_widgets/app_toggle.dart`. Props: `labels` (List<String>, exactement 2), `selectedIndex` (int), `onChanged` (ValueChanged<int>). Design: conteneur arrondi (AppRadius.xl), fond surfaceContainerHighest, bouton actif avec fond primary (amber) et texte onPrimary, bouton inactif avec texte onSurfaceVariant. Animation: AppDurations.fast, easeInOut. Hauteur compacte (36px). Utilise les design tokens existants.
- [X] T013 [US2] Add toggle slot in AppModal header in `flutter/lib/src/common_widgets/app_modal.dart`: when `headerActions` widget is provided, render it below the title row inside the modal header
- [X] T013b [US2] Wire AppToggle into shell modal listener in `flutter/lib/src/routing/app_router.dart`: when ModalOpen.type has toggle (transaction/subscription/debt), pass AppToggle as `headerActions` to `AppModal.show()` with correct labels and selectedIndex from ModalOpen.subType. Map toggle onChanged to `modalNotifier.setSubType(...)`. When ModalOpen.type has no toggle: pass null headerActions
- [X] T014 [US2] Write AppToggle widget tests in `flutter/test/common_widgets/app_toggle_test.dart`: should_displayTwoLabels_when_rendered, should_highlightFirstOption_when_selectedIndexIs0, should_callOnChanged_when_secondOptionTapped, should_switchVisualState_when_selectionChanges

**Checkpoint**: Toggle fonctionne pour les 3 types avec toggle, absent pour les 3 autres. US2 validé.

---

## Phase 5: User Story 3 — Mode édition (Priority: P2)

**Goal**: L'utilisateur tape sur un élément existant dans une liste, la modale s'ouvre en mode édition avec titre "Modifier..." et toggle positionné sur le sous-type de l'entité.

**Independent Test**: Tap sur une transaction "Recette" → modale avec titre "Modifier la transaction" et toggle sur "Recette".

### Implementation

- [X] T015 [US3] Add edit mode support to ModalNotifier.open() in `flutter/lib/src/features/modal/application/modal_notifier.dart`. Add optional `entity` parameter. When entity is provided: set mode=edit, extract subType from entity (Transaction.type for transaction, Subscription.frequence for subscription, Debt.sens for debt). When entity is null: keep existing create behavior.
- [X] T016 [US3] Verify shell modal listener already handles edit titles correctly in `flutter/lib/src/routing/app_router.dart`. The title is derived from ModalType title maps (already set in T002) + ModalMode (set by notifier). If needed, ensure toggle selectedIndex reflects ModalOpen.subType in edit mode.
- [X] T017 [US3] Add edit mode tests (new group) to `flutter/test/features/modal/application/modal_notifier_test.dart`: should_setModeEdit_when_entityProvided, should_setModeCreate_when_entityNull, should_extractRecette_when_editTransactionRecette, should_extractAnnuel_when_editSubscriptionAnnuel, should_extractPret_when_editDebtPret, should_useEditTitle_when_modeIsEdit

**Checkpoint**: Mode édition fonctionne — titre adapté, toggle positionné. US3 validé.

---

## Phase 6: User Story 5 — Accessibilité (Priority: P3)

**Goal**: La modale est utilisable avec les technologies d'assistance. Focus piégé, éléments labellisés pour lecteurs d'écran.

**Independent Test**: Activer TalkBack/VoiceOver → ouvrir modale → titre annoncé, focus piégé, toggle décrit correctement.

### Implementation

- [X] T018 [P] [US5] Add Semantics to AppModal in `flutter/lib/src/common_widgets/app_modal.dart`: Semantics(label: title, scopesRoute: true, namesRoute: true) on modal container, Semantics(button: true, label: 'Fermer') on close button, ExcludeSemantics on overlay when appropriate
- [X] T019 [P] [US5] Add Semantics to AppToggle in `flutter/lib/src/common_widgets/app_toggle.dart`: Semantics(toggled: isSelected, label: label) on each option, MergeSemantics wrapper with label describing the group

**Checkpoint**: Lecteur d'écran annonce titre, toggle, bouton fermeture. US5 validé.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Nettoyage, validation finale, edge cases

- [X] T020 Verify edge cases manually via quickstart.md scenarios in `specs/036-flutter-modal-system/quickstart.md`: rotation d'écran avec modale ouverte (FR-011 — natif Flutter, vérifier que l'état est préservé), bouton retour Android (natif showModalBottomSheet/showDialog), petit écran SE/mini (max 90% hauteur via isScrollControlled + constraints), clavier virtuel repositionnement (FR-012 — natif via MediaQuery.viewInsets)
- [X] T021 Run `flutter analyze` from `flutter/` and fix any warnings or errors
- [X] T022 Run full test suite `flutter test` from `flutter/` and verify all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 (ModalNotifier must exist)
- **US2 (Phase 4)**: Depends on Phase 3 (AppModal must exist for toggle integration)
- **US3 (Phase 5)**: Depends on Phase 3 (modal must open for edit mode)
- **US5 (Phase 6)**: Depends on Phase 3 + Phase 4 (widgets must exist for semantics)
- **Polish (Phase 7)**: Depends on all previous phases

### Within-Phase Parallel Opportunities

- Phase 2: T002 ∥ T003 (enum and state are independent files)
- Phase 4: T012 can start while T010 (shell integration) finalizes
- Phase 6: T018 ∥ T019 (different files, independent semantics)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Parallel: enum + state class (different files)
Task: "Create ModalType/ModalMode enums in flutter/lib/src/domain/enums/modal_type.dart"
Task: "Create ModalState freezed class in flutter/lib/src/features/modal/application/modal_state.dart"

# Sequential: build_runner after both files exist
Task: "Run build_runner to generate freezed code"

# Sequential: notifier depends on state + enum
Task: "Create ModalNotifier in flutter/lib/src/features/modal/application/modal_notifier.dart"
```

---

## Implementation Strategy

### MVP First (US1 + US2 — Phase 1→4)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (state management)
3. Complete Phase 3: US1 (modale ouverte depuis FAB)
4. Complete Phase 4: US2 (toggle fonctionnel)
5. **STOP and VALIDATE**: Tester création transaction/abonnement/dette avec toggle

### Incremental Delivery

1. Setup + Foundational → State management prêt
2. US1 → Modale ouvrable et fermable → **MVP livrable**
3. US2 → Toggle type → **Feature P1 complète**
4. US3 → Mode édition → **Feature P2 complète**
5. US5 → Accessibilité → **Feature P3 complète**
6. Polish → Tests finaux, edge cases → **Feature complète**

---

## Notes

- Pas de modification backend — feature Flutter uniquement
- Les formulaires (contenu de la modale) sont hors scope — le body est un slot (Widget child)
- Les enums existants (TransactionType, Frequency, DebtType) sont réutilisés, pas dupliqués
- Le seuil 768px est cohérent avec AdaptiveScaffold._breakpoint existant
- `showModalBottomSheet` et `showDialog` gèrent nativement : bouton retour Android, survie rotation (FR-011), repositionnement clavier (FR-012)
- Convention terminologie : enums en anglais (`ModalType.transaction`, `ModalType.transfer`), labels UI en français ("Nouvelle transaction", "Virement"). Aligné avec les enums existants (`TransactionType.depense`, `Frequency.mensuel`)
- Commit recommandé après chaque phase
