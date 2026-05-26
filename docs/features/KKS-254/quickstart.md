# Quickstart — KKS-254 : Budget détail Flutter (alignement DESIGN.md v5)

---

## Prérequis

```bash
# Vérifier que les dépendances communes sont disponibles
ls flutter/lib/src/common_widgets/confirm_dialog_custom.dart  # ConfirmDialogCustom.show()
ls flutter/lib/src/common_widgets/section_header_sticky.dart  # SectionHeaderSticky (référence)
ls flutter/lib/src/common_widgets/empty_state_widget.dart     # EmptyStateWidget
ls flutter/lib/src/domain/repositories/budget_repository.dart # getById() doit exister
ls flutter/lib/src/domain/repositories/transaction_repository.dart # getByMonth() doit exister

# Vérifier l'état initial des tests
cd flutter && flutter test test/src/features/budgets/
```

## Démarrage

```bash
cd flutter

# Vérifier que le codebase compile sans erreur avant de commencer
flutter analyze

# Identifier les usages de onChartsTap avant suppression (risque R-001)
grep -rn "onChartsTap" lib/
# Résultat attendu : 2 occurrences dans budget_list_screen.dart + 1 dans budget_hero_widget.dart

# Identifier les imports de budget_pie_chart.dart et budget_category_detail_sheet.dart
grep -rn "budget_pie_chart\|budget_category_detail_sheet" lib/
# Résultat attendu : uniquement dans budget_detail_screen.dart
```

## Ordre d'exécution recommandé

Suivre l'ordre du plan pour éviter les erreurs de compilation en cascade :

1. **Router + constructeur** — `app_router.dart` + signature `BudgetDetailScreen`
2. **BudgetHeroWidget** — suppression `onChartsTap`
3. **budget_transactions_provider** — nouveau fichier
4. **BudgetDetailScreen** — refonte complète
5. **budget_list_screen** — navigation + suppression `onChartsTap`
6. **Suppression widgets obsolètes** — pie chart + detail sheet
7. **Tests** — refonte + mise à jour hero test

---

## Vérification par composant

### Après Composant 1 (Router + navigation)

```bash
cd flutter

# Vérifier compilation
flutter analyze

# Vérifier que categoryId est bien lu dans le router
grep -n "categoryId" lib/src/routing/app_router.dart
# Attendu : state.uri.queryParameters['categoryId']
```

### Après Composant 2 (BudgetHeroWidget nettoyage)

```bash
cd flutter

# Vérifier que onChartsTap n'existe plus
grep -rn "onChartsTap" lib/
# Attendu : 0 occurrence

flutter analyze
```

### Après Composant 3 (budget_transactions_provider)

```bash
cd flutter

# Vérifier que le fichier existe
ls lib/src/features/budgets/application/budget_transactions_provider.dart

# Vérifier la compilation
flutter analyze
```

### Après Composant 4 (BudgetDetailScreen refonte)

```bash
cd flutter

# Vérifier la compilation (le plus critique — gros fichier)
flutter analyze

# Test manuel : naviguer depuis la liste vers un budget
flutter run
# → Taper sur un budget actif → écran détail avec hero + progress bar
# → Taper sur un budget historique → écran détail sans action pills
```

### Après Composant 5 (Suppression widgets obsolètes)

```bash
cd flutter

# Vérifier qu'aucun import résiduel ne traîne
grep -rn "budget_pie_chart\|budget_category_detail_sheet" lib/
# Attendu : 0 occurrence

flutter analyze
# Attendu : 0 erreur, 0 warning
```

### Validation finale (après tous les composants)

```bash
cd flutter

# Tests feature budgets
flutter test test/src/features/budgets/

# Analyse statique complète
flutter analyze

# Build release
flutter build apk --release
```

---

## Points d'attention

### onChartsTap (R-001)
Avant de supprimer `onChartsTap` de `BudgetHeroWidget`, confirmer avec grep qu'il n'y a que 2 usages dans `budget_list_screen.dart`. Si d'autres fichiers l'utilisent → les traiter avant de supprimer.

### Budget inactif (RES-005)
Si `categoryId` n'est pas trouvé dans l'overview, fallback sur `budgetNotifierProvider.state.items`. Ce fallback fonctionne car `budget_list_screen` appelle `loadItems(includeInactive: true)` avant de naviguer. Ne pas appeler `loadItems()` à nouveau depuis le détail si `state.items` est déjà peuplé.

### getById pour toggle/edit (RES-004)
Le pill toggle affiche "Désactiver" par défaut (actif = true implicite). La valeur réelle n'est lue qu'au moment du tap, via `ref.read(budgetRepositoryProvider).getById(budgetId)`. Ce pattern est intentionnel — pas de chargement systématique au `initState`.

### Filtrage transactions (RES-006)
Le `FutureProvider.family` charge **toutes** les transactions du mois. Le filtrage `categoryId + type DEPENSE` se fait dans le widget. C'est intentionnel (pattern identique à dette/abonnements).

---

## Checklist Success Criteria

- [ ] SC-001 : Navigation liste → détail fonctionne pour items actifs, inactifs et historique
- [ ] SC-002 : Hero affiche DÉPENSÉ + cible + reste/dépassement + progress bar pour la bonne catégorie
- [ ] SC-003 : Action pills visibles mois courant (overview item), masqués mois passé
- [ ] SC-004 : Delete → dialog confirmation → `budgetNotifier.delete()` → retour liste
- [ ] SC-005 : Toggle → `getById` → `budgetNotifier.update(actif: !actif)` → retour liste
- [ ] SC-006 : Transactions groupées Aujourd'hui/Hier/date, triées décroissantes, type DEPENSE + categoryId uniquement
- [ ] SC-007 : `flutter analyze` → 0 erreur après suppression widgets obsolètes
- [ ] SC-008 : Empty state si 0 transaction DEPENSE pour la catégorie ce mois
- [ ] SC-009 : `flutter test test/src/features/budgets/` → ≥ 8 tests PASS, 0 FAIL
