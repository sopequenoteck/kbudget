# Data Model: Flutter — Écran Dettes Liste

**Feature**: 048-flutter-debts-list | **Date**: 2026-02-23

## Entités existantes (non modifiées)

### Debt (Freezed model)

```
Debt
├── id: String (required)
├── personne: String (required) — nom de la personne
├── montant: double (required) — montant positif
├── sens: DebtType (required) — emprunt | pret
├── date: DateTime (required) — date de la dette
├── currency: Currency (default: eur) — devise
├── rembourse: bool (default: false) — statut remboursement
├── categoryId: String? — FK catégorie optionnelle
└── updatedAt: DateTime? — dernière mise à jour
```

### Category (Freezed model)

```
Category
├── id: String (required)
├── nom: String (required)
├── icone: String (required) — emoji
├── couleur: String (required) — hex color
├── isSystem: bool (default: false)
└── updatedAt: DateTime?
```

### DebtType (enum existant)

```
DebtType { emprunt, pret }
```

### Currency (enum existant)

```
Currency { eur, xof, usd, gbp, chf, cad, mad }
  ├── symbol: String
  ├── name: String
  └── decimalPlaces: int
```

---

## Nouvelles structures

### DebtStatusFilter (nouvel enum)

```
DebtStatusFilter { all, enCours, rembourse }
```

**Fichier** : `flutter/lib/src/domain/enums/debt_status_filter.dart`

**Règles de filtrage** :
- `all` → aucun filtre, toutes les dettes
- `enCours` → `debt.rembourse == false`
- `rembourse` → `debt.rembourse == true`

---

### DebtCurrencySummary (type alias record)

```
typedef DebtCurrencySummary = ({double totalEmprunts, double totalPrets});
```

**Fichier** : défini dans `debt_list_state.dart`

**Règles de calcul** :
- Calculé uniquement sur les dettes où `rembourse == false`
- `totalEmprunts` = somme des `montant` où `sens == DebtType.emprunt`
- `totalPrets` = somme des `montant` où `sens == DebtType.pret`
- Solde net = `totalPrets - totalEmprunts` (dérivé à l'affichage, pas stocké)
- Regroupé par `currency`

---

### DebtListState (nouvel état Freezed)

```
DebtListState
├── items: List<Debt> (default: []) — items filtrés et paginés
├── isLoading: bool (default: false)
├── error: String?
├── activeFilter: DebtStatusFilter (default: all)
├── summary: Map<Currency, DebtCurrencySummary> (default: {})
├── currentPage: int (default: 0)
├── hasMore: bool (default: true)
└── mutatingIds: Set<String> (default: {})
```

**Fichier** : `flutter/lib/src/features/debts/application/debt_list_state.dart`

**Invariants** :
- `summary` reflète TOUJOURS les dettes non remboursées, indépendamment de `activeFilter`
- `items` reflète les dettes après application de `activeFilter` + pagination
- `summary` est vide si aucune dette non remboursée n'existe

---

## Relations et flux de données

```
DebtRepository (existant)
    │
    ▼ getAll() → List<Debt>
DebtNotifier (modifié)
    ├── _allItems: List<Debt>          # cache interne non paginé
    ├── _computeSummary(_allItems)      # → Map<Currency, DebtCurrencySummary>
    ├── _applyFilter(_allItems, filter) # → List<Debt> filtrées
    ├── _refreshPage()                  # → pagination + mise à jour state
    ├── setFilter(DebtStatusFilter)     # → change filtre + _refreshPage
    └── loadItems() / refresh()         # → recharge depuis repository
         │
         ▼
DebtListState
    │
    ▼ lu par
DebtListScreen (modifié)
    ├── _DebtSummaryCard(summary, isLoading)
    ├── SegmentedFilter<DebtStatusFilter>(activeFilter, onChanged)
    ├── Section "Prêts" ← items.where(sens == pret)
    │   ├── _SectionHeader(title, subtotals)
    │   └── ListItem × N
    ├── Section "Emprunts" ← items.where(sens == emprunt)
    │   ├── _SectionHeader(title, subtotals)
    │   └── ListItem × N
    └── onPressed → modalNotifierProvider.open(ModalType.debt, entity: debt)
```

---

## Tri

- **Dans le notifier** : `_allItems` trié par `date` décroissante (existant, inchangé)
- **Dans le screen** : les items de chaque section héritent du tri par date du notifier (le `.where()` préserve l'ordre)
