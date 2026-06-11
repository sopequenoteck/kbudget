# Tasks: Récurrences liste Flutter (alignement DESIGN.md v5)

**Issue**: KKS-251 | **Date**: 2026-05-21  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Research**: [research.md](research.md)

---

## Phase 1 — Setup (Vérifications préliminaires)

**Objectif** : Confirmer le périmètre des impacts avant toute modification.

- [x] T-001 Grep `recurringValidate`, `recurringSkip`, `recurringDeactivate` hors feature recurring pour confirmer l'absence d'autres usages : `grep -rn "recurringValidate\|recurringSkip\|recurringDeactivate" flutter/lib --include="*.dart" | grep -v "features/recurring\|localization"` — résultat attendu : 0 ligne
- [x] T-002 [P] Inspecter les tests existants pour identifier les assertions à adapter : `grep -n "StatusBadge\|En retard\|À venir\|onValidate\|onSkip\|onDeactivate\|longPress\|Dismissible" flutter/test/src/features/recurring/presentation/recurring_list_screen_test.dart`
- [x] T-003 [P] Confirmer les tokens utilisés : `AppTypography.labelLetterSpacingForSize12 = 0.6`, `AppRadius.round = 999`, `AppRadius.xl = 16`, `AppThemeExtension` possède `iconCircleBg`, `incomeColor`, `expenseColor` — grep : `grep -n "labelLetterSpacingForSize12\|iconCircleBg" flutter/lib/src/constants/app_typography.dart flutter/lib/src/theme/app_theme_extension.dart`

**Checkpoint** : Usages l10n confirmés (feature-scoped uniquement), assertions test identifiées, tokens vérifiés.

---

## Phase 2 — Fondations (Prérequis bloquants)

**Objectif** : Outils utilitaires et l10n dont dépendent toutes les User Stories.

**⚠️ CRITIQUE** : T-012 est requis avant T-022 (sous-titre). T-011 est requis avant T-033/T-041 (labels boutons). T-013 est requis avant T-033 (validateAll callback).

- [x] T-011 `flutter/lib/src/localization/app_fr.arb` — mettre à jour 3 valeurs (`"recurringValidate": "Marquer comme payée"`, `"recurringSkip": "Passer cette occurrence"`, `"recurringDeactivate": "Désactiver la récurrence"`) + ajouter 4 clés (`recurringValidateAll`, `recurringNextOccurrence` avec placeholder `{date}`, `recurringMonthlySummaryTitle`, `recurringChargesCount` avec placeholder `{count}`) — puis `cd flutter && flutter gen-l10n` — Réf: IT-003 research
- [x] T-012 [P] `flutter/lib/src/utils/relative_date_formatter.dart` — ajouter `static String formatCompact(DateTime value, {DateTime? now})` : `diffDays==0` → `"aujourd'hui"`, `diffDays==1` → `"hier"`, `diffDays==-1` → `"demain"`, `2≤diffDays≤7` → `"il y a ${diffDays} j."`, `-30≤diffDays<-1` → `"dans ${-diffDays} j."`, sinon `DateFormat('dd MMM', 'fr').format(value)` — Réf: NFR-002, FR-003
- [x] T-013 [P] `flutter/lib/src/features/recurring/application/recurring_list_notifier.dart` — ajouter `Future<void> validateAll(List<String> ids)` : (1) guard `ids.isEmpty → return` ; (2) `state.copyWith(mutatingIds: {...state.mutatingIds, '__all__'}, error: null)` ; (3) `try { for (id) await validate(id); } on Exception {} finally { mutatingIds.remove('__all__') }` — Réf: NFR-001, NFR-006

**Checkpoint** : `flutter gen-l10n` propre, `formatCompact()` compilable, `validateAll()` compilable. Phase 3 peut commencer.

---

## Phase 3 — User Stories

### US1 — Transaction row aligné Angular (P1) 🎯 MVP

**Goal** : `RecurringListItem` visuellement fidèle à Angular — icône cercle 36px, sous-titre `fréquence · date_relative`, montant coloré. Interface simplifiée `{onTap}`. Skeleton aligné.

**Test indépendant** : Ouvrir l'écran Récurrences → ligne avec icône cercle 36px, sous-titre `"fréquence · dans X j."`, montant rouge/vert. Tap → callback. Aucun swipe. Skeleton 5 items.

- [x] T-021 [US1] `flutter/lib/src/features/recurring/presentation/widgets/recurring_list_item.dart` — restructurer : (1) `ConsumerWidget` → `StatelessWidget` ; (2) supprimer params `onValidate`, `onSkip`, `onDeactivate`, ajouter `onTap: VoidCallback` ; (3) supprimer `Dismissible`, `_SwipeBackground`, `GestureDetector.onLongPress`, `_showActionsSheet()` ; (4) envelopper le contenu dans `InkWell(onTap: onTap)` ; (5) supprimer import `recurring_list_notifier.dart` — Réf: FR-002, FR-004, FR-005, NFR-005
- [x] T-022 [US1] `recurring_list_item.dart` — (1) `_CategoryIcon` : `width/height: 40, borderRadius: AppRadius.md` → `width/height: 36, shape: BoxShape.circle`, fond : `_parseColorWithAlpha(color)` (Color `0x26 << 24 | hex`) sinon `themeExt.iconCircleBg`, emoji `fontSize: 18` ; (2) colonne texte : libellé `sizeSm/medium/onSurfaceVariant`, sous-titre `'${_frequencyLabel(l10n)} · ${RelativeDateFormatter.formatCompact(item.nextOccurrence)}'` sizeXs/onSurfaceVariant ; (3) montant : `expenseColor` si `type==depense` sinon `incomeColor` depuis `AppThemeExtension` ; (4) supprimer `_StatusBadge` et son espace vertical ; (5) ajouter imports `relative_date_formatter.dart`, `app_theme_extension.dart` — Réf: FR-001, FR-003, FR-004, FR-005
- [x] T-023 [P] [US1] `flutter/lib/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart` — (1) `itemCount: 6` → `itemCount: 5` ; (2) icône : `Container(width:40, height:40, borderRadius: AppRadius.md)` → `Container(width:36, height:36, shape: BoxShape.circle)` ; (3) côté droit : supprimer le Container badge-round (`height:20, width:60, borderRadius: AppRadius.round`) + le `SizedBox(height: space2)` entre badge et montant — ne garder que le Container montant (`height:12, width:80, AppRadius.sm`) — Réf: FR-016

**Checkpoint US1** : `RecurringListItem` affiche icône cercle 36px, sous-titre `fréquence · date_relative`, montant coloré. Skeleton 5 items sans badge droit. Aucun `Dismissible`.

---

### US2 — Groupes visuels + monthly summary (P2)

**Goal** : `RecurringListScreen` restructuré en `CustomScrollView` avec 3 groupes colorés par statut, carte monthly summary en tête, et bouton "Tout payé" sur le groupe EN RETARD.

**Test indépendant** : Charger des récurrences dans 3 statuts → voir 3 headers colorés, cartes surface/radius-xl, Dividers entre items, monthly summary en haut, bouton "Tout payé" uniquement sur EN RETARD.

- [x] T-031 [US2] `flutter/lib/src/features/recurring/presentation/recurring_list_screen.dart` — (1) migrer `RefreshIndicator + ListView.builder` → `RefreshIndicator + CustomScrollView(slivers: _buildContent(...))` ; (2) états `error` → `EmptyStateWidget(icon: PhosphorIconsRegular.warning, message: l10n.errorGeneric, ctaLabel: l10n.retry, onCtaTap: loadItems)` ; (3) état `empty` → `EmptyStateWidget(icon: PhosphorIconsRegular.repeat, message: l10n.recurringEmpty)` ; (4) ajouter dans `build()` : `ref.watch(exchangeRateListProvider)`, `ref.watch(dashboardNotifierProvider)`, `primaryCurrency = dashboardState.currencies.isNotEmpty ? dashboardState.currencies.first : null` ; (5) ajouter imports `empty_state_widget.dart`, `exchange_rate_notifier.dart`, `dashboard_notifier.dart`, `exchange_rate.dart`, `app_theme_extension.dart`, `currency_converter.dart`, `amount_formatter.dart`, `relative_date_formatter.dart` — Réf: FR-014, FR-015
- [x] T-032 [US2] `recurring_list_screen.dart` — ajouter widget privé `_MonthlySummaryCard` : (1) `_toMonthly(item)` = `montant * 4.33` (hebdo) / `montant` (mensuel) / `montant / 12` (annuel) ; (2) `_toPrimary(monthly, fromCurrency)` = `CurrencyConverter.convert(...)` ?? `monthly` ; (3) itérer items, accumuler `net` (recettes - dépenses), `totalExpenses`, `expenseCount` pour `type==depense` ; (4) layout `Container(color: surface, borderRadius: xl)` → `Row` avec colonne gauche (BILAN MENSUEL + `±netFormatted` coloré) + colonne droite (`{N} CHARGES` + `~{total}/mois`) — tokens : `sizeXs/letterSpacing0.6` pour labels, `sizeSm/semiBold` pour montants — Réf: FR-010
- [x] T-033 [US2] `recurring_list_screen.dart` — ajouter widget privé `_StatusGroupSection` : (1) `Column(Row(label+Spacer+btnAll?) + SizedBox(space2) + Container(surface/xl/clip, Column(items+Dividers)))` ; (2) header label : `sizeXs/semiBold/uppercase/letterSpacing:0.6`, couleur par statut (expenseColor/primary/onSurfaceVariant) ; (3) bouton "Tout payé" conditionnel (`showValidateAll && !isValidatingAll`) : `FilledButton(StadiumBorder, primary, height:28, sizeXs/semiBold)` ou spinner si `isValidatingAll` ; (4) ajouter méthode `_handleValidateAll(context, ids, l10n)` dans le screen (await validateAll + SnackBar succès interpolé / SnackBar erreur) — Réf: FR-006, FR-007, FR-008, FR-009, NFR-001, NFR-006
- [x] T-034 [US2] `recurring_list_screen.dart` — implémenter `_buildContent()` retournant `List<Widget>` : (1) grouper `state.items` en `overdue`/`today`/`upcoming` (filtrage par `.status`) ; (2) `SliverToBoxAdapter(Padding(_MonthlySummaryCard))` en tête ; (3) `if (overdue.isNotEmpty) SliverToBoxAdapter(_StatusGroupSection(..., showValidateAll:true, onValidateAll: _handleValidateAll))` ; (4) idem today + upcoming (sans bouton) ; (5) `SliverToBoxAdapter(SizedBox(height: space12*2))` en fin — Réf: FR-006, FR-010

**Checkpoint US2** : Écran affiche monthly summary + groupes colorés + carte surface + bouton "Tout payé" sur EN RETARD. Groupes absents si 0 items.

---

### US3 — Action sheet design aligné Angular (P3)

**Goal** : Bottom sheet avec résumé récurrence + 3 boutons stylisés. Désactivation directe sans `AlertDialog`.

**Test indépendant** : Tap ligne → bottom sheet avec fréquence uppercase, montant sizeXl coloré, "Prochaine : dans X j.". Boutons pleine largeur. Désactiver → direct sans confirm.

- [x] T-041 [US3] `recurring_list_screen.dart` — (1) ajouter widget privé `_ActionButton(label, icon, backgroundColor, foregroundColor, isMutating, onPressed)` : `SizedBox(width: double.infinity, child: FilledButton.icon(style: FilledButton.styleFrom(...), icon: isMutating ? CircularProgressIndicator(...) : PhosphorIcon(icon, 20), label: Text(label)))` ; (2) ajouter méthode `_showActionSheet(context, item, l10n, themeExt)` via `showModalBottomSheet` : `SafeArea(Padding(space4, Column(résumé + space4 + 3×_ActionButton)))` ; résumé : `fréquence.toUpperCase()` sizeXs/letterSpacing, montant sizeXl/bold coloré, `l10n.recurringNextOccurrence(RelativeDateFormatter.formatCompact(nextOccurrence))` sizeXs ; boutons : validate(primary/onPrimary/check), skip(surfaceContainerHighest/onSurface/skipForward), deactivate(surfaceContainerHighest/expenseColor/pause) — Réf: FR-011, FR-012
- [x] T-042 [US3] `recurring_list_screen.dart` — (1) supprimer `_showDeactivateConfirm()` et son `showDialog<void>(AlertDialog(...))` ; (2) `_handleDeactivate()` appelé directement depuis le bouton deactivate dans `_showActionSheet()` (sans dialog intermédiaire) ; (3) brancher `onItemTap: (item) => _showActionSheet(context, item, l10n, themeExt)` comme param de `_StatusGroupSection` dans `_buildContent()` — Réf: FR-013, NFR-005

**Checkpoint US3** : Tap → action sheet stylisée. `Désactiver` → action directe. `AlertDialog` supprimé. SnackBars fonctionnels.

---

## Phase 4 — Polish

**Objectif** : Tests et validation finale.

- [x] T-051 `flutter/test/src/features/recurring/application/recurring_list_notifier_test.dart` — ajouter groupe `validateAll` avec 3 tests : (a) `should_validateAll_call_validate_for_each_id_and_clear_sentinel` ; (b) `should_validateAll_stop_at_first_failure_and_clear_sentinel` ; (c) `should_validateAll_return_immediately_when_ids_empty` — puis `cd flutter && flutter test test/src/features/recurring/application/recurring_list_notifier_test.dart` — Réf: NFR-004
- [x] T-052 [P] `flutter/test/src/features/recurring/presentation/recurring_list_screen_test.dart` — (1) adapter `buildApp()` : ajouter overrides `exchangeRateListProvider.overrideWith(() => _MockExchangeRateNotifier())` + `dashboardNotifierProvider.overrideWith(() => _MockDashboardNotifier())` ; (2) supprimer assertions `find.text('En retard')` et `find.text('À venir')` (badges supprimés) → remplacés par `find.text('EN RETARD')` et `find.text('À VENIR')` (headers de groupe) ; (3) tri overdue avant upcoming toujours vérifié — Réf: NFR-004, SC-007
- [x] T-053 [P] `cd flutter && flutter analyze lib/src/features/recurring/ lib/src/utils/relative_date_formatter.dart` — 0 warning ; puis `cd flutter && flutter test test/src/features/recurring/` — 100% PASS — Réf: SC-007

**Checkpoint Final** : `flutter analyze` propre. Tous les tests passent. Rendu visuel conforme DESIGN.md v5 / Angular.

---

## Phase 5 — Dépendances & Ordre d'exécution

### Graphe de dépendances

```
T-001 ──┐
T-002 ──┤── Checkpoint Phase 1
T-003 ──┘
        │
T-011 ←─┘── (bloque T-033 labels, T-041 labels)
T-012   (parallèle T-011 — bloque T-022 sous-titre, T-041 résumé)
T-013   (parallèle T-011 — bloque T-033 validateAll callback)
        │── Checkpoint Phase 2
        │
T-021 ←─┘ (dépend Phase 2 — interface item)
T-022   (dépend T-021 + T-012 — visuels item)
T-023   (parallèle T-021 — fichier distinct skeleton)
        │── Checkpoint US1
        │
T-031 ←─┘ (dépend US1 — structure screen)
T-032   (dépend T-031 — même fichier, monthly summary widget)
T-033   (dépend T-031 + T-011 + T-013 + T-041* — voir note)
T-034   (dépend T-031 + T-032 + T-033 — branchage final)
        │── Checkpoint US2
        │
T-041 ←─┘ (dépend T-031 + T-011 + T-012 — action sheet)
T-042   (dépend T-041 + T-033 — suppression dialog + branchage)
        │── Checkpoint US3
        │
T-051 ←─┘ (dépend T-013)
T-052   (parallèle T-051 — fichier distinct)
T-053   (dépend T-051 + T-052)
```

> **Note T-033/T-041** : `_StatusGroupSection.onItemTap` appelle `_showActionSheet()` (T-041). En pratique, ajouter un stub `_showActionSheet()` vide lors de T-033, puis l'implémenter en T-041. Ou effectuer T-041 avant T-033 (recommandé pour éviter le stub).

### Ordre d'implémentation recommandé (développeur unique)

```
Phase 1 → Phase 2 → T-021 → T-023 → T-022 → T-031 → T-041 → T-032 → T-033 → T-034 → T-042 → Phase 4
```

### Table US Dependencies

| User Story | Tâches | Dépend de |
|-----------|--------|-----------|
| US1 — RecurringListItem | T-021, T-022, T-023 | Phase 2 complète (T-012 pour T-022) |
| US2 — RecurringListScreen | T-031, T-032, T-033, T-034 | US1 + T-011 + T-013 + T-041 (pour onItemTap) |
| US3 — Action sheet | T-041, T-042 | T-031 (structure screen) + T-011 + T-012 |

### Parallel Opportunities

| Groupe | Condition |
|--------|-----------|
| T-001, T-002, T-003 | Phase 1 — greps indépendants |
| T-012, T-013 | Phase 2 — fichiers distincts (utils vs notifier) |
| T-023 et T-021 | Après Phase 2 — fichiers distincts (skeleton vs item) |
| T-051, T-052 | Après Phase 3 complète — fichiers distincts |

---

## Requirements → Tâches

| Requirement | Tâches |
|-------------|--------|
| FR-001 (icône cercle 36px, alpha 0x26 ou iconCircleBg) | T-022 |
| FR-002 (tap → onTap, suppression swipe/longPress) | T-021 |
| FR-003 (sous-titre fréquence · date_relative) | T-012, T-022 |
| FR-004 (montant coloré expense/income) | T-022 |
| FR-005 (suppression _StatusBadge/_SwipeBackground/Dismissible) | T-021 |
| FR-006 (headers groupe sizeXs/semiBold/uppercase/letterSpacing) | T-033, T-034 |
| FR-007 (couleurs headers overdue/today/upcoming) | T-033 |
| FR-008 (carte Container surface/radius-xl/clip + Dividers) | T-033 |
| FR-009 (bouton "Tout payé" overdue uniquement, round/primary) | T-033 |
| FR-010 (monthly summary — normalisation mensuel + conversion devise) | T-032 |
| FR-011 (action sheet résumé fréquence/montant/nextOccurrence) | T-041 |
| FR-012 (3 boutons stylisés : validate/skip/deactivate + icônes phosphor) | T-041 |
| FR-013 (suppression AlertDialog, deactivate direct) | T-042 |
| FR-014 (état vide → EmptyStateWidget) | T-031 |
| FR-015 (état erreur → EmptyStateWidget + retry) | T-031 |
| FR-016 (skeleton 5 items, icône cercle, sans badge droit) | T-023 |
| NFR-001 (validateAll séquentiel, arrêt 1er échec, SnackBar) | T-013, T-033 |
| NFR-002 (formatCompact() sur fichier existant) | T-012 |
| NFR-003 (aucune modification repository/domain/DTOs) | Contrainte implicite |
| NFR-004 (tests adaptés + nouveaux tests validateAll) | T-051, T-052 |
| NFR-005 (action sheet dans screen, item expose onTap) | T-021, T-041, T-042 |
| NFR-006 (sentinel '__all__' dans mutatingIds) | T-013, T-033 |

---

## Tableau résumé

| Phase | Tâches | Parallélisables |
|-------|--------|----------------|
| Phase 1 — Setup | 3 | 2 (T-002, T-003) |
| Phase 2 — Fondations | 3 | 2 (T-012, T-013) |
| Phase 3 — US1 P1 | 3 | 1 (T-023) |
| Phase 3 — US2 P2 | 4 | 0 |
| Phase 3 — US3 P3 | 2 | 0 |
| Phase 4 — Polish | 3 | 2 (T-051, T-052) |
| **Total** | **18** | **7** |

---

## Implementation Strategy

### MVP First (US1 uniquement)

1. Phase 1 : T-001, T-002, T-003
2. Phase 2 : T-011, T-012, T-013
3. US1 : T-021, T-022, T-023
4. **STOP** : Vérifier `RecurringListItem` visuellement — icône cercle, sous-titre, montant coloré
5. Skeleton 5 items visible en loading

### Incremental Delivery

1. Setup + Fondations → utilitaires et l10n prêts
2. US1 (`RecurringListItem` + skeleton) → visuel de ligne aligné Angular
3. US3 (`_showActionSheet`) → action sheet fonctionnelle (prérequis pratique pour US2)
4. US2 (`RecurringListScreen`) → groupes + monthly summary + "Tout payé"
5. Polish → tests, flutter analyze, validation visuelle
