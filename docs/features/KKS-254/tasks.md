# Tasks — KKS-254 : Budget détail Flutter (alignement DESIGN.md v5)

**Issue** : KKS-254 | **Date** : 2026-05-23
**Input** : [spec.md](./spec.md) · [plan.md](./plan.md) · [research.md](./research.md) · [data-model.md](./data-model.md)

**Format** : `- [ ] [T-XXX] [P] [USX] Description — Réf: FR-XXX`
- `[P]` = parallélisable (fichiers différents, sans dépendance)
- `[USX]` = User Story couverte

---

## Phase 1 — Setup

**Objectif** : Vérifier les prérequis avant toute modification.

- [x] [T-001] Vérifier la présence des dépendances communes : `common_widgets/confirm_dialog_custom.dart`, `common_widgets/empty_state_widget.dart`, `domain/repositories/budget_repository.dart` (méthode `getById`), `domain/repositories/transaction_repository.dart` (méthode `getByMonth`) — Réf: A-001, A-003, A-005
- [x] [T-002] [P] `flutter analyze` baseline avant modification — zéro erreur attendue — Réf: NFR-001

**Checkpoint** : Prérequis présents, baseline compile → démarrer Phase 2.

---

## Phase 2 — Fondations (bloquant)

**Objectif** : Router, provider de transactions, nettoyage `BudgetHeroWidget`. Bloquant pour toutes les US.

**⚠️ CRITIQUE** : Aucune tâche de Phase 3+ ne peut commencer avant la complétion de cette phase.

- [x] [T-010] Modifier `flutter/lib/src/routing/app_router.dart` — GoRoute `details` : lire `categoryId` depuis `state.uri.queryParameters['categoryId'] ?? ''` et le transmettre à `BudgetDetailScreen(categoryId: categoryId, month: month)` — Réf: FR-001, RES-002
- [x] [T-011] [P] Créer `flutter/lib/src/features/budgets/application/budget_transactions_provider.dart` — `FutureProvider.family<List<Transaction>, ({int month, int year})>` appelant `transactionRepositoryProvider.getByMonth(params.month, params.year)` — pattern identique à `debtPaymentsProvider` — Réf: FR-016, RES-006
- [x] [T-012] [P] Modifier `flutter/lib/src/features/budgets/presentation/widgets/budget_hero_widget.dart` — Supprimer la déclaration `final VoidCallback onChartsTap` et tout usage interne (GestureDetector/bouton associé). `_DoughnutMini` et `fl_chart` restent. — Réf: FR-028, RES-008

**Checkpoint** : `flutter analyze` passe (T-012 casse les callsites de `budget_list_screen` — les 2 erreurs sont attendues et corrigées en T-036) → démarrer Phase 3.

---

## Phase 3 — US1 + US2 : Navigation · Hero · Transactions (P1)

**Objectif** : Parcours principal — navigation depuis la liste, hero budget, transactions groupées.

### US1 — Consultation du détail (P1)

- [x] [T-020] [US1] `flutter/lib/src/features/budgets/presentation/budget_detail_screen.dart` — Nouveau constructeur `ConsumerStatefulWidget` : `required String categoryId`, `String? month`. Parser `month` → `_selectedMonth`, `_selectedYear` dans `initState` via `addPostFrameCallback`. Charger overview ou history selon mois. Trouver l'item : `_findOverviewItem()` (overview) → fallback `_findFallbackBudget()` (state.items). Charger accounts si `state.items.isEmpty`. Supprimer : mixin `BudgetMonthHelpers`, `MonthSelector`, logique `_onMonthChanged`. Structure : `CustomScrollView` avec slivers. — Réf: FR-001, FR-005, FR-006, RES-005
- [x] [T-021] [US1] `budget_detail_screen.dart` — `_buildHero()` : label "DÉPENSÉ" uppercase `bodySmall onSurfaceVariant`, montant `titleLarge` (`expenseColor` si percentage > 100%), méta-ligne Row (PhosphorTarget + budget formaté + "·" + PhosphorWarning si dépassement sinon PhosphorChartPie + reste/dépassement formaté), `LinearProgressIndicator` conditionnelle (`percentage > 0`, états normal/warning >80%/exceeded >100%). — Réf: FR-008, FR-009, FR-010
- [x] [T-022] [US1] `budget_detail_screen.dart` — AppBar : `_buildTitle()` retourne `Row(icône catégorie dans conteneur circulaire `categoryCouleur+'26'`, nom catégorie)`. Pendant loading : titre "Budget". — Réf: FR-006, FR-007
- [x] [T-023] [US1] `budget_detail_screen.dart` — `_StickyTransactionHeader` : `SliverPersistentHeaderDelegate` privé au fichier (`minExtent = maxExtent = 44.0`), pinned dans `CustomScrollView`. Affiche "Transactions" + count transactions filtrées. — Réf: FR-011, RES-010
- [x] [T-024] [US1] `budget_detail_screen.dart` — Skeleton hero : `ShimmerWidget` (3 lignes de hauteurs variables) pendant `isLoading`. `ErrorView` avec bouton "Réessayer" → `_loadData()` si le budget state est en erreur. — Réf: NFR-004, SC-006
- [x] [T-025] [US1] `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` — 3 points de navigation → `context.pushNamed(RouteNames.budgetDetailsName, queryParameters: {'categoryId': item.categoryId, 'month': month})` : (1) items actifs mois courant (remplace `modalNotifierProvider.open(...)`), (2) items inactifs mois courant (remplace `onTap: null`), (3) items historique (ajouter `onTap`). — Réf: FR-002, FR-003, FR-004, RES-003

### US2 — Transactions groupées (P1)

- [x] [T-026] [US2] `budget_detail_screen.dart` — `_buildTransactionSlivers()` : `ref.watch(budgetTransactionsProvider((month: _selectedMonth, year: _selectedYear)))`. Filtrer : `tx.categoryId == widget.categoryId && tx.type == TransactionType.depense`. Trier décroissant par date. Grouper : "Aujourd'hui" / "Hier" / date longue locale. Retourner liste de slivers (1 `SliverToBoxAdapter` date-label + 1 `SliverList` par groupe). — Réf: FR-017, FR-018, FR-019
- [x] [T-027] [US2] `budget_detail_screen.dart` — `_TransactionRow` widget privé : `InkWell` (lecture seule). `Row` : `Container` 36px circle (couleur catégorie bg + emoji), `Column(libelle, date sous-titre formatée)`, `Text(montant, devise résolue via accounts.firstWhereOrNull((a) => a.id == tx.accountId)?.currency ?? budgetCurrency)`. — Réf: FR-020, RES-007
- [x] [T-028] [US2] `budget_detail_screen.dart` — Empty state `EmptyStateWidget` (icône `PhosphorReceipt`, label "Aucune transaction ce mois") dans `SliverFillRemaining` si liste filtrée vide. Skeleton : 4 `SliverList` items shimmer (`_TransactionSkeleton` privé : circle + 2 lignes) pendant chargement FutureProvider. — Réf: FR-021, FR-022, NFR-004

**Checkpoint** : Navigation liste → détail fonctionne, hero s'affiche, transactions groupées visibles. SC-001, SC-002, SC-006, SC-008 vérifiables manuellement.

---

## Phase 4 — US3 + US4 : Action pills · Nettoyage (P2)

**Objectif** : Actions budget mois courant + suppression widgets obsolètes.

### US3 — Actions sur le budget (P2)

- [x] [T-030] [US3] `budget_detail_screen.dart` — `_buildActionPills()` : affiché ssi `isCurrentMonth && overviewItem != null && overviewItem.budgetId != null`. Layout `Row` : pill danger gauche, `Spacer()`, pill toggle centre, pill edit droite. — Réf: FR-012
- [x] [T-031] [US3] `budget_detail_screen.dart` — Pill "Supprimer" : `ConfirmDialogCustom.show()` → si confirmé → `ref.read(budgetNotifierProvider.notifier).delete(budgetId)` → `context.go(RouteNames.budgets)`. Vérifier `mounted` après chaque `await`. — Réf: FR-013, NFR-003, NFR-005
- [x] [T-032] [US3] `budget_detail_screen.dart` — Pill "Désactiver"/"Activer" : `ref.read(budgetRepositoryProvider).getById(budgetId)` → `budgetNotifier.update(budget.copyWith(actif: !budget.actif))` → `context.go(RouteNames.budgets)`. Label initial "Désactiver" (actif = true par défaut, A-002). Vérifier `mounted`. — Réf: FR-014, NFR-003, RES-004
- [x] [T-033] [US3] `budget_detail_screen.dart` — Pill "Modifier" : `ref.read(budgetRepositoryProvider).getById(budgetId)` → `ref.read(modalNotifierProvider.notifier).open(ModalType.budget, entity: budget)`. Vérifier `mounted`. — Réf: FR-015, NFR-003

### US4 — Nettoyage widgets obsolètes (P2)

- [x] [T-034] [US4] Supprimer `flutter/lib/src/features/budgets/presentation/widgets/budget_pie_chart.dart` et `budget_category_detail_sheet.dart` : (1) retirer leurs imports de `budget_detail_screen.dart`, (2) supprimer les fichiers. — Réf: FR-023, FR-024, RES-001
- [x] [T-035] [US4] `budget_detail_screen.dart` — Retirer : import `UnbudgetedDetailSheet` (fichier conservé), import `MonthSelector`, mixin `with BudgetMonthHelpers`, méthode `_onMonthChanged`, classe privée `_BudgetItemRow`. Faire dans la même passe que T-034 (même fichier cible). — Réf: FR-025, FR-026, FR-027
- [x] [T-036] [US4] `budget_list_screen.dart` — Retirer les 2 occurrences `onChartsTap: () => context.push(...)` (lignes ~364 et ~525 de l'état actuel). `flutter analyze` doit passer après cette tâche. — Réf: FR-028, RES-008

**Checkpoint** : `flutter analyze` → 0 erreur. `grep -rn "BudgetPieChart\|BudgetCategoryDetailSheet\|onChartsTap" lib/` → 0 résultat. SC-003, SC-004, SC-005, SC-007 vérifiables.

---

## Phase 5 — Polish & Tests

**Objectif** : Couverture tests ≥ 8, validation statique finale.

- [x] [T-050] [P] `flutter/test/src/features/budgets/presentation/widgets/budget_hero_widget_test.dart` — Ligne 35 : retirer le paramètre `onChartsTap: () {}`. Vérifier que le test passe sans autre modification. — Réf: FR-028, SC-007 partiel
- [x] [T-051] Refonte `flutter/test/src/features/budgets/presentation/budget_detail_screen_test.dart` — 9 widget tests avec `ProviderContainer` overrides (`_MockBudgetNotifier`, `_MockTransactionRepository`, `_MockAccountNotifier`) :
  - `should_navigateToDetail_when_budgetItemTapped` (SC-001)
  - `should_showHero_when_budgetItemLoaded` (SC-001)
  - `should_showTransactionGroups_when_transactionsLoaded` (SC-002)
  - `should_showActionPills_when_currentMonth` (SC-003)
  - `should_hideActionPills_when_historyMonth` (SC-003 / SC-009)
  - `should_callDelete_when_deleteConfirmed` (SC-004)
  - `should_callUpdate_when_toggleConfirmed` (SC-005)
  - `should_showSkeleton_when_loading` (SC-006)
  - `should_showEmptyState_when_noTransactions` (SC-008)
  — Réf: NFR-006
- [x] [T-052] [P] Validation finale : `flutter test test/src/features/budgets/` (≥ 9 tests PASS, 0 FAIL) + `flutter analyze` (0 erreur, 0 warning) — Réf: SC-007, SC-009

---

## Mapping Requirements → Tâches

| Requirement | Tâche(s) |
|-------------|----------|
| FR-001 | T-010, T-020 |
| FR-002 | T-025 |
| FR-003 | T-025 |
| FR-004 | T-025 |
| FR-005 | T-020 |
| FR-006 | T-020, T-022 |
| FR-007 | T-022 |
| FR-008 | T-021 |
| FR-009 | T-021 |
| FR-010 | T-021 |
| FR-011 | T-023 |
| FR-012 | T-030 |
| FR-013 | T-031 |
| FR-014 | T-032 |
| FR-015 | T-033 |
| FR-016 | T-011 |
| FR-017 | T-026 |
| FR-018 | T-026 |
| FR-019 | T-026 |
| FR-020 | T-027 |
| FR-021 | T-028 |
| FR-022 | T-024, T-028 |
| FR-023 | T-034 |
| FR-024 | T-034 |
| FR-025 | T-035 |
| FR-026 | T-035 |
| FR-027 | T-035 |
| FR-028 | T-012, T-036 |
| NFR-001 | T-011 |
| NFR-002 | T-021, T-022, T-023, T-026, T-027, T-028 |
| NFR-003 | T-031, T-032, T-033 |
| NFR-004 | T-024, T-028 |
| NFR-005 | T-031 |
| NFR-006 | T-051 |

---

## Phase 6 — Dépendances & Ordre d'exécution

### Graphe de dépendances

```
T-001, T-002 (Setup)
     │
     ▼
T-010 ──────────────────────┐
T-011 [P] ──────────────────┤  (Fondations — parallélisables entre eux)
T-012 [P] ──────────────────┘
     │
     ▼
T-020 → T-021, T-022, T-023, T-024 [US1 — séquentiels dans BudgetDetailScreen]
T-025 [P avec T-020] [US1 — fichier différent : budget_list_screen]
     │
T-026 → T-027 → T-028 [US2 — séquentiels]
     │
     ▼
T-030 → T-031, T-032, T-033 [US3 — séquentiels]
T-034 [P] , T-035 [P] [US4 — parallélisables entre eux]
T-036 [dépend T-012 — complète la suppression onChartsTap]
     │
     ▼
T-050 [P], T-051, T-052 [P] (Polish)
```

### Dépendances par US

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US1 (P1) | T-020, T-021, T-022, T-023, T-024, T-025 | T-010, T-012 |
| US2 (P1) | T-026, T-027, T-028 | T-011, T-020 |
| US3 (P2) | T-030, T-031, T-032, T-033 | T-020, T-021 |
| US4 (P2) | T-034, T-035, T-036 | T-012, T-020 |

### Opportunités de parallélisme

| Groupe | Tâches | Condition |
|--------|--------|-----------|
| Phase 2 | T-010, T-011, T-012 | Fichiers distincts, indépendants |
| Phase 3 | T-025 avec T-020-T-024 | Fichiers distincts (`budget_list_screen` vs `budget_detail_screen`) |
| Phase 4 | T-034 + T-035 en une passe | Même fichier cible (`budget_detail_screen.dart`) — séquentiels |
| Phase 5 | T-050, T-052 avec T-051 | T-050 fichier distinct, T-052 en fin de T-051 |

---

## Stratégie d'implémentation

### MVP First

1. Phase 1 : Setup (T-001, T-002)
2. Phase 2 : Fondations (T-010, T-011, T-012) — **CRITIQUE**
3. Phase 3 US1 : Navigation + Hero (T-020 à T-025)
4. **STOP & VALIDER** : SC-001 manuellement (navigation + hero)
5. Phase 3 US2 : Transactions (T-026 à T-028)
6. **MVP livrable** : écran détail lecture seule + transactions groupées

### Livraison incrémentale

1. Setup + Fondations → infrastructure prête
2. US1 + US2 (P1) → MVP lecture seule — valider SC-001, SC-002, SC-006, SC-008
3. US3 (P2) → Action pills — valider SC-003, SC-004, SC-005
4. US4 (P2) → Nettoyage — valider SC-007
5. Polish → tests ≥ 9, `flutter analyze` propre

---

## Tableau résumé

| Phase | Tâches | Priorité | Parallélisables |
|-------|--------|----------|-----------------|
| Phase 1 — Setup | 2 | — | 1 (T-002) |
| Phase 2 — Fondations | 3 | — | 2 (T-011, T-012) |
| Phase 3 — US1+US2 (P1) | 9 | P1 | 1 (T-025) |
| Phase 4 — US3+US4 (P2) | 7 | P2 | 0 (séquentielles) |
| Phase 5 — Polish | 3 | — | 2 (T-050, T-052) |
| **Total** | **24** | | **8** |
