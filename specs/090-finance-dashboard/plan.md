# Implementation Plan: Dashboard Finance (Angular)

**Branch**: `090-finance-dashboard` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/090-finance-dashboard/spec.md`

## Summary

Restructurer le dashboard Angular existant pour correspondre exactement au wireframe finance KKS-200. Le dashboard actuel sera simplifie : les sections cartes de comptes individuels, mini-cartes abos/dettes, section abonnements actifs, section dettes actives et selecteur de mois sont **retirees**. Le nouveau layout suit : en-tete avec salutation → selecteur devise → patrimoine total (avec variation nette montant + %) → cartes revenus/depenses (avec comparaison vs mois precedent) → budgets (4 max par urgence) → transactions recentes (5 avec contre-valeurs). Auto-refresh 60s ajoute.

Aucun nouvel endpoint backend. Le dashboard consomme exclusivement les endpoints existants.

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21
**Primary Dependencies**: Angular Signals, Angular Router, Angular HttpClient, @ng-icons/phosphor-icons
**Storage**: N/A (server-only, consomme API REST)
**Testing**: Vitest (ng test)
**Target Platform**: Web (PWA mobile-first)
**Project Type**: Frontend PWA (restructuration du dashboard existant)
**Performance Goals**: Dashboard visible en < 2s, contre-valeurs instantanees au changement de devise
**Constraints**: Signals-first, standalone components, OnPush, inject() only, pas de subscribe() manuel
**Scale/Scope**: 1 ecran existant a restructurer, ~6 sous-composants (2 nouveaux, 1 modifie, 3 a retirer), 0 nouveau service

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | PASS | Aucun nouvel endpoint. Consomme les endpoints existants (total-balance, summary, overview, transactions, exchange-rates, users/me) |
| II. Securite par defaut | PASS | Pas de changement — les appels existants sont deja proteges par JWT |
| III. Simplicite & YAGNI | PASS | Restructuration incrementale. Pas de nouveau service. Calculs derives via computed(). Retrait de sections = simplification |
| IV. Mobile-First UX | PASS | Dashboard mobile-first existant, restructure selon wireframe. Layout responsive conserve |
| V. Testabilite | PASS | Tests unitaires sur les calculs derives (variation patrimoine, tri budgets). Tests composant sur le rendering conditionnel |
| VI. Observabilite | PASS | Pas de changement — logging existant suffisant |
| VII. Self-Hosted Ready | PASS | Pas de nouvelle dependance externe |

**GATE RESULT: PASS** — Aucune violation.

**Post-design re-check: PASS** — Le design n'introduit aucune violation supplementaire.

## Project Structure

### Documentation (this feature)

```text
specs/090-finance-dashboard/
├── plan.md              # This file
├── spec.md              # Specification
├── research.md          # Phase 0 — recherche et decisions
├── data-model.md        # Phase 1 — modeles de donnees
├── quickstart.md        # Phase 1 — guide de demarrage
├── checklists/
│   └── requirements.md  # Checklist qualite spec
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (fichiers impactes)

```text
app/src/app/features/dashboard/
├── dashboard.ts                          # MODIFIER — restructurer, ajouter auto-refresh, summary mois-1, signals derives
├── dashboard.html                        # MODIFIER — nouveau layout wireframe, retirer sections obsoletes
├── dashboard.scss                        # MODIFIER — styles patrimoine, summary cards, budgets, contre-valeurs
└── components/
    ├── currency-pill-selector.ts         # CONSERVER — pas de modification
    ├── budget-summary/
    │   ├── budget-summary.ts             # MODIFIER — limiter a 4 items, tri par urgence, barre progression coloree
    │   ├── budget-summary.html           # MODIFIER — nouveau layout
    │   └── budget-summary.scss           # MODIFIER — barres de progression, depassement
    ├── patrimoine-card/                  # NOUVEAU
    │   ├── patrimoine-card.ts            # Carte patrimoine total + variation + contre-valeur
    │   └── patrimoine-card.scss
    └── summary-cards/                    # NOUVEAU
        ├── summary-cards.ts              # Cartes revenus/depenses cote a cote + variation mois-1
        └── summary-cards.scss

app/src/app/shared/components/
└── shell/
    └── shell.html                        # MODIFIER — ajouter salutation personnalisee dans le header (route /dashboard)
```

**Fichiers a supprimer/nettoyer dans dashboard.html** :
- Zone cartes de comptes individuels (accounts zone)
- Mini-cartes abonnements/dettes (3 mini-cards)
- Section abonnements actifs (top 3 subscriptions)
- Section dettes actives (3 dernieres dettes)
- Selecteur de mois (MonthSelector prev/next)

**Services existants utilises (aucune modification)** :
- `TransactionService` — `getAll()`, `getSummary(month, year)`
- `AccountService` — `refreshTrigger`, `getAll()` (total-balance calcule cote client via `convertedTotalBalance` computed signal qui agrege les soldes des comptes actifs)
- `BudgetService` — `getOverview()`
- `ConversionService` — `convert(amount, from, to)`
- `ExchangeRateService` — `rates()`, `loadRates()`
- `PreferenceService` — `currencies()`, `primaryCurrency()`, `isEnabled(feature)`
- `UserService` — `profile()` (nom utilisateur)
- `NotificationService` — `unreadCount()` (deja dans le shell)

**Structure Decision**: Restructuration du dashboard existant dans `app/src/app/features/dashboard/`. Extraction de 2 nouveaux sous-composants (`patrimoine-card`, `summary-cards`) pour isoler la logique. Pas de nouveau service — les computed signals dans le composant suffisent. Les services d'abonnements et dettes ne sont plus importes dans le dashboard (injection retiree).

## Design detaille

### 1. Dashboard.ts — Restructuration

**Services a RETIRER de l'injection** :
- `SubscriptionService` (plus de section abonnements)
- `DebtService` (plus de section dettes)
- `ModalService` (plus de click → modal depuis le dashboard)

**Signals a RETIRER** :
- `subscriptions`, `subscriptionsLoading`, `subscriptionsError`
- `debts`, `debtsLoading`, `debtsError`
- `accounts` (liste de comptes individuelss — remplace par total-balance seul)
- Tous les computed lies aux sections supprimees

**Signals a CONSERVER/ADAPTER** :
- `accountsLoading`, `accountsError` → renommer en `totalBalanceLoading`, `totalBalanceError`
- `transactions`, `transactionsLoading`, `transactionsError` → conserver pour les 5 dernieres
- `activeCurrency` → conserver (CurrencyPillSelector)
- `convertedTotalBalance` → conserver et enrichir

**Nouveaux signals** :

```typescript
// Summary mois courant et precedent
readonly currentSummary = signal<MonthlySummary | null>(null);
readonly previousSummary = signal<MonthlySummary | null>(null);
readonly summaryLoading = signal(true);
readonly summaryError = signal(false);

// Budget overview
readonly budgetOverview = signal<BudgetOverview | null>(null);
readonly budgetLoading = signal(true);

// Auto-refresh
private autoRefreshTimer: ReturnType<typeof setInterval> | null = null;
```

**Nouveaux computed signals** :

```typescript
readonly netDuMois = computed(() => {
  const summary = this.currentSummary();
  if (!summary) return 0;
  return summary.totalRecettes - summary.totalDepenses;
});

readonly patrimoineDebutMois = computed(() => {
  const total = this.primaryCurrencyBalance();
  return total - this.netDuMois();
});

readonly variationPatrimoinePct = computed(() => {
  const debut = this.patrimoineDebutMois();
  if (debut === 0) return null;
  return (this.netDuMois() / debut) * 100;
});

readonly variationRevenus = computed(() => {
  const current = this.currentSummary()?.totalRecettes ?? 0;
  const previous = this.previousSummary()?.totalRecettes ?? 0;
  return current - previous;
});

readonly variationDepenses = computed(() => {
  const current = this.currentSummary()?.totalDepenses ?? 0;
  const previous = this.previousSummary()?.totalDepenses ?? 0;
  return current - previous;
});

readonly previousMonthName = computed(() => {
  // "fev.", "jan.", etc. via Intl.DateTimeFormat
});

readonly sortedBudgetItems = computed(() => {
  const items = this.budgetOverview()?.items ?? [];
  return [...items]
    .sort((a, b) => {
      const aExceeded = a.percentage >= 100;
      const bExceeded = b.percentage >= 100;
      if (aExceeded !== bExceeded) return aExceeded ? -1 : 1;
      return b.percentage - a.percentage;
    })
    .slice(0, 4);
});

readonly recentTransactions = computed(() =>
  [...this.transactions()].sort((a, b) => /* date desc */).slice(0, 5)
);
```

**Lifecycle** :

```typescript
ngOnInit() {
  this.loadAll();
  this.autoRefreshTimer = setInterval(() => this.silentRefresh(), 60_000);
}

ngOnDestroy() {
  if (this.autoRefreshTimer) clearInterval(this.autoRefreshTimer);
}

// Effect pour refresh au retour sur le dashboard
routeEffect = effect(() => {
  this.accountService.refreshTrigger(); // trigger existant
  this.loadAll();
});
```

**Methodes de chargement** :

```typescript
async loadAll() {
  // Parallele : accounts total-balance, summary (mois courant + mois-1), budgets overview, transactions, exchange-rates
  await Promise.all([
    this.loadTotalBalance(),
    this.loadSummaries(),
    this.loadBudgetOverview(),
    this.loadTransactions(),
    this.exchangeRateService.loadRates(),
  ]);
}

async silentRefresh() {
  // Meme que loadAll() mais sans activer les flags loading
  // En cas d'erreur, silent fail (pas d'affichage erreur)
}

async loadSummaries() {
  const now = new Date();
  const prev = new Date(now.getFullYear(), now.getMonth() - 1);
  const [current, previous] = await Promise.all([
    firstValueFrom(this.transactionService.getSummary(now.getMonth() + 1, now.getFullYear())),
    firstValueFrom(this.transactionService.getSummary(prev.getMonth() + 1, prev.getFullYear())),
  ]);
  this.currentSummary.set(current[0] ?? null);
  this.previousSummary.set(previous[0] ?? null);
}
```

### 2. PatrimoineCard (NOUVEAU sous-composant)

```typescript
@Component({
  selector: 'app-patrimoine-card',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  // ...
})
export class PatrimoineCard {
  totalBalance = input.required<number>();
  netDuMois = input.required<number>();
  variationPct = input<number | null>(null);
  currency = input.required<string>();
  convertedTotal = input<number | null>(null);
  convertedCurrency = input<string | null>(null);
  isLoading = input(false);
  hasError = input(false);
  retry = output<void>();
}
```

**Template** :
- Loading → skeleton shimmer (existant pattern `.state-loading`)
- Error → `.state-error` avec bouton Reessayer
- Sinon : carte avec montant principal (gros, `--font-size-3xl`), ligne variation (vert/rouge/neutre), contre-valeur (petit, `--text-secondary`)

**Styles** :
- `--color-income` pour variation positive
- `--color-expense` pour variation negative
- `--text-tertiary` pour variation neutre (0%)

### 3. SummaryCards (NOUVEAU sous-composant)

```typescript
@Component({
  selector: 'app-summary-cards',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  // ...
})
export class SummaryCards {
  totalRecettes = input.required<number>();
  totalDepenses = input.required<number>();
  variationRevenus = input.required<number>();
  variationDepenses = input.required<number>();
  previousMonthName = input.required<string>();
  currency = input.required<string>();
  convertedRecettes = input<number | null>(null);
  convertedDepenses = input<number | null>(null);
  convertedCurrency = input<string | null>(null);
  isLoading = input(false);
}
```

**Template** : 2 cartes en flexbox (`gap: var(--space-3)`, `flex: 1`), chacune avec :
- Pastille coloree + label ("REVENUS" / "DEPENSES")
- Montant principal formate (`AmountPipe`)
- Variation : "+200 vs fev." avec fleche (vert = bien pour revenus en hausse, rouge = mal pour depenses en hausse)
- Contre-valeur en petit

### 4. BudgetSummary — Modification

**Changements a apporter** :
- Ajouter un input `maxItems = input(4)` pour limiter le nombre de budgets affiches
- Trier les items par urgence (depasses d'abord, puis par percentage decroissant) — OU recevoir les items deja tries du parent
- Ajouter un en-tete avec le total global : "MENSUEL · EN EUR  1 736 / 2 030"
- Barre de progression : couleur normale sous 80% (`--color-primary`), warning 80-100% (`--bg-warning`), danger > 100% (`--color-expense`)
- "Voir tout →" comme lien vers `/budgets`
- Conditionnel : masque si `!preferenceService.isEnabled('BUDGETS')` (deja le cas)

### 5. Shell — Salutation dans le header

**Changement minimal** :
- Dans `shell.html`, a cote du logo dans le header, ajouter conditionnellement la salutation
- Condition : `router.url === '/dashboard'` ou utiliser un signal `isOnDashboard`
- Texte : "Bonjour [userName]" utilisant `userService.profile()?.name`
- Si `name` est null/vide, afficher "Bonjour" seul
- Style : `--font-size-lg`, `--font-weight-semibold`

### 6. Contre-valeurs sur les transactions recentes

**Dans le template du dashboard** :
- Pour chaque transaction dans `recentTransactions()`, utiliser `ConversionService.convert()` pour calculer la contre-valeur si `transaction.currency !== activeCurrency()`
- Afficher via le `rightSubtitle` ou `valueSubtitle` de `app-list-item` : "≈ $74,14"
- Si taux indisponible, ne rien afficher (pas de "N/A")

### 7. Auto-refresh 60s

- `setInterval(60_000)` dans `ngOnInit`
- `clearInterval` dans `ngOnDestroy`
- `silentRefresh()` : recharge toutes les donnees SANS activer les flags `isLoading` (pas de flash skeleton)
- En cas d'erreur sur un refresh automatique : silent fail, les donnees existantes restent affichees
- Le refresh au retour (via `routeEffect`) recharge normalement (avec loading state si les donnees sont stales)

## Complexity Tracking

> Aucune violation de la constitution — section non applicable.
