# Contrats techniques — KKS-240 : Phase 1 / Étape 4 — Refonte 4 écrans liste Flutter

> Date : 2026-05-10
> Issue : KKS-240
> Plan : [plan.md](./plan.md)

---

> **Note** : Refonte purement UI — aucun endpoint API nouveau, aucun service modifié, aucun type de données nouveau. Les contrats couvrent exclusivement les 4 nouveaux widgets publics et les 2 méthodes de groupement privées documentées ici pour référence croisée tasks ↔ plan.

---

## Interfaces & Types

### `_SemanticGroup` (Transactions)

> Réf: FR-006, FR-007

```dart
// Clés ordonnées des 5 buckets sémantiques — ordre de rendu garanti
const kSemanticGroups = [
  'Aujourd\'hui',
  'Hier',
  'Cette semaine',
  'Semaine dernière',
  'Plus ancien',
];

// Map résultat de _groupBySemantics() — LinkedHashMap ordonné
// Map<String, List<Transaction>>
```

**Invariants** :
- Un bucket absent de la map = aucune transaction pour cette période (groupe omis à l'affichage)
- Un item appartient à exactement un bucket (pas de doublon)
- Le bucket "Aujourd'hui" correspond à `tx.date.year == today.year && tx.date.month == today.month && tx.date.day == today.day`

---

### `_DebtBucket` (Dettes)

> Réf: FR-013

```dart
// Clés ordonnées des 7 buckets temporels — ordre d'affichage garanti
const kDebtBuckets = [
  'En retard',       // dueDate dépassée + !rembourse
  'Aujourd\'hui',    // dueDate == today + !rembourse
  'Cette semaine',   // dueDate dans les 7 prochains jours + !rembourse
  'Ce mois-ci',      // dueDate dans le mois courant + !rembourse
  'Plus tard',       // dueDate au-delà + !rembourse
  'Sans échéance',   // dueDate == null + !rembourse
  'Remboursées',     // rembourse == true
];

// Map résultat de _groupByDueDate() — LinkedHashMap ordonné
// Map<String, List<Debt>>
```

**Invariants** :
- Une dette remboursée (`rembourse == true`) est TOUJOURS dans "Remboursées", peu importe sa `dueDate`
- Une dette non remboursée sans `dueDate` est TOUJOURS dans "Sans échéance"
- L'ordre de rendu est celui du tableau `kDebtBuckets`
- Groupes vides omis à l'affichage

---

## API Endpoints

Aucun endpoint API nouveau — refonte purement présentationnelle. Les notifiers existants consomment les mêmes données Drift/API qu'avant.

---

## Contrats composants

### `DashboardHeroWidget`

> Réf: FR-001, FR-002, FR-003, FR-014, FR-015, FR-016

| Aspect | Détail |
|--------|--------|
| Responsabilité | Hero flat patrimoine total — sans gradient, avec variation mensuelle badgée, meta-lines et devise secondaire |
| Fichier | `lib/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart` |
| Key structurelle | `Key('dashboard_hero')` (normal) · `Key('dashboard_hero_skeleton')` (loading) |

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `accounts` | `List<Account>` | Oui | Comptes pour calcul patrimoine total |
| `activeCurrency` | `Currency` | Oui | Devise d'affichage principale |
| `exchangeRates` | `List<ExchangeRate>` | Oui | Taux de change pour conversion |
| `currencies` | `List<Currency>` | Oui | Toutes les devises (pour devise secondaire) |
| `currentSummary` | `MonthlySummary?` | Non | Résumé mensuel (revenus, dépenses) pour variation et meta-lines |
| `isLoading` | `bool` | Oui | Si true → affiche `_DashboardHeroSkeleton` |

**Outputs / Events** : aucun (widget purement affichage)

**Comportements contractuels** :
- `isLoading: true` → skeleton `Container(height: 96)` avec `Shimmer.fromColors`
- Montant patrimoine : `incomeColor` si ≥ 0, `expenseColor` si < 0
- Badge variation : affiché uniquement si `currentSummary != null`
- Devise secondaire : affichée uniquement si `currencies.length >= 2`
- Aucun `LinearGradient` — fond transparent (SC-002)
- Tokens exclusivement — aucun hex (SC-009)

---

### `TransactionHeroWidget`

> Réf: FR-005, FR-014, FR-015, FR-016

| Aspect | Détail |
|--------|--------|
| Responsabilité | Hero solde mensuel transactions — bilan revenus − dépenses avec meta-lines |
| Fichier | `lib/src/features/transactions/presentation/widgets/transaction_hero_widget.dart` |
| Key structurelle | `Key('transaction_hero')` (normal) · `Key('transaction_hero_skeleton')` (loading) |

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `summary` | `MonthlySummary?` | Non | Résumé mensuel — `totalRecettes`, `totalDepenses` |
| `primaryCurrency` | `Currency?` | Non | Devise d'affichage |
| `isLoading` | `bool` | Oui | Si true → skeleton |

**Outputs / Events** : aucun

**Comportements contractuels** :
- Bilan = `(summary?.totalRecettes ?? 0) - (summary?.totalDepenses ?? 0)`
- `isLoading: true` → skeleton
- Montant : `incomeColor` si ≥ 0, `expenseColor` si < 0
- Meta-line revenus : `PhosphorTrendUp` 14px + montant `incomeColor`
- Meta-line dépenses : `PhosphorTrendDown` 14px + montant `expenseColor`

---

### `SubscriptionHeroWidget`

> Réf: FR-009, FR-014, FR-015, FR-016

| Aspect | Détail |
|--------|--------|
| Responsabilité | Hero total mensuel abonnements avec meta-lines actifs/annuel |
| Fichier | `lib/src/features/subscriptions/presentation/widgets/subscription_hero_widget.dart` |
| Key structurelle | `Key('subscription_hero')` (normal) · `Key('subscription_hero_skeleton')` (loading) |

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `monthlyTotals` | `Map<Currency, double>` | Oui | Total mensuel normalisé par devise (depuis notifier) |
| `activeCount` | `int` | Oui | Nombre d'abonnements avec `actif == true` |
| `isLoading` | `bool` | Oui | Si true → skeleton |

**Outputs / Events** : aucun

**Comportements contractuels** :
- `monthlyTotals.isEmpty` → `SizedBox.shrink()` (même comportement que `_SubscriptionSummaryCard`)
- `isLoading: true` → skeleton
- Total mensuel : première entrée de `monthlyTotals` en `expenseColor`
- Meta-line actifs : `PhosphorRepeat` 14px + "$activeCount actifs"
- Meta-line annuel : `PhosphorCalendarBlank` 14px + "≈ ${total × 12} devise/an" (A-003 — notifier normalise déjà)

---

### `DebtHeroWidget`

> Réf: FR-012, FR-014, FR-015, FR-016

| Aspect | Détail |
|--------|--------|
| Responsabilité | Hero solde net dettes avec meta-lignes prêts/emprunts/en cours |
| Fichier | `lib/src/features/debts/presentation/widgets/debt_hero_widget.dart` |
| Key structurelle | `Key('debt_hero')` (normal) · `Key('debt_hero_skeleton')` (loading) |

**Inputs** :

| Nom | Type | Requis | Description |
|-----|------|--------|-------------|
| `summary` | `Map<Currency, DebtCurrencySummary>` | Oui | Totaux emprunts/prêts par devise |
| `primaryCurrency` | `Currency?` | Non | Devise principale pour le solde net |
| `enCours` | `int` | Oui | Nombre de dettes non remboursées (`!rembourse`) |
| `isLoading` | `bool` | Oui | Si true → skeleton |

**Outputs / Events** : aucun

**Comportements contractuels** :
- `summary.isEmpty` → `SizedBox.shrink()`
- Solde net = `totalPrets - totalEmprunts` pour `primaryCurrency` (ou première entrée si null)
- Montant : `incomeColor` si net > 0, `expenseColor` si net < 0, `onSurface` si 0
- Meta-ligne 1 : `PhosphorHandCoins` 14px + "N prêts" · `PhosphorHandshake` 14px + "M emprunts"
- Meta-ligne 2 : `PhosphorClock` 14px + "$enCours en cours"
- `isLoading: true` → skeleton

---

### Méthodes privées contractualisées (référence plan)

Ces méthodes sont privées dans leurs screens respectifs mais leur contrat est documenté ici pour assurer la cohérence tasks ↔ plan.

#### `_groupBySemantics()` — dans `_TransactionListScreenState`

> Réf: FR-006, CX-001

```dart
// Signature
Map<String, List<Transaction>> _groupBySemantics(
  List<Transaction> items,
  DateTime today,
)

// today = DateTime(now.year, now.month, now.day)  — tronqué à la journée
// Retourne LinkedHashMap avec clés dans l'ordre kSemanticGroups
// Buckets vides exclus du résultat
```

#### `_groupByDueDate()` — dans `_DebtListScreenState`

> Réf: FR-013, CX-002

```dart
// Signature
Map<String, List<Debt>> _groupByDueDate(
  List<Debt> items,
  DateTime today,
)

// today = DateTime(now.year, now.month, now.day)  — tronqué à la journée
// Retourne LinkedHashMap avec clés dans l'ordre kDebtBuckets
// Tri dans chaque bucket : dueDate ASC (null après), puis date DESC
// Buckets vides exclus du résultat
```

---

## Contrats services

Aucun service nouveau ni modifié — les notifiers existants (`DashboardNotifier`, `TransactionListNotifier`, `SubscriptionNotifier`, `DebtNotifier`) ne sont pas touchés (NFR-003).

---

## Résumé

| Type | Nombre |
|------|--------|
| Interfaces & Types | 2 (`_SemanticGroup`, `_DebtBucket`) |
| API Endpoints | 0 |
| Contrats composants | 4 (`DashboardHeroWidget`, `TransactionHeroWidget`, `SubscriptionHeroWidget`, `DebtHeroWidget`) + 2 méthodes privées |
| Contrats services | 0 |
| FR couverts | FR-001, FR-002, FR-003, FR-005, FR-006, FR-007, FR-009, FR-012, FR-013, FR-014, FR-015, FR-016 (12/17) |
