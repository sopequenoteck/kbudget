# Implementation Plan: Recherche & Filtres Transactions

**Branch**: `feature/search-filter-transactions` | **Date**: 2026-04-11 | **Spec**: [spec.md](spec.md)

## Summary

Rendre fonctionnelles les deux icones recherche et filtre du section header de la page Transactions. Implementation 100% client-side (les donnees sont deja en memoire via `getAll()`). Deux mecanismes distincts : (1) un champ de recherche inline qui remplace le titre dans le section header, (2) un panneau de filtres slide-down sous le section header avec chips type/categorie/compte. Tout le filtrage passe par un seul `computed()` qui chaine les criteres en AND.

## Technical Context

**Language/Version**: TypeScript 5.9 / Angular 21+
**Primary Dependencies**: Angular Signals, ng-icons/phosphor, SCSS tokens
**Storage**: N/A (state local en memoire, pas de persistence)
**Testing**: Karma/Jasmine (existant Angular)
**Target Platform**: PWA mobile-first (iPhone 14 Pro reference)
**Performance Goals**: filtrage < 16ms (frame budget 60fps)
**Constraints**: client-side uniquement, pas de nouvel endpoint API, pas de backend

## Constitution Check

| Principe | Gate | Statut |
|----------|------|--------|
| I. API-First | Pas de nouvel endpoint necessaire — le filtrage est client-side sur des donnees deja chargees | PASS |
| II. Securite par defaut | Pas de nouvelle route ni de donnees sensibles | PASS |
| III. Simplicite & YAGNI | Solution minimale : signals + computed, pas d'abstraction (pas de service de filtrage, pas de state management externe) | PASS |
| IV. Mobile-First UX | Champ recherche avec focus auto + clavier, panneau filtres tactile avec chips | PASS |
| V. Testabilite | La logique de filtrage vit dans des `computed()` purs, testables unitairement | PASS |
| VI. Observabilite | Pas de logging necessaire (interaction UI locale) | PASS |
| VII. Self-Hosted Ready | Pas de dependance externe ajoutee | PASS |

Aucune derogation necessaire.

## Project Structure

### Fichiers impactes

```text
app/src/app/features/transactions/
├── transactions.ts          (M) — signals filtrage, handlers recherche/filtre
├── transactions.html        (M) — template recherche inline + panneau filtres
├── transactions.scss        (M) — styles specifiques recherche/filtre

app/src/styles/
├── _list-patterns.scss      (M) — classes section-header search mode + filter panel
```

Legende : **(C)** = creer, **(M)** = modifier

### Decision : pas de composant partage

Le panneau filtres et le champ recherche vivent directement dans le composant Transactions. Raison : c'est le seul endroit ou ces interactions existent. Si un jour d'autres pages (Abonnements, Dettes) ont besoin de filtres, on extraira a ce moment-la. Trois lignes similaires valent mieux qu'une abstraction prematuree (Constitution III).

## Architecture detaillee

### 1. State de filtrage (transactions.ts)

**Couvre** : FR-001, FR-002, FR-004, FR-006, FR-008

Ajouter les signals suivants au composant :

```
// Recherche
readonly searchOpen = signal(false);
readonly searchQuery = signal('');

// Filtres
readonly filterOpen = signal(false);
readonly typeFilter = signal<TransactionType | null>(null);
readonly categoryFilter = signal<string | null>(null);   // category id
readonly accountFilter = signal<string | null>(null);     // account id

// Donnees pour les chips
readonly categories = signal<Category[]>([]);
readonly accounts = signal<AccountSummary[]>([]);

// Indicateur filtre actif
readonly hasActiveFilters = computed(() =>
  this.typeFilter() !== null ||
  this.categoryFilter() !== null ||
  this.accountFilter() !== null
);
```

Les categories et comptes sont charges dans `loadData()` via `forkJoin` (ajouter `categoryService.getAll()` et `accountService.getAll()` aux appels existants).

**Modification du `filteredTransactions` computed** :

Le computed existant filtre deja par mois/annee. On chaine les filtres supplementaires dans le meme computed :

```
1. Filtre mois/annee (existant)
2. Filtre type (si typeFilter !== null)
3. Filtre categorie (si categoryFilter !== null)
4. Filtre compte (si accountFilter !== null)
5. Filtre recherche (si searchQuery.trim() !== '')
   - P1 : includes() case-insensitive sur libelle
   - P3 : + category.nom + note
6. Sort par date descendant (existant)
```

Un seul `computed()`, pas de pipe intermediaire. Les filtres se combinent en AND naturellement (chaque `.filter()` enchaine).

**FR-008** : Les signals `searchQuery`, `typeFilter`, etc. persistent entre les changements de mois (ils ne sont pas reset dans `loadData()`).

### 2. Handlers (transactions.ts)

**Couvre** : FR-001, FR-004, FR-007

```
toggleSearch(): void
  - Toggle searchOpen
  - Si ferme : reset searchQuery
  - Si ouvert : focus sur l'input (via viewChild)

toggleFilter(): void
  - Toggle filterOpen
  - Si searchOpen : fermer la recherche d'abord

resetFilters(): void
  - typeFilter.set(null)
  - categoryFilter.set(null)
  - accountFilter.set(null)

setTypeFilter(type: TransactionType | null): void
  - Si meme type deja actif → set null (toggle off)
  - Sinon → set type

setCategoryFilter(categoryId: string | null): void
  - Meme pattern toggle

setAccountFilter(accountId: string | null): void
  - Meme pattern toggle
```

### 3. Template — recherche inline (transactions.html)

**Couvre** : FR-001, FR-003, FR-009

Modification du section header :

```
<div class="section-header" [class.stuck]="isStuck()">
  @if (searchOpen()) {
    <!-- Mode recherche : input remplace le titre -->
    <input class="section-header__search-input"
      type="text"
      placeholder="Rechercher..."
      [value]="searchQuery()"
      (input)="searchQuery.set($event.target.value)"
      (keydown.escape)="toggleSearch()"
      #searchInput />
  } @else {
    <h2 class="section-header__title">Transactions</h2>
  }
  <div class="section-header__actions">
    <button class="section-header__action-btn"
      [class.active]="searchOpen()"
      (click)="toggleSearch()"
      aria-label="Rechercher">
      <ng-icon [name]="searchOpen() ? 'phosphorX' : 'phosphorMagnifyingGlass'" size="20" />
    </button>
    <button class="section-header__action-btn"
      [class.active]="filterOpen() || hasActiveFilters()"
      (click)="toggleFilter()"
      aria-label="Filtrer">
      <ng-icon name="phosphorFunnel" size="20" />
      @if (hasActiveFilters()) {
        <span class="section-header__filter-dot"></span>
      }
    </button>
    ...separateur + recurrences (inchange)
  </div>
</div>
```

Icones Phosphor a ajouter aux imports : `phosphorX`.

### 4. Template — panneau filtres (transactions.html)

**Couvre** : FR-004, FR-005, FR-006, FR-007

Insere juste apres le section header (avant la liste) :

```
@if (filterOpen()) {
  <div class="filter-panel">
    <!-- Ligne 1 : type -->
    <div class="filter-panel__row">
      <button class="filter-chip"
        [class.active]="typeFilter() === null"
        (click)="setTypeFilter(null)">Tout</button>
      <button class="filter-chip"
        [class.active]="typeFilter() === 'DEPENSE'"
        (click)="setTypeFilter(TransactionType.DEPENSE)">Depenses</button>
      <button class="filter-chip"
        [class.active]="typeFilter() === 'RECETTE'"
        (click)="setTypeFilter(TransactionType.RECETTE)">Recettes</button>
    </div>

    <!-- Ligne 2 : categories (si categories du mois > 0) -->
    @if (monthCategories().length > 0) {
      <div class="filter-panel__row filter-panel__row--scroll">
        @for (cat of monthCategories(); track cat.id) {
          <button class="filter-chip"
            [class.active]="categoryFilter() === cat.id"
            (click)="setCategoryFilter(cat.id)">
            {{ cat.icone }} {{ cat.nom }}
          </button>
        }
      </div>
    }

    <!-- Ligne 3 : comptes (si 2+ comptes) -->
    @if (accounts().length > 1) {
      <div class="filter-panel__row filter-panel__row--scroll">
        @for (acc of accounts(); track acc.id) {
          <button class="filter-chip"
            [class.active]="accountFilter() === acc.id"
            (click)="setAccountFilter(acc.id)">
            {{ acc.icone }} {{ acc.nom }}
          </button>
        }
      </div>
    }

    <!-- Reinitialiser (si filtres actifs) -->
    @if (hasActiveFilters()) {
      <button class="filter-panel__reset" (click)="resetFilters()">Reinitialiser</button>
    }
  </div>
}
```

**`monthCategories` computed** : derive les categories presentes dans `filteredTransactions` (avant filtre categorie/recherche), triees par nombre de transactions decroissant. Utilise les transactions du mois uniquement.

### 5. Styles (transactions.scss + _list-patterns.scss)

**Couvre** : NFR-002, NFR-003

#### Dans `_list-patterns.scss` (ajouts au bloc `.section-header`)

```scss
&__search-input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-medium);
  color: var(--text-primary);
  padding: 0;

  &::placeholder {
    color: var(--text-tertiary);
  }
}

&__action-btn.active {
  color: var(--color-primary);
}

&__filter-dot {
  position: absolute;
  top: -2px;
  right: -2px;
  width: 6px;
  height: 6px;
  border-radius: var(--radius-round);
  background: var(--color-primary);
}
```

Note : le `&__action-btn` a besoin de `position: relative` pour positionner le dot.

#### Dans `transactions.scss` (nouveau bloc)

```scss
.filter-panel {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-3);
  background: var(--surface-default);
  border-radius: 0 0 var(--radius-xl) var(--radius-xl);
  margin-bottom: var(--space-2);
  animation: filter-slide-down var(--duration-fast) ease-out;

  &__row {
    display: flex;
    gap: var(--space-2);
    flex-wrap: wrap;

    &--scroll {
      flex-wrap: nowrap;
      overflow-x: auto;
      -webkit-overflow-scrolling: touch;
      scrollbar-width: none;
      &::-webkit-scrollbar { display: none; }
    }
  }

  &__reset {
    background: none;
    border: none;
    color: var(--text-tertiary);
    font-size: var(--font-size-xs);
    cursor: pointer;
    align-self: flex-start;
    padding: 0;
  }
}

.filter-chip {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-1) var(--space-3);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-round);
  background: transparent;
  color: var(--text-secondary);
  font-size: var(--font-size-xs);
  font-weight: var(--font-weight-medium);
  white-space: nowrap;
  cursor: pointer;
  transition: all var(--duration-fast);

  &.active {
    background: var(--primary-subtle);
    border-color: var(--color-primary);
    color: var(--color-primary);
  }
}

@keyframes filter-slide-down {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}
```

### 6. Empty state contextuel

**Couvre** : FR-009

Modifier la condition empty state existante pour distinguer 3 cas :

1. **Aucune transaction dans le mois** (existant) : icone phosphorReceipt + "Aucune transaction en mars 2026" + CTA "Ajouter une transaction"
2. **Recherche sans resultat** : icone phosphorMagnifyingGlass + "Aucune transaction trouvee" (pas de CTA)
3. **Filtres sans resultat** : icone phosphorFunnel + "Aucune depense en mars 2026" (message contextuel selon le filtre) + lien "Reinitialiser les filtres"

Le computed `emptyStateType` determine quel cas afficher : `'empty' | 'search' | 'filter'`.

### 7. FR-010 — Hero inchange

Le hero reste branche sur `activeSummary()` qui vient du summary API du mois complet. Les filtres n'affectent que `filteredTransactions` → `groupedTransactions`. Aucune modification du hero necessaire.

## Sequence d'implementation

| Ordre | Composant | FR couverts | Effort |
|-------|-----------|-------------|--------|
| 1 | Signals de filtrage + computed enrichi | FR-002, FR-006, FR-008 | S |
| 2 | Chargement categories/comptes dans loadData | FR-005 | XS |
| 3 | Template recherche inline + handler | FR-001, FR-003 | S |
| 4 | Styles recherche (_list-patterns.scss) | NFR-002, NFR-003 | XS |
| 5 | Template panneau filtres + handlers | FR-004, FR-005 | M |
| 6 | Styles panneau filtres (transactions.scss) | NFR-002, NFR-003 | S |
| 7 | Indicateur dot filtre actif | FR-007 | XS |
| 8 | Empty states contextuels | FR-009 | S |
| 9 | Recherche etendue (categorie + note) | FR-003 (P3) | XS |

Total estime : ~M (fonctionnalite concentree dans un seul composant)

## Risques et mitigations

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Section header sticky + panneau filtres = conflit z-index | Moyen | Le panneau vit apres le section header dans le DOM (pas dedans). Le sticky z-index 10 suffit. |
| Clavier iPhone couvre le panneau filtres | Bas | Le panneau filtres n'a pas d'input texte (que des chips). Seule la recherche ouvre le clavier, et elle vit dans le section header (haut de page). |
| monthCategories recalcule a chaque frappe recherche | Bas | monthCategories derive des transactions du mois AVANT filtre categorie/recherche, donc stable. |
| `position: relative` sur action-btn peut casser d'autres pages | Bas | Verifier visuellement les section headers des autres pages apres le changement. |

## Hors scope

- Pas de recherche server-side ni d'endpoint API
- Pas de persistence des filtres entre navigations (reset a l'entree sur la page)
- Pas de filtre par montant (range) — pas demande dans la spec
- Pas de filtre par date (deja couvert par le selecteur mois existant)
- Pas de propagation des filtres aux autres pages (Abonnements, Dettes, Budgets)
- Pas d'extraction de composant partage FilterPanel — sera fait si/quand une deuxieme page en a besoin

## Complexity Tracking

Aucune complexite ajoutee. Solution minimale : signals + computed + template conditionnel + CSS.
