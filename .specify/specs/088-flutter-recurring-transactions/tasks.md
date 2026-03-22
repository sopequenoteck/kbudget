# Tasks: Flutter Recurring Transactions & Subscription Payments

**Input**: Design documents from `/specs/088-flutter-recurring-transactions/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Inclus — la spec mentionne "Tests unitaires notifier + widget tests".

**Organization**: Tasks grouped by user story (US1=récurrences, US2=paiements abonnements, US3=notifications).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter**: `flutter/lib/src/` pour le code source, `flutter/test/src/` pour les tests
- Abréviation : `src/` = `flutter/lib/src/`, `test/` = `flutter/test/src/`

---

## Phase 1: Setup

**Purpose**: Préparation des fichiers partagés et infrastructure commune

- [x] T001 [P] Créer le modèle Freezed `RecurringTransaction` dans `src/domain/models/recurring_transaction.dart` — champs : id, montant, libelle, type (TransactionType), frequency (Frequency), nextOccurrence, recurringActive, categoryName?, categoryIcon?, categoryColor?, accountName?, accountCurrency? + getter dérivé `status` (overdue/today/upcoming)
- [x] T002 [P] Créer le modèle Freezed `SubscriptionPayment` dans `src/domain/models/subscription_payment.dart` — champs : id, montant, date, subscriptionName?, accountName?
- [x] T003 [P] Créer le modèle Freezed `SubscriptionTotalPaid` dans `src/domain/models/subscription_total_paid.dart` — champs : subscriptionId, subscriptionName?, totalPaid, paymentCount
- [x] T004 [P] Créer les DTOs `RecurringTransactionResponse` (json_serializable) dans `src/data/remote/dtos/recurring_transaction_dtos.dart` — mapper nested `category` et `account` vers les champs plats du modèle domaine
- [x] T005 [P] Créer les DTOs `SubscriptionPaymentResponse` et `SubscriptionTotalPaidResponse` dans `src/data/remote/dtos/subscription_payment_dtos.dart`
- [x] T006 Lancer `dart run build_runner build --delete-conflicting-outputs` pour générer les fichiers `.freezed.dart` et `.g.dart`

---

## Phase 2: Foundational (Data Layer)

**Purpose**: Data sources et repositories — bloque l'implémentation des écrans

**CRITICAL**: Compléter avant de commencer les Phases 3-5

- [x] T007 Créer `RecurringTransactionRemoteDataSource` dans `src/data/remote/data_sources/recurring_transaction_remote_data_source.dart` — 4 méthodes Dio : `getActive()` GET `/transactions/recurring`, `validate(id)` POST `/transactions/recurring/{id}/validate`, `skip(id)` PATCH `/transactions/recurring/{id}/skip`, `deactivate(id)` PATCH `/transactions/recurring/{id}/deactivate`
- [x] T008 Enrichir `SubscriptionRemoteDataSource` dans `src/data/remote/data_sources/subscription_remote_data_source.dart` — ajouter 3 méthodes : `pay(id)` POST `/subscriptions/{id}/pay`, `getPayments(id)` GET `/subscriptions/{id}/payments`, `getTotalPaid(id)` GET `/subscriptions/{id}/payments/total`
- [x] T009 [P] Créer l'interface `RecurringTransactionRepository` dans `src/domain/repositories/recurring_transaction_repository.dart` — méthodes : `listActive()`, `validate(id)`, `skip(id)`, `deactivate(id)`
- [x] T010 [P] Créer `RecurringTransactionRepositoryRemote` dans `src/features/recurring/data/recurring_transaction_repository_remote.dart` — implémente l'interface, injecte le data source, mappe DTOs → modèles domaine
- [x] T011 Enrichir l'interface `SubscriptionRepository` dans `src/domain/repositories/subscription_repository.dart` — ajouter : `pay(id)`, `getPayments(id)`, `getTotalPaid(id)`
- [x] T012 Enrichir `SubscriptionRepositoryRemote` dans `src/features/subscriptions/data/subscription_repository_remote.dart` — implémenter les 3 nouvelles méthodes avec mapping DTOs
- [x] T012b Enrichir `SubscriptionRepositoryLocal` dans `src/features/subscriptions/data/subscription_repository_local.dart` — ajouter les 3 nouvelles méthodes avec `throw UnimplementedError('Server-only: use remote repository')` pour maintenir la compilation
- [x] T013 Créer le provider `recurringTransactionRepositoryProvider` dans `src/features/recurring/data/recurring_transaction_repository_remote.dart` (ou fichier providers dédié) — Provider remote-only (pas de dataModeProvider, server-only)
- [x] T014 Lancer `dart run build_runner build --delete-conflicting-outputs` pour régénérer après ajouts

**Checkpoint**: Data layer complet — les notifiers peuvent maintenant être implémentés

---

## Phase 3: User Story 1 - Consulter et gérer les récurrences actives (Priority: P1) MVP

**Goal**: L'utilisateur peut voir ses récurrences actives, les valider, les passer ou les désactiver depuis un écran dédié avec swipe + long press bottom sheet.

**Independent Test**: Naviguer vers l'écran récurrences → vérifier la liste triée (overdue > today > upcoming) → valider une récurrence → vérifier le snackbar succès.

### Implementation for User Story 1

- [x] T015 [US1] Créer `RecurringListNotifier extends Notifier<ListState<RecurringTransaction>>` dans `src/features/recurring/application/recurring_list_notifier.dart` — méthodes : `loadItems()` (tri par status puis date), `validate(id)` (appel repo + refresh liste + return void), `skip(id)` (appel repo + refresh), `deactivate(id)` (appel repo + refresh). Utiliser `mutatingIds` pour l'état de chargement par item. Provider : `recurringListNotifierProvider`.
- [x] T016 [P] [US1] Créer `RecurringListSkeleton` dans `src/features/recurring/presentation/widgets/recurring_list_skeleton.dart` — shimmer loading suivant le pattern existant (voir `src/features/debts/presentation/widgets/`)
- [x] T017 [P] [US1] Créer `RecurringListItem` dans `src/features/recurring/presentation/widgets/recurring_list_item.dart` — ConsumerWidget affichant : icône catégorie + libellé, montant formaté + fréquence, badge statut coloré ("En retard" rouge, "Aujourd'hui" amber, "A venir" gris). Wrappé dans `Dismissible` : swipe droite (startToEnd) → valider (fond vert + icône check), swipe gauche (endToStart) → passer (fond orange + icône skip). `GestureDetector.onLongPress` → `showModalBottomSheet` avec 3 actions (Valider, Passer, Désactiver). Utiliser `confirmDismiss` pour exécuter l'action. Utiliser les clés i18n pour tous les textes.
- [x] T018 [US1] Créer `RecurringListScreen` dans `src/features/recurring/presentation/recurring_list_screen.dart` — ConsumerWidget avec : AppBar "Récurrences", body = switch sur `listState` (loading → skeleton, error → message + retry, empty → état vide avec icône + texte, data → ListView de `RecurringListItem`). Pull-to-refresh via `RefreshIndicator`. Dialog de confirmation pour désactivation (AlertDialog "Désactiver cette récurrence ?"). Ajouter les clés i18n nécessaires dans `src/localization/` : "Récurrences", "En retard", "Aujourd'hui", "A venir", "Valider", "Passer", "Désactiver", "Aucune récurrence active", "Désactiver cette récurrence ?".
- [x] T019 [US1] Ajouter la route `/transactions/recurring` dans `src/routing/route_names.dart` (constante `recurring`) et dans `src/routing/app_router.dart` (GoRoute pointant vers `RecurringListScreen`)

### Tests for User Story 1

- [x] T020 [P] [US1] Test unitaire `RecurringListNotifier` dans `test/features/recurring/application/recurring_list_notifier_test.dart` — tests : `should_load_items_sorted_by_status_then_date`, `should_validate_and_refresh_list`, `should_skip_and_refresh_list`, `should_deactivate_and_refresh_list`, `should_set_error_on_failure`, `should_track_mutating_ids`
- [x] T021 [P] [US1] Widget test `RecurringListScreen` dans `test/features/recurring/presentation/recurring_list_screen_test.dart` — tests : `should_show_skeleton_while_loading`, `should_show_empty_state`, `should_show_recurring_items_sorted`

**Checkpoint**: US1 complet — l'écran récurrences est fonctionnel et testable indépendamment

---

## Phase 4: User Story 2 - Payer un abonnement et consulter l'historique (Priority: P2)

**Goal**: L'utilisateur peut voir l'historique des paiements d'un abonnement avec total cumulé et payer un abonnement échu.

**Independent Test**: Ouvrir le détail d'un abonnement → vérifier la section historique → payer un abonnement → vérifier le paiement dans l'historique.

### Implementation for User Story 2

- [x] T022 [US2] Enrichir `SubscriptionNotifier` dans `src/features/subscriptions/application/subscription_notifier.dart` — ajouter : `pay(id)` (appel repo.pay → refresh), `loadPayments(id)` → state séparé ou provider dédié, `loadTotalPaid(id)`. Créer `subscriptionPaymentsProvider(id)` (FutureProvider.family) et `subscriptionTotalPaidProvider(id)` (FutureProvider.family).
- [x] T023 [P] [US2] Créer `PaymentHistorySection` dans `src/features/subscriptions/presentation/widgets/payment_history_section.dart` — ConsumerWidget affichant : en-tête "Historique des paiements" + total cumulé (montant + nombre de paiements), liste chronologique des paiements (date + montant + nom compte), état vide si aucun paiement
- [x] T024 [US2] Créer `SubscriptionDetailScreen` dans `src/features/subscriptions/presentation/subscription_detail_screen.dart` — ConsumerWidget avec : infos abonnement (nom, montant, fréquence, catégorie, compte, statut actif), bouton "Payer" si échéance atteinte (FloatingActionButton ou bouton prominent), `PaymentHistorySection`, navigation retour. Paramètres : `subscriptionId` + `initialSubscription?` (pattern DebtDetailScreen). Ajouter les clés i18n : "Historique des paiements", "Total payé", "Payer", "Aucun paiement".
- [x] T025 [US2] Ajouter la route `/subscriptions/:id` dans `src/routing/route_names.dart` (constante `subscriptionDetail`) et dans `src/routing/app_router.dart` (GoRoute enfant de la route subscriptions, `parentNavigatorKey: _rootNavigatorKey`)
- [x] T026 [US2] Câbler la navigation dans `SubscriptionListScreen` (`src/features/subscriptions/presentation/subscription_list_screen.dart`) — le tap sur un item navigue vers `SubscriptionDetailScreen` au lieu d'ouvrir le modal d'édition. Le FAB ou un bouton "Modifier" dans le détail ouvre toujours le formulaire via modal.

### Tests for User Story 2

- [x] T027 [P] [US2] Test unitaire enrichissement `SubscriptionNotifier` dans `test/features/subscriptions/application/subscription_notifier_test.dart` — ajouter tests : `should_pay_subscription`, `should_load_payments`, `should_load_total_paid`
- [x] T028 [P] [US2] Widget test `SubscriptionDetailScreen` dans `test/features/subscriptions/presentation/subscription_detail_screen_test.dart` — tests : `should_show_subscription_info`, `should_show_payment_history`, `should_show_pay_button_when_due`

**Checkpoint**: US1 + US2 complets — récurrences et paiements abonnements fonctionnels indépendamment

---

## Phase 5: User Story 3 - Actions depuis les notifications (Priority: P3)

**Goal**: L'utilisateur peut agir sur une notification de récurrence ou abonnement (Valider/Passer/Payer) et naviguer vers l'écran concerné via deep link.

**Independent Test**: Recevoir une notification de récurrence → action "Valider" → vérifier la transaction créée. Taper la notification → vérifier la navigation vers l'écran.

### Implementation for User Story 3

- [x] T029 [P] [US3] Ajouter `recurringTransactionDue` à l'enum `NotificationType` dans `src/domain/enums/notification_type.dart` — avec icône Phosphor et couleur associées
- [x] T030 [P] [US3] Ajouter `recurringTransaction` à l'enum `EntityType` dans `src/domain/enums/entity_type.dart`
- [x] T031 [US3] Enrichir `NotificationPanel` dans `src/features/notifications/presentation/notification_panel.dart` — ajouter dans `_buildNotificationItem` : pour `NotificationType.recurringTransactionDue` → 2 boutons trailing (Valider avec PhosphorIconsRegular.check + Passer avec PhosphorIconsRegular.skipForward), pour `NotificationType.subscriptionDue` → 1 bouton trailing (Payer avec PhosphorIconsRegular.currencyEur). Les actions appellent `ref.read(recurringListNotifierProvider.notifier).validate/skip(entityId)` ou `ref.read(subscriptionNotifierProvider.notifier).pay(entityId)` puis `markAsRead`.
- [x] T032 [US3] Enrichir la navigation deep link dans `NotificationPanel._onNotificationTap` — ajouter : `recurringTransactionDue` → `context.push('/transactions/recurring')` (liste, pas de détail individuel), `subscriptionDue` → `context.push('/subscriptions/${notification.entityId}')` (détail abonnement)

### Tests for User Story 3

- [x] T033 [US3] Widget test `NotificationPanel` enrichi dans `test/features/notifications/presentation/notification_panel_test.dart` — tests : `should_show_validate_skip_buttons_for_recurring`, `should_show_pay_button_for_subscription`, `should_navigate_to_recurring_screen_on_tap`, `should_navigate_to_subscription_detail_on_tap`

**Checkpoint**: Toutes les user stories fonctionnelles et testables indépendamment

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Intégration finale, code generation, validation

- [x] T034 Lancer `dart run build_runner build --delete-conflicting-outputs` pour régénérer tous les fichiers Freezed/json_serializable
- [x] T035 Vérifier la complétude i18n — s'assurer que toutes les clés ajoutées dans T018 et T024 sont présentes dans les fichiers ARB de `src/localization/` et qu'aucun texte n'est hardcodé
- [x] T036 Lancer `flutter analyze` et corriger les warnings éventuels
- [x] T037 Lancer `flutter test` et vérifier que tous les tests passent (existants + nouveaux)
- [x] T038 Valider le quickstart.md — suivre les étapes manuellement pour vérifier le fonctionnement end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T006 build_runner)
- **US1 (Phase 3)**: Depends on Phase 2 (T007 data source, T009-T010 repository)
- **US2 (Phase 4)**: Depends on Phase 2 (T008 data source enrichi, T011-T012 repository enrichi)
- **US3 (Phase 5)**: Depends on US1 (T015 notifier) + US2 (T022 notifier enrichi)
- **Polish (Phase 6)**: Depends on all user stories

### User Story Dependencies

- **US1 (P1)**: Indépendant — démarre après Phase 2
- **US2 (P2)**: Indépendant — démarre après Phase 2 (parallélisable avec US1)
- **US3 (P3)**: Dépend de US1 + US2 (utilise les notifiers des deux stories pour les actions)

### Within Each User Story

- Models/DTOs avant data sources
- Data sources avant repositories
- Repositories avant notifiers
- Notifiers avant screens
- Screens avant tests widget

### Parallel Opportunities

- **Phase 1** : T001, T002, T003, T004, T005 en parallèle (fichiers distincts)
- **Phase 2** : T009, T010 en parallèle avec T011, T012
- **Phase 3+4** : US1 et US2 en parallèle (fichiers et modules distincts)
- **Tests** : Tous les tests [P] d'une même phase en parallèle

---

## Parallel Example: User Story 1

```bash
# Parallèle : widget skeleton + list item (fichiers distincts)
Task T016: "Créer RecurringListSkeleton dans widgets/recurring_list_skeleton.dart"
Task T017: "Créer RecurringListItem dans widgets/recurring_list_item.dart"

# Puis séquentiel : screen dépend des widgets
Task T018: "Créer RecurringListScreen"

# Parallèle : tests unitaires + widget tests (fichiers distincts)
Task T020: "Test RecurringListNotifier"
Task T021: "Test RecurringListScreen"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (models + DTOs)
2. Compléter Phase 2: Foundational (data layer)
3. Compléter Phase 3: User Story 1 (écran récurrences)
4. **STOP et VALIDER** : Tester l'écran récurrences indépendamment
5. Commit MVP

### Incremental Delivery

1. Setup + Foundational → Data layer complet
2. US1 → Écran récurrences fonctionnel → Commit
3. US2 → Détail abonnement + paiements → Commit
4. US3 → Actions notifications → Commit
5. Polish → Tests complets, i18n, validation → Commit final

---

## Notes

- API REST uniquement (server-only) — pas de Drift/SQLite
- Le modèle `RecurringTransaction` est nouveau (aucun code Flutter existant)
- Le `SubscriptionDetailScreen` est nouveau (actuellement seul le formulaire modal existe)
- Swipe via `Dismissible` natif (pas de `flutter_slidable`)
- Les enums `NotificationType` et `EntityType` sont modifiés en Phase 5 (US3) car non nécessaires avant
- Commit stratégique recommandé après chaque phase
