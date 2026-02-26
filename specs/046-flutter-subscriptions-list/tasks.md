# Tasks: Flutter — Écran Abonnements Liste

**Input**: Design documents from `/specs/046-flutter-subscriptions-list/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (i18n)

**Purpose**: Ajouter les clés de localisation nécessaires à toutes les user stories

- [X] T001 Add subscription list i18n keys (filter labels, summary, empty states, frequency suffixes) in `flutter/lib/src/localization/app_fr.arb` and `flutter/lib/src/localization/app_en.arb`

> Clés à ajouter :
> - `subscriptionsFilterAll` : "Tous" / "All"
> - `subscriptionsFilterActifs` : "Actifs" / "Active"
> - `subscriptionsFilterInactifs` : "Inactifs" / "Inactive"
> - `subscriptionsTotalMensuel` : "Total mensuel" / "Monthly total"
> - `subscriptionsEmptyActifs` : "Aucun abonnement actif" / "No active subscription"
> - `subscriptionsEmptyInactifs` : "Aucun abonnement inactif" / "No inactive subscription"
> - `subscriptionFrequencyMensuel` : "/mois" / "/mo"
> - `subscriptionFrequencyAnnuel` : "/an" / "/yr"
> - `subscriptionNextRenewal` : "Prochain : {date}" / "Next: {date}" (avec paramètre date)
> - `subscriptionBadgeInactif` : "Inactif" / "Inactive"

---

## Phase 2: Foundational (Models & Notifier Refactor)

**Purpose**: Créer les nouveaux modèles et refactorer le notifier — bloque toutes les user stories

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 [P] Create `SubscriptionStatusFilter` enum with values `all`, `actif`, `inactif` in `flutter/lib/src/domain/enums/subscription_status_filter.dart`

> Pattern à suivre : `TransactionTypeFilter` enum existant. 3 valeurs simples.

- [X] T003 [P] Create `nextRenewalDate(DateTime dateDebut, Frequency frequence, {DateTime? today})` utility in `flutter/lib/src/utils/next_renewal_date.dart`

> Algorithme (cf. data-model.md) :
> 1. `nextDate = dateDebut`
> 2. Tant que `nextDate <= today` : avancer de 1 mois (mensuel) ou 1 an (annuel)
> 3. Retourner `nextDate`
>
> Le paramètre optionnel `today` permet l'injection de la date courante pour les tests.
> Cas limites : `dateDebut` futur → retourne `dateDebut` ; débordement jour (31→28/29) géré par `DateTime(y, m+n, d)`.

- [X] T004 Create `SubscriptionListState` Freezed model in `flutter/lib/src/features/subscriptions/application/subscription_list_state.dart`

> Champs (cf. data-model.md) : `items` (List\<Subscription\>, filtrés paginés), `isLoading` (bool), `error` (String?), `activeFilter` (SubscriptionStatusFilter, défaut: all), `monthlyTotals` (Map\<Currency, double\>), `currentPage` (int), `hasMore` (bool), `mutatingIds` (Set\<String\>).
> Pattern à suivre : `TransactionListState` dans `transaction_list_state.dart`.
> Dépend de T002 pour l'import de `SubscriptionStatusFilter`.

- [X] T005 Run `dart run build_runner build --delete-conflicting-outputs` in `flutter/` to generate `.freezed.dart` file for `SubscriptionListState`

- [X] T006 Refactor `SubscriptionNotifier` to use `SubscriptionListState` in `flutter/lib/src/features/subscriptions/application/subscription_notifier.dart`

> Changements :
> 1. Changer type state de `ListState<Subscription>` à `SubscriptionListState`
> 2. Ajouter `List<Subscription> _allItems = []` interne (tous les items non filtrés)
> 3. Dans `loadItems()` : stocker dans `_allItems` **trié alphabétiquement par nom** (préserver le tri existant), appliquer filtre, calculer totaux. `_applyFilter()` DOIT préserver l'ordre de tri.
> 4. Ajouter `setFilter(SubscriptionStatusFilter filter)` : met à jour `activeFilter`, appelle `_applyFilter()` + `_refreshPage()`
> 5. Ajouter `_applyFilter(List<Subscription> items, SubscriptionStatusFilter filter)` : switch expression all/actif/inactif
> 6. Ajouter `_computeMonthlyTotals(List<Subscription> allItems)` : filtre actifs, group by currency, sum(mensuel=montant, annuel=montant/12)
> 7. Adapter `create()`, `update()`, `delete()`, `toggleActif()`, `refresh()`, `loadMore()` pour utiliser le nouveau state
> 8. Pattern à suivre : `TransactionListNotifier.setFilter()` et `_applyFilter()`

**Checkpoint**: Foundation ready — notifier refactoré, modèles générés, utilitaire créé

---

## Phase 3: User Story 1 — Consulter la liste des abonnements (Priority: P1) MVP

**Goal**: L'utilisateur voit tous ses abonnements triés alphabétiquement avec nom, montant/fréquence, icône catégorie, prochaine date de renouvellement, et badge "Inactif" pour les inactifs.

**Independent Test**: Ouvrir l'écran avec des abonnements → vérifier affichage correct de chaque item.

### Implementation for User Story 1

- [X] T007 [US1] Update `SubscriptionListScreen` to use `SubscriptionListState` — adapt state reading, ListItem value format as `"{amount} {currency}/{fréquence}"` (e.g. "15,99 €/mois"), add next renewal date in subtitle via `nextRenewalDate()` formatted with `intl` DateFormat("d MMMM", "fr_FR"), keep `rightSubtitle` for badge inactif in `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart`

> Changements dans le screen :
> 1. `ref.watch(subscriptionNotifierProvider)` retourne maintenant `SubscriptionListState`
> 2. `ListItem.value` : remplacer `AmountFormatter.format(sub.montant)` par `"${AmountFormatter.format(sub.montant, currency: sub.currency)}${l10n.subscriptionFrequencyMensuel}"` (ou Annuel selon `sub.frequence`)
> 3. `ListItem.subtitle` : remplacer label fréquence par `l10n.subscriptionNextRenewal(DateFormat("d MMMM", "fr_FR").format(nextRenewalDate(sub.dateDebut, sub.frequence)))`
> 4. `ListItem.rightSubtitle` : garder `sub.actif ? null : l10n.subscriptionBadgeInactif` (badge inactif via texte — cf. research.md R3)
> 5. Adapter les 3 états (loading/error/empty) pour lire depuis `SubscriptionListState`
> 6. Gérer `categoryId == null` : icône par défaut (ex: `Icons.repeat` ou emoji générique) et couleur par défaut (`theme.colorScheme.surfaceContainerHighest`) — cf. Edge Case 3
> 7. Pull-to-refresh : appelle `notifier.refresh()`

**Checkpoint**: US1 fonctionnel — liste complète avec tous les détails par item

---

## Phase 4: User Story 2 — Total mensuel des abonnements actifs (Priority: P2)

**Goal**: Carte récapitulative au-dessus de la liste montrant le total mensuel par devise des abonnements actifs (annuels ÷ 12).

**Independent Test**: Créer des abonnements actifs (mensuel + annuel, multi-devises) → vérifier le total affiché.

### Implementation for User Story 2

- [X] T008 [US2] Add `_SubscriptionSummaryCard` private widget and integrate as SliverToBoxAdapter before the list in `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart`

> Widget `_SubscriptionSummaryCard` :
> - Input : `Map<Currency, double> monthlyTotals`, `bool isLoading`
> - Si `monthlyTotals` vide → retourne `SizedBox.shrink()` (FR-005)
> - Si `isLoading` → skeleton shimmer (même pattern que `TransactionSummaryCard`)
> - Sinon : Card avec label `l10n.subscriptionsTotalMensuel` + montant par devise formaté via `AmountFormatter`
> - Si multi-devises : afficher un Row/Column avec un total par devise
> - Padding : `AppSpacing.space4` horizontal, `AppSpacing.space2` vertical
> - Style : fond `surfaceContainerLowest`, coins arrondis `AppRadius.md`
> - Intégration dans `CustomScrollView.slivers` : insérer le `SliverToBoxAdapter(_SubscriptionSummaryCard(...))` avant le builder de liste
> - Lire `state.monthlyTotals` depuis `SubscriptionListState`

**Checkpoint**: US1 + US2 fonctionnels — liste + carte total mensuel

---

## Phase 5: User Story 3 — Filtrer par statut (Priority: P2)

**Goal**: Filtre segmenté Tous/Actifs/Inactifs au-dessus de la liste, filtrage côté client instantané, message vide adapté au filtre.

**Independent Test**: Sélectionner chaque filtre → vérifier que la liste affichée correspond au statut.

### Implementation for User Story 3

- [X] T009 [US3] Add `SegmentedFilter<SubscriptionStatusFilter>` widget between summary card and list, wire to `notifier.setFilter()`, update empty state with filter-aware message in `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart`

> Changements :
> 1. Ajouter `SliverToBoxAdapter` avec `SegmentedFilter<SubscriptionStatusFilter>` entre summary card et liste
> 2. Items : `[SegmentedFilterItem(value: .all, label: l10n.subscriptionsFilterAll), ..actif, ..inactif]`
> 3. `selectedValue: state.activeFilter`
> 4. `onChanged: (f) => ref.read(subscriptionNotifierProvider.notifier).setFilter(f)`
> 5. Padding : `EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2)`
> 6. Mettre à jour le message vide : switch expression sur `state.activeFilter` → `subscriptionsEmpty` / `subscriptionsEmptyActifs` / `subscriptionsEmptyInactifs`
> 7. Pull-to-refresh : s'assurer que `refresh()` conserve le filtre actif (géré dans le notifier)

**Checkpoint**: US1 + US2 + US3 fonctionnels — liste + total + filtre

---

## Phase 6: User Story 4 — Ouvrir le formulaire d'édition (Priority: P3)

**Goal**: Tap sur un item ouvre le formulaire d'édition en modal avec données pré-remplies et toggle fréquence correct.

**Independent Test**: Taper sur un item → vérifier que la modal s'ouvre avec les bonnes données.

### Implementation for User Story 4

- [X] T010 [US4] Verify and fix modal integration with refactored state — ensure `onPressed` callback on ListItem calls `modalNotifierProvider.open(ModalType.subscription, entity: sub)`, verify refresh after save/delete re-applies active filter in `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart`

> Le tap → modal est déjà implémenté dans le screen actuel. Vérifier :
> 1. Le `onPressed` utilise toujours `sub` depuis `state.items[index]` (pas `_allItems`)
> 2. Le callback `onSaved` dans le modal consumer appelle `notifier.update()` ou `notifier.create()` qui re-appliquent le filtre
> 3. Le callback `onDeleted` appelle `notifier.delete()` qui re-applique le filtre
> 4. Le toggle fréquence dans le header modal est bien passé via `sub.frequence`
> 5. Vérifier que le FAB "Nouvel abonnement" reste accessible et fonctionnel après tous les changements (FR-012)
> 6. Si des ajustements sont nécessaires suite au refactor du state, les appliquer

**Checkpoint**: Toutes les user stories fonctionnelles

---

## Phase 7: Polish & Tests

**Purpose**: Tests unitaires et validation finale

- [X] T011 [P] Create unit tests for `nextRenewalDate` utility in `flutter/test/src/utils/next_renewal_date_test.dart`

> Tests à écrire (nommage `should_..._when_...`) :
> - `should_return_next_month_when_monthly_and_date_past`
> - `should_return_next_year_when_annual_and_date_past`
> - `should_return_start_date_when_date_in_future`
> - `should_handle_month_overflow_when_day_31_monthly` (31 jan → 28/29 fév)
> - `should_advance_multiple_periods_when_start_date_far_past`

- [X] T012 [P] Update subscription notifier tests with filter and monthly totals tests in `flutter/test/src/features/subscriptions/application/subscription_notifier_test.dart`

> Tests à ajouter :
> - `should_filter_active_subscriptions_when_filter_set_to_actif`
> - `should_filter_inactive_subscriptions_when_filter_set_to_inactif`
> - `should_show_all_subscriptions_when_filter_set_to_all`
> - `should_compute_monthly_total_when_active_subscriptions_exist`
> - `should_convert_annual_to_monthly_when_computing_totals` (÷12)
> - `should_group_totals_by_currency_when_multi_currency`
> - `should_return_empty_totals_when_no_active_subscriptions`
> - `should_preserve_filter_when_refresh_called`
> - `should_not_change_monthly_totals_when_filter_changes` (total toujours basé sur _allItems actifs, pas sur items filtrés)
> - Pattern : `ProviderContainer` avec `overrides` pour mocker le repository

- [X] T013 [P] Create widget tests for `SubscriptionListScreen` in `flutter/test/src/features/subscriptions/presentation/subscription_list_screen_test.dart`

> Tests à écrire (nommage `should_..._when_...`) :
> - `should_display_subscription_items_when_data_loaded`
> - `should_display_empty_state_when_no_subscriptions`
> - `should_display_summary_card_when_active_subscriptions_exist`
> - `should_hide_summary_card_when_no_active_subscriptions`
> - `should_display_filter_aware_empty_message_when_filter_active`
> - `should_display_skeleton_when_loading`
> - Pattern : `ProviderScope` + `MaterialApp.router` + `AppTheme.light`, override `subscriptionNotifierProvider` avec state fixture

- [X] T014 Run `flutter analyze` and `flutter test` in `flutter/` to validate no regressions

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: T004 depends on T002. T005 depends on T004. T006 depends on T003 + T005.
- **US1 (Phase 3)**: Depends on Phase 2 complete (T006)
- **US2 (Phase 4)**: Depends on US1 (T007) — modifies same file sequentially
- **US3 (Phase 5)**: Depends on US2 (T008) — modifies same file sequentially
- **US4 (Phase 6)**: Depends on US3 (T009) — verification after all screen changes
- **Polish (Phase 7)**: T011 and T012 can start after Phase 2. T013 after Phase 6. T014 after all tasks.

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational (Phase 2) — no dependency on other stories
- **US2 (P2)**: Functionally independent, but shares screen file with US1 → sequential after US1
- **US3 (P2)**: Functionally independent, but shares screen file with US2 → sequential after US2
- **US4 (P3)**: Verification task — after all screen modifications complete

### Parallel Opportunities

```
T001 (i18n) ──────────────────────────────────────────────────┐
T002 (enum) ─────┐                                            │
T003 (utility) ──┤── parallel (different files)               │
                 ├── T004 (state) ── T005 (build_runner) ──┐  │
                 └─────────────────────────────────────────┤  │
                                                           ├── T006 (notifier)
                                                           │
                                                           ├── T007 (US1) ── T008 (US2) ── T009 (US3) ── T010 (US4)
                                                           │
                                                           ├── T011 (tests utility) ─── parallel ─┐
                                                           ├── T012 (tests notifier) ── parallel ─┤
                                                           └── T013 (widget tests) ─── parallel ─┤── T014 (validate)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (T001) + Phase 2 (T002–T006) → Foundation ready
2. Complete Phase 3 (T007) → US1 : liste des abonnements complète
3. **STOP and VALIDATE**: Ouvrir l'écran, vérifier affichage items avec montant/fréquence, date renouvellement, badge inactif
4. Commit MVP

### Incremental Delivery

1. T001–T006 → Foundation ready → commit
2. T007 → US1 : liste basique → commit (MVP)
3. T008 → US2 : + carte total mensuel → commit
4. T009 → US3 : + filtre statut → commit
5. T010 → US4 : + vérification édition → commit
6. T011–T014 → Tests + validation → commit final

---

## Notes

- Tous les fichiers modifiés sont dans le module `flutter/`
- Les phases 3–6 modifient le même fichier (`subscription_list_screen.dart`) → exécution séquentielle obligatoire
- Les tests (Phase 7) peuvent démarrer dès que Phase 2 est complète (T011, T012 parallèles)
- Commit recommandé après chaque phase complète
- Le `build_runner` (T005) doit être exécuté AVANT toute utilisation du state Freezed
