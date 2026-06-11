# Quickstart — KKS-240 : Refonte 4 écrans liste Flutter

> Date : 2026-05-10
> Issue : KKS-240

---

## Pré-requis

- [ ] Constitution lue (`docs/constitution.md`)
- [ ] Spec validée (`docs/features/KKS-240/spec.md` — review PASS)
- [ ] Research complétée (`docs/features/KKS-240/research.md`)
- [ ] Plan approuvé (`docs/features/KKS-240/plan.md`)
- [ ] Branche `feature/flutter-screens-listes-v5` checkoutée
- [ ] KKS-238 mergé sur main (SectionHeaderSticky disponible)

## Phase 1 — Setup

```bash
cd flutter
git status                              # vérifier branche
flutter analyze lib/src/               # doit passer à 0 warning
flutter test                           # tests existants OK
```

**Vérification** : `flutter analyze` exit 0. Tests existants verts.

## Phase 2 — Fondations (vérifications préalables)

```bash
# Vérifier que SectionHeaderSticky est disponible
grep -rn "class SectionHeaderSticky" lib/src/common_widgets/

# Vérifier que PatrimoineCard n'est importée que dans dashboard_screen.dart
grep -rn "PatrimoineCard\|IncomeExpenseCards" lib/src/

# Vérifier que TransactionDayGroup n'est importé que dans transaction_list_screen.dart
grep -rn "TransactionDayGroup" lib/src/

# Vérifier les TODO KKS-240 à traiter
grep -rn "TODO KKS-240" lib/src/
```

**Vérification** : `PatrimoineCard` et `IncomeExpenseCards` uniquement dans `dashboard_screen.dart`. `TransactionDayGroup` uniquement dans `transaction_list_screen.dart`.

## Phase 3 — Implémentation User Stories

### US-001 — DashboardHeroWidget (T-1 + T-2)

1. Créer `lib/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart`
   - Copier la logique de calcul de `patrimoine_card.dart` (patrimoine + variation + devise secondaire)
   - Structure hero flat : label + montant 3xl + badge variation + meta-lines + devise secondaire
   - `key: const Key('dashboard_hero')` ; skeleton `Key('dashboard_hero_skeleton')`
2. Modifier `dashboard_screen.dart` : remplacer `PatrimoineCard` + `IncomeExpenseCards` par `DashboardHeroWidget`
3. Supprimer `patrimoine_card.dart` et `income_expense_cards.dart`

```bash
flutter analyze lib/src/features/dashboard/
grep -rn "LinearGradient" lib/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart  # doit être 0
grep -rn "PatrimoineCard\|IncomeExpenseCards" lib/src/features/dashboard/  # doit être 0
```

### US-002 — TransactionHeroWidget + groupement sémantique (T-3 + T-4 + T-5)

1. Créer `lib/src/features/transactions/presentation/widgets/transaction_hero_widget.dart`
2. Modifier `transaction_list_screen.dart` :
   - Supprimer le bloc `ChoiceChip`
   - Remplacer `TransactionSummaryCard` par `TransactionHeroWidget`
   - Ajouter `SectionHeaderSticky(title: 'Transactions')`
   - Implémenter `_groupBySemantics()` (5 buckets) + `date-label` inline amber/neutre
   - Utiliser `state.allMonthTransactions` pour le groupement
3. Modifier `transaction_day_group.dart` : retirer le header date interne (ligne ~52)

```bash
flutter analyze lib/src/features/transactions/
grep -rn "ChoiceChip" lib/src/features/transactions/  # doit être 0
```

### US-003 — SubscriptionHeroWidget + sections Actifs/Inactifs (T-6 + T-7)

1. Créer `lib/src/features/subscriptions/presentation/widgets/subscription_hero_widget.dart`
2. Modifier `subscription_list_screen.dart` :
   - Supprimer les 2 blocs `ChoiceChip` (empty + data state)
   - Remplacer `_SubscriptionSummaryCard` par `SubscriptionHeroWidget`
   - Ajouter `SectionHeaderSticky(title: 'Abonnements · $activeCount actifs')`
   - Implémenter date-labels "Actifs" / "Inactifs" avec sections filtrées
   - Supprimer `_SubscriptionSummaryCard` et `_SummaryCardSkeleton`

```bash
flutter analyze lib/src/features/subscriptions/
grep -rn "ChoiceChip" lib/src/features/subscriptions/  # doit être 0
```

### US-004 — DebtHeroWidget + groupement temporel (T-8 + T-9)

1. Créer `lib/src/features/debts/presentation/widgets/debt_hero_widget.dart`
2. Modifier `debt_list_screen.dart` :
   - Supprimer `_buildFilter()` et ses appels
   - Supprimer `_SectionHeader` privé
   - Supprimer `_DebtSummaryCard` et `_SummaryCardSkeleton`
   - Remplacer par `DebtHeroWidget`
   - Ajouter `SectionHeaderSticky(title: 'Dettes · $kEnCours en cours')`
   - Implémenter `_groupByDueDate()` (7 buckets) + date-labels colorés

```bash
flutter analyze lib/src/features/debts/
grep -rn "ChoiceChip\|_SectionHeader\|DebtSummaryCard" lib/src/features/debts/  # doit être 0
```

## Phase 4 — Polish (T-10)

```bash
# Écrire les 4 fichiers de tests
# flutter/test/src/features/dashboard/presentation/widgets/dashboard_hero_widget_test.dart
# flutter/test/src/features/transactions/presentation/widgets/transaction_hero_widget_test.dart
# flutter/test/src/features/subscriptions/presentation/widgets/subscription_hero_widget_test.dart
# flutter/test/src/features/debts/presentation/widgets/debt_hero_widget_test.dart

# Exécuter les tests
cd flutter
flutter test test/src/features/dashboard/presentation/
flutter test test/src/features/transactions/presentation/
flutter test test/src/features/subscriptions/presentation/
flutter test test/src/features/debts/presentation/

# Validation finale
flutter analyze lib/src/features/
grep -rn "TODO KKS-240" lib/src/                        # doit être 0
grep -rn "LinearGradient" lib/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart  # doit être 0
grep -rn "ChoiceChip" lib/src/features/{transactions,subscriptions,debts}/  # doit être 0
grep -nE "Color\(0x|#[0-9a-fA-F]{6,8}" lib/src/features/*/presentation/widgets/*_hero_widget.dart    # doit être 0
```

## Commandes utiles

| Action | Commande |
|--------|----------|
| Tests hero dashboard | `cd flutter && flutter test test/src/features/dashboard/` |
| Tests hero transactions | `cd flutter && flutter test test/src/features/transactions/` |
| Tests hero abonnements | `cd flutter && flutter test test/src/features/subscriptions/` |
| Tests hero dettes | `cd flutter && flutter test test/src/features/debts/` |
| Tous les tests | `cd flutter && flutter test` |
| Analyse statique | `cd flutter && flutter analyze lib/src/features/` |
| Vérifier no-hex | `grep -rn "Color(0x\|#[0-9a-fA-F]" flutter/lib/src/features/*/presentation/widgets/*_hero_widget.dart` |
| Vérifier no-ChoiceChip | `grep -rn "ChoiceChip" flutter/lib/src/features/` |

## Checklist finale

- [ ] `flutter analyze` exit 0 (SC-008)
- [ ] Aucun `LinearGradient` dans `dashboard_hero_widget.dart` (SC-002)
- [ ] Aucun `ChoiceChip` dans les 4 écrans (SC-003)
- [ ] `SectionHeaderSticky` dans Transactions, Abonnements et Dettes (SC-004)
- [ ] Keys concrètes présentes dans les 4 heros (SC-005)
- [ ] Skeletons avec keys (SC-006)
- [ ] Date-label amber "Aujourd'hui" + rouge "En retard" testés (SC-007)
- [ ] Aucun hex hardcodé dans les heros (SC-009)
- [ ] `forEachTheme` dans les 4 fichiers de tests (SC-010)
- [ ] `TODO KKS-240` absents du code (SC-011)
- [ ] `PatrimoineCard` + `IncomeExpenseCards` absents de `dashboard_screen.dart` (SC-001)
- [ ] ≥ 10 tests passés (NFR-001)
- [ ] Review-impl PASS
