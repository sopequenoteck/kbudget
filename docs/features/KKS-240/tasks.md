# Tasks — KKS-240 : Phase 1 / Étape 4 — Refonte 4 écrans liste Flutter

> Date : 2026-05-10
> Issue : KKS-240
> Spec : [spec.md](./spec.md)
> Plan : [plan.md](./plan.md)

---

## Phase 1 : Setup

- [x] [T-001] [P1] Vérifier branche `feature/flutter-screens-listes-v5`, confirmer `SectionHeaderSticky` disponible, grep imports uniques (`PatrimoineCard`/`IncomeExpenseCards` → dashboard_screen uniquement ; `TransactionDayGroup` → transaction_list_screen uniquement), confirmer `TODO KKS-240` présents dans les 3 screens, `flutter analyze` exit 0 — Réf: NFR-003, NFR-004, A-001

**Checkpoint** : `grep -rn "SectionHeaderSticky" flutter/lib/src/common_widgets/` → classe trouvée. `grep -rn "PatrimoineCard\|IncomeExpenseCards" flutter/lib/src/` → 2 résultats uniquement dans `dashboard_screen.dart`. `grep -rn "TODO KKS-240" flutter/lib/src/` → 3 résultats (transactions, subscriptions, debts). `flutter analyze` exit 0.

---

## Phase 2 : Fondations (bloquantes)

> Aucune fondation technique bloquante — pas de nouveau token, pas de nouvelle entité, pas de migration. Les 4 streams US sont indépendants entre eux. La phase 2 est réduite à la vérification des suppressions prévues.

- [x] [T-010] [P1] Confirmer que les fichiers à supprimer (plan T-2) ne sont importés nulle part hors de leur screen hôte : `grep -rn "income_expense_cards\|patrimoine_card" flutter/lib/src/` → imports uniquement dans `dashboard_screen.dart`. Confirmer que `_SectionHeader` (privé) et `_DebtSummaryCard` (privé) sont bien des classes privées non exportées — Réf: FR-001, CL-001

**Checkpoint** : `grep -rn "income_expense_cards\|patrimoine_card" flutter/lib/src/` → 1 fichier (dashboard_screen.dart). Aucun autre import détecté. Sécurité de suppression confirmée.

---

## Phase 3 : User Stories (par priorité)

### P1 — Critiques

#### US-001 — Dashboard hero flat

- [x] [T-020] [P] [P1] [US-001] Créer `dashboard_hero_widget.dart` : `StatelessWidget` flat sans gradient, key `Key('dashboard_hero')`, migration de la logique de calcul depuis `PatrimoineCard` (patrimoine total, variation mensuelle badgée, devise secondaire), structure hero xs/uppercase + montant size3xl/bold incomeColor|expenseColor + badge variation + meta-line `PhosphorTrendUp` revenus + meta-line `PhosphorTrendDown` dépenses + ligne devise secondaire, skeleton `_DashboardHeroSkeleton` (key `Key('dashboard_hero_skeleton')`, `Container(height: 96)` + `Shimmer.fromColors`), documentation `///` — Réf: FR-002, FR-003, FR-014, FR-015, FR-016, NFR-005, RES-001, RES-007

- [x] [T-021] [P1] [US-001] Modifier `dashboard_screen.dart` : supprimer imports `PatrimoineCard` + `IncomeExpenseCards`, remplacer le bloc `if (state.currencies.length > 1)... PatrimoineCard + IncomeExpenseCards` par `DashboardHeroWidget(accounts: state.accounts, activeCurrency: state.activeCurrency, exchangeRates: ..., currencies: state.currencies, currentSummary: state.currentSummary, isLoading: state.isLoading)` ; supprimer physiquement `patrimoine_card.dart` et `income_expense_cards.dart` — Réf: FR-001, FR-003, FR-017, CL-001, CL-002

#### US-002 — Transactions : hero + SectionHeaderSticky + groupement sémantique

- [x] [T-022] [P] [P1] [US-002] Créer `transaction_hero_widget.dart` : `StatelessWidget`, key `Key('transaction_hero')`, paramètres `(MonthlySummary? summary, Currency? primaryCurrency, bool isLoading)`, bilan = `totalRecettes - totalDepenses`, label "SOLDE" xs/uppercase, montant size3xl incomeColor|expenseColor, meta-lines `PhosphorTrendUp`/`PhosphorTrendDown` 14px, skeleton `Key('transaction_hero_skeleton')`, documentation `///` — Réf: FR-005, FR-014, FR-015, FR-016, NFR-005, RES-001, RES-007

- [x] [T-023] [P1] [US-002] Modifier `transaction_list_screen.dart` : supprimer le bloc `Wrap(ChoiceChip...)` + import `TransactionTypeFilter` UI (garder dans notifier) ; remplacer `TransactionSummaryCard` par `TransactionHeroWidget(summary: state.summary, primaryCurrency: primaryCurrency, isLoading: state.isLoading)` ; ajouter `SectionHeaderSticky(title: 'Transactions')` ; implémenter `_groupBySemantics(List<Transaction> items, DateTime today) → Map<String, List<Transaction>>` (5 buckets ordonnés, buckets vides omis) ; utiliser `state.allMonthTransactions` ; pour chaque bucket non vide : `SliverToBoxAdapter(child: Padding(child: Text(label, xs/medium, color)))` + `SliverList(TransactionDayGroup sans header)` ; "Aujourd'hui" → `AppColors.amber`, autres → `colorScheme.onSurfaceVariant` — Réf: FR-004, FR-006, FR-016, FR-017, RES-004, CX-001

- [x] [T-024] [P] [P1] [US-002] Modifier `transaction_day_group.dart` : retirer l'appel à `DayHeaderFormatter.format(date)` et le widget associé dans `build()` (environ ligne 52) ; si `date` devient inutilisé → retirer le paramètre ; widget réduit à la `SliverList` des items du groupe — Réf: FR-007

#### US-003 — Abonnements : hero + SectionHeaderSticky + Actifs/Inactifs

- [x] [T-025] [P] [P1] [US-003] Créer `subscription_hero_widget.dart` : `StatelessWidget`, key `Key('subscription_hero')`, paramètres `(Map<Currency, double> monthlyTotals, int activeCount, bool isLoading)`, `monthlyTotals.isEmpty → SizedBox.shrink()`, label "ABONNEMENTS" xs/uppercase, total mensuel size3xl/bold/expenseColor, meta-line `PhosphorRepeat` 14px + "$activeCount actifs", meta-line `PhosphorCalendarBlank` 14px + "≈ ${total×12} devise/an", skeleton `Key('subscription_hero_skeleton')`, documentation `///` — Réf: FR-009, FR-014, FR-015, FR-016, NFR-005, RES-001, RES-007, A-003

- [x] [T-026] [P1] [US-003] Modifier `subscription_list_screen.dart` : supprimer les 2 blocs `Wrap(ChoiceChip...)` (état vide + état données) ; remplacer `_SubscriptionSummaryCard` par `SubscriptionHeroWidget(monthlyTotals: state.monthlyTotals, activeCount: activeCount, isLoading: state.isLoading)` où `activeCount = state.items.where((s) => s.actif).length` ; ajouter `SectionHeaderSticky(title: 'Abonnements · $activeCount actifs')` ; date-label `SliverToBoxAdapter(child: Padding(child: Text('Actifs', xs/medium, onSurfaceVariant)))` + items actifs ; date-label "Inactifs" + items inactifs ; sections vides omises ; supprimer classes `_SubscriptionSummaryCard` et `_SummaryCardSkeleton` du fichier — Réf: FR-008, FR-010, FR-016, FR-017, RES-003, CL-006

#### US-004 — Dettes : hero + SectionHeaderSticky + groupement temporel

- [x] [T-027] [P] [P1] [US-004] Créer `debt_hero_widget.dart` : `StatelessWidget`, key `Key('debt_hero')`, paramètres `(Map<Currency, DebtCurrencySummary> summary, Currency? primaryCurrency, int enCours, bool isLoading)`, `summary.isEmpty → SizedBox.shrink()`, solde net = `totalPrets - totalEmprunts` pour `primaryCurrency` (ou première entrée si null), label "DETTES" xs/uppercase, montant size3xl incomeColor|expenseColor|onSurface, meta-ligne 1 `PhosphorHandCoins` 14px + "N prêts" · `PhosphorHandshake` 14px + "M emprunts", meta-ligne 2 `PhosphorClock` 14px + "$enCours en cours", skeleton `Key('debt_hero_skeleton')`, documentation `///` — Réf: FR-012, FR-014, FR-015, FR-016, NFR-005, RES-001, RES-003, RES-007

- [x] [T-028] [P1] [US-004] Modifier `debt_list_screen.dart` : supprimer `_buildFilter()` et ses 2 appels ; supprimer classe privée `_SectionHeader` ; supprimer `_DebtSummaryCard` et `_SummaryCardSkeleton` ; calculer `kEnCours = state.items.where((d) => !d.rembourse).length` ; câbler `DebtHeroWidget(summary: state.summary, primaryCurrency: primaryCurrency, enCours: kEnCours, isLoading: state.isLoading)` ; ajouter `SectionHeaderSticky(title: 'Dettes · $kEnCours en cours')` ; implémenter `_groupByDueDate(List<Debt> items, DateTime today) → Map<String, List<Debt>>` (7 buckets, tri dueDate ASC + date DESC, buckets vides omis) ; date-labels colorés ("En retard" → expenseColor, "Aujourd'hui" → amber, autres → onSurfaceVariant) — Réf: FR-011, FR-013, FR-016, FR-017, RES-003, RES-005, CX-002

**Checkpoint** : `flutter analyze lib/src/features/` exit 0. `grep -rn "ChoiceChip" flutter/lib/src/features/{transactions,subscriptions,debts}/` → 0 résultat. `grep -rn "PatrimoineCard\|IncomeExpenseCards" flutter/lib/src/` → 0 résultat. `grep -rn "LinearGradient" flutter/lib/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart` → 0 résultat.

---

## Phase 4 : Polish

- [x] [T-050] [P] [P1] Tests `dashboard_hero_widget_test.dart` via `forEachTheme` : présence `Key('dashboard_hero')` (SC-005), skeleton `Key('dashboard_hero_skeleton')` quand `isLoading: true` (SC-006), aucun `LinearGradient` dans le widget (SC-002), couleur montant `incomeColor` si patrimoine ≥ 0 / `expenseColor` si < 0, dark + light (SC-010) — Réf: NFR-001, SC-002, SC-005, SC-006, SC-010

- [x] [T-051] [P] [P1] Tests `transaction_hero_widget_test.dart` via `forEachTheme` : présence `Key('transaction_hero')` (SC-005), skeleton (SC-006), montant bilan correct incomeColor|expenseColor, dark + light (SC-010) — Réf: NFR-001, SC-005, SC-006, SC-010

- [x] [T-052] [P] [P1] Tests `subscription_hero_widget_test.dart` via `forEachTheme` : présence `Key('subscription_hero')` (SC-005), skeleton (SC-006), `monthlyTotals.isEmpty → SizedBox.shrink()`, dark + light (SC-010) — Réf: NFR-001, SC-005, SC-006, SC-010

- [x] [T-053] [P] [P1] Tests `debt_hero_widget_test.dart` via `forEachTheme` : présence `Key('debt_hero')` (SC-005), skeleton (SC-006), date-label "En retard" couleur `expenseColor` + date-label "Aujourd'hui" couleur `AppColors.amber` (SC-007), dark + light (SC-010) — Réf: NFR-001, SC-005, SC-006, SC-007, SC-010

- [x] [T-054] [P1] Validation finale : `flutter test` exit 0 (≥ 10 tests) (NFR-001) ; `flutter analyze lib/src/features/` exit 0 (SC-008) ; grep no-hex exit 0 (SC-009) ; `grep -rn "ChoiceChip" flutter/lib/src/features/` → 0 (SC-003) ; `grep -rn "TODO KKS-240" flutter/lib/` → 0 (SC-011) ; `grep -rn "SectionHeaderSticky" flutter/lib/src/features/{transactions,subscriptions,debts}/` → ≥ 1 par feature (SC-004) — Réf: NFR-001, NFR-002, SC-001, SC-003, SC-004, SC-008, SC-009, SC-011

- [x] [T-055] [P] [P1] Tests screens (SectionHeaderSticky runtime + navigation) : pour `transaction_list_screen_test.dart`, `subscription_list_screen_test.dart`, `debt_list_screen_test.dart` — via `ProviderScope` + overrides, `forEachTheme` obligatoire — vérifier que `SectionHeaderSticky` est rendu dans l'arbre de widgets (SC-004) ; pour les 4 screens (incl. `dashboard_screen_test.dart`) vérifier que le tap sur un item déclenche `GoRouter.push()` via `MockGoRouter` (SC-012) — Réf: NFR-001, SC-004, SC-012

**Checkpoint** : `flutter test` exit 0, ≥ 10 tests passés. `flutter analyze` exit 0. 0 ChoiceChip, 0 TODO KKS-240, 0 hex hardcodé, 0 LinearGradient dans dashboard_hero_widget.dart. SC-012 couvert dans 4 screen tests.

---

## Phase 5 : Dependencies & Execution Order

### Graphe de dépendances

```
T-001
  └─ T-010 (vérification suppressions)
       ├─ T-020 [P] (DashboardHeroWidget)
       │    └─ T-021 (DashboardScreen + suppressions)
       │         └─ T-050 [P] (tests dashboard)
       │
       ├─ T-022 [P] (TransactionHeroWidget)
       │    └─ T-023 (TransactionListScreen)
       │         └─ T-051 [P] (tests transaction)
       │
       ├─ T-024 [P] (TransactionDayGroup — peut démarrer avec T-022)
       │    └─ T-023 (doit être complété avant T-023)
       │
       ├─ T-025 [P] (SubscriptionHeroWidget)
       │    └─ T-026 (SubscriptionListScreen)
       │         └─ T-052 [P] (tests subscription)
       │
       └─ T-027 [P] (DebtHeroWidget)
            └─ T-028 (DebtListScreen)
                 └─ T-053 [P] (tests debt)

T-021 + T-023 + T-026 + T-028 → T-055 [P] (tests screens SC-004 + SC-012)

T-050 + T-051 + T-052 + T-053 + T-055 → T-054 (validation finale)
```

### US Dependencies

| User Story | Tâches | Dépend de |
|------------|--------|-----------|
| US-001 — Dashboard hero flat | T-020, T-021 | T-001, T-010 |
| US-002 — Transactions hero + groupement | T-022, T-023, T-024 | T-001, T-010 |
| US-003 — Abonnements hero + sections | T-025, T-026 | T-001, T-010 |
| US-004 — Dettes hero + groupement temporel | T-027, T-028 | T-001, T-010 |

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|----------------------|-----------|
| G1 | T-020, T-022, T-024, T-025, T-027 | T-010 complété — 4 heros + retrait header créés en parallèle |
| G2 | T-021, T-023, T-026, T-028 | Chaque screen dépend uniquement de son hero (T-020→T-021, T-022+T-024→T-023, T-025→T-026, T-027→T-028) |
| G3 | T-050, T-051, T-052, T-053, T-055 | T-021+T-023+T-026+T-028 complétés — 5 suites de tests en parallèle |

---

## Implementation Strategy

### MVP First

- **MVP** : T-001 → T-010 → T-020 + T-022 + T-025 + T-027 (4 heros)
  Valeur : les 4 hero widgets peuvent être intégrés visuellement. Les screens gardent encore leurs ChoiceChips mais les heros sont prêts.

- **Itération 2** : T-021 + T-023 + T-024 + T-026 + T-028 (4 screens refactorisés)
  Valeur : anti-patterns supprimés, groupements fonctionnels, spec pleinement implémentée.

- **Itération 3** : T-050 + T-051 + T-052 + T-053 + T-055 + T-054 (tests + validation)
  Valeur : filet de sécurité pour les futures évolutions, SC-012 navigation couvert.

### Incremental Delivery

| Livraison | Tâches | Valeur délivrée |
|-----------|--------|----------------|
| L1 — Setup | T-001, T-010 | Branche prête, suppressions validées, analyse 0 warning |
| L2 — 4 Heros | T-020, T-022, T-025, T-027 | Widgets hero testables indépendamment |
| L3 — Dashboard | T-021 | US-001 complète : PatrimoineCard supprimée, hero câblé |
| L4 — Transactions | T-024, T-023 | US-002 complète : ChoiceChips supprimés, groupement sémantique fonctionnel |
| L5 — Abonnements | T-026 | US-003 complète : ChoiceChips supprimés, Actifs/Inactifs fonctionnels |
| L6 — Dettes | T-028 | US-004 complète : ChoiceChips supprimés, groupement temporel fonctionnel |
| L7 — Tests | T-050, T-051, T-052, T-053, T-055, T-054 | Couverture complète (hero + screen + navigation), prêt review-impl |

---

## Mapping Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| FR-001 (suppression PatrimoineCard + IncomeExpenseCards) | T-021 |
| FR-002 (DashboardHeroWidget flat) | T-020 |
| FR-003 (conservation logique métier dashboard) | T-020, T-021 |
| FR-004 (suppression ChoiceChip Transactions) | T-023 |
| FR-005 (TransactionHeroWidget) | T-022 |
| FR-006 (SectionHeaderSticky global + groupement sémantique Transactions) | T-023 |
| FR-007 (retrait header TransactionDayGroup) | T-024 |
| FR-008 (suppression ChoiceChip Abonnements) | T-026 |
| FR-009 (SubscriptionHeroWidget) | T-025 |
| FR-010 (SectionHeaderSticky global + date-labels Actifs/Inactifs) | T-026 |
| FR-011 (suppression ChoiceChip Dettes) | T-028 |
| FR-012 (DebtHeroWidget) | T-027 |
| FR-013 (SectionHeaderSticky global + groupement temporel Dettes) | T-028 |
| FR-014 (Keys structurelles) | T-020, T-022, T-025, T-027 |
| FR-015 (tokens exclusivement) | T-020, T-022, T-025, T-027 |
| FR-016 (skeleton loading) | T-020, T-022, T-025, T-027 |
| FR-017 (suppression TODO KKS-240) | T-021, T-023, T-026, T-028 |
| NFR-001 (≥ 10 tests) | T-050, T-051, T-052, T-053, T-054 |
| NFR-002 (analyze exit 0) | T-054 |
| NFR-003 (aucune modification notifier) | T-021, T-023, T-026, T-028 |
| NFR-004 (dépendances KKS-237+238) | T-001 |
| NFR-005 (documentation ///) | T-020, T-022, T-025, T-027 |
| SC-001 à SC-011 | T-050, T-051, T-052, T-053, T-054 |
| SC-012 (navigation tap → GoRouter.push()) | T-055 |

---

## Résumé

| Phase | Total | P1 | P2 | P3 | Parallélisables |
|-------|-------|----|----|----|-----------------|
| Setup | 1 | 1 | 0 | 0 | 0 |
| Fondations | 1 | 1 | 0 | 0 | 0 |
| User Stories P1 | 9 | 9 | 0 | 0 | 5 (T-020, T-022, T-024, T-025, T-027) |
| Polish | 6 | 6 | 0 | 0 | 5 (T-050, T-051, T-052, T-053, T-055) |
| **Total** | **17** | **17** | **0** | **0** | **10** |
