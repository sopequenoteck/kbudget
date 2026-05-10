# Plan — KKS-240 : Phase 1 / Étape 4 — Refonte 4 écrans liste Flutter

> Date : 2026-05-10
> Issue : KKS-240
> Spec : [spec.md](./spec.md)
> Research : [research.md](./research.md)

---

## Constitution Check

| Gate | Statut | Commentaire |
|------|--------|-------------|
| I. API-First / Local-First | ✅ PASS | Refonte purement UI — aucun nouvel endpoint, aucune migration Drift. Les notifiers existants (Drift local-first) ne sont pas modifiés (NFR-003) |
| II. Sécurité par défaut | ✅ PASS | Hors scope — pas de nouvelles routes, pas d'accès données sensibles |
| III. Simplicité & YAGNI | ✅ PASS | StatelessWidget avec paramètres (RES-001), méthodes privées pour groupements (RES-004/005), pas d'abstraction partagée pour les `date-label` (RES-002 pattern inline) |
| IV. Mobile-First UX | ✅ PASS | Le hero flat est optimisé mobile (pas de gradient coûteux en rendu, lecture rapide) |
| V. Testabilité | ✅ PASS | Chaque hero = StatelessWidget testable isolément avec paramètres. Pattern `forEachTheme` obligatoire. 10 tests minimum (NFR-001) |
| VI. Observabilité | ✅ PASS | Aucun nouveau log requis — refonte purement présentationnelle |
| VII. Trajectoire B — Standalone | ✅ PASS | Refonte UI Flutter uniquement. Aucune implication store, versioning ou IAP |

### Dérogations

Aucune dérogation — tous les principes sont respectés.

### Complexity Tracking

| # | Complexité | Justification | Alternative envisagée |
|---|-----------|---------------|----------------------|
| CX-001 | Algorithme groupement sémantique Transactions (5 buckets, calcul `startOfWeek`) | FR-006 exige une parité avec Angular — le groupement sémantique est la valeur centrale de cette US | Groupement par jour (existant) — rejeté car anti-pattern DESIGN.md v5 |
| CX-002 | Algorithme groupement temporel Dettes (7 buckets par `dueDate`) | FR-013 + alignement Angular. La complexité est O(n) et concentrée dans une méthode privée de 25 lignes | Groupement Prêts/Emprunts (existant) — rejeté car choix utilisateur (session clarify) |
| CX-003 | Calcul patrimoine + variation + devise secondaire migré depuis `PatrimoineCard` | Migration obligatoire — `PatrimoineCard` est `@Deprecated` et supprimée. La logique est copiée sans modification | Déléguer au `DashboardNotifier` — rejeté car NFR-003 |

---

## Résumé de l'approche

Refonte en **4 livrables parallèles** (un par écran), chacun constitué de : (1) un nouveau hero `StatelessWidget` remplaçant la summary card existante, (2) une modification de l'écran hôte pour intégrer `SectionHeaderSticky` global + suppression des `ChoiceChip` + nouveau groupement. Aucun notifier, aucun modèle, aucune couche data ne sont modifiés. Les tests couvrent les 4 heros via `forEachTheme`.

---

## Contexte technique

- **Stack** : Flutter 3.27 / Dart 3.6, Riverpod, Freezed, `shimmer`, `phosphor_flutter`, `collection`
- **Dépendances nouvelles** : aucune
- **Dépendances existantes impactées** : `SectionHeaderSticky` (KKS-238), `AppThemeExtension` (KKS-237), `AmountFormatter`, `CurrencyConverter`

---

## Architecture

### Structure des fichiers impactés

```
flutter/
├── lib/src/features/
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── dashboard_screen.dart                          (M) — remplace PatrimoineCard + IncomeExpenseCards
│   │       └── widgets/
│   │           ├── patrimoine_card.dart                       (D) — suppression (deprecated)
│   │           ├── income_expense_cards.dart                  (D) — suppression
│   │           └── dashboard_hero_widget.dart                 (C) — nouveau hero flat
│   │
│   ├── transactions/
│   │   └── presentation/
│   │       ├── transaction_list_screen.dart                   (M) — hero + SectionHeaderSticky + groupement sémantique + sup. ChoiceChips
│   │       └── widgets/
│   │           ├── transaction_hero_widget.dart               (C) — nouveau hero solde mensuel
│   │           └── transaction_day_group.dart                 (M) — retrait header date interne
│   │
│   ├── subscriptions/
│   │   └── presentation/
│   │       ├── subscription_list_screen.dart                  (M) — hero + SectionHeaderSticky + date-labels Actifs/Inactifs + sup. ChoiceChips
│   │       └── widgets/
│   │           └── subscription_hero_widget.dart              (C) — nouveau hero total mensuel
│   │
│   └── debts/
│       └── presentation/
│           ├── debt_list_screen.dart                          (M) — hero + SectionHeaderSticky + groupement temporel + sup. ChoiceChips + sup. _SectionHeader
│           └── widgets/
│               └── debt_hero_widget.dart                      (C) — nouveau hero solde net
│
└── test/src/features/
    ├── dashboard/presentation/widgets/
    │   └── dashboard_hero_widget_test.dart                    (C)
    ├── transactions/presentation/widgets/
    │   └── transaction_hero_widget_test.dart                  (C)
    ├── subscriptions/presentation/widgets/
    │   └── subscription_hero_widget_test.dart                 (C)
    └── debts/presentation/widgets/
        └── debt_hero_widget_test.dart                         (C)

Légende : C = Créer, M = Modifier, D = Supprimer
```

### Flux de données par écran

```
DashboardScreen (ConsumerStatefulWidget)
  └── watch(dashboardNotifierProvider) → state
      ├── DashboardHeroWidget(
      │     accounts: state.accounts,
      │     activeCurrency: state.activeCurrency,
      │     exchangeRates: exchangeRateState.items,
      │     currencies: state.currencies,
      │     currentSummary: state.currentSummary,
      │     isLoading: state.isLoading,
      │   )  [Key('dashboard_hero')]
      └── ...sections existantes (BudgetSummary, RecentTransactions)

TransactionListScreen (ConsumerStatefulWidget)
  └── watch(transactionListNotifierProvider) → state
      ├── TransactionHeroWidget(
      │     summary: state.summary,
      │     primaryCurrency: primaryCurrency,
      │     isLoading: state.isLoading,
      │   )  [Key('transaction_hero')]
      ├── SectionHeaderSticky(title: 'Transactions')
      └── SliverList → date-label + TransactionDayGroup (sans header)

SubscriptionListScreen (ConsumerStatefulWidget)
  └── watch(subscriptionNotifierProvider) → state
      ├── SubscriptionHeroWidget(
      │     monthlyTotals: state.monthlyTotals,
      │     activeCount: state.items.where((s) => s.actif).length,
      │     isLoading: state.isLoading,
      │   )  [Key('subscription_hero')]
      ├── SectionHeaderSticky(title: 'Abonnements · $activeCount actifs')
      └── SliverList → date-label "Actifs" + items actifs + date-label "Inactifs" + items inactifs

DebtListScreen (ConsumerStatefulWidget)
  └── watch(debtNotifierProvider) → state
      ├── kEnCours = state.items.where((d) => !d.rembourse).length
      ├── DebtHeroWidget(
      │     summary: state.summary,
      │     primaryCurrency: primaryCurrency,
      │     enCours: kEnCours,
      │     isLoading: state.isLoading,
      │   )  [Key('debt_hero')]
      ├── SectionHeaderSticky(title: 'Dettes · $kEnCours en cours')
      └── SliverList → date-label par bucket + DebtItem
```

---

## Approche par composant

### T-1 — DashboardHeroWidget

- **Responsabilité** : Afficher patrimoine total flat (sans gradient), variation mensuelle badgée, meta-lines revenus/dépenses, conversion devise secondaire. Remplace `PatrimoineCard` + `IncomeExpenseCards`.
- **Fichier** : `flutter/lib/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart` (C)
- **Requirements couverts** : FR-001, FR-002, FR-003, FR-015 (tokens), FR-016 (skeleton)
- **Approche** :
  - `StatelessWidget` avec `key: const Key('dashboard_hero')` (FR-014)
  - Paramètres : `accounts`, `activeCurrency`, `exchangeRates`, `currencies`, `currentSummary`, `isLoading`
  - Si `isLoading: true` → `_DashboardHeroSkeleton` (key: `Key('dashboard_hero_skeleton')`)
  - Logique patrimoine migrée de `PatrimoineCard.build()` sans modification (CX-003)
  - Montant : `AppTypography.size3xl` / bold / `themeExt.incomeColor` si ≥ 0, sinon `themeExt.expenseColor` (FR-002)
  - Badge variation : `Container(decoration: BoxDecoration(color: variationColor.withValues(alpha: 0.15), borderRadius: AppRadius.round))` + texte sm/medium (same pattern PatrimoineCard)
  - Meta-line revenus : `Row { PhosphorIcon(PhosphorIconsRegular.trendUp, size: 14), Text(totalRecettes, incomeColor) }`
  - Meta-line dépenses : `Row { PhosphorIcon(PhosphorIconsRegular.trendDown, size: 14), Text(totalDepenses, expenseColor) }`
  - Conversion secondaire : `Text('≈ X devise', xs/onSurfaceVariant)` si `patrimoineSecondaire != null`
  - Fond : transparent (pas de `BoxDecoration`) — `LinearGradient` INTERDIT (FR-002, SC-002)
  - Documentation `///` avec exemple complet (NFR-005)

### T-2 — DashboardScreen : suppression + câblage

- **Responsabilité** : Supprimer `PatrimoineCard` + `IncomeExpenseCards`, câbler `DashboardHeroWidget`.
- **Fichiers** : `dashboard_screen.dart` (M), `patrimoine_card.dart` (D), `income_expense_cards.dart` (D)
- **Requirements couverts** : FR-001, FR-003
- **Approche** :
  - Supprimer les imports de `PatrimoineCard` et `IncomeExpenseCards`
  - Remplacer le bloc `if (state.currencies.length > 1)... PatrimoineCard + IncomeExpenseCards` par `DashboardHeroWidget(...)` unique
  - `previousSummary` (utilisé par `IncomeExpenseCards` pour delta) n'est plus nécessaire — les delta par card revenus/dépenses sont abandonnés (CL-002)
  - Supprimer physiquement `patrimoine_card.dart` et `income_expense_cards.dart` (FR-001, SC-001)

### T-3 — TransactionHeroWidget

- **Responsabilité** : Afficher solde mensuel (revenus - dépenses), meta-lines revenus/dépenses.
- **Fichier** : `flutter/lib/src/features/transactions/presentation/widgets/transaction_hero_widget.dart` (C)
- **Requirements couverts** : FR-005, FR-015, FR-016
- **Approche** :
  - `StatelessWidget` avec `key: const Key('transaction_hero')`
  - Paramètres : `summary: MonthlySummary?`, `primaryCurrency: Currency?`, `isLoading: bool`
  - Bilan = `(summary?.totalRecettes ?? 0) - (summary?.totalDepenses ?? 0)` → label "SOLDE"
  - Montant `size3xl`/bold : `incomeColor` si ≥ 0, `expenseColor` si < 0
  - Meta-line revenus : `PhosphorTrendUp` 14px + montant `incomeColor`
  - Meta-line dépenses : `PhosphorTrendDown` 14px + montant `expenseColor`
  - Skeleton : `_TransactionHeroSkeleton` — `Container(height: 96)` + `Shimmer.fromColors`

### T-4 — TransactionListScreen : refonte complète

- **Responsabilité** : Supprimer ChoiceChips, câbler `TransactionHeroWidget`, `SectionHeaderSticky` global, groupement sémantique 5 buckets, `date-label` inline.
- **Fichier** : `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart` (M)
- **Requirements couverts** : FR-004, FR-006, FR-007, FR-016
- **Approche** :
  - Supprimer le bloc `SliverToBoxAdapter(child: Wrap(ChoiceChip...))` (FR-004)
  - Remplacer `TransactionSummaryCard` par `TransactionHeroWidget(summary: state.summary, ...)`
  - Ajouter `SectionHeaderSticky(title: 'Transactions')` après le hero
  - Méthode `_groupBySemantics(List<Transaction> items, DateTime today)` retournant `LinkedHashMap<String, List<Transaction>>` avec clés ordonnées : `['Aujourd\'hui', 'Hier', 'Cette semaine', 'Semaine dernière', 'Plus ancien']` (CX-001 — RES-004)
  - Algorithme `_semanticLabel()` : (RES-004)
    ```
    today = DateTime(now.year, now.month, now.day)
    yesterday = today - 1 day
    startOfWeek = today - (today.weekday - 1) days   // lundi ISO
    startOfLastWeek = startOfWeek - 7 days
    ```
  - Utiliser `state.allMonthTransactions` (toutes les transactions du mois, filtre UI retiré)
  - Pour chaque bucket non vide : `date-label` inline puis `TransactionDayGroup` sans header
  - `date-label` "Aujourd'hui" → `AppColors.amber` ; autres → `colorScheme.onSurfaceVariant` (FR-006, SC-007)
  - Edge case mois passé : tous les items tombent dans "Plus ancien" — comportement acceptable (CL-007 différé)

### T-5 — TransactionDayGroup : retrait header date

- **Responsabilité** : Retirer le header de date interne (remplacé par `date-label` parent).
- **Fichier** : `flutter/lib/src/features/transactions/presentation/widgets/transaction_day_group.dart` (M)
- **Requirements couverts** : FR-007
- **Approche** :
  - Identifier et supprimer le `DayHeaderFormatter.format(date)` dans `build()` (ligne 52)
  - Garder uniquement le `SliverList` des items — le widget devient un wrapper de liste pure
  - Si `date` n'est plus nécessaire après le retrait, retirer le paramètre (breaking change minimal — seul `TransactionListScreen` l'utilise)

### T-6 — SubscriptionHeroWidget

- **Responsabilité** : Afficher total mensuel abonnements, meta-lines actifs/annuel.
- **Fichier** : `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_hero_widget.dart` (C)
- **Requirements couverts** : FR-009, FR-015, FR-016
- **Approche** :
  - `StatelessWidget` avec `key: const Key('subscription_hero')`
  - Paramètres : `monthlyTotals: Map<Currency, double>`, `activeCount: int`, `isLoading: bool`
  - Label "ABONNEMENTS" xs/uppercase/tertiary
  - Total mensuel `size3xl`/bold/`expenseColor` (première devise de `monthlyTotals`)
  - Meta-line actifs : `PhosphorRepeat` 14px + "$activeCount actifs" (FR-009, CL-001)
  - Meta-line annuel : `PhosphorCalendarBlank` 14px + "≈ ${total × 12}€/an" (A-003 validé — RES — notifier normalise déjà)
  - Total annuel = première entrée de `monthlyTotals` × 12 (A-003)
  - Skeleton : `_SubscriptionHeroSkeleton` — `Container(height: 96)` + `Shimmer.fromColors`

### T-7 — SubscriptionListScreen : refonte complète

- **Responsabilité** : Supprimer ChoiceChips, câbler `SubscriptionHeroWidget`, `SectionHeaderSticky` global, date-labels Actifs/Inactifs.
- **Fichier** : `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` (M)
- **Requirements couverts** : FR-008, FR-010, FR-016
- **Approche** :
  - Supprimer les 2 blocs `Wrap(ChoiceChip...)` (empty state + data state) (FR-008)
  - Remplacer `_SubscriptionSummaryCard` par `SubscriptionHeroWidget(...)`
  - `activeCount = state.items.where((s) => s.actif).length`
  - Ajouter `SectionHeaderSticky(title: 'Abonnements · $activeCount actifs')` après le hero (FR-010, CL-003)
  - Date-label "Actifs" (`onSurfaceVariant`) → liste des abonnements avec `actif == true`
  - Date-label "Inactifs" (`onSurfaceVariant`) → liste des abonnements avec `actif == false`
  - `date-label` = `SliverToBoxAdapter(child: Padding(horizontal: s4, vertical: s2, child: Text(label, xs/medium, color)))`
  - Sections vides omises (FR-010, edge case US-003)
  - Supprimer `_SubscriptionSummaryCard` et `_SummaryCardSkeleton` du fichier (remplacées par hero)

### T-8 — DebtHeroWidget

- **Responsabilité** : Afficher solde net dettes, meta-lignes prêts/emprunts/en cours.
- **Fichier** : `flutter/lib/src/features/debts/presentation/widgets/debt_hero_widget.dart` (C)
- **Requirements couverts** : FR-012, FR-015, FR-016
- **Approche** :
  - `StatelessWidget` avec `key: const Key('debt_hero')`
  - Paramètres : `summary: Map<Currency, DebtCurrencySummary>`, `primaryCurrency: Currency?`, `enCours: int`, `isLoading: bool`
  - Solde net = `(summary[primaryCurrency]?.totalPrets ?? 0) - (summary[primaryCurrency]?.totalEmprunts ?? 0)` (RES-003)
  - Montant `size3xl`/bold : `incomeColor` si net > 0, `expenseColor` si < 0, `onSurface` si 0
  - Meta-ligne 1 : `PhosphorHandCoins` 14px + "N prêts" · `PhosphorHandshake` 14px + "M emprunts"
  - Meta-ligne 2 : `PhosphorClock` 14px + "$enCours en cours"
  - Skeleton : `_DebtHeroSkeleton` — `Container(height: 96)` + `Shimmer.fromColors`

### T-9 — DebtListScreen : refonte complète

- **Responsabilité** : Supprimer ChoiceChips, câbler `DebtHeroWidget`, `SectionHeaderSticky` global, groupement temporel 7 buckets, date-labels colorés.
- **Fichier** : `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` (M)
- **Requirements couverts** : FR-011, FR-013, FR-016
- **Approche** :
  - Supprimer `_buildFilter()` et son appel (FR-011)
  - Supprimer la classe privée `_SectionHeader` (FR-013 — remplacée par SectionHeaderSticky global)
  - Supprimer `_DebtSummaryCard` et `_SummaryCardSkeleton` (remplacées par `DebtHeroWidget`)
  - `kEnCours = state.items.where((d) => !d.rembourse).length` (RES-003)
  - Remplacer `_DebtSummaryCard` par `DebtHeroWidget(summary: state.summary, primaryCurrency: primaryCurrency, enCours: kEnCours, isLoading: state.isLoading)`
  - Ajouter `SectionHeaderSticky(title: 'Dettes · $kEnCours en cours')` après le hero
  - Méthode privée `_groupByDueDate(List<Debt> items, DateTime today)` : 7 buckets ordonnés (CX-002 — RES-005)
  - Buckets et couleurs date-label :
    - "En retard" → `themeExt.expenseColor` (dueDate dépassée + non remboursée)
    - "Aujourd'hui" → `AppColors.amber`
    - "Cette semaine" / "Ce mois-ci" / "Plus tard" / "Sans échéance" → `colorScheme.onSurfaceVariant`
    - "Remboursées" → `colorScheme.onSurfaceVariant`
  - Tri dans chaque bucket : `dueDate` ASC (null après), puis `date` DESC (RES-002)
  - `date-label` = `SliverToBoxAdapter(child: Padding(child: Text(label, xs/medium, color)))`

### T-10 — Tests widget (4 fichiers)

- **Responsabilité** : Couvrir les 12 SC via `forEachTheme`.
- **Fichiers** : 4 fichiers `*_hero_widget_test.dart` (C)
- **Requirements couverts** : NFR-001, FR-014, SC-001 à SC-012
- **Approche** :
  - Pattern `forEachTheme` de `flutter/test/helpers/theme_test_helpers.dart` (NFR-001)
  - Chaque fichier teste son hero widget en isolation (RES-001 — StatelessWidget testable)
  - Tests communs par hero : rendu normal, skeleton (isLoading: true), clés structurelles (SC-005/006)
  - `dashboard_hero_widget_test.dart` : SC-001, SC-002 (no LinearGradient), SC-005, SC-006, SC-010
  - `transaction_hero_widget_test.dart` : SC-003 (no ChoiceChip), SC-005, SC-006, SC-007 (amber Aujourd'hui), SC-010
  - `subscription_hero_widget_test.dart` : SC-004 (SectionHeaderSticky), SC-005, SC-006, SC-010
  - `debt_hero_widget_test.dart` : SC-005, SC-006, SC-007 (rouge En retard), SC-010
  - Test SC-012 (navigation) : dans chaque screen test, pas dans le hero test

---

## Risques et mitigations

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| `TransactionDayGroup` utilisé ailleurs après retrait du header | Moyen | Bas | `grep -rn "TransactionDayGroup"` avant modification — vérifier que seul `TransactionListScreen` l'importe |
| `IncomeExpenseCards` ou `PatrimoineCard` importés ailleurs | Haut | Bas | `grep -rn "IncomeExpenseCards\|PatrimoineCard"` avant suppression |
| Overflow widget sur petits écrans (320px) avec 2 meta-lines + montant 3xl | Moyen | Moyen | Tester à 320px hauteur — `FittedBox` sur le montant si nécessaire |
| `state.allMonthTransactions` vs `filteredTransactions` : si l'API ne les distingue pas dans le notifier | Moyen | Bas | Vérifier `TransactionListState` — si absent, utiliser `state.filteredTransactions` avec filtre à `all` |
| `primaryCurrency` null dans `DebtHeroWidget` (pas de currencies configurées) | Bas | Bas | Guard `if (summary.isEmpty) return SizedBox.shrink()` dans le hero |

---

## Artefacts complémentaires

| Artefact | Fichier | Généré | Justification |
|----------|---------|--------|---------------|
| Research | [research.md](./research.md) | Oui | 8 décisions techniques documentées |
| Data Model | — | Non | Aucune nouvelle entité (spec §Key Entities) |
| Quickstart | [quickstart.md](./quickstart.md) | Oui | Guide développeur pour la refonte des 4 écrans |

---

## Hors scope

- Ajout du champ `remainingAmount` sur le `ListItem` des dettes (RES-002/RES-008 — future issue)
- Modification des notifiers, states, ou repositories (NFR-003)
- Groupement temporel des Abonnements par date de prochain renouvellement (complexité non justifiée pour Flutter avec `actif: bool` simple — Angular a `nextRenewal` calculé)
- Filtrage par type dans Transactions via le notifier (le `TransactionTypeFilter` reste dans le notifier mais hors UI)
- Animation de transition entre l'ancienne et la nouvelle présentation
- `SectionHeaderSticky` avec bouton filtre/recherche dans Transactions (hors spec KKS-240)
- Delta revenus/dépenses vs mois précédent par card (absent d'Angular hero — CL-002)
