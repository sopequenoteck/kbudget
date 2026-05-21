# Review Log — KKS-252

---

## Itération 1 — 2026-05-21 | review-spec | BLOQUANT → corrigé → PASS

**Agent** : devflow-review  
**Verdict initial** : BLOQUANT (2 constats bloquants)  
**Verdict après corrections** : PASS (corrections appliquées immédiatement)  
**Constats** : 2 BLOQUANT · 5 WARNING · 4 INFO

### Bloquants (corrigés)

| ID | Localisation | Description | Correction |
|----|-------------|-------------|------------|
| B-1 | `spec.md` FR-015 | `budgetId` queryParam inexistant dans `BudgetDetailScreen` (vue graphique globale, pas par item) — CL-007 différé à tort | FR-015 corrigé : tap item = modal `ModalType.budget` (comportement actuel conservé) |
| B-2 | `spec.md` NFR-003 | "Dériver de BudgetPieChart" impossible en Dart avec une interface différente ; `color: String` incompatible avec `PieChartItem.color: Color` | NFR-003 corrigé : widget standalone indépendant, conversion hex→Color via `parseHexColor()` interne |

### Warnings (corrigés)

| ID | Localisation | Description | Correction |
|----|-------------|-------------|------------|
| W-1 | `spec.md` FR-001 | Formule `totalSpent - unbudgetedTotal` non précisée pour le mode historique | FR-001 complété : "s'applique aussi en mode historique" |
| W-2 | `spec.md` FR-011 | Définition de "catégorie système" manquante | FR-011 précisé : `isSystem=false`, exemple "Non catégorisé" |
| W-3 | `spec.md` FR-008 | Mécanisme debounce non résolu (CL-006 différé) → testabilité compromise | FR-008 précisé : `dart:async Timer` cancelable, testable via `fakeAsync` |
| W-4 | `spec.md` FR-011 US3/S3 | Rendu visuel "désactivé" non précisé | FR-011 précisé : `onPressed: null`, apparence grisée |
| W-5 | `spec.md` Key Entities | Fallback `activeCurrency` si `currencies.isEmpty` non documenté | Key Entities Currency : fallback `Currency.eur` documenté |

### Infos (corrigés)

| ID | Localisation | Description | Correction |
|----|-------------|-------------|------------|
| I-1 | `spec.md` US4, FR-003 | Terme "SVG" résiduel après correction NFR-003 | US4 titre, FR-003, US4/S1, US1/S5 nettoyés |
| I-2 | `spec.md` Edge Cases | `allCategoriesHaveBudget` absent des Edge Cases | Non corrigé (non bloquant, FR-011 suffit) |
| I-3 | `spec.md` NFR-007 | `categoryNotifierProvider` absent de la liste des overrides test | NFR-007 complété |
| I-4 | `clarify-log.md` CL-007 | Justification CL-007 circulaire ("confirmé au plan") | Résolu par correction B-1 (FR-015 clarifié) |

---

## Itération 1 — 2026-05-21 | review-tasks | PASS

**Agent** : devflow-review  
**Verdict** : PASS  
**Constats** : 0 BLOQUANT · 3 WARNING · 2 INFO

### Couverture

| Vérification | Résultat |
|---|---|
| FR couverts (18/18) | ✅ PASS |
| NFR couverts (7/7) | ✅ PASS |
| Sections plan couvertes (11/11) | ✅ PASS |
| Tâches fantômes | ✅ Aucune |
| Mapping Requirements cohérent | ✅ PASS |

### Warnings (non bloquants)

| ID | Description |
|----|-------------|
| W-001 | Graphe Phase 5 : 3 arêtes manquantes — T-031 dépend de T-022 + T-030 ; T-032 et T-033 dépendent de T-021. MVP path impose l'ordre correct en pratique. |
| W-002 | T-002 absent du graphe Phase 5 (présent dans le MVP path uniquement) |
| W-003 | T-051 : test SC-003 (fakeAsync debounce) regroupé avec 4 cas simples — risque de blocage global si SC-003 difficile |

### Infos

| ID | Description |
|----|-------------|
| I-001 | T-022 granularité élevée (7 FR, ~80L) — acceptable si T-021 complété avant |
| I-002 | Tableau résumé "Parallélisables" sous-estime le total réel (7 tâches [P] vs 2 comptabilisées en phase US) |

---

## Itération 1 — 2026-05-22 | review-impl | PASS

**Agent** : devflow-review  
**Verdict** : PASS  
**Constats** : 0 BLOQUANT · 5 WARNING · 2 INFO

### Conformité spec (FR/NFR)

| FR/NFR | Implémenté | Localisation | Notes |
|--------|-----------|--------------|-------|
| FR-001 `budgetedSpent = totalSpent - unbudgetedTotal` | Oui | `budget_list_screen.dart` L307-309 / L477-479 | Mois courant ET historique |
| FR-002 ligne `heroConverted` devise2 | Oui | `budget_hero_widget.dart` L151-159 | Conditionnel |
| FR-003 `_DoughnutMini` fl_chart standalone | Oui | `budget_hero_widget.dart` L24-52 | `PieChart(centerSpaceRadius: 26)`, opacity 0.7 |
| FR-004 méta dépassements + count | Oui | `budget_hero_widget.dart` L169-193 | |
| FR-005 méta non budgété GestureDetector | Oui | `budget_hero_widget.dart` L196-220 | |
| FR-006 MonthSelector conservé | Oui | `budget_hero_widget.dart` L116-120 | |
| FR-007 CurrencyPillSelector dans hero | Oui | `budget_hero_widget.dart` L122-126 | |
| FR-008 debounce 2s Timer cancelable | Oui | `budget_list_screen.dart` L104-125 | |
| FR-009 montants liste convertis | Oui | `budget_list_screen.dart` L297-301 | |
| FR-010 SectionHeaderSticky | Oui | `budget_list_screen.dart` L398-402 | |
| FR-011 bouton "+" conditionnel | Oui | `budget_list_screen.dart` L376-382 | Masqué hors mois courant, désactivé si allCategoriesHaveBudget |
| FR-012 bouton Tray si unbudgetedTotal > 0 | Oui | `budget_list_screen.dart` L370-375 | |
| FR-013 inactifs mois courant, sans barre | Oui | `budget_list_screen.dart` L429-457 | `showProgressBar: false`, `onTap: null` |
| FR-014 barre 3 états couleur | Oui | `budget_item.dart` L68-74 | >100% expenseColor, ≥80% textWarning, sinon categoryCouleur |
| FR-015 tap → ModalType.budget, inactifs non-tappables | Oui | `budget_list_screen.dart` L417-421, L449 | |
| FR-016 skeleton loading | Oui | `budget_list_screen.dart` L215-225 | BudgetHeroSkeleton + 5x BudgetItem.skeleton() |
| FR-017 EmptyStateWidget liste vide | Déviation | `budget_list_screen.dart` L564-589 | Widget custom inline à la place du composant commun |
| FR-018 EmptyStateWidget erreur + Réessayer | Déviation | `budget_list_screen.dart` L228-266 | Widget custom — bouton l10n.retry présent |
| NFR-001 aucune modification data/domain | Oui | — | BudgetRepository, Budget, BudgetOverview inchangés |
| NFR-002 CurrencyPillSelector depuis features/dashboard/ | Oui | `budget_hero_widget.dart` L8 | |
| NFR-003 _DoughnutMini standalone | Oui | `budget_hero_widget.dart` L24-52 | |
| NFR-004 SectionHeaderSticky common_widgets | Oui | `budget_list_screen.dart` L7 | |
| NFR-005 CurrencyConverter + exchangeRateListProvider | Oui | `budget_list_screen.dart` L141-153 | |
| NFR-006 design tokens uniquement | Oui | Tous fichiers | |
| NFR-007 tests avec 4 overrides | Partiel | `budget_list_screen_test.dart` L56-73 | `dashboardNotifierProvider` non mocké |

### Conformité plan

| Décision | Respectée | Notes |
|----------|-----------|-------|
| Fichiers modifiés uniquement `budget_list_screen.dart` + `budget_item.dart` | Déviation | `budget_hero_widget.dart` créé (extraction pré-commit-review justifiée) |
| `_activeCurrency` local setState | Oui | L45 |
| `_debounceTimer` cancelable dans dispose() | Oui + extension | dispose() persiste aussi immédiatement si timer actif |
| `_persistCurrencyChange` pattern DashboardScreen | Déviation | Appel direct `preferenceRemoteDataSourceProvider` au lieu de `dashboardNotifierProvider.notifier` |
| initState() includeInactive: true systématique | Oui | L63 |
| Calculs dérivés dans build() | Oui | Via _buildCurrentMonthSlivers / _buildHistorySlivers |

### Warnings

| ID | Description |
|----|-------------|
| W-001 | FR-017/FR-018 : `EmptyStateWidget` commun non utilisé — implémentation inline fonctionnellement équivalente mais incohérente avec les autres écrans |
| W-002 | Déviation plan : `budget_hero_widget.dart` public créé vs classes privées dans le screen — justifié par la review pre-commit (convention projet) |
| W-003 | Déviation plan : `_persistCurrencyChange` bypass `dashboardNotifierProvider` — désalignement transitoire possible entre local et notifier state |
| W-004 | SC-003 non couvert par vrai test fakeAsync — smoke test uniquement, garantie debounce non vérifiée |
| W-005 | NFR-007 : `dashboardNotifierProvider` non mocké — init `_activeCurrency` depuis dashboardState jamais testée |

### Infos

| ID | Description |
|----|-------------|
| I-001 | Assertion SC-001 faible : `find.textContaining('100')` + findsWidgets peut matcher plusieurs widgets |
| I-002 | dispose() persist immédiate (timer actif) — comportement défensif non planifié, correct, non testé |
