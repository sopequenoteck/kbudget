# Tasks: Flutter — Écran Dettes Liste

**Input**: Design documents from `/specs/048-flutter-debts-list/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Organization**: Tasks grouped by user story pour implémentation et test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendances)
- **[Story]**: User story associée (US1, US2, US3, US4)
- Chemins exacts inclus dans chaque description

---

## Phase 1: Setup

**Purpose**: Créer les nouvelles structures de données et les clés i18n nécessaires à toutes les stories.

- [x] T001 [P] Create `DebtStatusFilter` enum (`all`, `enCours`, `rembourse`) in `flutter/lib/src/domain/enums/debt_status_filter.dart`
- [x] T002 [P] Create `DebtListState` Freezed class with `DebtCurrencySummary` typedef record `({double totalEmprunts, double totalPrets})` in `flutter/lib/src/features/debts/application/debt_list_state.dart` — fields: `items`, `isLoading`, `error`, `activeFilter` (default: `all`), `summary` (`Map<Currency, DebtCurrencySummary>`), `currentPage`, `hasMore`, `mutatingIds`
- [x] T003 [P] Add i18n keys for debt list screen in `flutter/lib/src/localization/app_fr.arb` and `flutter/lib/src/localization/app_en.arb` — keys: `debtsTitle`, `debtsSummaryEmprunts`, `debtsSummaryPrets`, `debtsSummaryNet`, `debtsFilterAll`, `debtsFilterEnCours`, `debtsFilterRembourse`, `debtsEmpty`, `debtsEmptyEnCours`, `debtsEmptyRembourse`, `debtsSectionPrets`, `debtsSectionEmprunts`, `debtBadgeRembourse`
- [x] T004 Run `dart run build_runner build --delete-conflicting-outputs` in `flutter/` to generate `debt_list_state.freezed.dart` (depends on T002)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migrer le notifier existant pour supporter le filtre et le résumé financier. BLOQUE toutes les user stories.

- [x] T005 Migrate `DebtNotifier` from `Notifier<ListState<Debt>>` to `Notifier<DebtListState>` in `flutter/lib/src/features/debts/application/debt_notifier.dart` — update provider type declaration, add `_computeSummary()` method (sum emprunts/prêts par Currency sur non-remboursées uniquement), add `_applyFilter(List<Debt>, DebtStatusFilter)` method, add public `setFilter(DebtStatusFilter)` method, update `_refreshPage()` to apply filter before pagination and always recompute summary on `_allItems`, update all `state.copyWith()` calls to use new `DebtListState` fields

**Checkpoint**: Notifier prêt — les user stories peuvent commencer.

---

## Phase 3: User Story 1 — Consulter la liste des dettes (Priority: P1) MVP

**Goal**: L'utilisateur voit ses dettes organisées en deux sections "Prêts" et "Emprunts" avec sous-totaux par devise, badge "Remboursé", et gestion des états loading/error/empty.

**Independent Test**: Ouvrir l'écran avec des dettes existantes et vérifier l'affichage des sections, items, sous-totaux et badge.

**Acceptance**: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-014, FR-015, FR-016

### Implementation

- [x] T006 [US1] Implement `DebtListScreen` base structure — convert `StatelessWidget` stub to `ConsumerStatefulWidget`, add `initState` with conditional `loadItems()` via `WidgetsBinding.addPostFrameCallback`, wrap in `RefreshIndicator` (onRefresh calls `notifier.refresh()` which preserves `activeFilter`) + `CustomScrollView`, add FAB bottom padding `SizedBox(height: AppSpacing.space12 * 2)` in `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`
- [x] T007 [US1] Implement `_buildContent` data state — partition `state.items` by `debt.sens` into prêts and emprunts lists (Prêts section first, then Emprunts section), render two sections each with: `SliverToBoxAdapter` section header (title + sub-totals per currency computed via `fold()`) + `SliverList.builder` with `ListItem` per debt (icon=category emoji or default, title=personne, subtitle=formatted date, value=formatted amount with currency, rightSubtitle="Remboursé" badge if `debt.rembourse` using `colorScheme.error` color), skip section entirely if list is empty, in `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`
- [x] T008 [US1] Implement loading, error, and empty states in `_buildContent` — loading: `Shimmer.fromColors` container placeholder (height ~80px, simple rounded rectangle) + `Column` of 5 `ListItem.skeleton()`, error: `SliverFillRemaining` with error icon + retry button calling `notifier.refresh()`, empty: `SliverFillRemaining` with empty icon + "Aucune dette" message, in `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`

**Checkpoint**: MVP fonctionnel — la liste des dettes s'affiche avec sections, sous-totaux, badge et gestion d'états.

---

## Phase 4: User Story 2 — Résumé financier (Priority: P2)

**Goal**: Une carte récapitulative affiche les totaux emprunts/prêts/solde net par devise (non-remboursées uniquement), avec couleurs sémantiques.

**Independent Test**: Créer des dettes de différents types et devises, vérifier les totaux et la coloration du solde net.

**Acceptance**: FR-007, FR-008, FR-009, FR-010

### Implementation

- [x] T009 [US2] Implement `_DebtSummaryCard` widget and `_SummaryCardSkeleton` in `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` — card receives `Map<Currency, DebtCurrencySummary>` and `isLoading`, shows per currency: "Emprunts" row with `debtOweColor`, "Prêts" row with `debtOwedColor`, "Solde net" row with `incomeColor` if positive / `expenseColor` if negative / `onSurfaceVariant` if zero, format amounts via `AmountFormatter.format()`, skeleton: `Shimmer.fromColors` container height ~80px, hide card entirely if summary is empty (`SizedBox.shrink`)
- [x] T010 [US2] Integrate `_DebtSummaryCard` into `_buildContent` as first `SliverToBoxAdapter` in all states (data, empty, loading) — pass `state.summary` and `state.isLoading`, card remains unaffected by active filter (summary always computed on non-repaid debts by notifier) in `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`

**Checkpoint**: Résumé financier affiché au-dessus de la liste avec couleurs sémantiques.

---

## Phase 5: User Story 3 — Filtre par statut (Priority: P2)

**Goal**: Un filtre segmenté (Tous/En cours/Remboursé) filtre la liste côté client. Les sections et sous-totaux s'adaptent au filtre. Le résumé ne change pas.

**Independent Test**: Sélectionner chaque option du filtre et vérifier la liste, les sous-totaux et les messages vides contextuels.

**Acceptance**: FR-011, FR-012

### Implementation

- [x] T011 [US3] Integrate `SegmentedFilter<DebtStatusFilter>` into `_buildContent` — place as `SliverToBoxAdapter` between summary card and sections, 3 items (`debtsFilterAll`/`debtsFilterEnCours`/`debtsFilterRembourse` from l10n), `selectedValue: state.activeFilter`, `onChanged: notifier.setFilter`, visible in data and empty states (not in loading/error) in `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`
- [x] T012 [US3] Update empty state to show contextual messages per active filter — `DebtStatusFilter.all` → `debtsEmpty`, `DebtStatusFilter.enCours` → `debtsEmptyEnCours`, `DebtStatusFilter.rembourse` → `debtsEmptyRembourse` from l10n, in `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`

**Checkpoint**: Filtre fonctionnel — sections et sous-totaux s'adaptent, résumé reste fixe.

---

## Phase 6: User Story 4 — Ouvrir le formulaire d'édition (Priority: P3)

**Goal**: Le tap sur un item ouvre le formulaire DebtForm en modal avec les données pré-remplies.

**Independent Test**: Taper sur un item et vérifier que la modal s'ouvre avec les bonnes données.

**Acceptance**: FR-013

### Implementation

- [x] T013 [US4] Add `onPressed` callback to each `ListItem` in both sections — call `ref.read(modalNotifierProvider.notifier).open(ModalType.debt, entity: debt)` to open `DebtForm` in edit mode with pre-filled data, in `flutter/lib/src/features/debts/presentation/debt_list_screen.dart`

**Checkpoint**: Tap → modal fonctionne — le cycle liste → édition est complet.

---

## Phase 7: Polish & Tests

**Purpose**: Tests unitaires et validation finale.

- [x] T014 [P] Write notifier unit tests in `flutter/test/src/features/debts/application/debt_notifier_test.dart` — test `loadItems` populates state, `setFilter(enCours)` excludes remboursées, `setFilter(rembourse)` shows only remboursées, `_computeSummary` returns correct totals per currency (emprunts/prêts séparés), summary excludes remboursées, `create`/`update`/`delete` update state correctly, use `ProviderContainer` with mock `DebtRepository` override, naming: `should_*_when_*`
- [x] T015 [P] Write widget tests in `flutter/test/src/features/debts/presentation/debt_list_screen_test.dart` — test: sections "Prêts" and "Emprunts" displayed, items show personne/montant/date/category, badge "Remboursé" visible for repaid debts, empty state message, skeleton loading state, use `ProviderScope` with `overrides` + `MaterialApp.router` + `AppTheme.light`
- [x] T016 Run `flutter analyze` in `flutter/` and fix any issues
- [x] T017 Run quickstart.md validation checklist (7 verification steps)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dépendances — démarrage immédiat. T001, T002, T003 en parallèle. T004 après T002.
- **Foundational (Phase 2)**: Dépend de Phase 1 (T004 terminé) — BLOQUE toutes les user stories.
- **US1 (Phase 3)**: Dépend de Phase 2. C'est le MVP.
- **US2 (Phase 4)**: Dépend de Phase 2. Peut démarrer en parallèle de US1 mais modifie le même fichier.
- **US3 (Phase 5)**: Dépend de Phase 2. Peut démarrer après US1 (modifie `_buildContent`).
- **US4 (Phase 6)**: Dépend de US1 (les ListItem doivent exister pour ajouter `onPressed`).
- **Polish (Phase 7)**: Dépend de toutes les stories terminées. T014 et T015 en parallèle.

### Ordre recommandé (séquentiel, développeur unique)

```
T001 + T002 + T003 (parallel) → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012 → T013 → T014 + T015 (parallel) → T016 → T017
```

### Parallel Opportunities

```bash
# Phase 1 — trois fichiers différents en parallèle :
T001: debt_status_filter.dart
T002: debt_list_state.dart
T003: app_fr.arb + app_en.arb

# Phase 7 — deux fichiers de test en parallèle :
T014: debt_notifier_test.dart
T015: debt_list_screen_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Compléter Phase 1: Setup (T001–T004)
2. Compléter Phase 2: Foundational (T005)
3. Compléter Phase 3: User Story 1 (T006–T008)
4. **STOP et VALIDER** : la liste s'affiche avec sections, sous-totaux, badge, états
5. Commit et vérifier

### Incremental Delivery

1. Setup + Foundational → Notifier prêt
2. + User Story 1 → MVP : liste sectionnée fonctionnelle
3. + User Story 2 → Résumé financier coloré
4. + User Story 3 → Filtre Tous/En cours/Remboursé
5. + User Story 4 → Tap → édition en modal
6. + Polish → Tests + validation

---

## Notes

- Tous les changements UI (T006–T013) sont dans le même fichier `debt_list_screen.dart` → séquentiels
- Le notifier (T005) est le seul fichier modifié hors screen → peut être commité indépendamment
- Les tests (T014, T015) sont dans des fichiers séparés → parallélisables
- Commit recommandé après chaque checkpoint de phase
