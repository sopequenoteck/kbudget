# Research: 074-angular-budget-categories

## R-001: Feature BUDGETS dans le type Angular

**Decision**: Ajouter `'BUDGETS'` au type union `Feature` et à la constante `FEATURES` dans `preference.model.ts`.

**Rationale**: Le type actuel est `'SUBSCRIPTIONS' | 'DEBTS' | 'SHOP'`. Le backend a `BUDGETS` dans l'enum Java `Feature`. L'ajout suit le même pattern que les 3 features existantes.

**Alternatives considered**: Aucune — c'est un ajout obligatoire.

**Fichier**: `app/src/app/core/models/preference.model.ts`

---

## R-002: Librairie de charts (ng2-charts / Chart.js)

**Decision**: Installer `ng2-charts` (wrapper Angular pour Chart.js) + `chart.js` comme dépendances.

**Rationale**: Recommandé dans la spec. ng2-charts fournit des composants Angular standalone (`BaseChartDirective`) compatibles avec les signals et OnPush. Chart.js est léger (~60KB gzipped) et ne nécessite aucun service cloud.

**Alternatives considered**:
- D3.js : trop verbose pour un simple Doughnut Chart
- Apache ECharts : trop lourd pour un seul type de graphique
- SVG custom : maintenance plus lourde

**Installation**: `npm install ng2-charts chart.js`

**Usage pattern**:
```typescript
import { BaseChartDirective } from 'ng2-charts';
import { Chart, DoughnutController, ArcElement, Tooltip, Legend } from 'chart.js';

Chart.register(DoughnutController, ArcElement, Tooltip, Legend);
```

---

## R-003: Pattern service signal-based

**Decision**: Suivre le pattern `ProductService` / `TransactionService` — signals pour l'état, Observable pour les appels HTTP, `refreshTrigger` pour la réactivité.

**Rationale**: Pattern établi dans l'app (6+ services l'utilisent). Cohérence architecturale.

**Alternatives considered**: Aucune — pattern obligatoire selon la constitution (Simplicité & YAGNI).

**Structure type**:
```typescript
@Injectable({ providedIn: 'root' })
export class BudgetService {
  readonly refreshTrigger = signal(0);

  getAll(includeInactive = false): Observable<Budget[]> { ... }
  getOverview(): Observable<BudgetOverview> { ... }
  getHistory(month: string): Observable<BudgetHistory> { ... }
  create(request: BudgetRequest): Observable<Budget> { ... }
  update(id: string, request: BudgetRequest): Observable<Budget> { ... }
  delete(id: string): Observable<void> { ... }

  refresh(): void { this.refreshTrigger.update(v => v + 1); }
}
```

---

## R-004: Modal pattern pour le formulaire budget

**Decision**: Utiliser le `ModalService` existant avec un nouveau type `'budget'`. Le formulaire `BudgetForm` est un composant standalone avec `input()` / `output()`.

**Rationale**: Pattern identique à `ProductForm`, `TransactionForm`, etc. Le `Shell` gère la logique save/delete.

**Alternatives considered**: Aucune — pattern imposé par l'architecture existante.

**Ajouts**:
- `ModalType` : ajouter `'budget'`
- `Shell` : ajouter `@case('budget')` dans le switch + handler `onBudgetSaved()`
- `BudgetForm` : `input<Budget | null>()` + `output<BudgetRequest>()`

---

## R-005: Sélecteur de mois

**Decision**: Réutiliser le pattern du dashboard (`selectedMonth` / `selectedYear` signals + navigation avant/arrière). Le format de mois est `yyyy-MM` (même format que l'API `/budgets/history?month=yyyy-MM`).

**Rationale**: Pattern existant dans le dashboard. L'API history attend un `month` au format `yyyy-MM`.

**Alternatives considered**:
- Datepicker complet : trop lourd pour une navigation mensuelle

---

## R-006: Catégorie "Autre" (non budgétées)

**Decision**: L'API `BudgetOverviewResponse` inclut déjà une catégorie "Autre" agrégée côté backend. Le frontend l'affiche telle quelle avec une couleur grise par défaut.

**Rationale**: La logique d'agrégation est côté backend (conformément au principe API-First). Le frontend ne fait que l'afficher.

**Alternatives considered**: Calcul côté frontend — rejeté (violerait API-First).

---

## R-007: Doughnut Chart — total au centre

**Decision**: Utiliser un plugin Chart.js custom (inline) pour afficher le total des dépenses au centre du Doughnut. Le plugin dessine le texte via l'API Canvas dans le hook `afterDraw`.

**Rationale**: Chart.js ne supporte pas nativement le texte au centre d'un Doughnut. Un plugin inline est la solution standard (documentée dans la doc Chart.js).

**Alternatives considered**:
- Overlay HTML positionné en absolu : fragile, problèmes de responsive
- Plugin Chart.js externe (chartjs-plugin-doughnutlabel) : dépendance supplémentaire inutile

---

## R-008: Icône Phosphor pour Budgets

**Decision**: Utiliser `phosphorChartPie` / `phosphorChartPieFill` pour l'entrée navigation Budgets.

**Rationale**: L'app utilise Phosphor Icons. `ChartPie` représente bien la répartition budgétaire. Déjà disponible dans `@ng-icons/phosphor-icons`.

**Alternatives considered**:
- `phosphorChartBar` : déjà utilisé comme placeholder dans settings
- `phosphorWallet` : trop générique
