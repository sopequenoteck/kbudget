# Documentation — KKS-252 : Budgets liste Flutter (alignement DESIGN.md v5)

> Date : 2026-05-22  
> Issue : KKS-252  
> Parent : KKS-242

---

## Résumé

L'écran `BudgetListScreen` Flutter a été entièrement refactorisé pour s'aligner sur la source de vérité Angular (DESIGN.md v5). Le hero affiche désormais le montant budgété réel (`totalSpent - unbudgetedTotal`) avec un `DoughnutMini` fl_chart intégré, la conversion multi-devise en temps réel via `CurrencyPillSelector` avec debounce 2s, et une méta-ligne (dépassements, non-budgété cliquable). La liste est restructurée en `CustomScrollView` + `SectionHeaderSticky` avec séparation actifs/inactifs et actions conditionnelles.

---

## Guide utilisateur

### Fonctionnalités

#### Hero avec montant budgété et DoughnutMini

**Description** : Le hero affiche le montant total dépensé sur les budgets actifs, hors dépenses non-budgétées. Un graphique en donut (80px) représente la répartition des dépenses par catégorie à droite du montant. Une méta-ligne indique le nombre de budgets en dépassement et le montant non-budgété (cliquable → détail).

**Usage** : Le montant hero correspond à `totalSpent - unbudgetedTotal` de l'overview, converti dans la devise active. Le donut se masque automatiquement si aucune catégorie n'a de dépense.

#### Sélection de devise en temps réel

**Description** : Les pills de devise (`CurrencyPillSelector`) dans la top-row permettent de basculer l'affichage de tous les montants (hero + liste) instantanément. Après 2 secondes sans nouveau changement, la devise est persistée, les taux de change rechargés, et les données rafraîchies.

**Usage** : Tapper une pill bascule immédiatement l'affichage. Si une seule devise est configurée, le sélecteur est masqué automatiquement.

#### Section header sticky + actions conditionnelles

**Description** : Un `SectionHeaderSticky` ("Budgets" + count actifs) reste visible lors du scroll. Il contient deux actions conditionnelles : le bouton Tray (visible si `unbudgetedTotal > 0`, ouvre `UnbudgetedDetailSheet`) et le bouton "+" (visible en mois courant uniquement, désactivé si toutes les catégories ont déjà un budget).

**Usage** : En mode historique (mois passés), le bouton "+" est absent. En mois courant avec toutes les catégories couvertes, il est grisé (`onPressed: null`).

#### Séparation actifs / inactifs

**Description** : Les budgets inactifs sont toujours chargés (`includeInactive: true`) et affichés sous un label "Inactifs" en bas de liste, avec opacité 0,5 et sans barre de progression. Cette section n'apparaît qu'en mois courant.

**Usage** : Aucune action disponible sur les items inactifs (`onTap: null`). En mode historique, seuls les items de l'historique sont affichés.

#### Barre de progression 3 états

**Description** : La barre de chaque budget item change de couleur selon le taux de consommation : couleur catégorie (< 80%), couleur warning (80–100%), couleur dépense (> 100%).

**Usage** : La barre est masquée pour les items inactifs (`showProgressBar: false`).

### Exemples d'utilisation

```
Mois courant, 2 devises (EUR, CHF) :
- Hero : "1 234,00 €" + "≈ 1 112,00 CHF" + DoughnutMini
- Meta : "⚠ 1 en dépassement · 3 budgets" + "📥 45,00 € non budgété"
- SectionHeaderSticky : "Budgets  3  [🥧] [+]"
- Liste actifs : 3 BudgetItem avec barre 3 états
- Label "Inactifs" + 1 item Opacity(0.5) sans barre

Mode historique (mars 2026) :
- Hero : montant de l'historique + DoughnutMini
- SectionHeaderSticky : "Budgets  5" (sans bouton +)
- Pas de section inactifs
```

---

## Changements techniques

### Fichiers créés

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/features/budgets/presentation/widgets/budget_hero_widget.dart` | `DoughnutSegment` (DTO), `_DoughnutMini` (fl_chart, privé), `BudgetHeroWidget` (hero public), `BudgetHeroSkeleton` (skeleton shimmer) |
| `flutter/test/src/features/budgets/presentation/budget_list_screen_test.dart` | 5 tests widget SC-001 → SC-005 (montant hero, DoughnutMini, debounce, inactifs, bouton +) |
| `flutter/test/src/features/budgets/presentation/widgets/budget_hero_widget_test.dart` | 3 tests widget DoughnutMini (US4/S1-S3) |

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/features/budgets/presentation/budget_list_screen.dart` | Refonte complète (419L → 620L) : ajout `_activeCurrency`, `_debounceTimer`, `_onCurrencyChanged`, `_convertAmount`, `_persistCurrencyChange` ; restructuration en `CustomScrollView` + Slivers ; `BudgetHeroWidget` intégré ; section inactifs ; `BudgetSummaryBar` supprimé ; `_showInactive` supprimé |
| `flutter/lib/src/features/budgets/presentation/widgets/budget_item.dart` | Ajout `showProgressBar: bool = true` ; correction FR-014 couleur barre < 80% (catégorie avec alpha 0.7) |

### Dépendances ajoutées

Aucune nouvelle dépendance — `fl_chart`, `shimmer`, `collection` et `go_router` étaient déjà dans `pubspec.yaml`.

---

## Configuration

Aucune configuration spécifique requise. Le composant lit ses données depuis les providers existants :

| Provider | Rôle |
|----------|------|
| `budgetNotifierProvider` | Budget items + overview + history |
| `dashboardNotifierProvider` | Devise active + liste des devises |
| `exchangeRateListProvider` | Taux de change pour la conversion |
| `categoryNotifierProvider` | Catégories pour les items inactifs et `allCategoriesHaveBudget` |

La persistance de la devise passe par `preferenceRemoteDataSourceProvider` (couche data directe, sans passer par `dashboardNotifierProvider`).

---

## Tests et validation

### Tests widget (8 tests, tous PASS)

| Test | Fichier | SC |
|------|---------|-----|
| `should_render_pie_chart_when_doughnut_segments_not_empty` | `budget_hero_widget_test.dart` | US4/S1 |
| `should_hide_pie_chart_when_doughnut_segments_empty` | `budget_hero_widget_test.dart` | US4/S2 |
| `should_exclude_zero_value_segments_from_pie_chart` | `budget_hero_widget_test.dart` | US4/S3 |
| `should_display_budgetedSpent_as_totalSpent_minus_unbudgetedTotal` | `budget_list_screen_test.dart` | SC-001 |
| `should_display_pie_chart_when_overview_items_have_depense` | `budget_list_screen_test.dart` | SC-002 |
| `should_not_crash_after_currency_change_debounce` | `budget_list_screen_test.dart` | SC-003 |
| `should_display_inactifs_label_when_inactive_budgets_exist_in_current_month` | `budget_list_screen_test.dart` | SC-004 |
| `should_disable_add_button_when_all_categories_have_budget` | `budget_list_screen_test.dart` | SC-005 |

**Résultat** : `857/857 tests PASS` (incluant tous les tests existants — aucune régression).

### Analyse statique

```bash
flutter analyze lib/src/features/budgets/ lib/src/common_widgets/
# → No issues found
```

### Déviations documentées (review-impl)

| Déviation | Justification | Impact |
|-----------|--------------|--------|
| États vide/erreur en widgets inline (vs `EmptyStateWidget`) | Cohérence visuelle non critique | Mineur — fonctionnellement équivalent |
| `budget_hero_widget.dart` public (vs classes privées dans le screen) | Convention projet (pattern hero widget des autres features) — imposé par pre-commit-review | Positif — meilleure testabilité |
| `_persistCurrencyChange` via `preferenceRemoteDataSourceProvider` directement | Même pattern que `DashboardScreen` | Désalignement transitoire de `dashboardState` si l'utilisateur ouvre le dashboard sans refresh |
| SC-003 debounce = smoke test uniquement | `preferenceRemoteDataSourceProvider` requiert Dio, difficile à mocker en test widget | Test fakeAsync complet différé |

### Validation manuelle

- [ ] Montant hero = `totalSpent - unbudgetedTotal` vérifié sur device
- [ ] DoughnutMini visible avec dépenses, masqué sans
- [ ] Changement de devise → recalcul immédiat de tous les montants
- [ ] Debounce 2s : persistance unique après changements rapides
- [ ] Label "Inactifs" visible en mois courant, absent en historique
- [ ] Bouton "+" désactivé si toutes les catégories sont couvertes
- [ ] Bouton "+" absent en mode historique
- [ ] Bouton Tray visible si non-budgété > 0 → UnbudgetedDetailSheet
- [ ] Barre 3 états couleur (< 80% catégorie, 80-100% warning, > 100% dépassement)
- [ ] Skeleton loading pendant le chargement initial
- [ ] Erreur réseau → message + bouton "Réessayer"
