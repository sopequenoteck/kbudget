# Documentation — KKS-240 : Phase 1 / Étape 4 — Refonte 4 écrans liste Flutter

> Date : 2026-05-10
> Issue : KKS-240
> Branche : `feature/flutter-screens-listes-v5`
> Statut : Done

---

## Résumé

Refonte des 4 écrans liste majeurs Flutter (`Dashboard`, `Transactions`, `Abonnements`, `Dettes`) pour conformité DESIGN.md v5. Les gradients, `SegmentedFilter`/`ChoiceChips` et les summary cards non conformes ont été supprimés et remplacés par 4 nouveaux `StatelessWidget` hero flat avec meta-lines Phosphor, un `SectionHeaderSticky` global par écran, et des groupements sémantiques/temporels en lieu et place des filtres. Aucun notifier, aucune couche data, aucune dépendance externe ne sont modifiés.

---

## Guide utilisateur

### Dashboard

- Le patrimoine total est présenté dans un **hero flat** sans gradient (fond transparent), avec le montant en `incomeColor` si positif ou `expenseColor` si négatif.
- Un **badge variation mensuelle** (ex. "+1 200 € ce mois (+4,2%)") est affiché sous le montant lorsqu'un résumé mensuel est disponible.
- Deux **meta-lines** affichent les revenus (icône ↗) et dépenses (icône ↘) du mois.
- Si deux devises sont configurées, la conversion est affichée en petit sous le montant principal (ex. "≈ 1 340 $").

### Transactions

- Le **hero solde mensuel** remplace l'ancienne `TransactionSummaryCard` : bilan recettes − dépenses avec meta-lines revenus/dépenses.
- Les transactions sont **groupées par labels sémantiques** : "Aujourd'hui" · "Hier" · "Cette semaine" · "Semaine dernière" · "Plus ancien". Groupes vides omis.
- Le label **"Aujourd'hui"** est affiché en **amber**. Les autres labels sont en neutre (`onSurfaceVariant`).
- Les filtres par type (Tous / Recettes / Dépenses) sont supprimés — toutes les transactions du mois sont affichées.
- Un `SectionHeaderSticky` "Transactions" reste visible en haut lors du scroll.

### Abonnements

- Le **hero total mensuel** remplace l'ancienne `_SubscriptionSummaryCard` : total en `expenseColor`, meta-line "N actifs" et meta-line "≈ X €/an".
- La liste est divisée en deux sections par des **date-labels** légers : "Actifs" puis "Inactifs" (section absente si vide).
- Les filtres (Tous / Actifs / Inactifs) sous forme de ChoiceChips sont supprimés.
- Un `SectionHeaderSticky` "Abonnements · N actifs" reste visible en haut lors du scroll.

### Dettes

- Le **hero solde net** remplace l'ancienne `_DebtSummaryCard` : solde net prêts − emprunts (`incomeColor` si positif, `expenseColor` si négatif, `onSurface` si nul), meta-ligne prêts/emprunts, meta-ligne "K en cours".
- La liste est **groupée par urgence temporelle** sur 7 buckets : "En retard" · "Aujourd'hui" · "Cette semaine" · "Ce mois-ci" · "Plus tard" · "Sans échéance" · "Remboursées". Groupes vides omis.
- Les date-labels sont colorés : "En retard" → **rouge** (`expenseColor`), "Aujourd'hui" → **amber**, les autres → neutre.
- Le tri dans chaque bucket : `dueDate` ASC (null après les dates), puis `date` DESC.
- Les filtres (Tous / En cours / Remboursé) sont supprimés.
- Un `SectionHeaderSticky` "Dettes · K en cours" reste visible en haut lors du scroll.

---

## Changements techniques

### Fichiers créés (8)

| Fichier | Description |
|---------|-------------|
| `flutter/lib/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart` | Hero patrimoine total — StatelessWidget, migration logique PatrimoineCard |
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_hero_widget.dart` | Hero solde mensuel transactions — StatelessWidget |
| `flutter/lib/src/features/subscriptions/presentation/widgets/subscription_hero_widget.dart` | Hero total mensuel abonnements — StatelessWidget |
| `flutter/lib/src/features/debts/presentation/widgets/debt_hero_widget.dart` | Hero solde net dettes — StatelessWidget |
| `flutter/test/src/features/dashboard/presentation/widgets/dashboard_hero_widget_test.dart` | 8 tests forEachTheme : keys, skeleton, incomeColor, expenseColor |
| `flutter/test/src/features/transactions/presentation/widgets/transaction_hero_widget_test.dart` | 8 tests forEachTheme |
| `flutter/test/src/features/subscriptions/presentation/widgets/subscription_hero_widget_test.dart` | 6 tests forEachTheme |
| `flutter/test/src/features/debts/presentation/widgets/debt_hero_widget_test.dart` | 10 tests forEachTheme |

### Fichiers modifiés (5)

| Fichier | Modifications |
|---------|---------------|
| `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` | Remplacement PatrimoineCard + IncomeExpenseCards → DashboardHeroWidget |
| `flutter/lib/src/features/transactions/presentation/transaction_list_screen.dart` | Suppression ChoiceChips + TransactionSummaryCard → TransactionHeroWidget + SectionHeaderSticky + _groupBySemantics() |
| `flutter/lib/src/features/subscriptions/presentation/subscription_list_screen.dart` | Suppression ChoiceChips + _SubscriptionSummaryCard → SubscriptionHeroWidget + SectionHeaderSticky + date-labels |
| `flutter/lib/src/features/debts/presentation/debt_list_screen.dart` | Suppression ChoiceChips + _DebtSummaryCard + _SectionHeader → DebtHeroWidget + SectionHeaderSticky + _groupByDueDate() |
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_day_group.dart` | Suppression du paramètre `date` et du header de date interne |

### Tests de screens mis à jour (3)

| Fichier | Modifications |
|---------|---------------|
| `flutter/test/src/features/transactions/presentation/transaction_list_screen_test.dart` | Suppression tests ChoiceChip/SummaryCard, ajout SectionHeaderSticky runtime |
| `flutter/test/src/features/subscriptions/presentation/subscription_list_screen_test.dart` | Suppression tests ChoiceChip/SummaryCard, ajout date-labels + SectionHeaderSticky + navigation GoRouter |
| `flutter/test/src/features/debts/presentation/debt_list_screen_test.dart` | Suppression tests filtres/sections obsolètes, ajout groupement temporel + SectionHeaderSticky + navigation GoRouter |

### Fichiers supprimés (5)

| Fichier | Raison |
|---------|--------|
| `flutter/lib/src/features/dashboard/presentation/widgets/patrimoine_card.dart` | Remplacé par `DashboardHeroWidget` |
| `flutter/lib/src/features/dashboard/presentation/widgets/income_expense_cards.dart` | Fusionné dans `DashboardHeroWidget` |
| `flutter/lib/src/features/transactions/presentation/widgets/transaction_summary_card.dart` | Remplacé par `TransactionHeroWidget` |
| `flutter/test/src/features/dashboard/presentation/widgets/patrimoine_card_test.dart` | Widget supprimé |
| `flutter/test/src/features/dashboard/presentation/widgets/income_expense_cards_test.dart` | Widget supprimé |

### Dépendances

Aucune dépendance nouvelle. Dépendances existantes consommées :
- `shimmer` — skeleton loading
- `phosphor_flutter` — icônes meta-lines
- `SectionHeaderSticky` (KKS-238) — header collant
- `AppThemeExtension` — tokens `incomeColor` / `expenseColor`
- `AppColors.amber500` — date-label "Aujourd'hui" et "En retard"

---

## Configuration

Aucune configuration nouvelle. Les widgets hero lisent leurs données via les paramètres (pas de `ref.watch` interne) — les screens hôtes transmettent les données du notifier existant.

---

## Tests et validation

### Résultats

| Suite | Résultat |
|-------|---------|
| `flutter test` (global) | ✅ 836 tests, 0 échec |
| `flutter analyze lib/src/features/` (4 features) | ✅ No issues found |

### Couverture par Success Criteria

| SC | Description | Vérifié |
|----|-------------|---------|
| SC-001 | PatrimoineCard + IncomeExpenseCards absents du dashboard | ✅ Grep 0 résultat |
| SC-002 | Aucun LinearGradient dans dashboard_hero_widget.dart | ✅ Grep 0 résultat |
| SC-003 | Aucun ChoiceChip dans les 3 écrans | ✅ Grep 0 résultat |
| SC-004 | SectionHeaderSticky runtime dans les 3 screens | ✅ Tests T-055 + grep |
| SC-005 | Keys structurelles présentes dans les 4 heros | ✅ Tests T-050–T-053 |
| SC-006 | Skeletons avec keys dans les 4 heros | ✅ Tests T-050–T-053 |
| SC-007 | Date-label amber "Aujourd'hui" + expenseColor "En retard" | ✅ Code + tests T-053 |
| SC-008 | `flutter analyze` exit 0 | ✅ |
| SC-009 | Aucun hex hardcodé dans les 4 hero widgets | ✅ Grep 0 résultat |
| SC-010 | `forEachTheme` dans les 4 tests hero | ✅ |
| SC-011 | Aucun TODO KKS-240 | ✅ Grep 0 résultat |
| SC-012 | Navigation GoRouter.push sur items | ✅ Tests T-055 (subscription + debt) |
| NFR-001 | ≥ 10 tests | ✅ 836 total |

### Points de vigilance post-merge (warnings review-impl)

- **W-001** : Documentation `///` à compléter sur `DashboardHeroWidget`, `SubscriptionHeroWidget`, `DebtHeroWidget`
- **W-003** : Key `'dashboard_hero'` doublonnée — retirer le `key:` de l'instanciation dans `dashboard_screen.dart`
- **W-005** : `SectionHeaderSticky` absent du bloc `isLoading` dans `DebtListScreen` — à aligner avec `SubscriptionListScreen`

### Validation manuelle recommandée

1. Ouvrir chaque écran en dark mode et vérifier l'absence de gradient
2. Vérifier les labels sémantiques Transactions avec des données de dates variées
3. Vérifier les buckets temporels Dettes avec des dettes en retard (dueDate passée)
4. Vérifier la navigation item → detail pour Abonnements et Dettes
5. Vérifier le skeleton loading sur connexion lente

---

## Liens

- Issue Linear : [KKS-240](https://linear.app/kksdev/issue/KKS-240/phase-1-etape-4-refonte-4-ecrans-l-flutter)
- Parent : KKS-236 (Phase 1 — Refonte UI Flutter)
- Dépendances : KKS-237 (tokens), KKS-238 (SectionHeaderSticky)
- Artefacts : [spec.md](./spec.md) · [plan.md](./plan.md) · [tasks.md](./tasks.md) · [review-log.md](./review-log.md)
