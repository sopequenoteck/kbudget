# Tasks: Budgets par catégorie — suivi des dépenses avec snapshots mensuels

**Input**: Design documents from `/specs/076-budget-category-tracking/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Context**: Les budgets (CRUD, dashboard, historique, camembert) sont déjà implémentés (KKS-073/074/075). Ce ticket couvre le **delta** : catégorie "Autre", notifications de seuil, toggle actif/inactif UI, et corrections du mode local Flutter.

**FR déjà couverts par KKS-073/074/075** (aucune tâche nécessaire) : FR-001, FR-002, FR-003, FR-004, FR-006, FR-008, FR-010, FR-011, FR-012, FR-013, FR-016, FR-017, FR-018.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Enrichir les enums et DTOs partagés nécessaires à toutes les user stories

- [X] T001 [P] Ajouter `BUDGET_THRESHOLD` et `BUDGET_EXCEEDED` dans `api/src/main/java/fr/kksdev/budget/api/enums/NotificationType.java`
- [X] T002 [P] Ajouter `BUDGET` dans `api/src/main/java/fr/kksdev/budget/api/enums/EntityType.java`
- [X] T003 [P] Créer le DTO `UnbudgetedItemResponse` dans `api/src/main/java/fr/kksdev/budget/api/dto/response/UnbudgetedItemResponse.java` avec les champs : categoryId (UUID), categoryNom (String), categoryIcone (String), categoryCouleur (String), montantDepense (BigDecimal)
- [X] T004 [P] Ajouter les champs `unbudgetedItems` (List\<UnbudgetedItemResponse\>) et `unbudgetedTotal` (BigDecimal) dans `api/src/main/java/fr/kksdev/budget/api/dto/response/BudgetOverviewResponse.java`
- [X] T005 [P] Ajouter les champs `unbudgetedItems` (List\<UnbudgetedItemResponse\>) et `unbudgetedTotal` (BigDecimal) dans `api/src/main/java/fr/kksdev/budget/api/dto/response/BudgetHistoryResponse.java`

**Checkpoint**: Enums et DTOs prêts. Les endpoints existants retournent `unbudgetedItems: []` et `unbudgetedTotal: 0` par défaut.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Query infrastructure pour les dépenses non budgétées

**⚠️ CRITICAL**: Les phases US2 et US5 dépendent de cette phase

- [X] T006 Ajouter la query `findUnbudgetedSpendingByMonth` dans `api/src/main/java/fr/kksdev/budget/api/repository/TransactionRepository.java` — query JPQL : somme des dépenses par catégorie pour un mois donné, excluant les catégories ayant un budget actif (voir data-model.md pour la query exacte). Retourner une List de projections (categoryId, categoryNom, categoryIcone, categoryCouleur, montantDepense)
- [X] T007 Ajouter la query `existsByTypeAndEntityTypeAndEntityIdAndCreatedAtBetween` dans `api/src/main/java/fr/kksdev/budget/api/repository/NotificationRepository.java` — pour vérifier qu'une notification de seuil n'a pas déjà été envoyée pour un budget donné dans le mois courant

**Checkpoint**: Foundation ready — les user stories peuvent commencer

---

## Phase 3: User Story 2 — Catégorie "Autre" avec drill-down (Priority: P1) 🎯 MVP

**Goal**: Afficher les dépenses des catégories sans budget sous une entrée "Autre" cliquable avec drill-down, sur les trois plateformes

**Independent Test**: Avoir des dépenses dans des catégories sans budget, consulter l'overview ou l'historique, vérifier que "Autre" apparaît avec le total et que le tap affiche le détail par catégorie

### Backend

- [X] T008 [US2] Implémenter `getUnbudgetedSpending(User user, YearMonth month)` dans `api/src/main/java/fr/kksdev/budget/api/service/BudgetService.java` — appelle la query T006, convertit en devise principale si multi-devises, retourne une liste d'`UnbudgetedItemResponse` + le total
- [X] T009 [US2] Enrichir la méthode `getOverview()` dans `BudgetService.java` — appeler `getUnbudgetedSpending()` pour le mois courant et ajouter les résultats dans `BudgetOverviewResponse.unbudgetedItems` et `.unbudgetedTotal`
- [X] T010 [US2] Enrichir la méthode `getHistory()` dans `BudgetService.java` — appeler `getUnbudgetedSpending()` pour le mois demandé et ajouter les résultats dans `BudgetHistoryResponse.unbudgetedItems` et `.unbudgetedTotal`

### Angular

- [X] T011 [P] [US2] Ajouter l'interface `UnbudgetedItem` et enrichir `BudgetOverview` et `BudgetHistory` avec `unbudgetedItems` et `unbudgetedTotal` dans `app/src/app/core/models/budget.model.ts`
- [X] T012 [US2] Afficher la section "Autre" dans `app/src/app/features/budgets/components/budget-list/budget-list.ts` — après la liste des budgets, afficher une ligne "Autre" avec le total des dépenses non budgétées (si > 0), cliquable pour naviguer vers la vue détail avec un query param `showUnbudgeted=true`
- [X] T013 [US2] Afficher le drill-down "Autre" dans `app/src/app/features/budgets/components/budget-detail/budget-detail.ts` — si `showUnbudgeted=true` en query param ou si l'utilisateur tape sur la section "Autre" du camembert, afficher la liste détaillée des catégories non budgétées avec icône, couleur et montant
- [X] T014 [US2] Intégrer "Autre" dans le camembert `app/src/app/features/budgets/components/budget-chart.ts` — ajouter une section "Autre" (couleur grise) dans le doughnut chart si `unbudgetedTotal > 0`

### Flutter (remote)

- [X] T015 [P] [US2] Créer le modèle Freezed `UnbudgetedItem` dans `flutter/lib/src/domain/models/unbudgeted_item.dart` avec les champs categoryId, categoryNom, categoryIcone, categoryCouleur, montantDepense + json_serializable
- [X] T016 [P] [US2] Enrichir `BudgetOverview` avec `unbudgetedItems` (List\<UnbudgetedItem\>) et `unbudgetedTotal` (double) dans `flutter/lib/src/domain/models/budget_overview.dart`
- [X] T017 [P] [US2] Enrichir `BudgetHistory` avec `unbudgetedItems` (List\<UnbudgetedItem\>) et `unbudgetedTotal` (double) dans `flutter/lib/src/domain/models/budget_history.dart`
- [X] T018 [US2] Mettre à jour le mapping dans `flutter/lib/src/features/budgets/data/budget_repository_remote.dart` — passer les champs `unbudgetedItems` et `unbudgetedTotal` depuis les réponses API (BudgetOverviewResponse/BudgetHistoryResponse) vers les modèles domain `BudgetOverview` et `BudgetHistory`. S'assurer que les `UnbudgetedItem` sont correctement désérialisés via `fromJson`.
- [X] T019 [US2] Créer le widget `UnbudgetedDetailSheet` dans `flutter/lib/src/features/budgets/presentation/widgets/unbudgeted_detail_sheet.dart` — bottom sheet affichant la liste des catégories non budgétées avec icône, couleur et montant (même style que `BudgetCategoryDetailSheet`)
- [X] T020 [US2] Afficher la section "Autre" dans `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` — après la liste des budgets, afficher une ligne "Autre" avec le total (si > 0), tap ouvre `UnbudgetedDetailSheet`
- [X] T021 [US2] Intégrer "Autre" dans `flutter/lib/src/features/budgets/presentation/budget_detail_screen.dart` — ajouter "Autre" dans le camembert (section grise) et dans la liste des items, tap ouvre `UnbudgetedDetailSheet`

### Flutter (local)

- [X] T022 [US2] Ajouter la query `getUnbudgetedSpendingForMonth(int month, int year)` dans `flutter/lib/src/data/local/daos/budget_dao.dart` — SQL : somme des dépenses par catégorie non budgétée (voir data-model.md)
- [X] T023 [US2] Enrichir `getOverview()` dans `flutter/lib/src/features/budgets/data/budget_repository_local.dart` — appeler `getUnbudgetedSpendingForMonth()` et populer `unbudgetedItems` + `unbudgetedTotal` dans le `BudgetOverview` retourné
- [X] T024 [US2] Enrichir `getHistory()` dans `budget_repository_local.dart` — appeler `getUnbudgetedSpendingForMonth()` pour le mois demandé et populer les champs `unbudgetedItems` + `unbudgetedTotal` dans le `BudgetHistory` retourné

### Code generation

- [X] T025 [US2] Exécuter `dart run build_runner build --delete-conflicting-outputs` dans `flutter/` pour régénérer les fichiers `.freezed.dart` et `.g.dart` après les modifications des modèles (T015, T016, T017)

**Checkpoint**: "Autre" visible et cliquable sur les 3 plateformes. Le camembert inclut "Autre". Le drill-down fonctionne.

---

## Phase 4: User Story 3 — Toggle actif/inactif dans les UI (Priority: P2)

**Goal**: Permettre à l'utilisateur de désactiver/réactiver un budget depuis les interfaces Angular et Flutter

**Independent Test**: Désactiver un budget depuis le formulaire d'édition, vérifier qu'il disparaît du dashboard mais reste dans la liste avec le filtre "inclure inactifs"

### Angular

- [X] T026 [P] [US3] Ajouter un toggle switch "Actif" dans `app/src/app/features/budgets/components/budget-form/budget-form.ts` — visible uniquement en mode édition, envoie `actif: true/false` dans le `BudgetRequest`
- [X] T027 [P] [US3] Ajouter un toggle/filtre "Afficher les inactifs" dans `app/src/app/features/budgets/components/budget-list/budget-list.ts` — quand activé, appelle `getAll(true)` pour inclure les budgets inactifs ; les budgets inactifs sont affichés avec une opacité réduite

### Flutter

- [X] T028 [P] [US3] Ajouter un toggle switch "Actif" dans `flutter/lib/src/features/budgets/presentation/widgets/budget_form.dart` — visible uniquement en mode édition, met à jour le champ `actif` du budget
- [X] T029 [P] [US3] Ajouter un toggle/filtre "Afficher les inactifs" dans `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` — quand activé, charge les budgets incluant les inactifs ; les inactifs sont affichés avec une opacité réduite

**Checkpoint**: Toggle actif/inactif fonctionnel sur Angular et Flutter. Les budgets inactifs sont masqués du dashboard mais consultables dans la liste.

---

## Phase 5: User Story 4 — Corrections mode local Flutter (Priority: P2)

**Goal**: Corriger les snapshots lazy et la conversion multi-devises en mode local Flutter pour aligner le comportement sur le mode remote

**Independent Test**: En mode local, naviguer vers un mois passé et vérifier qu'un snapshot est créé automatiquement. Avoir des budgets en devises différentes et vérifier que les totaux sont convertis en devise principale.

### Snapshots lazy

- [X] T030 [US4] Implémenter la création lazy de snapshots dans `flutter/lib/src/features/budgets/data/budget_repository_local.dart` — dans `getHistory()`, si aucun snapshot n'existe pour le mois demandé ET le mois est passé, créer les snapshots à partir des budgets actifs actuels, des dépenses réelles du mois, et des taux de conversion depuis la table `exchange_rates`. Utiliser `BudgetDao` pour insérer les snapshots.
- [X] T031 [US4] Ajouter la méthode `insertSnapshot()` dans `flutter/lib/src/data/local/daos/budget_dao.dart` si elle n'existe pas déjà — insère un `BudgetSnapshot` dans la table Drift

### Multi-devises local

- [X] T032 [US4] Corriger la conversion multi-devises dans `getOverview()` de `budget_repository_local.dart` — pour chaque budget dont la devise diffère de la devise principale (lue depuis `AppConfig` via `appConfigRepositoryProvider`), chercher le taux dans la table `exchange_rates` Drift, appliquer la conversion sur `montantBudgetNormalise` et `montantDepense`. Fallback à 1.0 si aucun taux trouvé (log warning)

**Checkpoint**: Mode local Flutter aligné avec le mode remote. Snapshots lazy créés automatiquement, totaux multi-devises convertis correctement.

---

## Phase 6: User Story 5 — Notifications de seuil (Priority: P3)

**Goal**: Envoyer automatiquement une notification push + in-app quand les dépenses atteignent le seuil configuré (ex: 80%) ou dépassent 100% du budget

**Independent Test**: Créer un budget à 500 EUR avec seuil 80%, ajouter des transactions jusqu'à 400 EUR, vérifier qu'une notification BUDGET_THRESHOLD est créée. Ajouter jusqu'à 500 EUR, vérifier qu'une notification BUDGET_EXCEEDED est créée. Ajouter une autre transaction, vérifier qu'aucune notification supplémentaire n'est envoyée ce mois.

### Backend

- [X] T033 [US5] Implémenter `checkThresholdsForCategory(User user, UUID categoryId)` dans `api/src/main/java/fr/kksdev/budget/api/service/BudgetService.java` — trouver le budget actif pour cette catégorie, calculer les dépenses du mois courant, vérifier le franchissement du seuil ET de 100%, pour chaque seuil franchi vérifier via la query T007 qu'aucune notification n'existe déjà ce mois pour ce budget, si non : appeler `NotificationService.createNotification()` avec type `BUDGET_THRESHOLD` ou `BUDGET_EXCEEDED`, entityType `BUDGET`, entityId = budget.id, title et body descriptifs (nom catégorie + pourcentage). Logger au niveau INFO chaque notification envoyée (categoryName, percentage, budgetId).
- [X] T034 [US5] Intégrer l'appel à `checkThresholdsForCategory()` dans `api/src/main/java/fr/kksdev/budget/api/service/TransactionService.java` — après `createTransaction()`, `updateTransaction()` et `deleteTransaction()`, si la transaction est de type DEPENSE, appeler `budgetService.checkThresholdsForCategory(user, transaction.getCategory().getId())`. Injecter `BudgetService` dans `TransactionService`.

### Localisation Flutter

- [X] T035 [P] [US5] Ajouter les clés l10n pour les notifications budget dans `flutter/lib/src/localization/` — ex: `budgetThresholdTitle`, `budgetThresholdBody`, `budgetExceededTitle`, `budgetExceededBody` (pour l'affichage dans la liste des notifications in-app)

- [X] T040 [US5] Écrire les tests unitaires pour `checkThresholdsForCategory()` dans `api/src/test/java/.../service/BudgetServiceTest.java` — cas : franchissement seuil 80% → notification BUDGET_THRESHOLD créée, franchissement 100% → notification BUDGET_EXCEEDED créée, déduplication mensuelle (pas de doublon si notification existe déjà ce mois), transaction non-DEPENSE → aucune notification, budget inactif → aucune notification, seuil personnalisé (ex: 60%) respecté.

**Checkpoint**: Notifications de seuil fonctionnelles. Une seule notification par seuil franchi par mois. Push + in-app via le système de notifications existant (STOMP).

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales et cohérence cross-plateforme

- [X] T036 Exécuter les tests backend existants `cd api && mvn test -Dtest="BudgetServiceTest,BudgetControllerTest"` et corriger les éventuelles régressions dues aux modifications de DTOs (champs ajoutés)
- [X] T037 Exécuter les tests Flutter existants `cd flutter && flutter test test/src/features/budgets/` et corriger les éventuelles régressions
- [X] T041 Exécuter les tests Angular `cd app && ng test --include='**/budgets/**'` et corriger les éventuelles régressions — N/A : aucun test Angular dans le module budgets
- [X] T038 Vérifier la cohérence cross-plateforme : les données "Autre" sont identiques entre Angular et Flutter (remote), le camembert inclut "Autre" sur les deux plateformes, le toggle actif fonctionne de manière cohérente
- [X] T039 Exécuter `cd flutter && flutter analyze` pour vérifier qu'il n'y a pas de warnings/errors statiques

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — peut commencer immédiatement
- **Foundational (Phase 2)**: Dépend de Phase 1 (enums + DTOs)
- **US2 "Autre" (Phase 3)**: Dépend de Phase 2 (queries) — **MVP**
- **US3 Toggle (Phase 4)**: Dépend de Phase 1 uniquement — **parallélisable avec Phase 3**
- **US4 Local fixes (Phase 5)**: Dépend de Phase 3 (modèles Flutter enrichis)
- **US5 Notifications (Phase 6)**: Dépend de Phase 2 (query notification)
- **Polish (Phase 7)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **US2 (P1)**: Dépend de Phase 2. Bloque US4.
- **US3 (P2)**: Indépendant des autres US. Parallélisable avec US2.
- **US4 (P2)**: Dépend de US2 (modèles Freezed enrichis).
- **US5 (P3)**: Indépendant des autres US. Parallélisable avec US2/US3/US4.

### Parallel Opportunities

```
Phase 1: T001 || T002 || T003 || T004 || T005  (5 tâches en parallèle)
Phase 3: T011 || T015 || T016 || T017           (modèles Angular + Flutter en parallèle)
Phase 4: T026 || T027 || T028 || T029           (toggle Angular || Flutter en parallèle)
Phase 4: US3 peut être fait en parallèle de US2
Phase 6: US5 peut être fait en parallèle de US3/US4
```

---

## Parallel Example: User Story 2

```bash
# Backend séquentiel :
T008 → T009 → T010

# Angular + Flutter modèles en parallèle (après backend) :
T011 || T015 || T016 || T017

# Code generation Flutter :
T025 (après T015 + T016 + T017)

# Flutter remote mapping :
T018 (après T016 + T017)

# Angular UI séquentiel :
T012 → T013 → T014

# Flutter remote UI séquentiel :
T019 → T020 → T021

# Flutter local séquentiel :
T022 → T023 → T024

# Angular UI || Flutter remote UI || Flutter local (3 branches parallèles)
```

---

## Implementation Strategy

### MVP First (US2 — Catégorie "Autre")

1. Phase 1: Setup (enums + DTOs) — 5 tâches
2. Phase 2: Foundational (queries) — 2 tâches
3. Phase 3: US2 "Autre" — 17 tâches
4. **STOP et VALIDATE**: Vérifier "Autre" sur les 3 plateformes
5. Commit et déployer le MVP

### Incremental Delivery

1. Setup + Foundational → Infrastructure prête
2. US2 "Autre" → Test indépendamment → Commit (MVP!)
3. US3 Toggle → Test indépendamment → Commit
4. US4 Local fixes → Test indépendamment → Commit
5. US5 Notifications → Test indépendamment → Commit
6. Polish → Validation finale → Commit

---

## Notes

- [P] tasks = fichiers différents, pas de dépendances
- [Story] label = traçabilité vers la user story de la spec
- Pas de migration Flyway : le schéma est complet (V17), seuls les enums Java changent
- **Nouvelle dépendance inter-services** : T034 introduit `TransactionService → BudgetService`. Le DAG reste acyclique car `BudgetService` utilise `TransactionRepository` directement (pas `TransactionService`). Ne jamais injecter `TransactionService` dans `BudgetService` pour éviter un cycle.
- Les tests existants (41 backend, 20 Flutter) doivent continuer à passer
- Commit après chaque phase ou groupe logique
