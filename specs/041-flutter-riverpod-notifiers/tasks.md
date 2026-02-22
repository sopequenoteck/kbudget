# Tasks: Flutter Notifiers Riverpod CRUD

**Input**: Design documents from `/specs/041-flutter-riverpod-notifiers/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus — la spec exige la testabilite (Constitution V) et le pattern de test existe deja (auth_notifier_test.dart).

**Organization**: Tasks groupees par phase incrementale. TransactionNotifier sert de reference (US1-US5), puis replication aux 4 autres entites, puis actions specifiques (US6).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependance)
- **[Story]**: User story concernee (US1-US6)
- Chemins exacts relatifs a la racine du repo

---

## Phase 1: Foundational (ListState + Mocks)

**Purpose**: Creer le modele d'etat generique partage par les 5 notifiers et preparer l'infrastructure de test.

**CRITICAL**: Aucun notifier ne peut etre implemente avant la completion de cette phase.

- [x] T001 Creer le modele Freezed ListState\<T\> dans `flutter/lib/src/domain/models/list_state.dart` — champs: items (List\<T\>, default []), isLoading (bool, default false), error (String?), currentPage (int, default 0), hasMore (bool, default true), mutatingIds (Set\<String\>, default {}). Ajouter le re-export dans `flutter/lib/src/domain/models/models.dart`
- [x] T002 Executer `dart run build_runner build --delete-conflicting-outputs` depuis `flutter/` pour generer `list_state.freezed.dart`. Verifier la compilation avec `flutter analyze`
- [x] T003 Verifier que `flutter/test/helpers/mocks.dart` contient deja les mocks des 5 repositories (TransactionRepository, AccountRepository, CategoryRepository, SubscriptionRepository, DebtRepository) et que `mocks.mocks.dart` est genere. Si manquant, ajouter les annotations et re-executer build_runner

**Checkpoint**: ListState\<T\> compile, mocks generes, `flutter analyze` passe.

---

## Phase 2: TransactionNotifier — Reference (US1-US5, P1+P2) MVP

**Goal**: Implementer le premier notifier complet qui servira de patron pour les 4 autres. Couvre les user stories 1 a 5.

**Independent Test**: Charger la liste de transactions, creer/modifier/supprimer un element, verifier la pagination — tout via tests unitaires.

### Implementation

- [x] T004 [US1] Creer TransactionNotifier dans `flutter/lib/src/features/transactions/application/transaction_notifier.dart` — provider `transactionNotifierProvider`, classe etendant `Notifier<ListState<Transaction>>`, methodes `build()` (retourne ListState vide), `loadItems()` (getAll + sort date desc + page 0), `refresh()` (recharge depuis repo). Gerer isLoading/error/items. Champ prive `_allItems` et constante `_pageSize = 20`
- [x] T005 [US2] Ajouter methode `create(Transaction item)` a TransactionNotifier — set isLoading=true, appeler repo.create(), inserer le resultat dans _allItems, trier, rafraichir la page, set isLoading=false. En cas d'erreur: set state.error, set isLoading=false. Pas de mutatingIds (l'element n'existe pas encore dans la liste)
- [x] T006 [US3] Ajouter methode `update(Transaction item)` a TransactionNotifier — ajouter ID dans mutatingIds, appeler repo.update(), remplacer dans _allItems, trier, rafraichir la page. En cas d'erreur: set state.error, retirer de mutatingIds
- [x] T007 [US4] Ajouter methode `delete(String id)` optimiste a TransactionNotifier — sauvegarder l'element et son index, retirer de _allItems et items, ajouter ID dans mutatingIds, appeler repo.delete(). Succes: retirer de mutatingIds. Echec: re-inserer a la position sauvegardee, set state.error, retirer de mutatingIds
- [x] T008 [US5] Ajouter methode `loadMore()` a TransactionNotifier — si !hasMore ou isLoading: return. Incrementer currentPage, prendre les (currentPage+1)*_pageSize premiers elements de _allItems, mettre a jour items et hasMore. Ajouter methode privee `_refreshPage()` utilisee par create/update/delete pour re-calculer la tranche visible

### Tests

- [x] T009 Creer le fichier de test `flutter/test/src/features/transactions/application/transaction_notifier_test.dart` — setup avec ProviderContainer + MockTransactionRepository override. Tests: should_haveEmptyState_when_created, should_showLoading_when_loadItemsCalled, should_showItems_when_loadSucceeds, should_sortByDateDesc_when_loaded, should_showError_when_loadFails, should_showEmptyList_when_noData, should_reloadItems_when_refreshCalled, should_addItem_when_createSucceeds, should_showError_when_createFails, should_updateItem_when_updateSucceeds, should_showError_when_updateFails, should_removeItem_when_deleteSucceeds, should_rollbackItem_when_deleteFails, should_loadNextPage_when_loadMoreCalled, should_stopPagination_when_noMoreItems, should_trackMutatingIds_when_mutationInProgress

**Checkpoint**: TransactionNotifier complet et teste. Pattern valide pour replication.

---

## Phase 3: Replication — 4 Notifiers (US1-US5)

**Goal**: Creer les 4 notifiers restants en suivant le pattern TransactionNotifier. Chaque notifier implemente loadItems, create, update, delete (optimiste), loadMore, refresh.

**Independent Test**: Chaque notifier fonctionne independamment avec les memes capacites que TransactionNotifier.

### Implementation (tous parallelisables — fichiers differents)

- [x] T010 [P] Creer AccountNotifier dans `flutter/lib/src/features/accounts/application/account_notifier.dart` — meme pattern que TransactionNotifier. Tri par nom croissant (`a.nom.compareTo(b.nom)`). Provider `accountNotifierProvider`. Repo via `accountRepositoryProvider`
- [x] T011 [P] Creer CategoryNotifier dans `flutter/lib/src/features/categories/application/category_notifier.dart` — meme pattern que TransactionNotifier. Tri par nom croissant. Provider `categoryNotifierProvider`. Repo via `categoryRepositoryProvider`
- [x] T012 [P] Creer SubscriptionNotifier dans `flutter/lib/src/features/subscriptions/application/subscription_notifier.dart` — meme pattern que TransactionNotifier. Tri par nom croissant. Provider `subscriptionNotifierProvider`. Repo via `subscriptionRepositoryProvider`
- [x] T013 [P] Creer DebtNotifier dans `flutter/lib/src/features/debts/application/debt_notifier.dart` — meme pattern que TransactionNotifier. Tri par date decroissante (meme que Transaction). Provider `debtNotifierProvider`. Repo via `debtRepositoryProvider`

**Checkpoint**: 5 notifiers fonctionnels avec CRUD + pagination. SC-004 (5 entites avec memes capacites) valide.

---

## Phase 4: Actions Specifiques par Entite (US6, P3)

**Goal**: Ajouter les actions metier specifiques a chaque entite.

**Independent Test**: Executer chaque action specifique et verifier que la liste se met a jour.

### Implementation (tous parallelisables)

- [x] T014 [P] [US6] Ajouter methode `setDefault(String id)` a AccountNotifier dans `flutter/lib/src/features/accounts/application/account_notifier.dart` — ajouter ID dans mutatingIds, appeler repo.setDefault(id), mettre a jour l'ancien compte par defaut (isDefault=false) et le nouveau (isDefault=true) dans _allItems et items. Gerer erreur
- [x] T015 [P] [US6] Ajouter guard isSystem a CategoryNotifier dans `flutter/lib/src/features/categories/application/category_notifier.dart` — dans update() et delete(), verifier si la categorie a `isSystem == true`. Si oui: set state.error = 'Les categories systeme ne peuvent pas etre modifiees/supprimees' et return sans appeler le repository (FR-015)
- [x] T016 [P] [US6] Ajouter methode `toggleActif(String id)` a SubscriptionNotifier dans `flutter/lib/src/features/subscriptions/application/subscription_notifier.dart` — trouver l'abonnement dans _allItems, appeler update(subscription.copyWith(actif: !actif)). Reutiliser la methode update() existante (FR-011)
- [x] T017 [P] [US6] Ajouter methode `markAsRepaid(String id)` a DebtNotifier dans `flutter/lib/src/features/debts/application/debt_notifier.dart` — trouver la dette dans _allItems, appeler update(debt.copyWith(rembourse: true)). Reutiliser la methode update() existante (FR-010)

**Checkpoint**: Toutes les actions specifiques implementees. FR-009 a FR-015 valides.

---

## Phase 5: Tests — 4 Notifiers Restants

**Purpose**: Tester les 4 notifiers restants + les actions specifiques.

### Tests (tous parallelisables)

- [x] T018 [P] Creer test `flutter/test/src/features/accounts/application/account_notifier_test.dart` — meme structure que TransactionNotifier test (load, create, update, delete optimiste, pagination, mutatingIds). Ajouter: should_setDefault_when_setDefaultSucceeds, should_updatePreviousDefault_when_newDefaultSet, should_showError_when_setDefaultFails
- [x] T019 [P] Creer test `flutter/test/src/features/categories/application/category_notifier_test.dart` — meme structure de base. Ajouter: should_refuseUpdate_when_categoryIsSystem, should_refuseDelete_when_categoryIsSystem, should_allowUpdate_when_categoryIsNotSystem
- [x] T020 [P] Creer test `flutter/test/src/features/subscriptions/application/subscription_notifier_test.dart` — meme structure de base. Ajouter: should_toggleActif_when_toggleActifCalled, should_deactivate_when_activeSubscriptionToggled
- [x] T021 [P] Creer test `flutter/test/src/features/debts/application/debt_notifier_test.dart` — meme structure de base. Ajouter: should_markAsRepaid_when_markAsRepaidCalled, should_showError_when_markAsRepaidFails

**Checkpoint**: 100% des notifiers testes. SC-003 (erreurs affichees) et SC-004 (5 notifiers fonctionnels) valides.

---

## Phase 6: Polish & Validation

**Purpose**: Validation finale cross-cutting.

- [x] T022 Executer `flutter analyze` depuis `flutter/` et corriger les warnings/erreurs eventuels
- [x] T023 Executer `flutter test` depuis `flutter/` et verifier que tous les tests passent
- [x] T024 Verifier que les exports sont corrects — `list_state.dart` re-exporte dans `models.dart`, chaque notifier provider est accessible depuis son fichier

**Checkpoint**: Feature complete. Tous les criteres de succes (SC-001 a SC-006) verifiables.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: Aucune dependance — demarre immediatement
- **Phase 2 (TransactionNotifier)**: Depend de Phase 1 (ListState<T> doit exister)
- **Phase 3 (Replication)**: Depend de Phase 2 (pattern valide par les tests)
- **Phase 4 (Actions specifiques)**: Depend de Phase 3 (notifiers de base doivent exister)
- **Phase 5 (Tests)**: Depend de Phase 4 (actions specifiques doivent etre implementees)
- **Phase 6 (Polish)**: Depend de Phase 5 (tous les tests doivent exister)

### User Story Mapping

| User Story | Phase(s) | Tasks |
|------------|----------|-------|
| US1 — Load/Display | 2, 3 | T004, T010-T013 |
| US2 — Create | 2, 3 | T005, T010-T013 |
| US3 — Update | 2, 3 | T006, T010-T013 |
| US4 — Delete optimiste | 2, 3 | T007, T010-T013 |
| US5 — Pagination | 2, 3 | T008, T010-T013 |
| US6 — Actions specifiques | 4 | T014-T017 |

### Parallel Opportunities

**Phase 1**: T001 → T002 (sequentiel, codegen depend du fichier). T003 peut etre parallele avec T002
**Phase 2**: T004 → T005 → T006 → T007 → T008 (sequentiel, meme fichier). T009 apres T008
**Phase 3**: T010, T011, T012, T013 tous en parallele (fichiers differents)
**Phase 4**: T014, T015, T016, T017 tous en parallele (fichiers differents)
**Phase 5**: T018, T019, T020, T021 tous en parallele (fichiers differents)

---

## Parallel Example: Phase 3

```text
# Lancer les 4 notifiers en parallele (fichiers differents, meme pattern):
Task T010: "Creer AccountNotifier dans flutter/lib/src/features/accounts/application/account_notifier.dart"
Task T011: "Creer CategoryNotifier dans flutter/lib/src/features/categories/application/category_notifier.dart"
Task T012: "Creer SubscriptionNotifier dans flutter/lib/src/features/subscriptions/application/subscription_notifier.dart"
Task T013: "Creer DebtNotifier dans flutter/lib/src/features/debts/application/debt_notifier.dart"
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2)

1. Completer Phase 1: ListState<T> + mocks
2. Completer Phase 2: TransactionNotifier complet + tests
3. **STOP et VALIDER**: `flutter test` passe, pattern confirme
4. Ce MVP suffit pour brancher l'ecran des transactions

### Incremental Delivery

1. Phase 1 → Foundational pret
2. Phase 2 → TransactionNotifier valide (MVP)
3. Phase 3 → 5/5 notifiers avec CRUD + pagination
4. Phase 4 → Actions specifiques metier
5. Phase 5 → Tests complets
6. Phase 6 → Validation finale

---

## Notes

- Chaque notifier dans Phase 3 replique exactement le pattern de TransactionNotifier (Phase 2), avec seulement le tri et le type d'entite qui changent
- Les actions specifiques (Phase 4) sont des ajouts incrementaux aux notifiers existants
- Le mock file `flutter/test/helpers/mocks.dart` doit inclure les 5 repositories — verifier si certains mocks existent deja (AuthRepository mock existe)
- `_allItems` est une liste privee dans chaque notifier, non exposee dans l'etat — cela separe les donnees brutes de la vue paginee
