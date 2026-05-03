# Tasks: Écran Transactions (liste + filtres)

**Input**: Design documents from `/specs/012-transaction-list/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: Non demandés dans la spec. Pas de tâches de test générées.

**Organization**: Tasks groupées par user story. Toutes les modifications portent sur les 3 mêmes fichiers (`transactions.ts`, `transactions.html`, `transactions.scss`), donc l'exécution est séquentielle.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Frontend**: `app/src/app/` (Angular monorepo)

---

## Phase 1: Setup

**Purpose**: Aucune initialisation nécessaire — projet existant, dépendances installées, fichiers stub déjà créés.

> Phase 1 est vide. Passer directement à Phase 2.

---

## Phase 2: Foundational (Scaffold du composant)

**Purpose**: Mettre en place le squelette du composant avec les signals d'état, les imports, et la méthode de chargement des données. BLOQUE toutes les user stories.

- [x] T001 Implémenter le scaffold du composant Transactions avec les signals d'état (selectedMonth, selectedYear, typeFilter, loading, error, transactions, summary), les signals dérivés (selectedMonthLabel, filteredTransactions), les imports (ListItem, AmountPipe, RelativeDatePipe, NgClass, TransactionService), et la méthode loadData() avec effect() sur refreshTrigger. loadData() DOIT annuler l'appel HTTP précédent avant d'en lancer un nouveau (Subscription ou AbortController) pour gérer le changement de mois pendant un chargement. Fichier : `app/src/app/features/transactions/transactions.ts`

**Checkpoint**: Le composant compile avec tous les signals et la méthode loadData(). Pas encore de template.

---

## Phase 3: User Story 1 - Consulter ses transactions du mois (Priority: P1) MVP

**Goal**: L'utilisateur voit la liste des transactions du mois courant avec le résumé mensuel (recettes, dépenses, solde) et les états loading/empty.

**Independent Test**: Naviguer vers `/transactions` → la liste du mois courant s'affiche avec le résumé. Si aucune transaction, le message "Aucune transaction" apparaît. Pendant le chargement, un spinner est visible.

### Implementation for User Story 1

- [x] T002 [US1] Implémenter le template avec le résumé mensuel (3 cartes : recettes en vert, dépenses en rouge, solde), la liste des transactions via `ListItem` (icon=catégorie, title=libellé, subtitle=catégorie, value=montant via AmountPipe, rightSubtitle=date via RelativeDatePipe, valueClass=amount-income/amount-expense), et les états loading (spinner CSS) et empty ("Aucune transaction") dans `app/src/app/features/transactions/transactions.html`
- [x] T003 [US1] Implémenter les styles : layout résumé mensuel (3 cartes en flexbox), couleurs recettes/dépenses (--color-income/--color-expense), spinner CSS pour l'état loading, état vide centré, et spacing général via design tokens dans `app/src/app/features/transactions/transactions.scss`

**Checkpoint**: L'écran affiche les transactions du mois courant avec résumé, loading et empty state. MVP fonctionnel.

---

## Phase 4: User Story 2 - Filtrer par mois et année (Priority: P2)

**Goal**: L'utilisateur peut naviguer entre les mois via des flèches prev/next. La liste et le résumé se mettent à jour.

**Independent Test**: Cliquer sur ◀/▶ pour changer de mois → la liste et le résumé se mettent à jour. Le label affiche "Mois Année". Le passage décembre→janvier change l'année.

### Implementation for User Story 2

- [x] T004 [US2] Ajouter les méthodes prevMonth() et nextMonth() (gestion du passage décembre↔janvier avec changement d'année) et le rechargement des données via loadData() dans `app/src/app/features/transactions/transactions.ts`
- [x] T005 [US2] Ajouter le sélecteur de mois dans le template : bouton ◀ (prevMonth), label central selectedMonthLabel(), bouton ▶ (nextMonth), avec aria-labels pour l'accessibilité dans `app/src/app/features/transactions/transactions.html`
- [x] T006 [US2] Ajouter les styles du sélecteur de mois : layout flexbox centré, boutons prev/next tactiles (min 44px), label en font-weight semibold dans `app/src/app/features/transactions/transactions.scss`

**Checkpoint**: Navigation mois fonctionnelle. La liste et le résumé se mettent à jour à chaque changement.

---

## Phase 5: User Story 3 - Filtrer par type de transaction (Priority: P2)

**Goal**: L'utilisateur peut filtrer la liste par type : Tous, Dépenses, Recettes. Le filtrage est instantané (côté client).

**Independent Test**: Cliquer sur "Dépenses" → seules les dépenses sont affichées. Cliquer sur "Tous" → toutes les transactions réapparaissent.

### Implementation for User Story 3

- [x] T007 [US3] Ajouter la méthode setTypeFilter(type) pour mettre à jour le signal typeFilter dans `app/src/app/features/transactions/transactions.ts`
- [x] T008 [US3] Ajouter le toggle de filtre type dans le template : 3 boutons (Tous, Dépenses, Recettes) avec classe .active selon typeFilter(), rôle group et aria-label dans `app/src/app/features/transactions/transactions.html`
- [x] T009 [US3] Ajouter les styles du toggle filtre type : même pattern que le type-toggle des formulaires existants (boutons segmentés, .active avec --color-primary) dans `app/src/app/features/transactions/transactions.scss`

**Checkpoint**: Filtrage par type instantané. Combinable avec le filtre mois/année.

---

## Phase 6: User Story 4 - Gestion des erreurs réseau (Priority: P3)

**Goal**: En cas d'erreur réseau, un message d'erreur s'affiche avec un bouton "Réessayer".

**Independent Test**: Couper le backend → l'écran affiche "Erreur de chargement" avec un bouton "Réessayer". Cliquer → le chargement est relancé.

### Implementation for User Story 4

- [x] T010 [US4] Ajouter l'état erreur dans le template : message "Erreur de chargement" avec bouton "Réessayer" qui appelle loadData(), affiché quand error() est true dans `app/src/app/features/transactions/transactions.html`
- [x] T011 [US4] Ajouter les styles de l'état erreur : message centré, bouton retry avec style btn-outline dans `app/src/app/features/transactions/transactions.scss`

**Checkpoint**: Tous les états (loading, data, empty, error) sont fonctionnels.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales et validation

- [x] T012 Vérifier le lint (`cd app && ng lint`) et le formatage (`cd app && npm run format`) sur les fichiers modifiés
- [x] T013 Valider le quickstart.md : tester les 6 scénarios de validation listés dans `specs/012-transaction-list/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 2 (Foundational)**: Aucune dépendance — commence immédiatement
- **Phase 3 (US1)**: Dépend de Phase 2 (scaffold du composant)
- **Phase 4 (US2)**: Dépend de Phase 3 (template et styles de base)
- **Phase 5 (US3)**: Dépend de Phase 3 (template et styles de base). Peut être parallélisé avec Phase 4 si travaillé par deux personnes.
- **Phase 6 (US4)**: Dépend de Phase 3 (template de base)
- **Phase 7 (Polish)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US1 (P1)**: Dépend de Phase 2 (scaffold). Aucune dépendance sur d'autres stories.
- **US2 (P2)**: Dépend de US1 (template de base où insérer le sélecteur de mois).
- **US3 (P2)**: Dépend de US1 (template de base où insérer le toggle). Indépendant de US2.
- **US4 (P3)**: Dépend de US1 (template de base où insérer l'état erreur). Indépendant de US2/US3.

### Within Each User Story

- TypeScript avant template HTML (les méthodes doivent exister avant d'être référencées)
- Template avant SCSS (les classes doivent exister avant d'être stylées)

### Parallel Opportunities

- US2 et US3 peuvent être développées en parallèle (ajouts indépendants au template)
- T010 et T011 (US4) sont parallélisables (fichiers différents : html vs scss)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001 : Scaffold du composant (Phase 2)
2. T002-T003 : Liste + résumé + loading/empty (Phase 3)
3. **STOP and VALIDATE** : Naviguer vers `/transactions`, vérifier l'affichage
4. Déployer si prêt

### Incremental Delivery

1. Phase 2 → Scaffold → Composant compile
2. Phase 3 (US1) → Liste + résumé → MVP fonctionnel
3. Phase 4 (US2) → Navigation mois → Vision historique
4. Phase 5 (US3) → Filtre type → Analyse ciblée
5. Phase 6 (US4) → Gestion erreurs → Robustesse
6. Phase 7 → Lint + validation finale

---

## Notes

- Toutes les modifications portent sur 3 fichiers dans `app/src/app/features/transactions/`
- Aucun nouveau fichier source à créer (les stubs existent)
- Les composants partagés (ListItem, AmountPipe, RelativeDatePipe) sont uniquement importés
- Le TransactionService et ses méthodes (getAll, getSummary, refreshTrigger) sont existants
- Commit recommandé après chaque phase complétée
