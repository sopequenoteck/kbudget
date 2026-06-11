# Plan — KKS-252 : Budgets liste Flutter (alignement DESIGN.md v5)

**Issue**: KKS-252 | **Branch**: `develop` | **Date**: 2026-05-21  
**Spec**: [spec.md](spec.md) | **Clarify**: [clarify-log.md](clarify-log.md) | **Research**: [research.md](research.md)

---

## Constitution Check

| Principe | Applicable | Statut | Notes |
|----------|-----------|--------|-------|
| I — API-First / Local-First | Non | ✅ N/A | Aucun endpoint REST ni schéma Drift modifié. NFR-001 confirmé : couches data/domain intactes |
| II — Sécurité | Non | ✅ N/A | Pas de routes, pas de secrets, pas de données cross-user |
| III — Simplicité & YAGNI | Oui | ✅ PASS | `_BudgetHeroWidget`, `_DoughnutMini`, `DoughnutSegment` tous privés dans le screen. `_showInactive` supprimé. `BudgetSummaryBar` retiré du screen. Aucun nouveau provider |
| IV — Mobile-First UX | Oui | ✅ PASS | SectionHeaderSticky, séparation actifs/inactifs, DoughnutMini compact 80px, CurrencyPillSelector en hero top-row |
| V — Testabilité | Oui | ✅ PASS | NFR-007 : 4 overrides test définis. Timer debounce testable via `fakeAsync + pump(Duration(seconds: 2))` |
| VI — Observabilité | Oui | ✅ PASS | Aucun `print()` introduit |
| VII — Two Trajectories | Non | ✅ N/A | Trajectoire B uniquement — pas d'impact API REST ni sync Drift |

**Résultat : PASS — aucune gate violée.**

---

## Complexity Tracking

| # | Complexité | Justification | Alternative envisagée |
|---|-----------|---------------|----------------------|
| CX-001 | Import cross-feature `CurrencyPillSelector` (features/dashboard → features/budgets) | Évite duplication de code (NFR-002). Pattern déjà utilisé dans la codebase (`budget_category_detail_sheet.dart` importé ailleurs). Angular fait de même. | Déplacer vers `common_widgets/` — hors scope, risque régression dashboard |
| CX-002 | `dart:async Timer` cancelable pour debounce 2s | Mécanisme minimal, pas de dépendance RxDart. Pattern identique à `dashboard_screen.dart`. Testable via `fakeAsync` | RxDart debounce — nouvelle dépendance non nécessaire |
| CX-003 | `categoryNotifierProvider` ajouté comme dépendance screen | Seule source disponible de `Category.isSystem` sans modifier le domain. Chargement conditionnel dans `initState` | Nouveau provider dérivé — prématuré pour un calcul local à un écran |

---

## Résumé de l'approche

Refonte complète de `budget_list_screen.dart` (419 lignes) pour alignement sur la source de vérité Angular. Trois livrables principaux : (1) `_BudgetHeroWidget` (privé) — remplace `BudgetSummaryBar`, intègre `_DoughnutMini` fl_chart, `CurrencyPillSelector`, conversion temps réel, méta-lignes ; (2) state screen enrichi — ajout `_activeCurrency: Currency` (setState local) + `_debounceTimer: Timer?` (cancelable), suppression `_showInactive` ; (3) liste restructurée — `SectionHeaderSticky` avec actions conditionnelles, séparation actifs/inactifs (mois courant uniquement), conversion devise en temps réel dans `build()`. Aucune modification des couches data/domain/repository.

---

## Contexte technique

**Language/Version** : Dart >= 3.6 / Flutter >= 3.27  
**Primary Dependencies** : flutter_riverpod, fl_chart `^0.70.2`, phosphor_flutter `^2.1.0`, shimmer `^3.0.0`, dart:async (Timer)  
**Storage** : N/A — aucun schéma Drift modifié, aucun endpoint REST modifié  
**Testing** : flutter_test + widget tests (ProviderContainer overrides)  
**Target Platform** : iOS + Android (Trajectoire B — Standalone Commercial)  
**Project Type** : Mobile app — refonte visuelle + UX  
**Performance Goals** : N/A — écran avec < 20 budgets typiquement  
**Constraints** : NFR-001 — `BudgetRepository`, `Budget`, `BudgetOverview`, `BudgetHistory`, DTOs non modifiés

---

## Architecture — Fichiers impactés

### Modifications (M)

| Fichier | Nature | FR/NFR couverts |
|---------|--------|----------------|
| `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` | Refonte complète — hero widget, DoughnutMini, CurrencyPillSelector, debounce, SectionHeaderSticky, séparation inactifs | FR-001 → FR-018, NFR-001 → NFR-007 |
| `flutter/test/src/features/budgets/presentation/budget_list_screen_test.dart` | Adaptation tests existants + nouveaux cas (hero montant, DoughnutMini, debounce, inactifs, allCategoriesHaveBudget) | NFR-007 |

### Aucun fichier à créer

Tous les nouveaux widgets (`_BudgetHeroWidget`, `_DoughnutMini`, `DoughnutSegment`, `_InactiveLabel`) sont des classes privées dans `budget_list_screen.dart`.

---

## Approche détaillée par composant

### 1. State screen — ajouts et suppressions

**FR couverts** : NFR-001, CL-005 (research)

#### 1.1 Nouvelles variables d'état

```dart
// Ajouts dans _BudgetListScreenState
Currency _activeCurrency = Currency.eur; // setState local (CL-005, RES-001)
Timer? _debounceTimer;                   // debounce 2s (FR-008, CX-002)
```

#### 1.2 Suppression

- `bool _showInactive = false;` → supprimé (A-004 spec)

#### 1.3 `initState()` enrichi

```dart
@override
void initState() {
  super.initState();
  final now = DateTime.now();
  _selectedMonth = now.month;
  _selectedYear = now.year;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final budgetState = ref.read(budgetNotifierProvider);
    if (budgetState.items.isEmpty && !budgetState.isLoading) {
      ref.read(budgetNotifierProvider.notifier).loadItems(includeInactive: true); // toujours true
    }
    ref.read(budgetNotifierProvider.notifier).loadOverview();

    // initialiser activeCurrency depuis dashboardState (FR-007, CL-005)
    final dashState = ref.read(dashboardNotifierProvider);
    if (dashState.currencies.isNotEmpty) {
      setState(() => _activeCurrency = dashState.currencies.first);
    }

    // charger categories si nécessaire (RES-004)
    final catState = ref.read(categoryNotifierProvider);
    if (catState.items.isEmpty && !catState.isLoading) {
      ref.read(categoryNotifierProvider.notifier).loadItems();
    }
  });
}
```

#### 1.4 `dispose()` enrichi

```dart
@override
void dispose() {
  _debounceTimer?.cancel(); // CX-002
  super.dispose();
}
```

---

### 2. Providers watchés dans `build()`

**FR couverts** : FR-001, FR-007, FR-009, FR-011, NFR-005

```dart
@override
Widget build(BuildContext context) {
  final state = ref.watch(budgetNotifierProvider);
  final dashboardState = ref.watch(dashboardNotifierProvider);
  final exchangeRateState = ref.watch(exchangeRateListProvider);
  final categoryState = ref.watch(categoryNotifierProvider);
  // ...
}
```

---

### 3. Helper `_convertAmount()` et calculs dans `build()`

**FR couverts** : FR-001, FR-009, NFR-005 (RES-001)

Calcul dans `build()` — pattern identique à `_MonthlySummaryCard` dans `recurring_list_screen.dart` :

```dart
double _convertAmount(double amount, String fromCurrencyStr) {
  final fromCurrency = Currency.values.firstWhereOrNull(
    (c) => c.name.toUpperCase() == fromCurrencyStr.toUpperCase(),
  );
  if (fromCurrency == null || fromCurrency == _activeCurrency) return amount;
  return CurrencyConverter.convert(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: _activeCurrency,
        rates: ref.read(exchangeRateListProvider).items,
      ) ??
      amount;
}
```

Calculs dérivés dans `build()` (post-`if isLoading/error`):

```dart
// Hero (FR-001)
final budgetedSpent = _convertAmount(data.totalSpent - data.unbudgetedTotal, data.currency);
final convertedUnbudgeted = _convertAmount(data.unbudgetedTotal, data.currency);

// Ligne heroConverted (FR-002)
final devise2 = dashboardState.currencies.length >= 2
    ? dashboardState.currencies.firstWhere((c) => c != _activeCurrency, orElse: () => Currency.eur)
    : null;
final heroConverted = (devise2 != null && _activeCurrency != devise2)
    ? CurrencyConverter.convert(amount: budgetedSpent, fromCurrency: _activeCurrency, toCurrency: devise2, rates: exchangeRateState.items)
    : null;

// Items actifs convertis (FR-009, RES-001)
final convertedItems = state.overview?.items.map((item) {
  final depense = _convertAmount(item.montantDepense, item.currency ?? data.currency);
  final budget = _convertAmount(item.montantBudgetNormalise ?? item.montantBudget, item.currency ?? data.currency);
  return (item: item, depense: depense, budget: budget);
}).toList() ?? [];

// Items inactifs (FR-013, RES-002) — mois courant uniquement
final inactiveItems = isCurrentMonth
    ? state.items.where((b) => !b.actif).toList()
    : <Budget>[];

// DoughnutMini segments (FR-003, RES-003)
final doughnutSegments = convertedItems
    .where((e) => e.depense > 0)
    .map((e) => DoughnutSegment(value: e.depense, color: e.item.categoryCouleur ?? ''))
    .toList();

// allCategoriesHaveBudget (FR-011, RES-004)
final nonSystemCats = categoryState.items.where((c) => !c.isSystem).toList();
final budgetedIds = state.items.where((b) => b.actif).map((b) => b.categoryId).toSet();
final allCategoriesHaveBudget = nonSystemCats.isNotEmpty &&
    nonSystemCats.every((c) => budgetedIds.contains(c.id));
```

---

### 4. `DoughnutSegment` + `_DoughnutMini` — US4

**FR couverts** : FR-003, NFR-003 (RES-003)

```dart
class DoughnutSegment {
  const DoughnutSegment({required this.value, required this.color});
  final double value;
  final String color; // hex String, ex: "#E91E63"
}

class _DoughnutMini extends StatelessWidget {
  const _DoughnutMini({required this.segments});
  final List<DoughnutSegment> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final fallback = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      width: 80, height: 80,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 26, // RES-003 : ratio 65% centre
          sectionsSpace: 1,
          sections: segments.map((s) {
            final color = parseHexColor(s.color)?.withValues(alpha: 0.7) ?? fallback;
            return PieChartSectionData(
              value: s.value,
              color: color,
              showTitle: false,
              radius: 14,
            );
          }).toList(),
        ),
      ),
    );
  }
}
```

---

### 5. `_BudgetHeroWidget` — US1

**FR couverts** : FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007

Widget privé `StatelessWidget`. Il remplace `BudgetSummaryBar` dans le screen.

Structure visuelle :

```
┌─────────────────────────────────────┐
│ MonthSelector ←──────── CurrencyPills│  ← top-row (FR-006, FR-007)
│                                     │
│  [montant budgetedSpent]  [DoughnutMini 80px]  ← hero row (FR-001, FR-003)
│  [≈ X devise2]                      │  ← heroConverted si applicable (FR-002)
│  ⚠ N en dépassement · N budgets     │  ← méta-ligne (FR-004)
│  📥 X non budgété          (tap→)   │  ← méta non budgété si > 0 (FR-005)
└─────────────────────────────────────┘
```

Interface :

```dart
class _BudgetHeroWidget extends StatelessWidget {
  const _BudgetHeroWidget({
    required this.budgetedSpent,
    required this.activeCurrency,
    required this.heroConverted,         // nullable
    required this.heroConvertedCurrency, // nullable
    required this.overBudgetCount,
    required this.budgetCount,
    required this.unbudgetedTotal,
    required this.doughnutSegments,
    required this.currencies,
    required this.onCurrencyChanged,
    required this.onUnbudgetedTap,
    // MonthSelector params
    required this.selectedMonth,
    required this.selectedYear,
    required this.isCurrentMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
  });
  // ...
}
```

Lignes méta :
- Dépassements : `overBudgetCount > 0` → afficher "⚠ $overBudgetCount en dépassement · " (sinon rien)
- Count : toujours "$budgetCount budgets"
- Non budgété (FR-005) : `unbudgetedTotal > 0` → `GestureDetector(onTap: onUnbudgetedTap)` sur la ligne

---

### 6. Gestion devise — US2

**FR couverts** : FR-007, FR-008, NFR-005 (CX-002)

Handler `_onCurrencyChanged` dans `_BudgetListScreenState` :

```dart
void _onCurrencyChanged(Currency currency) {
  setState(() => _activeCurrency = currency); // rebuildimmédiat (FR-008)
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(seconds: 2), () async {
    // Persistance (FR-008)
    await ref.read(dashboardNotifierProvider.notifier).updateActiveCurrency(currency);
    // Rechargement taux
    ref.read(exchangeRateListProvider.notifier).loadItems();
    // Rechargement données budgets
    ref.read(budgetNotifierProvider.notifier).loadOverview(
      month: _selectedMonth, year: _selectedYear,
    );
  });
}
```

---

### 7. `SectionHeaderSticky` + actions — US3

**FR couverts** : FR-010, FR-011, FR-012, NFR-004 (RES-002, RES-004)

```dart
SectionHeaderSticky(
  title: 'Budgets',
  count: convertedItems.length,  // actifs uniquement
  actions: [
    // Bouton Tray (FR-012) — si unbudgetedTotal > 0
    if (data.unbudgetedTotal > 0)
      IconButton(
        icon: PhosphorIcon(PhosphorIconsRegular.tray),
        onPressed: () => _openUnbudgetedSheet(context),
      ),
    // Bouton "+" (FR-011) — masqué si !isCurrentMonth
    if (isCurrentMonth)
      IconButton(
        icon: PhosphorIcon(PhosphorIconsRegular.plus),
        onPressed: allCategoriesHaveBudget
            ? null       // désactivé (onPressed: null = grisé)
            : () => _openCreateBudgetModal(context),
      ),
  ],
)
```

---

### 8. Liste items — séparation actifs/inactifs

**FR couverts** : FR-009, FR-013, FR-014, FR-015 (RES-002)

Structure `CustomScrollView` avec `SliverList` :

```dart
// Items actifs
SliverList(
  delegate: SliverChildBuilderDelegate(
    (ctx, i) => BudgetItem(
      item: convertedItems[i].item,
      convertedDepense: convertedItems[i].depense,
      convertedBudget: convertedItems[i].budget,
      onTap: () => _openBudgetModal(context, convertedItems[i].item),
    ),
    childCount: convertedItems.length,
  ),
),

// Label "Inactifs" + items inactifs (FR-013) — mois courant uniquement
if (inactiveItems.isNotEmpty) ...[
  SliverToBoxAdapter(child: _InactiveLabel()),
  SliverList(
    delegate: SliverChildBuilderDelegate(
      (ctx, i) => Opacity(
        opacity: 0.5,
        child: BudgetItem(
          item: inactiveItems[i],  // Budget (pas BudgetOverviewItem)
          convertedDepense: 0,     // pas de montant dépensé
          convertedBudget: _convertAmount(inactiveItems[i].montant, inactiveItems[i].currency ?? ''),
          onTap: null,             // non tappable (FR-015)
          showProgressBar: false,  // sans barre (FR-013)
        ),
      ),
      childCount: inactiveItems.length,
    ),
  ),
],
```

`_InactiveLabel` : widget privé `StatelessWidget` affichant "Inactifs" (style `date-label`).

---

### 9. `BudgetItem` — interface étendue

**FR couverts** : FR-009, FR-013, FR-014, FR-015

`BudgetItem` nécessite des paramètres supplémentaires pour supporter les items inactifs :
- `onTap: VoidCallback?` — déjà nullable ?
- `showProgressBar: bool = true` — nouveau flag
- `convertedDepense: double` — montant dépensé converti (0 pour inactifs)
- `convertedBudget: double` — montant budget converti

Barre 3 états (FR-014) — inchangée logiquement, couleur selon ratio :
- `< 0.8` → `categoryCouleur` (parseHexColor)
- `0.8 – 1.0` → `AppThemeExtension.textWarning`
- `> 1.0` → `AppThemeExtension.expenseColor`

---

### 10. Skeleton + Empty State + Error

**FR couverts** : FR-016, FR-017, FR-018

- **Loading** : `state.isLoading && state.overview == null && state.history == null` → skeleton existant (adapter si besoin hero)
- **Empty** : `convertedItems.isEmpty && data.unbudgetedTotal == 0` → `EmptyStateWidget(icon: ..., message: '...', ctaLabel: 'Créer un budget', onCtaTap: () => _openCreateBudgetModal(context))`
- **Error** : `state.error != null && state.overview == null` → `EmptyStateWidget(ctaLabel: 'Réessayer', onCtaTap: () => ref.read(budgetNotifierProvider.notifier).loadOverview(...))`

---

### 11. Tests widget — adaptations NFR-007

**FR couverts** : NFR-007 (SC-001 → SC-006)

Setup `buildApp()` devra ajouter les overrides :
- `budgetNotifierProvider` — mock state avec overview et items
- `dashboardNotifierProvider` — mock state avec currencies
- `exchangeRateListProvider` — mock taux (ou liste vide)
- `categoryNotifierProvider` — mock catégories

Nouveaux cas de test :
- `should_display_budgetedSpent_when_totalSpent_minus_unbudgeted` (SC-001)
- `should_show_doughnutMini_when_segments_not_empty` (SC-002)
- `should_hide_doughnutMini_when_all_montantDepense_zero` (SC-002)
- `should_debounce_persistance_after_2s` (SC-003 — `fakeAsync`)
- `should_show_inactive_label_when_inactive_budgets_present` (SC-004)
- `should_hide_inactive_section_in_history_mode` (SC-004)
- `should_disable_plus_button_when_allCategoriesHaveBudget` (SC-005)
- `should_hide_plus_button_when_not_current_month` (SC-005)

---

## Risques & Mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|------------|
| `BudgetItem` API incompatible avec les paramètres étendus (`showProgressBar`, `convertedDepense`) | Moyen | Moyen | Lire `budget_item.dart` avant de modifier — adapter l'interface en place si nécessaire |
| `loadOverview()` dans `_onCurrencyChanged` ne supporte pas `month`/`year` params | Faible | Haut | Vérifier la signature de `loadOverview` dans `budget_notifier.dart` avant l'implémentation |
| `CurrencyConverter.convert()` retourne null si taux absent → fallback nominal | Certain | Bas | Déjà géré avec `?? amount` dans `_convertAmount()` — pattern existant |
| `categoryNotifierProvider.notifier.loadItems()` signature différente de `budgetNotifierProvider` | Faible | Moyen | Vérifier l'API du notifier avant l'appel dans `initState` |
| Tests `fakeAsync` + Timer pour debounce 2s — nécessite import `dart:async` dans le test | Faible | Bas | `fakeAsync` et `pump(Duration(seconds: 2))` — pattern standard Flutter test |
| `BudgetHistory` vs `BudgetOverview` : champ `items` est `List<BudgetHistoryItem>` vs `List<BudgetOverviewItem>` — types différents | Moyen | Haut | Les deux types ont les mêmes champs utilisés (A-001 validée). Vérifier le type de retour de `data.items` selon `isCurrentMonth` — cast ou branche if |

---

## Hors scope

- Création de budgets (formulaire modal — déjà fonctionnel)
- Navigation vers `BudgetDetailScreen` par item (FR-015 : modal conservée)
- `UnbudgetedDetailSheet` : déjà existant, aucune modification
- Modification de `BudgetRepository`, `Budget`, `BudgetOverview`, `BudgetHistory`, DTOs (NFR-001)
- Déplacer `CurrencyPillSelector` vers `common_widgets/` (hors scope, risque régression)
- Pagination des budgets (pas de pagination API)
- Tests notifier (aucun notifier modifié)

---

## Artefacts complémentaires

| Artefact | Fichier | Généré | Justification |
|----------|---------|--------|---------------|
| Research | [research.md](./research.md) | Oui | 5 inconnues techniques résolues (RES-001 → RES-005) |
| Data Model | — | Non | Pas d'entité nouvelle — `DoughnutSegment` est un DTO interne au widget |
| Quickstart | [quickstart.md](./quickstart.md) | Oui | Guide d'implémentation par phase |
