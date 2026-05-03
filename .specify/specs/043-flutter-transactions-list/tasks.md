# Tasks: Écran Transactions Liste (Flutter)

**Input**: Design documents from `/specs/043-flutter-transactions-list/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md
**Branch**: `043-flutter-transactions-list`
**Linear**: [KKS-103](https://linear.app/kksdev/issue/KKS-103/flutter-ecran-transactions-liste)

**Tests**: Inclus (convention projet — Constitution principe V: Testabilité).

**Organization**: Tâches groupées par user story. US1 et US2 sont fusionnées (toutes deux P1, implémentation indissociable).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut être exécuté en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story rattachée (US1, US2, US3, US4, US5)

## Path Conventions

- Tous les chemins sont relatifs à la racine du monorepo
- Code source : `flutter/lib/src/`
- Tests : `flutter/test/src/`

---

## Phase 1: Foundational (Data Layer)

**Purpose**: Modifications du data layer partagé (modèles, repository, DAO, DTOs) nécessaires avant toute implémentation d'écran.

**GATE**: Aucune tâche US ne peut commencer avant la fin de cette phase.

**Note (F3)**: T005 prépare l'appel Dio `GET /transactions?month=M&year=Y` mais l'endpoint backend n'est pas créé dans ce ticket. En mode `remote`, cet appel échouera tant que l'endpoint n'existe pas côté API. Un ticket backend séparé est nécessaire pour supporter le mode remote.

- [x] T001 [P] Rename `solde` → `bilan` in MonthlySummary Freezed model in `flutter/lib/src/domain/models/monthly_summary.dart` — changer le champ `solde` en `bilan` (type double, required). Cf. Research R3 et data-model.md §MonthlySummary.
- [x] T002 [P] Update `MonthlySummaryResponse` DTO in `flutter/lib/src/data/remote/dtos/transaction_dtos.dart` — renommer le champ `solde` en `bilan` et ajouter `@JsonKey(name: 'solde')` pour garder la compatibilité JSON API. Cf. Research R3.
- [x] T003 [P] Add `Future<List<Transaction>> getByMonth(int month, int year)` to abstract interface in `flutter/lib/src/domain/repositories/transaction_repository.dart`. Cf. Research R1, data-model.md §TransactionRepository.
- [x] T004 [P] Add `getTransactionsByMonth(int month, int year)` Drift query + fix `getMonthlySummary()` to exclude ajustements in `flutter/lib/src/data/local/daos/transaction_dao.dart` — nouvelle requête SQL `SELECT * FROM transactions WHERE date >= startOfMonth AND date < startOfNextMonth ORDER BY date DESC` + ajouter `AND type != 'ajustement'` dans `getMonthlySummary()`. Cf. Research R1, R4, data-model.md §TransactionDao.
- [x] T005 [P] Add `Future<List<TransactionResponse>> getByMonth(int month, int year)` Dio endpoint (`GET /transactions?month=M&year=Y`) in `flutter/lib/src/data/remote/data_sources/transaction_remote_data_source.dart`. Cf. Research R1, data-model.md §TransactionRemoteDataSource.
- [x] T006 Run `dart run build_runner build --delete-conflicting-outputs` in `flutter/` — régénérer `.freezed.dart` et `.g.dart` après modifications MonthlySummary et DTO.
- [x] T007 Implement `getByMonth()` + rename `solde` → `bilan` in mapper in `flutter/lib/src/features/transactions/data/transaction_repository_local.dart` — appeler `dao.getTransactionsByMonth()` et mapper vers domain model. Renommer variable `solde` en `bilan` dans le mapper `getMonthlySummary()`. **Dépend de T003 (interface), T004 (DAO), T006 (build_runner)**. Cf. data-model.md §Modifications.
- [x] T008 [P] Implement `getByMonth()` + rename `solde` → `bilan` in mapper in `flutter/lib/src/features/transactions/data/transaction_repository_remote.dart` — appeler `remoteDataSource.getByMonth()` et mapper vers domain model. Mapper `r.solde` → `bilan:` dans `getMonthlySummary()`. **Dépend de T003 (interface), T005 (remote DS), T006 (build_runner)**. Cf. data-model.md §Modifications.
- [x] T009 [P] Update all `.solde` references to `.bilan` in `flutter/lib/src/features/dashboard/presentation/widgets/monthly_summary_section.dart`. Cf. Research R3 §Impact cascade.
- [x] T010 Verify foundational changes compile — run `flutter analyze` in `flutter/` and fix any errors.

**Checkpoint**: Data layer prêt. `getByMonth()` disponible dans les deux repositories, `bilan` remplace `solde`, ajustements exclus du résumé.

---

## Phase 2: US1 + US2 — Consulter & Naviguer entre mois (P1)

**Goal**: L'utilisateur ouvre l'écran transactions et voit le mois courant avec résumé + liste groupée par jour. Il peut naviguer entre les mois via le sélecteur.

**Independent Test**: Ouvrir l'écran → voir février 2026 avec résumé et liste. Changer de mois → données rechargées. Mois vide → message "Aucune transaction ce mois-ci". Erreur → bouton retry.

**Covers**: FR-001, FR-002, FR-004, FR-004a, FR-005, FR-008, FR-009, FR-010, FR-012, FR-013, FR-014, FR-015, FR-016, NFR-001, NFR-002

- [x] T011 [P] [US1] Create `TransactionTypeFilter` enum (`all`, `depense`, `recette`) + `TransactionListState` Freezed model in `flutter/lib/src/features/transactions/application/transaction_list_state.dart` — champs: `allMonthTransactions` (List\<Transaction\>, default []), `filteredTransactions` (List\<Transaction\>, default []), `activeFilter` (TransactionTypeFilter, default all), `selectedMonth` (int), `selectedYear` (int), `summary` (MonthlySummary?), `isLoading` (bool, default true), `error` (String?). Cf. data-model.md §TransactionListState.
- [x] T012 [P] [US1] Create `DayHeaderFormatter.format(DateTime date)` static method in `flutter/lib/src/utils/day_header_formatter.dart` — retourne "Aujourd'hui" si today, "Hier" si yesterday, sinon `EEEE d MMMM` locale `fr_FR` (ex: "Lundi 20 février"). Utiliser package `intl`. Cf. Research R6, FR-004a.
- [x] T013 [US1] Run `dart run build_runner build --delete-conflicting-outputs` in `flutter/` — régénérer `transaction_list_state.freezed.dart`.
- [x] T014 [US1] Create `TransactionListNotifier` extending `Notifier<TransactionListState>` in `flutter/lib/src/features/transactions/application/transaction_list_notifier.dart` — méthodes: `loadMonth(int month, int year)` charge transactions via `repository.getByMonth()` + summary via `repository.getMonthlySummary()` (retourne `List<MonthlySummary>` → extraire `list.firstOrNull` pour obtenir un `MonthlySummary?`), sets both `allMonthTransactions` et `filteredTransactions` (filter=all). `changeMonth(int month, int year)` met à jour `selectedMonth/Year`, set `isLoading=true`, appelle `loadMonth()` avec protection FR-016 (ignorer les réponses obsolètes si le mois a changé entre-temps — comparer month/year demandé vs state actuel). `refresh()` recharge le mois courant (liste + résumé, FR-011). Gestion erreur: catch exceptions → set `error` message, `isLoading=false`. Exposer `transactionListNotifierProvider`. Cf. Research R2, R7, data-model.md §Providers.
- [x] T015 [P] [US1] Create `TransactionSummaryCard` widget in `flutter/lib/src/features/transactions/presentation/widgets/transaction_summary_card.dart` — affiche 3 métriques: total recettes (vert income), total dépenses (rouge expense), bilan. Props: `summary` (MonthlySummary?), `isLoading` (bool). Si `isLoading=true`: afficher skeleton shimmer (3 barres). Utiliser `AmountFormatter.format()` pour les montants et `AppThemeExtension` pour les couleurs sémantiques. Cf. FR-002, FR-012, FR-013.
- [x] T016 [P] [US1] Create `TransactionDayGroup` widget in `flutter/lib/src/features/transactions/presentation/widgets/transaction_day_group.dart` — affiche un en-tête de jour (via `DayHeaderFormatter.format()`) + liste de `ListItem` pour chaque transaction du jour. Props: `date` (DateTime), `transactions` (List\<Transaction\>), `categories` (Map\<String, Category\>), `onTransactionTap` (Function(Transaction)?). Chaque ListItem: `icon` = catégorie icône (ou emoji par défaut "📝"), `iconBackgroundColor` = parseHexColor(catégorie.couleur), `title` = transaction.libelle, `subtitle` = catégorie.nom (ou "Sans catégorie"), `value` = AmountFormatter.format(montant, type), `valueColor` = `AmountFormatter.amountColor(type, colors) ?? colorScheme.onSurface` (retourne `null` pour ajustements → fallback `onSurface`), `onPressed` = onTransactionTap. Semantic label = "$libellé, $montant formaté" (NFR-001). Cf. FR-005, Edge Cases.
- [x] T017 [US1] Implement `TransactionListScreen` as `ConsumerStatefulWidget` replacing stub in `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart` — architecture: `RefreshIndicator` > `CustomScrollView` > slivers. Slivers: (1) `MonthSelector(onChanged: notifier.changeMonth)`, (2) `TransactionSummaryCard(summary, isLoading)`, (3) si `isLoading` → `Column(children: List.generate(5, ListItem.skeleton()))`, (4) si `error` → widget erreur avec bouton "Réessayer" → `notifier.refresh()`, (5) si `filteredTransactions` vide → état vide avec message "Aucune transaction ce mois-ci", (6) sinon → grouper `filteredTransactions` par jour (`.groupBy(date.ymd)`) et afficher `TransactionDayGroup` pour chaque groupe. `initState` → `WidgetsBinding.addPostFrameCallback` → `notifier.loadMonth(now.month, now.year)`. Consommer `transactionListNotifierProvider` et `categoryNotifierProvider` pour la map catégories. Cf. quickstart.md §Architecture, FR-008, FR-009, FR-010.

**Checkpoint**: Écran fonctionnel avec navigation mensuelle. US1 + US2 testables indépendamment.

---

## Phase 3: US3 — Filtrer par type de transaction (P2)

**Goal**: L'utilisateur filtre la liste avec un filtre segmenté (Tous / Dépenses / Recettes). Le résumé reste inchangé.

**Independent Test**: Sélectionner "Dépenses" → seules les dépenses affichées. Résumé inchangé. Sélectionner "Tous" → toutes les transactions réapparaissent. Filtre "Recettes" sans recette → message "Aucune recette ce mois-ci".

**Covers**: FR-003, FR-006, FR-009 (messages filtrés), FR-012

- [x] T018 [US3] Add `setFilter(TransactionTypeFilter filter)` method to `TransactionListNotifier` in `flutter/lib/src/features/transactions/application/transaction_list_notifier.dart` — filtre côté client (FR-006): si `all` → `filteredTransactions = allMonthTransactions`, si `depense` → filtrer `type == TransactionType.depense`, si `recette` → filtrer `type == TransactionType.recette`. Note: les ajustements sont visibles dans "Tous" mais exclus de "Dépenses" et "Recettes". Mettre à jour `activeFilter` dans le state. Aussi modifier `loadMonth()` pour réappliquer le filtre actif après chargement.
- [x] T019 [US3] Wire `SegmentedFilter<TransactionTypeFilter>` in `TransactionListScreen` in `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart` — ajouter un sliver entre le résumé et la liste. Items: `[SegmentedFilterItem(value: .all, label: 'Tous'), SegmentedFilterItem(value: .depense, label: 'Dépenses'), SegmentedFilterItem(value: .recette, label: 'Recettes')]`. `selectedValue` = state.activeFilter. `onChanged` = notifier.setFilter(). Adapter le message d'état vide selon le filtre: "Aucune dépense ce mois-ci" / "Aucune recette ce mois-ci" (FR-009).

**Checkpoint**: Filtrage fonctionnel. US3 testable indépendamment.

---

## Phase 4: US4 — Ouvrir une transaction en édition (P2)

**Goal**: L'utilisateur tape sur une transaction pour ouvrir le formulaire d'édition. Au retour, la liste est rafraîchie.

**Independent Test**: Taper sur un item → navigation vers le formulaire (ou no-op si route absente). Retour → données rechargées.

**Covers**: FR-007

- [x] T020 [US4] Add tap navigation to edit form in `TransactionListScreen` + `TransactionDayGroup` in `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart` — passer `onTransactionTap` callback au `TransactionDayGroup`: `context.push('/transactions/${transaction.id}').then((_) => notifier.refresh())`. Si la route n'existe pas encore (formulaire non implémenté), encapsuler dans un try-catch pour que le tap soit un no-op silencieux. La route `/transactions/:id` sera ajoutée avec le ticket formulaire d'édition. Cf. Research R9, FR-007.

**Checkpoint**: Navigation vers édition préparée. US4 testable.

---

## Phase 5: US5 — Rafraîchir la liste (P3)

**Goal**: L'utilisateur tire vers le bas pour recharger les données du mois courant (liste + résumé).

**Independent Test**: Tirer vers le bas → indicateur de rafraîchissement → données rechargées. Erreur réseau → message d'erreur sans perte des données existantes.

**Covers**: FR-011

- [x] T021 [US5] Wire `RefreshIndicator.onRefresh` to `notifier.refresh()` in `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart` — le `RefreshIndicator` encapsule déjà le `CustomScrollView` (ajouté en T017). Brancher `onRefresh: () => notifier.refresh()`. S'assurer que `refresh()` retourne un `Future` pour que l'indicateur se ferme correctement. En cas d'erreur, afficher un SnackBar sans perdre les données existantes (FR-011, US5-AS2).

**Checkpoint**: Pull-to-refresh fonctionnel. Toutes les US complètes.

---

## Phase 6: Tests

**Purpose**: Tests unitaires et widget tests couvrant les comportements critiques.

- [x] T022 [P] Create `DayHeaderFormatter` unit tests in `flutter/test/src/utils/day_header_formatter_test.dart` — tests: `should_return_aujourdhui_when_date_is_today`, `should_return_hier_when_date_is_yesterday`, `should_return_full_format_when_date_is_older` (vérifier format "Lundi 20 février"), `should_handle_null_date`. Pattern: `should_[résultat]_when_[condition]`.
- [x] T023 [P] Create `TransactionListNotifier` unit tests in `flutter/test/src/features/transactions/application/transaction_list_notifier_test.dart` — setup: `ProviderContainer` avec mock `TransactionRepository`. Tests: `should_load_transactions_and_summary_when_loadMonth_called`, `should_set_error_when_repository_throws`, `should_filter_depenses_when_setFilter_depense`, `should_filter_recettes_when_setFilter_recette`, `should_show_all_including_ajustements_when_setFilter_all`, `should_ignore_stale_response_when_month_changed_rapidly` (FR-016), `should_reload_both_list_and_summary_when_refresh_called` (FR-011), `should_reapply_filter_after_month_change`. Pattern: `should_[résultat]_when_[condition]`.
- [x] T024 [P] Create `TransactionListScreen` widget tests in `flutter/test/src/features/transactions/presentation/transaction_list_screen_test.dart` — setup: `ProviderScope` + `MaterialApp.router` + `AppTheme.light` avec mocks repository et catégories. Tests: `should_display_shimmer_when_loading`, `should_display_transactions_grouped_by_day_when_loaded`, `should_display_empty_state_when_no_transactions`, `should_display_error_with_retry_when_error`, `should_display_summary_card_with_correct_values`, `should_filter_list_when_segment_tapped`. Pattern: `should_[résultat]_when_[condition]`.
- [x] T025 Run `flutter analyze` + `flutter test test/src/features/transactions/ test/src/utils/day_header_formatter_test.dart` in `flutter/` — vérifier 0 erreurs d'analyse et tous les tests passent.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales, i18n, accessibilité.

- [x] T026 Add i18n strings to `flutter/lib/src/localization/app_fr.arb` — ajouter les clés manquantes : `transactionsEmptyMonth` ("Aucune transaction ce mois-ci"), `transactionsEmptyDepenses` ("Aucune dépense ce mois-ci"), `transactionsEmptyRecettes` ("Aucune recette ce mois-ci"), `transactionsSummaryRecettes` ("Recettes"), `transactionsSummaryDepenses` ("Dépenses"), `transactionsSummaryBilan` ("Bilan"), `transactionsFilterAll` ("Tous"), `transactionsFilterDepenses` ("Dépenses"), `transactionsFilterRecettes` ("Recettes"), `transactionsError` ("Une erreur est survenue"), `transactionsRetry` ("Réessayer"). Puis régénérer les fichiers de localisation.
- [x] T027 Replace hardcoded strings in screen + widgets with i18n references — mettre à jour `TransactionListScreen`, `TransactionSummaryCard` et les messages d'état vide pour utiliser `AppLocalizations.of(context)` au lieu de chaînes en dur.
- [x] T028 Run full validation: `flutter analyze` + `flutter test` in `flutter/` — vérifier 0 erreurs et tous tests passent (y compris tests existants non régressés par le renommage solde→bilan).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: Aucune dépendance — peut démarrer immédiatement
- **Phase 2 (US1+US2)**: Dépend de Phase 1 complète — BLOQUE toutes les US
- **Phase 3 (US3)**: Dépend de Phase 2 (notifier + screen existent)
- **Phase 4 (US4)**: Dépend de Phase 2 (screen existe). Indépendant de Phase 3
- **Phase 5 (US5)**: Dépend de Phase 2 (screen existe). Indépendant de Phases 3-4
- **Phase 6 (Tests)**: Dépend de Phases 2-5 (toutes les US implémentées)
- **Phase 7 (Polish)**: Dépend de Phase 6 (tests passent)

### User Story Dependencies

```
Phase 1 (Foundational)
    │
    ▼
Phase 2 (US1+US2) ─── MVP
    │
    ├──► Phase 3 (US3) ─┐
    ├──► Phase 4 (US4) ─┤── peuvent être parallélisées
    └──► Phase 5 (US5) ─┘
              │
              ▼
         Phase 6 (Tests)
              │
              ▼
         Phase 7 (Polish)
```

### Within Each Phase

- Tâches marquées `[P]` peuvent être exécutées en parallèle
- Les tâches `build_runner` (T006, T013) doivent suivre les modifications de modèles Freezed
- Les tâches de compilation/vérification (T010, T025, T028) sont des gates de validation

### Parallel Opportunities

**Phase 1**: T001, T002, T003, T004, T005 en parallèle (5 fichiers différents). Puis T007, T008, T009 en parallèle.

**Phase 2**: T011, T012 en parallèle. Puis T015, T016 en parallèle. T017 dernier (dépend de tout).

**Phase 3-5**: Phases 3, 4, 5 en parallèle entre elles (même fichier mais scopes distincts — préférer séquentiel pour éviter conflits).

**Phase 6**: T022, T023, T024 en parallèle (3 fichiers test différents).

---

## Parallel Example: Phase 1

```
# Lancer les 5 modifications de fichiers en parallèle :
Task: T001 "Rename solde→bilan in monthly_summary.dart"
Task: T002 "Update MonthlySummaryResponse DTO"
Task: T003 "Add getByMonth to TransactionRepository interface"
Task: T004 "Add getTransactionsByMonth + fix getMonthlySummary in DAO"
Task: T005 "Add getByMonth to RemoteDataSource"

# Puis build_runner :
Task: T006 "Run build_runner"

# Puis implémentations repository en parallèle :
Task: T007 "Implement getByMonth in RepositoryLocal"
Task: T008 "Implement getByMonth in RepositoryRemote"
Task: T009 "Update dashboard .solde → .bilan"
```

## Parallel Example: Phase 2

```
# Lancer state + formatter en parallèle :
Task: T011 "Create TransactionListState + enum"
Task: T012 "Create DayHeaderFormatter"

# Puis build_runner :
Task: T013 "Run build_runner"

# Puis notifier :
Task: T014 "Create TransactionListNotifier"

# Puis widgets en parallèle :
Task: T015 "Create TransactionSummaryCard"
Task: T016 "Create TransactionDayGroup"

# Puis screen :
Task: T017 "Implement TransactionListScreen"
```

---

## Implementation Strategy

### MVP First (US1 + US2 Only)

1. Compléter Phase 1: Foundational (data layer)
2. Compléter Phase 2: US1 + US2 (écran + navigation mois)
3. **STOP et VALIDER**: Tester l'écran avec le mois courant + navigation
4. Commit stratégique

### Incremental Delivery

1. Phase 1 + Phase 2 → MVP (consultation + navigation) → Commit
2. Phase 3 → Filtrage → Commit
3. Phase 4 → Navigation édition → Commit
4. Phase 5 → Pull-to-refresh → Commit
5. Phase 6 → Tests → Commit
6. Phase 7 → Polish i18n → Commit final

---

## Summary

| Métrique | Valeur |
|----------|--------|
| **Total tâches** | 28 |
| Phase 1 (Foundational) | 10 |
| Phase 2 (US1+US2) | 7 |
| Phase 3 (US3) | 2 |
| Phase 4 (US4) | 1 |
| Phase 5 (US5) | 1 |
| Phase 6 (Tests) | 4 |
| Phase 7 (Polish) | 3 |
| **Tâches parallélisables** | 14 (50%) |
| **MVP scope** | Phases 1-2 (17 tâches) |

## Notes

- [P] = fichiers différents, pas de dépendance → parallélisable
- [Story] = rattachement à la user story pour traçabilité
- Chaque phase est testable indépendamment
- Commits recommandés après chaque checkpoint de phase
- Les fichiers `.freezed.dart` et `.g.dart` sont régénérés et commités
