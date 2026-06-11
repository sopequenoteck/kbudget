# Tasks — KKS-241 : Refonte 3 formulaires XL Flutter (bottom sheet 4-rows)

**Issue** : KKS-241 | **Date** : 2026-05-11
**Input** : [spec.md](./spec.md) · [plan.md](./plan.md) · [research.md](./research.md) · [data-model.md](./data-model.md)

**Format** : `- [ ] [T-XXX] [P] [USX] Description — Réf: FR-XXX`
- `[P]` = parallélisable (fichiers différents, sans dépendance)
- `[USX]` = User Story couverte

---

## Phase 1 — Setup

**Objectif** : Vérifier les prérequis avant toute modification.

- [x] T-001 Vérifier la présence et la stabilité des widgets KKS-238 + KKS-239 : `common_widgets/bottom_sheet_4_rows_widget.dart`, `common_widgets/inline_date_picker.dart`, `common_widgets/category_select_expand.dart` — Réf: A-001, A-002
- [x] T-002 [P] Vérifier que `subscription_form_test.dart` passe à 100% avant modification : `flutter test test/src/features/subscriptions/presentation/widgets/subscription_form_test.dart`

**Checkpoint** : Les dépendances sont présentes et les tests actuels passent → démarrer Phase 2.

---

## Phase 2 — Fondations (bloquant)

**Objectif** : Infrastructure récurrence + routing + composant partagé. Bloquant pour toutes les US.

**⚠️ CRITIQUE** : Aucune migration de formulaire ne peut commencer avant la complétion de cette phase.

### Infrastructure récurrence (RES-001)

- [x] T-010 Créer `flutter/lib/src/data/remote/dtos/recurring_transaction_create_request.dart` — Freezed `RecurringTransactionCreateRequest` : champs `montant`, `libelle`, `type`, `frequency`, `nextOccurrence`, `categoryId?`, `accountId?`, `note?` — Réf: FR-012, FR-013 · C-01
- [x] T-011 [P] Ajouter signature `Future<RecurringTransaction> create(RecurringTransactionCreateRequest req)` à l'interface `flutter/lib/src/domain/repositories/recurring_transaction_repository.dart` — Réf: FR-012 · M-01
- [x] T-012 [P] Ajouter méthode `create()` à `flutter/lib/src/data/remote/data_sources/recurring_transaction_remote_data_source.dart` : `POST /transactions/recurring` + `RecurringTransactionResponse.fromJson(response.data)` — Réf: FR-013 · M-02
- [x] T-013 Implémenter `create()` dans `flutter/lib/src/features/recurring/data/recurring_transaction_repository_remote.dart` : appel data source + `toDomain()` — dépend T-011, T-012 · M-03
- [x] T-014 Ajouter `Future<void> create(RecurringTransactionCreateRequest req)` à `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart` : pattern `isLoading` + try/catch + `_refreshList()` identique à `deactivate()` — dépend T-013 · M-04
- [x] T-015 [P] Relancer `dart run build_runner build --delete-conflicting-outputs` depuis `flutter/` + vérifier génération des fichiers `.freezed.dart` et `.g.dart` + `flutter analyze` — dépend T-010

### Routing + composant partagé (RES-004, RES-006)

- [x] T-016 [P] Créer `flutter/lib/src/common_widgets/bsheet_type_toggle.dart` — `StatelessWidget BSheetTypeToggle` avec `labels: List<String>`, `selectedIndex: int`, `onChanged: ValueChanged<int>`. Style : actif = `colorScheme.primary` fond + `colorScheme.onPrimary` texte ; inactif = bordure `colorScheme.outline` + `colorScheme.onSurfaceVariant`. Police `AppTypography.sizeSm`, padding `vertical: 4, horizontal: AppSpacing.space3` — Réf: FR-007 · C-02
- [x] T-017 Modifier `flutter/lib/src/routing/app_router.dart` : (a) ajouter `_showFormBottomSheet(BuildContext ctx, Widget child)` avec `isScrollControlled: true`, `useSafeArea: true`, `Padding(bottom: MediaQuery.viewInsetsOf(ctx).bottom)` ; (b) mettre à jour `_showModal()` pour `ModalType.transaction` / `ModalType.subscription` / `ModalType.debt` → appeler `_showFormBottomSheet` au lieu de `AppModal.show` ; (c) supprimer `headerActions` / `_ModalToggle` pour ces 3 types — dépend T-016 · M-05 — Réf: FR-012, CL-001

**Checkpoint** : `flutter analyze` passe, `build_runner` généré, `app_router.dart` compilé → démarrer Phase 3 (US1).

---

## Phase 3 — US1 : Migration TransactionForm (Priorité P1) 🎯 MVP

**Objectif** : Migrer `TransactionForm` vers `BottomSheet4RowsWidget` avec récurrence.

**Test indépendant** : Ouvrir TransactionForm via FAB (+) → saisir montant + libellé → valider. Pas de double header. Catégorie et date en expand inline.

- [x] T-020 [US1] `flutter/lib/src/features/transactions/presentation/widgets/transaction_form.dart` — Remplacer le contenu par le squelette `BottomSheet4RowsWidget`. Ajouter état `String? _expandedSection` + helper `_toggleSection(String key)`. Configurer Row 1 : `BSheetTypeToggle(labels: ['Dépense', 'Recette'])` dans `topTrailing`, titre depuis `modalNotifierProvider`. Configurer Row 2 : `amountField` = TextField montant hero ; `libelleField` = `LibelleAutocompleteField` (conserver controller + listener `_onLibelleChanged`) — Réf: FR-001, FR-007, FR-009 · M-06
- [x] T-021 [US1] TransactionForm — Row 3 `metaPills` (date + catégorie + compte) et `expandedContent` : switch sur `_expandedSection` → `InlineDatePicker` / `CategorySelectExpand` (avec `onCreatingChanged` → `_isCreatingCategory` → `footerEnabled`) / `SelectPicker` accounts. Ajouter `iconButtons` : `phosphorNoteBlank` (note). Gestion `FocusScope.unfocus()` avant ouverture expand — dépend T-020 · M-06 — Réf: FR-002, FR-003, FR-004, FR-006
- [x] T-022 [US1] TransactionForm — expand note : `iconButtons` `phosphorNoteBlank` → expand textarea (`_noteController`) + `notePreview` si `_noteController.text.isNotEmpty`. `PopScope` : `canPop = _expandedSection == null` ; `onPopInvokedWithResult` ferme l'expand avant le bottom sheet — dépend T-021 · M-06 — Réf: FR-008
- [x] T-023 [US1] TransactionForm — expand récurrence (mode création uniquement) : `iconButtons` `phosphorRepeat` visible si `!_isEditMode`. Expand : `Switch` "Transaction récurrente" → si activé : `BSheetTypeToggle(labels: ['Hebdo', 'Mensuel', 'Annuel'])` + `InlineDatePicker` prochaine occurrence. Désactiver l'icône si `dataModeProvider = DataMode.local` (RES-004, R-004) — dépend T-022 · M-06 — Réf: FR-013
- [x] T-024 [US1] TransactionForm — `footerLeading` mode édition : pill "Supprimer" (danger) → `showDeleteConfirmDialog` → `widget.onDeleted`. Soumission : validation montant + libellé ; si `_isRecurring`, appeler `ref.read(recurringListNotifierProvider.notifier).create(req)` après `widget.onSaved` ; SnackBar erreur spécifique si `create()` échoue (transaction déjà créée, récurrence non critique) — dépend T-023 · M-06 — Réf: FR-005, FR-013
- [x] T-025 [US1] Créer `flutter/test/src/features/transactions/presentation/widgets/transaction_form_test.dart` — 6 cas : `should_display_amount_and_libelle_fields_when_form_opens`, `should_submit_when_amount_and_libelle_valid`, `should_show_error_when_libelle_empty`, `should_show_error_when_amount_negative_or_zero`, `should_show_delete_pill_when_edit_mode`, `should_hide_recurring_icon_when_edit_mode` — Réf: FR-011, SC-004 · C-03

**Checkpoint** : `flutter test test/src/features/transactions/` PASS. Tester manuellement : FAB → TransactionForm → saisie → valider. SC-001, SC-002, SC-003, SC-008 vérifiés.

---

## Phase 4 — US2 : Migration SubscriptionForm (Priorité P2)

**Objectif** : Migrer `SubscriptionForm` vers `BottomSheet4RowsWidget` avec toggle 3-boutons et pill devise.

**Test indépendant** : Ouvrir SubscriptionForm → toggle Hebdo/Mensuel/Annuel en Row 1 → saisir nom + montant → catégorie et date en expand inline → valider.

- [x] T-030 [US2] `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_form.dart` — Remplacer par squelette `BottomSheet4RowsWidget`. Ajouter `String? _expandedSection`, `Frequency _selectedFrequency`, `Currency? _forcedCurrency`. Row 1 : `BSheetTypeToggle(labels: ['Hebdo', 'Mensuel', 'Annuel'])` dans `topTrailing`. Row 2 : montant hero + nom (controller `_nomController`) — Réf: FR-001, FR-007 · M-07
- [x] T-031 [US2] SubscriptionForm — Row 3 `metaPills` : date de début + catégorie + compte + pill devise (visible si `_selectedAccountId == null`). `expandedContent` : `InlineDatePicker` / `CategorySelectExpand` / `SelectPicker` accounts / `SelectPicker` devise (`Currency.values.map((c) => SelectPickerItem(id: c.name, label: '${c.displayName} (${c.symbol})'))`). Quand compte sélectionné : `_forcedCurrency = null` — dépend T-030 · M-07 — Réf: FR-002, FR-003, FR-004, FR-006, FR-016
- [x] T-032 [US2] SubscriptionForm — `iconButtons` : `phosphorToggleRight/Left` visible en mode édition uniquement → bascule `_isActif`. `footerLeading` mode édition : pill "Supprimer" → `showDeleteConfirmDialog` → `widget.onDeleted` — dépend T-031 · M-07 — Réf: FR-005, FR-010
- [x] T-033 [US2] Adapter `flutter/test/src/features/subscriptions/presentation/widgets/subscription_form_test.dart` : remplacer `find.byType(AppFormField)` → `find.byType(BottomSheet4RowsWidget)`, `find.byType(FilledButton)` → `find.byKey(Key('bsheet_submit'))`. Ajouter : `should_disable_footer_when_creating_category` — Réf: FR-011, SC-004 · M-09

**Checkpoint** : `flutter test test/src/features/subscriptions/` PASS. SC-002, SC-003, SC-005, SC-006 vérifiés sur SubscriptionForm.

---

## Phase 5 — US3 : Migration DebtForm (Priorité P3)

**Objectif** : Migrer `DebtForm` avec pill "Échéance" toujours visible, reminder Bell, et footerLeading dual.

**Test indépendant** : Ouvrir DebtForm → toggle Emprunt/Prêt → saisir montant + personne → pill Échéance visible (grisée si vide) → valider.

- [x] T-040 [US3] `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart` — Remplacer par squelette `BottomSheet4RowsWidget`. Row 1 : `BSheetTypeToggle(labels: ['Emprunt', 'Prêt'])` dans `topTrailing` ; couleur montant hero dynamique (vert prêt / rouge emprunt via `colorScheme.secondary` / `colorScheme.error`). Row 2 : montant hero + personne (controller `_personneController`). Supprimer `_includeInBalance` de l'état UI (champ calculé silencieusement) — Réf: FR-001, FR-007, FR-017 · M-08
- [x] T-041 [US3] DebtForm — Row 3 `metaPills` : date + catégorie + compte + échéance (toujours présente — grisée si `_dueDate == null`, date formatée sinon, avec × pour effacer) + devise (visible si `_selectedAccountId == null`). `expandedContent` switch : `InlineDatePicker` date / `CategorySelectExpand` / `SelectPicker` accounts / `InlineDatePicker` dueDate / `SelectPicker` devise — dépend T-040 · M-08 — Réf: FR-002, FR-003, FR-004, FR-006, FR-014, FR-016
- [x] T-042 [US3] DebtForm — `iconButtons` `phosphorBell` → expand reminder : `InlineDatePicker` date + bouton "Choisir l'heure" → `showTimePicker()` Material déclenché après sélection date. `PopScope` : fermeture expand sur retour Android — dépend T-041 · M-08 — Réf: FR-008, FR-015
- [x] T-043 [US3] DebtForm — `footerLeading` mode édition : pill "Supprimer" (danger) + pill "Remboursé/Non remboursé" (`BSheetSubmitVariant.status`). Soumission : `includeInBalance = _selectedAccountId != null` calculé silencieusement avant création/mise à jour — dépend T-042 · M-08 — Réf: FR-005, FR-017
- [x] T-044 [US3] Créer `flutter/test/src/features/debts/presentation/widgets/debt_form_test.dart` — 4 cas : `should_display_echeance_pill_always`, `should_submit_debt_when_valid`, `should_show_delete_pill_when_edit_mode`, `should_show_rembourse_pill_when_edit_mode` — Réf: FR-011, SC-004 · C-04

**Checkpoint** : `flutter test test/src/features/debts/` PASS. SC-006, SC-009 vérifiés. Pill Échéance visible sur DebtForm vide.

---

## Phase 6 — Polish & Validation finale

**Objectif** : Validation croisée, analyse statique, checklist complète.

- [x] T-050 [P] `flutter analyze` — zéro warning/error après migration des 3 formulaires
- [x] T-051 [P] `flutter test test/src/features/` — 100% PASS (SC-004)
- [x] T-052 Validation manuelle checklist `quickstart.md` — SC-001 à SC-009 vérifiés sur device/simulateur

---

## Mapping Requirements → Tâches

| Requirement | Tâche(s) |
|-------------|----------|
| FR-001 | T-020, T-030, T-040 |
| FR-002 | T-021, T-031, T-041 |
| FR-003 | T-021, T-031, T-041 |
| FR-004 | T-021, T-031, T-041 |
| FR-005 | T-024, T-032, T-043 |
| FR-006 | T-021, T-031, T-041 |
| FR-007 | T-016, T-020, T-030, T-040 |
| FR-008 | T-022, T-042 |
| FR-009 | T-020 |
| FR-010 | T-032 |
| FR-011 | T-025, T-033, T-044 |
| FR-012 | T-010, T-011, T-012, T-013, T-017 |
| FR-013 | T-010, T-011, T-012, T-013, T-014, T-023, T-024 |
| FR-014 | T-041 |
| FR-015 | T-042 |
| FR-016 | T-031, T-041 |
| FR-017 | T-040, T-043 |
| NFR-001 | T-024 (soumission ≤ 3 taps) |
| NFR-002 | T-010 à T-017 (aucun nouvel appel réseau hors récurrence) |
| NFR-004 | T-021, T-031, T-041 (suppression showDatePicker/CategoryPicker) |

---

## Dépendances & ordre d'exécution

### Graphe de dépendances

```
T-001, T-002 (Setup)
     │
     ▼
T-010 ──────────────────────────┐
T-011 [P] ─┐                   │
T-012 [P] ─┤                   │
           ▼                   ▼
          T-013               T-015 (build_runner)
           │
           ▼
          T-014 (notifier create)
T-016 [P] (BSheetTypeToggle)
           │
           ▼
          T-017 (app_router)
     │
     ▼
Phases 3, 4, 5 (formulaires — en parallèle possible)
     │
     ▼
T-050, T-051, T-052 (Phase 6)
```

### Dépendances par US

| User Story | Tâches | Dépend de (hors Phase 2) |
|------------|--------|--------------------------|
| US1 (P1) | T-020→T-025 | T-014, T-017 |
| US2 (P2) | T-030→T-033 | T-017 |
| US3 (P3) | T-040→T-044 | T-017 |

### Opportunités de parallélisme

| Groupe | Tâches | Condition |
|--------|--------|-----------|
| Après T-001, T-002 | T-010, T-011, T-012, T-016 | Indépendants entre eux |
| Après T-017 | T-020, T-030, T-040 | US parallélisables par développeur |
| Phase 6 | T-050, T-051 | Après completion de T-025, T-033, T-044 |

---

## Stratégie d'implémentation

### MVP First (US1 uniquement)

1. Phase 1 : Setup (T-001, T-002)
2. Phase 2 : Fondations (T-010 à T-017) — **CRITIQUE**
3. Phase 3 : US1 TransactionForm (T-020 à T-025)
4. **STOP & VALIDER** : SC-001, SC-002, SC-003, SC-008 manuellement + tests PASS
5. Merge si prêt — SubscriptionForm et DebtForm en features séparées

### Livraison incrémentale

1. Setup + Fondations → infrastructure prête
2. US1 TransactionForm → valider → merge (MVP — formulaire le plus critique)
3. US2 SubscriptionForm → valider → merge
4. US3 DebtForm → valider → merge
5. Phase 6 → validation globale

---

## Tableau résumé

| Phase | Tâches | Priorité | Parallélisables |
|-------|--------|----------|-----------------|
| Phase 1 — Setup | 2 | — | 1 (T-002) |
| Phase 2 — Fondations | 8 | — | 4 (T-011, T-012, T-015, T-016) |
| Phase 3 — US1 (P1) | 6 | P1 | 0 (séquentielles) |
| Phase 4 — US2 (P2) | 4 | P2 | 0 (séquentielles) |
| Phase 5 — US3 (P3) | 5 | P3 | 0 (séquentielles) |
| Phase 6 — Polish | 3 | — | 2 (T-050, T-051) |
| **Total** | **28** | | **7** |
