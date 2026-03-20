# Tasks: Améliorations dettes Flutter

**Input**: Design documents from `/specs/079-flutter-debt-enhancements/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Tests unitaires notifier demandés dans la spec (KKS-196). Inclus dans les phases concernées.

**Organization**: Tasks groupées par user story. US2 crée l'écran détail (shell) + remboursement ; US3 l'enrichit avec historique et progression.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (Data Layer)

**Purpose**: Models, DTOs, data source, repository, notifier enrichis — BLOQUE toutes les user stories

**⚠️ CRITICAL**: Aucune user story ne peut commencer avant la complétion de cette phase

### Models & DTOs

- [x] T002 [P] Enrichir le model Debt Freezed avec les nouveaux champs (accountId, accountName, includeInBalance, dueDate, reminderDate, reminderTime, remainingAmount) dans `flutter/lib/src/domain/models/debt.dart`
- [x] T003 [P] Créer le model DebtPayment Freezed (id, montant, date, accountName) dans `flutter/lib/src/domain/models/debt_payment.dart`
- [x] T004 [P] Enrichir DebtRequest et DebtResponse avec les nouveaux champs + créer RepayRequest, SnoozeRequest, PaymentResponse dans `flutter/lib/src/data/remote/dtos/debt_dtos.dart`

### Repository & Data Source

- [x] T005 Ajouter les méthodes repay, getPayments, snooze à l'interface DebtRepository dans `flutter/lib/src/domain/repositories/debt_repository.dart`
- [x] T006 Ajouter les appels Dio pour POST /debts/{id}/repay, GET /debts/{id}/payments, POST /debts/{id}/snooze + enrichir les mappers request/response dans `flutter/lib/src/data/remote/data_sources/debt_remote_data_source.dart`
- [x] T007 Implémenter repay, getPayments, snooze dans DebtRepositoryRemote en déléguant au data source dans `flutter/lib/src/features/debts/data/debt_repository_remote.dart`

### Application Layer

- [x] T008 Enrichir DebtListNotifier avec méthodes repay(debtId, accountId, amount) et snooze(debtId, date, time) + créer debtPaymentsProvider (FutureProvider.family) dans `flutter/lib/src/features/debts/application/debt_notifier.dart`

### Code Generation

- [x] T009 Exécuter `cd flutter && dart run build_runner build --delete-conflicting-outputs` pour générer les fichiers .freezed.dart et .g.dart

**Checkpoint**: Data layer complet — les user stories peuvent commencer

---

## Phase 2: User Story 1 — Formulaire de dette enrichi (Priority: P1) 🎯 MVP

**Goal**: L'utilisateur peut créer/modifier une dette avec compte bancaire, rappel (date+heure), et toggle patrimoine

**Independent Test**: Créer une dette avec les nouveaux champs et vérifier la persistance via l'API

### Implementation for User Story 1

- [x] T010 [US1] Enrichir DebtForm : ajouter SelectPicker pour le compte bancaire (liste des comptes actifs via accountNotifierProvider), logique de forçage devise quand compte sélectionné, dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`
- [x] T011 [US1] Enrichir DebtForm : ajouter section rappel avec showDatePicker (date) + showTimePicker conditionnel (heure, défaut 09:00, visible si date sélectionnée). **Note** : PAS de validation date future pour le rappel dans le formulaire de création/édition (contrairement au SnoozeDialog T021 qui exige une date future). Dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`
- [x] T012 [US1] Enrichir DebtForm : ajouter SwitchListTile "Inclure dans le patrimoine" (visible si aucun compte, auto-coché+masqué si compte sélectionné) + ajouter dueDate picker + mettre à jour la logique de soumission (request enrichie), dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`
- [x] T013 [US1] Mettre à jour le pré-remplissage en mode édition : compte, rappel (date+heure), patrimoine, dueDate, dans `flutter/lib/src/features/debts/presentation/widgets/debt_form.dart`

**Checkpoint**: Le formulaire de dette enrichi est fonctionnel — créer/modifier une dette avec tous les nouveaux champs

---

## Phase 3: User Story 2 — Remboursement d'une dette (Priority: P1)

**Goal**: L'utilisateur peut rembourser une dette (partiel ou total) depuis un écran détail avec bottom sheet

**Independent Test**: Effectuer un remboursement et vérifier la transaction créée + mise à jour du montant restant

**Dependencies**: Crée l'écran détail (shell) qui sera enrichi par US3

### Implementation for User Story 2

- [x] T014 [US2] Ajouter la route /debts/:id dans go_router + RouteNames.debtDetail dans `flutter/lib/src/routing/route_names.dart` et `flutter/lib/src/routing/app_router.dart`
- [x] T015 [US2] Créer DebtDetailScreen (ConsumerStatefulWidget) avec : en-tête (personne + badge type EMPRUNT/PRET + badge "Remboursé" si soldé), section montants (initial + restant), bouton "Rembourser" (visible si !rembourse), bouton edit, skeleton shimmer pendant le chargement initial. **Edge case** : si `accountId != null` mais le compte n'existe plus, afficher "Compte supprimé" au lieu du nom du compte. Dans `flutter/lib/src/features/debts/presentation/debt_detail_screen.dart`
- [x] T016 [US2] Créer RepayBottomSheet (ConsumerStatefulWidget) via AppModal.show() avec : SelectPicker compte (obligatoire, pré-sélection compte associé ou premier actif), TextFormField montant (DecimalTextInputFormatter, pré-rempli remainingAmount, max=remainingAmount), validation + soumission via notifier.repay(), snackbar résultat. Si aucun compte actif disponible, afficher un message invitant à créer un compte. Dans `flutter/lib/src/features/debts/presentation/widgets/repay_bottom_sheet.dart`
- [x] T017 [US2] Câbler la navigation depuis DebtListScreen : tap sur un item → context.push('/debts/${debt.id}') au lieu d'ouvrir le modal d'édition, dans `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`

**Checkpoint**: Le remboursement fonctionne — bottom sheet, transaction créée, dette mise à jour, snackbar affiché

---

## Phase 4: User Story 3 — Détail de dette enrichi avec historique des paiements (Priority: P2)

**Goal**: L'écran détail affiche montant restant, barre de progression, infos enrichies (compte, rappel, patrimoine), et historique des paiements

**Independent Test**: Vérifier l'affichage du détail après plusieurs remboursements — progression, liste paiements, total cumulé

### Implementation for User Story 3

- [x] T018 [US3] Enrichir DebtDetailScreen : ajouter section progression avec LinearProgressIndicator (paiements/total), pourcentage, couleur par type (EMPRUNT=debt-owe, PRET=debt-owed), dans `flutter/lib/src/features/debts/presentation/debt_detail_screen.dart`
- [x] T019 [US3] Enrichir DebtDetailScreen : ajouter section infos (date, devise, dueDate, catégorie, compte bancaire, "Inclus dans le solde", rappel date+heure) avec icônes Phosphor. **Edge case** : si `accountId != null` mais le compte n'existe plus, afficher "Compte supprimé" (cohérent avec T015). Dans `flutter/lib/src/features/debts/presentation/debt_detail_screen.dart`
- [x] T020 [US3] Enrichir DebtDetailScreen : ajouter section "Paiements" avec ListView chronologique (date + montant + compte), total cumulé en en-tête, état vide "Aucun paiement enregistré", chargement via debtPaymentsProvider, dans `flutter/lib/src/features/debts/presentation/debt_detail_screen.dart`

**Checkpoint**: L'écran détail est complet — progression visuelle, infos enrichies, historique paiements

---

## Phase 5: User Story 4 — Report de rappel / snooze (Priority: P3)

**Goal**: L'utilisateur peut reporter le rappel d'une dette à une nouvelle date/heure depuis l'écran détail

**Independent Test**: Reporter un rappel et vérifier que la nouvelle date/heure est persistée

### Implementation for User Story 4

- [x] T021 [US4] Créer SnoozeDialog (ConsumerStatefulWidget) via AppModal.show() avec : DatePicker (pré-rempli rappel actuel, validation date future via validator), TimePicker (pré-rempli heure actuelle), soumission via notifier.snooze(), snackbar "Rappel reporté", dans `flutter/lib/src/features/debts/presentation/widgets/snooze_dialog.dart`
- [x] T022 [US4] Ajouter bouton "Reporter le rappel" sur DebtDetailScreen (visible si reminderDate != null), câbler ouverture du SnoozeDialog, rafraîchir la dette après snooze, dans `flutter/lib/src/features/debts/presentation/debt_detail_screen.dart`

**Checkpoint**: Le snooze fonctionne — dialogue, validation date future, rappel mis à jour

---

## Phase 6: User Story 5 — Actions notification push (Priority: P3)

**Goal**: Les notifications de dette proposent "Reporter" et "Rembourser" avec deep link vers le détail

**Independent Test**: Simuler une notification de rappel et vérifier la navigation vers le détail

**Dependencies**: Dépend du système de notification existant (KKS-072)

### Implementation for User Story 5

- [x] T023 [US5] Enrichir le panneau de notifications : pour les notifications de type DEBT_REMINDER et DEBT_DUE, ajouter boutons d'action "Rembourser" (navigue vers /debts/{entityId}) et "Reporter" (ouvre SnoozeDialog avec la dette chargée via getById), dans `flutter/lib/src/features/notifications/presentation/notification_list_screen.dart`
- [x] T024 [US5] Ajouter la gestion du deep link au tap sur une notification de dette : navigation vers /debts/{entityId} via context.push(), marquer la notification comme lue, dans `flutter/lib/src/features/notifications/presentation/notification_list_screen.dart`

**Checkpoint**: Les actions notification fonctionnent — deep link vers détail, snooze depuis notification

---

## Phase 7: Tests

**Purpose**: Tests unitaires notifier + widget tests

- [x] T025 [P] Écrire les tests unitaires du DebtListNotifier enrichi : should_repay_debt_when_valid_amount, should_update_remaining_when_partial_repay, should_mark_repaid_when_full_repay, should_reject_repay_when_amount_zero, should_reject_repay_when_amount_negative, should_reject_repay_when_amount_exceeds_remaining, should_snooze_reminder_when_future_date, should_show_error_when_no_active_accounts, dans `flutter/test/src/features/debts/application/debt_notifier_test.dart`
- [x] T026 [P] Écrire les tests unitaires pour debtPaymentsProvider : should_load_payments_when_debt_has_history, should_return_empty_when_no_payments, dans `flutter/test/src/features/debts/application/debt_notifier_test.dart`
- [x] T027 [P] Écrire les widget tests du DebtForm enrichi : should_force_currency_when_account_selected, should_hide_patrimoine_toggle_when_account_selected, should_show_time_picker_when_reminder_date_selected, should_prefill_fields_when_editing, should_allow_past_reminder_date_in_form (confirmer l'absence de validation future), dans `flutter/test/src/features/debts/presentation/widgets/debt_form_test.dart`

**Checkpoint**: Tous les tests passent

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Localisation, code generation final, nettoyage

- [x] T028 [P] Ajouter les clés de localisation l10n manquantes (remboursement, rappel reporté, montant restant, aucun paiement, inclure patrimoine, date future requise) dans `flutter/lib/src/localization/`
- [x] T029 Exécuter `cd flutter && dart run build_runner build --delete-conflicting-outputs` pour la génération finale
- [x] T030 Exécuter `cd flutter && flutter analyze` pour vérifier qu'il n'y a pas de warnings
- [x] T031 Exécuter `cd flutter && flutter test` pour valider que tous les tests passent (existants + nouveaux)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — BLOQUE toutes les user stories
- **US1 (Phase 2)**: Dépend de Phase 1 uniquement
- **US2 (Phase 3)**: Dépend de Phase 1. Crée l'écran détail (shell)
- **US3 (Phase 4)**: Dépend de Phase 3 (écran détail créé par US2)
- **US4 (Phase 5)**: Dépend de Phase 3 (écran détail pour le bouton snooze)
- **US5 (Phase 6)**: Dépend de Phase 3 (route /debts/:id) + Phase 5 (SnoozeDialog)
- **Tests (Phase 7)**: Dépend de Phases 1-6
- **Polish (Phase 8)**: Dépend de toutes les phases

### User Story Dependencies

```
Phase 1 (Foundational)
  ├── US1 (Form) ── indépendant
  └── US2 (Repay + Detail shell)
        ├── US3 (Detail enrichment) ── dépend de US2
        ├── US4 (Snooze) ── dépend de US2
        └── US5 (Notifications) ── dépend de US2 + US4
```

### Parallel Opportunities

- **Phase 1**: T002, T003, T004 en parallèle (fichiers différents)
- **Phase 2 + Phase 3**: US1 et US2 peuvent démarrer en parallèle après Phase 1
- **Phase 7**: T025, T026, T027 en parallèle (fichiers de test différents)
- **Phase 8**: T028 en parallèle avec T029

---

## Parallel Example: Phase 1 (Foundational)

```bash
# Lancer les 3 models/DTOs en parallèle :
Task: "Enrichir Debt model dans flutter/lib/src/domain/models/debt.dart"
Task: "Créer DebtPayment model dans flutter/lib/src/domain/models/debt_payment.dart"
Task: "Enrichir DTOs dans flutter/lib/src/data/remote/dtos/debt_dtos.dart"

# Puis séquentiellement :
Task: "Repository interface → Data source → Repository impl → Notifier → Build runner"
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Foundational (data layer complet)
2. Complete Phase 2: US1 — Formulaire enrichi
3. Complete Phase 3: US2 — Détail + Remboursement
4. **STOP and VALIDATE**: Formulaire + Remboursement fonctionnels
5. Commit + vérifier `/sync-doc`

### Incremental Delivery

1. Phase 1 → Data layer ✓
2. Phase 2 → US1 Form ✓ → Commit
3. Phase 3 → US2 Repay + Detail ✓ → Commit
4. Phase 4 → US3 History + Progress ✓ → Commit
5. Phase 5 → US4 Snooze ✓ → Commit
6. Phase 6 → US5 Notifications ✓ → Commit
7. Phase 7+8 → Tests + Polish ✓ → Commit final

---

## Notes

- Mode serveur uniquement — ne PAS modifier DebtRepositoryLocal ni DebtDao
- Alignement complet sur l'implémentation Angular (KKS-078) pour tous les comportements UX
- Les fichiers .freezed.dart et .g.dart seront régénérés par build_runner (T009, T029)
- Commit après chaque phase ou groupe logique de tâches
- Vérifier `/sync-doc` après le dernier commit
