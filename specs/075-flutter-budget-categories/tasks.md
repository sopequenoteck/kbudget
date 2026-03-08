# Tasks: Budgets par catégorie — Flutter

**Input**: Design documents from `/specs/075-flutter-budget-categories/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/budget-api.md, research.md, quickstart.md

**Tests**: Non demandés dans la spec. Non inclus.

**Organization**: Tasks groupées par user story. Chaque story est indépendamment testable après la phase fondamentale.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile**: `flutter/lib/src/` (source), `flutter/test/src/` (tests)
- Toutes les commandes depuis `flutter/`

---

## Phase 1: Setup

**Purpose**: Ajout dépendances et configuration enums

- [x] T001 Ajouter `fl_chart` au `flutter/pubspec.yaml` et exécuter `flutter pub get`
- [x] T002 [P] Ajouter `budgets` à l'enum `Feature` avec `@JsonValue('BUDGETS')`, label, icon (PhosphorIcons), description, defaultEnabled dans `flutter/lib/src/domain/enums/feature.dart`
- [x] T003 [P] Ajouter `ModalType.budget` à l'enum + entries dans les maps (modalCreateTitles, modalEditTitles, modalDefaultSubTypes, modalToggleLabels, modalToggleValues) dans `flutter/lib/src/domain/enums/modal_type.dart`

---

## Phase 2: Foundational (Domain + Data Layer)

**Purpose**: Couche domaine, données et state management partagée par TOUTES les user stories

**CRITICAL**: Aucune user story ne peut commencer avant complétion de cette phase

### Domain Models

- [x] T004 [P] Créer le modèle Freezed `Budget` dans `flutter/lib/src/domain/models/budget.dart` (id, categoryId, montant, frequence, currency, seuilNotification, actif, categoryNom, categoryIcone, categoryCouleur, spent, updatedAt)
- [x] T005 [P] Créer les modèles Freezed `BudgetOverview` + `BudgetOverviewItem` dans `flutter/lib/src/domain/models/budget_overview.dart` (month, totalBudget, totalSpent, percentage, currency, items; item: budgetId, categoryId, categoryNom, categoryIcone, categoryCouleur, montantBudget, montantBudgetNormalise, currency, montantDepense, percentage, frequence)
- [x] T006 [P] Créer les modèles Freezed `BudgetHistory` + `BudgetHistoryItem` dans `flutter/lib/src/domain/models/budget_history.dart` (month, totalBudget, totalSpent, percentage, currency, items; item: categoryId, categoryNom, categoryIcone, categoryCouleur, montantBudget, currency, tauxChange nullable, montantDepense, percentage, createdAt)
- [x] T007 [P] Créer l'interface abstraite `BudgetRepository` dans `flutter/lib/src/domain/repositories/budget_repository.dart` (getAll, getById, create, update, delete, getOverview, getHistory)

### Remote Data Layer

- [x] T008 [P] Créer les DTOs Freezed `BudgetRequest`, `BudgetResponse`, `BudgetOverviewResponse`, `BudgetOverviewItemResponse`, `BudgetHistoryResponse`, `BudgetHistoryItemResponse` dans `flutter/lib/src/data/remote/dtos/budget_dtos.dart` (calqués sur contracts/budget-api.md, avec fromJson/toJson)
- [x] T009 Créer `BudgetRemoteDataSource` dans `flutter/lib/src/data/remote/data_sources/budget_remote_data_source.dart` — 7 méthodes Dio : create(POST), getAll(GET ?includeInactive), getOverview(GET /overview), getHistory(GET /history?month), getById(GET /{id}), update(PUT /{id}), delete(DELETE /{id})

### Local Data Layer (Drift)

- [x] T010 [P] Ajouter les tables Drift `Budgets` et `BudgetSnapshots` dans `flutter/lib/src/data/local/database.dart` — colonnes selon data-model.md, ajouter `BudgetDao` à la liste des DAOs, incrémenter schemaVersion
- [x] T011 Créer `BudgetDao` dans `flutter/lib/src/data/local/daos/budget_dao.dart` — CRUD budgets + CRUD snapshots (getAllBudgets, getActiveBudgets, getBudgetById, insertBudget, updateBudget, deleteBudget, getSnapshotsByMonth, insertSnapshot)
- [x] T012 Ajouter les mappers `budgetFromDb`, `budgetToDb`, `snapshotFromDb`, `snapshotToDb` dans `flutter/lib/src/data/local/mappers.dart`

### Repository Implementations

- [x] T013 [P] Créer `BudgetRepositoryRemote` dans `flutter/lib/src/features/budgets/data/budget_repository_remote.dart` — injecte BudgetRemoteDataSource, convertit DTOs ↔ domain models
- [x] T014 [P] Créer `BudgetRepositoryLocal` dans `flutter/lib/src/features/budgets/data/budget_repository_local.dart` — injecte BudgetDao, utilise mappers, implémente getOverview/getHistory localement (calcul client-side depuis tables budget + transactions)

### Data Mode Provider

- [x] T015 Ajouter `budgetRepositoryProvider` dans `flutter/lib/src/data/data_mode_provider.dart` — strategy pattern local/remote identique aux autres repositories

### Code Generation

- [x] T016 Exécuter `dart run build_runner build --delete-conflicting-outputs` pour générer les fichiers `.freezed.dart`, `.g.dart` et les fichiers Drift

### Application Layer

- [x] T017 Créer `BudgetListState` Freezed dans `flutter/lib/src/features/budgets/application/budget_list_state.dart` (extends ListState pattern: items, isLoading, error, currentPage, hasMore, mutatingIds + overview, history, selectedMonth, selectedYear)
- [x] T018 Créer `BudgetNotifier` extends `Notifier<BudgetListState>` dans `flutter/lib/src/features/budgets/application/budget_notifier.dart` — méthodes: build(), loadItems(), loadOverview(), loadHistory(month), create(), update(), delete(), setMonth(), refresh(), _refreshPage()

**Checkpoint**: Couche fondamentale complète — toutes les user stories peuvent commencer

---

## Phase 3: User Story 2 - Consulter la liste complète des budgets (Priority: P1) MVP

**Goal**: Écran dédié `/budgets` listant tous les budgets du mois sélectionné avec sélecteur de mois, skeleton loading et état vide

**Independent Test**: Naviguer vers `/budgets`, vérifier l'affichage de la liste, changer de mois, voir le skeleton loading

### Implementation for User Story 2

- [x] T019 [P] [US2] Créer le widget `BudgetItem` dans `flutter/lib/src/features/budgets/presentation/widgets/budget_item.dart` — icône catégorie (emoji/couleur), nom, barre de progression (couleur catégorie, rouge si dépassement), montants (dépensé/budgété), skeleton factory constructor
- [x] T020 [P] [US2] Créer le widget `BudgetSummaryBar` dans `flutter/lib/src/features/budgets/presentation/widgets/budget_summary_bar.dart` — barre résumé global (total dépensé / total budget, pourcentage, barre de progression globale)
- [x] T021 [US2] Créer `BudgetListScreen` (ConsumerStatefulWidget) dans `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` — CustomScrollView avec: MonthSelector (existant), BudgetSummaryBar, SliverList de BudgetItem; états: loading (shimmer 5× BudgetItem.skeleton), erreur (retry), vide (incitation créer budget); limite navigation 12 mois arrière et mois courant max; tap item → ouvre formulaire édition via ModalNotifier
- [x] T022 [US2] Ajouter les routes `/budgets` et `/budgets/details` dans `flutter/lib/src/routing/app_router.dart` — dans ShellRoute, conditionnel Feature.budgets; ajouter l'entrée bottom nav pour budgets

**Checkpoint**: L'écran liste budgets est fonctionnel avec navigation mois et skeleton loading

---

## Phase 4: User Story 3 - Créer et modifier un budget (Priority: P1)

**Goal**: Formulaire modal bottom sheet pour créer/éditer un budget (catégorie filtrée, montant, devise, fréquence, seuil notification)

**Independent Test**: Ouvrir le formulaire via FAB, créer un budget, vérifier la liste se rafraîchit; éditer un budget existant

### Implementation for User Story 3

- [x] T023 [US3] Créer `BudgetForm` (ConsumerStatefulWidget) dans `flutter/lib/src/features/budgets/presentation/widgets/budget_form.dart` — champs: catégorie (SelectPicker filtré sans budget existant, verrouillé en édition), montant (DecimalTextInputFormatter), devise (SelectPicker depuis currencies préférences), fréquence (SelectPicker HEBDOMADAIRE/MENSUEL/ANNUEL), seuil notification (Slider 50-100% par pas de 5%); validation lazy (_showErrors); mode create/edit via ModalNotifier; boutons Annuler + Sauvegarder
- [x] T024 [US3] Intégrer `BudgetForm` dans le système modal — ajouter le `@case` pour `ModalType.budget` dans le shell (AppModal), connecter le FAB "+" sur `/budgets` pour ouvrir `ModalType.budget` dans `flutter/lib/src/routing/app_router.dart` ou le shell scaffold

**Checkpoint**: La création et édition de budgets fonctionne via le formulaire modal

---

## Phase 5: User Story 1 - Consulter l'aperçu budgets sur le dashboard (Priority: P1)

**Goal**: Section "Budgets" sur le dashboard montrant résumé du mois courant (total + top 5 catégories avec barres de progression)

**Independent Test**: Créer des budgets via l'API, ouvrir le dashboard, vérifier la section Budgets avec les données du mois courant

### Implementation for User Story 1

- [x] T025 [US1] Créer `BudgetSummarySection` dans `flutter/lib/src/features/dashboard/presentation/widgets/budget_summary_section.dart` — ConsumerWidget; header "Budgets" + lien "Voir tout" (context.push('/budgets')); charge overview via budgetNotifier.loadOverview(); top 5 items triés par % dépensé décroissant avec BudgetItem compact (barre progression + montants); total footer (dépensé/budget); états: loading (shimmer), erreur (retry); conditionnel: masqué si feature BUDGETS désactivée OU aucun budget actif
- [x] T026 [US1] Intégrer `BudgetSummarySection` dans le dashboard — ajouter la section dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` après les sections existantes, conditionnelle sur `enabledFeatures.contains(Feature.budgets)`

**Checkpoint**: Le dashboard affiche la section budgets avec le résumé du mois courant

---

## Phase 6: User Story 4 - Supprimer un budget (Priority: P2)

**Goal**: Bouton supprimer dans le formulaire d'édition avec confirmation via confirm_delete_dialog

**Independent Test**: Ouvrir un budget en édition, taper Supprimer, confirmer, vérifier la disparition de la liste

### Implementation for User Story 4

- [x] T027 [US4] Ajouter le bouton "Supprimer" dans `BudgetForm` (mode édition uniquement) dans `flutter/lib/src/features/budgets/presentation/widgets/budget_form.dart` — bouton rouge à gauche des actions, appelle `showDeleteConfirmDialog()`, si confirmé → `budgetNotifier.delete(id)` + ferme le modal

**Checkpoint**: La suppression de budget fonctionne avec confirmation

---

## Phase 7: User Story 5 - Consulter l'historique avec graphique camembert (Priority: P2)

**Goal**: Camembert résumé sur l'écran liste + écran détail `/budgets/details` avec camembert interactif et bottom sheet catégorie

**Independent Test**: Naviguer vers l'écran budgets avec des données, voir le camembert, taper dessus → écran détail, taper une portion → bottom sheet avec transactions

### Implementation for User Story 5

- [x] T028 [P] [US5] Créer le widget `BudgetPieChart` dans `flutter/lib/src/features/budgets/presentation/widgets/budget_pie_chart.dart` — fl_chart PieChart avec sections colorées par catégorie (categoryCouleur), touch callback pour sélection de portion; props: items (overview ou history), onSectionTapped callback, clickable flag; pas de légende (infos dans les items de liste)
- [x] T029 [US5] Intégrer le camembert résumé dans `BudgetListScreen` — ajouter `BudgetPieChart` en haut de la liste (SliverToBoxAdapter) quand des données existent, clickable=true, tap → `context.push('/budgets/details?month=YYYY-MM')` dans `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart`
- [x] T030 [US5] Créer `BudgetDetailScreen` (ConsumerStatefulWidget) dans `flutter/lib/src/features/budgets/presentation/budget_detail_screen.dart` — parse query param `month`; MonthSelector; BudgetPieChart (clickable=false); liste détaillée des items avec pourcentage; mois courant → données overview live, mois passé → données history (snapshots) + portion "Autre" pour non-budgétées; états: loading, erreur, vide
- [x] T031 [US5] Créer le bottom sheet détail catégorie dans `flutter/lib/src/features/budgets/presentation/widgets/budget_category_detail_sheet.dart` — affiché au tap sur une portion du camembert dans l'écran détail; contenu: icône + nom catégorie, montant dépensé, pourcentage, liste des transactions du mois filtrées par categoryId (données locales, pas de nouvel endpoint)

**Checkpoint**: Le graphique camembert et l'écran détail historique sont fonctionnels

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Intégration finale, cohérence et validation

- [x] T032 Vérifier la cohérence visuelle des écrans budgets avec le design system — tokens AppSpacing, AppColors, AppRadius, AppTypography dans tous les widgets créés
- [x] T033 Exécuter `flutter analyze` et corriger les warnings/erreurs dans `flutter/`
- [x] T034 Exécuter `flutter test` et vérifier que les tests existants passent toujours dans `flutter/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — peut commencer immédiatement
- **Foundational (Phase 2)**: Dépend de Setup — BLOQUE toutes les user stories
- **US2 Liste (Phase 3)**: Dépend de Foundational — premier écran à implémenter
- **US3 Form (Phase 4)**: Dépend de US2 (FAB sur l'écran liste ouvre le formulaire)
- **US1 Dashboard (Phase 5)**: Dépend de Foundational uniquement (indépendant de US2/US3 mais mieux après pour tester le lien "Voir tout")
- **US4 Delete (Phase 6)**: Dépend de US3 (bouton dans le formulaire)
- **US5 History (Phase 7)**: Dépend de US2 (intégration camembert dans la liste)
- **Polish (Phase 8)**: Dépend de toutes les stories complétées

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational)
    ↓
Phase 3 (US2: Liste) ←──── Phase 5 (US1: Dashboard) [indépendant]
    ↓
Phase 4 (US3: Form)
    ↓                ↘
Phase 6 (US4: Delete)  Phase 7 (US5: History/Chart)
    ↓                ↙
Phase 8 (Polish)
```

### Within Each User Story

- Widgets UI (marqués [P]) avant écrans
- Écrans avant intégration
- Intégration en dernier

### Parallel Opportunities

- T002 + T003 (enums) en parallèle
- T004 + T005 + T006 + T007 (domain models + repo interface) en parallèle
- T008 + T010 (DTOs remote + tables Drift) en parallèle
- T013 + T014 (repo remote + repo local) en parallèle
- T019 + T020 (widgets BudgetItem + BudgetSummaryBar) en parallèle
- US1 (dashboard) peut être implémenté en parallèle de US2/US3 si besoin

---

## Parallel Example: Phase 2 Foundational

```bash
# Parallèle 1: Domain models (T004, T005, T006, T007)
Task: "Créer Budget model dans flutter/lib/src/domain/models/budget.dart"
Task: "Créer BudgetOverview model dans flutter/lib/src/domain/models/budget_overview.dart"
Task: "Créer BudgetHistory model dans flutter/lib/src/domain/models/budget_history.dart"
Task: "Créer BudgetRepository interface dans flutter/lib/src/domain/repositories/budget_repository.dart"

# Parallèle 2: Data layer (T008, T010) — après T004-T007
Task: "Créer DTOs Freezed dans flutter/lib/src/data/remote/dtos/budget_dtos.dart"
Task: "Ajouter tables Drift dans flutter/lib/src/data/local/database.dart"

# Parallèle 3: Repo impls (T013, T014) — après T009, T011, T012
Task: "Créer BudgetRepositoryRemote dans flutter/lib/src/features/budgets/data/budget_repository_remote.dart"
Task: "Créer BudgetRepositoryLocal dans flutter/lib/src/features/budgets/data/budget_repository_local.dart"
```

---

## Implementation Strategy

### MVP First (US2 + US3: Liste + Formulaire)

1. Compléter Phase 1: Setup
2. Compléter Phase 2: Foundational (CRITICAL)
3. Compléter Phase 3: US2 (liste budgets avec navigation mois)
4. Compléter Phase 4: US3 (formulaire création/édition)
5. **STOP et VALIDER**: Tester CRUD complet sur l'écran budgets
6. Déployer/demo si prêt

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US2 (Liste) → Écran principal fonctionnel
3. US3 (Form) → CRUD complet → **MVP deployable**
4. US1 (Dashboard) → Résumé visible au lancement
5. US4 (Delete) → Gestion complète
6. US5 (History/Chart) → Visualisation avancée
7. Polish → Qualité finale

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label relie la tâche à la user story pour traçabilité
- Commit après chaque tâche ou groupe logique
- Exécuter `build_runner` après chaque ajout de modèle Freezed ou table Drift (T016)
- Vérifier `flutter analyze` régulièrement pendant le développement
