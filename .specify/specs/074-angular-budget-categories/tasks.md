# Tasks: Budgets par catégorie — Angular

**Input**: Design documents from `/specs/074-angular-budget-categories/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Non demandés explicitement — pas de tâches de test générées.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4, US5)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup

**Purpose**: Installation dépendances et création des modèles de base

- [x] T001 Installer ng2-charts et chart.js — `cd app && npm install ng2-charts chart.js`
- [x] T002 Créer les interfaces TypeScript Budget, BudgetRequest, BudgetOverview, BudgetHistory et constantes FREQUENCIES dans `app/src/app/core/models/budget.model.ts` (voir data-model.md)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infrastructure partagée nécessaire à TOUTES les user stories

**⚠️ CRITICAL**: Aucune user story ne peut démarrer avant la fin de cette phase

- [x] T003 [P] Ajouter `'BUDGETS'` au type union `Feature` et à la constante `FEATURES` (value: `'BUDGETS'`, label: `'Budgets'`, icon: `'phosphorChartPie'`, filledIcon: `'phosphorChartPieFill'`, description: `'Suivre vos budgets par catégorie'`, route: `'/budgets'`) dans `app/src/app/core/models/preference.model.ts`
- [x] T004 [P] Créer le BudgetService signal-based dans `app/src/app/core/services/budget.ts` — inject ApiService, méthodes : `getAll(includeInactive?)`, `getOverview()`, `getHistory(month)`, `getById(id)`, `create(request)`, `update(id, request)`, `delete(id)`, signal `refreshTrigger`, méthode `refresh()`. Endpoints : `/budgets`, `/budgets/overview`, `/budgets/history?month=`, `/budgets/{id}`. Suivre le pattern ProductService existant.
- [x] T005 [P] Ajouter `'budget'` au type `ModalType` et les titres correspondants (créer: `'Nouveau budget'`, éditer: `'Modifier le budget'`) dans `app/src/app/core/services/modal.service.ts`

**Checkpoint**: Foundation prête — les user stories peuvent démarrer

---

## Phase 3: User Story 1 — Consulter l'aperçu des budgets sur le dashboard (Priority: P1) 🎯 MVP

**Goal**: Section "Budgets" sur le dashboard avec total dépensé/budgété et top 5 catégories avec barres de progression colorées

**Independent Test**: Ouvrir le dashboard avec la feature BUDGETS activée → section visible avec barres de progression. Feature désactivée → section masquée. Aucun budget → état vide avec CTA.

### Implementation for User Story 1

- [x] T006 [US1] Créer le composant BudgetSummary (standalone, OnPush) dans `app/src/app/features/dashboard/components/budget-summary/budget-summary.ts` — inject BudgetService, signal `overview` (BudgetOverview | null), signal `loading`, signal `error`. Afficher : titre "Budgets" avec lien "Voir tout" → `/budgets`, total dépensé/budgété (AmountPipe), top 5 items triés par percentage décroissant avec barres de progression (couleur = categoryCouleur, largeur = percentage%), montant en rouge si percentage > 100. État vide : message + bouton "Créer un budget" qui ouvre la modale budget (ModalService). État loading : spinner. État erreur : message + retry.
- [x] T007 [US1] Intégrer BudgetSummary dans le dashboard — modifier `app/src/app/features/dashboard/dashboard.ts` : importer BudgetSummary, ajouter `<app-budget-summary>` juste après la section résumé mensuel, conditionner l'affichage à `preferenceService.isEnabled('BUDGETS')`.

**Checkpoint**: Dashboard affiche la section Budgets avec données réelles

---

## Phase 4: User Story 2 — Gérer les budgets depuis l'écran dédié (Priority: P1)

**Goal**: Écran `/budgets` listant tous les budgets du mois sélectionné avec sélecteur de mois, barres de progression, et actions CRUD

**Independent Test**: Naviguer vers `/budgets` → liste des budgets visible, naviguer entre les mois, supprimer un budget avec confirmation.

### Implementation for User Story 2

- [x] T008 [US2] Créer les routes budgets dans `app/src/app/features/budgets/budgets.routes.ts` — exporter `BUDGETS_ROUTES: Routes` avec path `''` → BudgetList et path `'details'` → BudgetDetail (lazy-loaded)
- [x] T009 [US2] Ajouter la route `/budgets` dans `app/src/app/app.routes.ts` — path `'budgets'`, `canActivate: [featureGuard]`, `data: { feature: 'BUDGETS' }`, `loadChildren` vers `budgets.routes.ts`
- [x] T010 [US2] Créer le composant BudgetList (standalone, OnPush) dans `app/src/app/features/budgets/budget-list/budget-list.ts` — signals : `selectedMonth`, `selectedYear`, `monthData` (`BudgetOverview | BudgetHistory | null`), `loading`, `error`. Sélecteur de mois (flèches ← → + label "Mars 2026"). Pour le mois courant : appeler `budgetService.getOverview()` → `BudgetOverview`. Pour les autres mois : appeler `budgetService.getHistory(yyyy-MM)` → `BudgetHistory`. **Stratégie de normalisation** : les deux interfaces partagent `month`, `totalBudget`, `totalSpent`, `percentage`, `currency`, `items[]` — chaque item a `categoryId`, `categoryNom`, `categoryIcone`, `categoryCouleur`, `montantBudget`, `currency`, `montantDepense`, `percentage`. Les champs spécifiques (`budgetId`, `montantBudgetNormalise`, `frequence` pour Overview ; `tauxChange`, `createdAt` pour History) ne sont pas utilisés dans la liste. Le template peut donc consommer les champs communs sans distinction de type. Liste de tous les items avec : icône catégorie, nom, barre de progression (couleur categoryCouleur), montant dépensé/budgété, percentage. Montant rouge si > 100%. Catégorie "Autre" affichée telle quelle. Effect sur `budgetService.refreshTrigger()` pour recharger. **Gestion d'erreur** : signal `error` (string | null), si erreur → afficher message + bouton "Réessayer" (appelle `loadData()`), même pattern que BudgetSummary (T006).
- [x] T010b [US2] Ajouter les actions CRUD dans BudgetList — modifier `app/src/app/features/budgets/budget-list/budget-list.ts` : bouton "Nouveau budget" en haut (désactivé avec tooltip si toutes les catégories ont un budget). Chaque item : boutons edit (ouvre modale via ModalService) et delete (confirmation dialog → `budgetService.delete()` → refresh).

**Checkpoint**: Écran /budgets fonctionnel avec navigation mois et liste

---

## Phase 5: User Story 3 — Créer ou modifier un budget (Priority: P1)

**Goal**: Formulaire en modale pour créer/modifier un budget avec validation

**Independent Test**: Ouvrir le formulaire → catégories filtrées (sans budget existant) en création. Remplir et soumettre → budget créé. Éditer → champs pré-remplis.

### Implementation for User Story 3

- [x] T011 [US3] Créer le composant BudgetForm (standalone, OnPush) dans `app/src/app/features/budgets/components/budget-form/budget-form.ts` — `input<Budget | null>()` (null = création), `output<BudgetRequest>()`. Reactive Forms group : categoryId (required), montant (required, min 0.01), frequence (required), currency (défaut EUR), seuilNotification (min 0, max 100, défaut 80), actif (défaut true). En mode création : charger les catégories via CategoryService, filtrer celles qui ont déjà un budget (via BudgetService.getAll()). Si la liste filtrée est vide (toutes les catégories ont un budget), désactiver le bouton de soumission avec message explicatif. En mode édition : pré-remplir, catégorie non modifiable. Utiliser FormField existant. Selects pour catégorie (avec icône), fréquence (FREQUENCIES constante), devise (currencies du PreferenceService).
- [x] T012 [US3] Intégrer le formulaire budget dans le Shell — modifier `app/src/app/shared/components/shell/shell.ts` : importer BudgetForm, ajouter `@case('budget')` dans le switch du template modal avec `<app-budget-form>`, implémenter `onBudgetSaved(request: BudgetRequest)` (create ou update via BudgetService, closeModal, refresh). Passer `editingEntity` comme input budget.

**Checkpoint**: CRUD complet fonctionnel — créer, lire, modifier, supprimer des budgets

---

## Phase 6: User Story 4 — Visualiser la répartition des dépenses (Priority: P2)

**Goal**: Doughnut Chart sous la liste dans `/budgets` + vue détaillée `/budgets/details`

**Independent Test**: Naviguer vers `/budgets` → Doughnut visible sous la liste. Cliquer → `/budgets/details` avec graphique agrandi et liste détaillée.

### Implementation for User Story 4

- [x] T013 [US4] Ajouter le Doughnut Chart dans BudgetList — modifier `app/src/app/features/budgets/budget-list/budget-list.ts` : importer `BaseChartDirective` de ng2-charts, enregistrer `Chart.register(DoughnutController, ArcElement, Tooltip, Legend)`. Computed signal `chartData` depuis overview.items : labels = categoryNom, data = montantDepense, backgroundColor = categoryCouleur. Computed `chartOptions` avec plugin inline pour afficher le total au centre (afterDraw hook, ctx.canvas). Section sous la liste : `<canvas baseChart type="doughnut">` cliquable → `router.navigate(['/budgets/details'], { queryParams: { month: selectedMonth() } })`. Si aucune dépense : message "Aucune dépense ce mois" au lieu du chart.
- [x] T014 [US4] Créer le composant BudgetDetail (standalone, OnPush) dans `app/src/app/features/budgets/budget-detail/budget-detail.ts` — Doughnut Chart agrandi (même données que budget-list, taille plus grande). Liste des catégories avec : icône, nom, montant dépensé, pourcentage, couleur. Bouton retour vers `/budgets`. **Mois sélectionné** : récupéré via query param `month` (ex: `/budgets/details?month=2026-03`) — si absent, utiliser le mois courant. BudgetList passe le mois sélectionné en query param lors de la navigation vers details. Sélecteur de mois identique à BudgetList (flèches ← →), met à jour le query param via `router.navigate`. Pour le mois courant : `budgetService.getOverview()`, pour les autres : `budgetService.getHistory(month)`. **Gestion d'erreur** : signal `error` (string | null), si erreur → afficher message + bouton "Réessayer" (appelle `loadData()`), même pattern que T006/T010.

**Checkpoint**: Visualisation graphique complète

---

## Phase 7: User Story 5 — Accéder aux budgets via la navigation (Priority: P2)

**Goal**: Entrée "Budgets" dans sidebar/bottom nav + lien "Voir tout" dashboard

**Independent Test**: Activer BUDGETS → entrée visible dans nav. Désactiver → disparaît. Cliquer "Voir tout" → /budgets.

### Implementation for User Story 5

- [x] T015 [US5] Importer les icônes Phosphor et finaliser la navigation — Importer `phosphorChartPie` et `phosphorChartPieFill` dans le registre d'icônes centralisé (vérifier `app.config.ts` ou le module d'icônes existant). Vérifier que le computed `navItems` dans Shell génère bien l'entrée "Budgets" à partir de T003. Vérifier que le lien "Voir tout" dans BudgetSummary (T006) navigue vers `/budgets` via `routerLink`.

**Checkpoint**: Navigation complète — Budgets accessible depuis tous les points d'entrée

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Améliorations transverses

- [x] T016 [P] Ajouter l'action BUDGET dans le FAB — modifier `app/src/app/shared/components/fab/fab.ts` : ajouter une action conditionnelle "Nouveau budget" (icône `phosphorChartPie`) visible si `preferenceService.isEnabled('BUDGETS')` et si l'utilisateur est sur la route `/budgets`. L'action ouvre la modale budget.
- [x] T017 Validation quickstart et critères de succès — exécuter le scénario de `quickstart.md` : activer BUDGETS, naviguer vers /budgets, créer un budget, vérifier dashboard, vérifier Doughnut Chart, naviguer entre les mois. **Vérifier les critères de succès** : SC-001 (section dashboard visible sans délai perceptible), SC-003 (navigation mois fluide < 1s), SC-006 (responsive mobile 320px — vérifier via DevTools viewport).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — démarrage immédiat
- **Foundational (Phase 2)**: Dépend de Phase 1 — BLOQUE toutes les user stories
- **US1 Dashboard (Phase 3)**: Dépend de Phase 2
- **US2 Écran dédié (Phase 4)**: Dépend de Phase 2
- **US3 Formulaire (Phase 5)**: Dépend de Phase 2 + T010 (route /budgets pour contexte)
- **US4 Doughnut (Phase 6)**: Dépend de Phase 4 (T010 — BudgetList existe)
- **US5 Navigation (Phase 7)**: Dépend de Phase 2 (T003) + Phase 3 (T006 — lien "Voir tout")
- **Polish (Phase 8)**: Dépend de toutes les phases précédentes

### User Story Dependencies

```
Phase 1 (Setup)
    │
Phase 2 (Foundational: T003, T004, T005)
    │
    ├── US1 (T006, T007) ────────────────────┐
    │                                         │
    ├── US2 (T008, T009, T010, T010b) ──┐            │
    │                            │            │
    ├── US3 (T011, T012)         │            │
    │                            │            │
    │                     US4 (T013, T014)    │
    │                                         │
    └── US5 (T015) ◄──────────────────────────┘
                            │
                     Phase 8 (T016, T017)
```

### Parallel Opportunities

- **Phase 2**: T003, T004, T005 peuvent s'exécuter en parallèle (fichiers différents)
- **Après Phase 2**: US1 (T006-T007) et US2 (T008-T010) et US3 (T011-T012) en parallèle
- **Phase 4**: T008, T009 en parallèle (routes séparées)

---

## Parallel Example: After Phase 2

```bash
# Agent 1 — US1 Dashboard:
Task T006: "Créer BudgetSummary dans features/dashboard/components/budget-summary/"
Task T007: "Intégrer BudgetSummary dans dashboard.ts"

# Agent 2 — US2 Écran dédié:
Task T008: "Créer budgets.routes.ts"
Task T009: "Ajouter route /budgets dans app.routes.ts"
Task T010: "Créer BudgetList"

# Agent 3 — US3 Formulaire:
Task T011: "Créer BudgetForm"
Task T012: "Intégrer dans Shell"
```

---

## Implementation Strategy

### MVP First (User Stories P1)

1. Phase 1: Setup (T001-T002)
2. Phase 2: Foundational (T003-T005) — CRITIQUE
3. Phase 3: US1 Dashboard (T006-T007) — **Premier résultat visible**
4. Phase 4: US2 Écran dédié (T008-T010)
5. Phase 5: US3 Formulaire (T011-T012) — **CRUD complet**
6. **STOP et VALIDER** : tester le flux complet create/read/update/delete

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US1 → Dashboard section visible → **MVP déployable**
3. US2 + US3 → Écran dédié + CRUD → **Feature utilisable**
4. US4 → Doughnut Chart → **Analytique visuelle**
5. US5 + Polish → Navigation + FAB → **Expérience complète**

---

## Notes

- Tous les composants : standalone, OnPush, signals-first, inject()
- Pas de `subscribe()` manuel — utiliser `firstValueFrom()` ou `toSignal()`
- Pattern service : signals pour state, Observable pour HTTP, refreshTrigger pour réactivité
- Formulaire : Reactive Forms avec FormField existant
- Barres de progression : `width` en % via style binding, `background-color` via categoryCouleur
- Design tokens : utiliser `var(--token)` exclusivement, pas de valeurs hardcodées
- Commit après chaque tâche ou groupe logique
