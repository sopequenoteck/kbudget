# Spécification — KKS-240 : Phase 1 / Étape 4 — Refonte 4 écrans liste Flutter

> Date : 2026-05-10
> Issue : KKS-240
> Branche : `feature/flutter-screens-listes-v5`
> Priorité : High
> Labels : Feature
> Parent : KKS-236

---

## Résumé

Refonte des 4 écrans liste majeurs Flutter (`Dashboard`, `Transactions`, `Abonnements`, `Dettes`) pour alignement sur DESIGN.md v5 et parité avec les écrans Angular de référence. Suppression des anti-patterns (gradients, SegmentedFilter/ChoiceChips), ajout du pattern Hero flat avec meta-lines Phosphor, 1 `SectionHeaderSticky` global par écran, et groupements sémantiques/temporels (Transactions : labels temporels ; Abonnements : actifs/inactifs ; Dettes : urgence par `dueDate`).

---

## User Stories

### US-001 — Dashboard : hero flat patrimoine (P1)

L'utilisateur ouvre le dashboard et voit son patrimoine présenté dans un hero flat — sans gradient — avec ses revenus et dépenses du mois affichés en meta-lines icônées. L'aspect visuel est sobre et lisible en dark mode.

**Why this priority** : `PatrimoineCard` est marquée `@Deprecated` dans le code depuis KKS-239. C'est le composant le plus visible de l'app. La non-conformité DESIGN.md v5 est bloquante pour la cohérence visuelle globale.

**Independent Test** : Naviguer sur le Dashboard — la carte patrimoine ne doit présenter aucun gradient de fond (aucun `LinearGradient`). Les revenus et dépenses du mois sont visibles en meta-lines (icône Phosphor + montant), pas en 2 cards distinctes avec bordure.

**Acceptance Scenarios** :

1. **Given** un utilisateur avec des comptes et transactions ce mois, **When** il ouvre le Dashboard, **Then** un `DashboardHeroWidget` est affiché : label "PATRIMOINE TOTAL" (xs/uppercase/tertiary), montant 3xl/bold (`incomeColor` si patrimoine ≥ 0, `expenseColor` si < 0), badge variation "+X€ ce mois (+X%)" sous le montant, meta-line revenus (icône `PhosphorTrendUp` 14px + montant incomeColor), meta-line dépenses (icône `PhosphorTrendDown` 14px + montant expenseColor)
2. **Given** un utilisateur avec 2 devises configurées, **When** il visualise le hero, **Then** la conversion devise secondaire est affichée en xs/tertiary sous le montant principal (≈ X devise)
3. **Given** un patrimoine net positif ce mois, **When** le badge variation est rendu, **Then** il affiche "+X€ ce mois (+X%)" en `incomeColor` ; si négatif → expenseColor ; si nul → onSurfaceVariant
4. **Given** le Dashboard, **When** il est rendu, **Then** `PatrimoineCard` et `IncomeExpenseCards` ne sont plus référencés dans `DashboardScreen.build()`

---

### US-002 — Transactions liste : hero solde + SectionHeaderSticky global + groupement sémantique + suppression filtre (P1)

L'utilisateur navigue sur l'écran Transactions et voit le solde mensuel dans un hero (avec meta-lines revenus/dépenses). Le filtre ChoiceChip est absent. Les transactions sont groupées par labels sémantiques ("Aujourd'hui" / "Hier" / "Cette semaine" / "Semaine dernière" / "Plus ancien") séparés par des `date-label`. Un seul `SectionHeaderSticky` global ancre le titre de l'écran.

**Why this priority** : 3 `ChoiceChip` sont des anti-patterns DESIGN.md v5 explicitement documentés (`// TODO KKS-240` dans le code). La `TransactionSummaryCard` (3 metric chips) remplace sans valeur le pattern hero attendu.

**Independent Test** : Naviguer sur Transactions — aucun `ChoiceChip` visible, un hero solde mensuel en haut, un `SectionHeaderSticky` "Transactions" collant, les groupes sémantiques séparés par des `date-label` amber (Aujourd'hui) ou neutres.

**Acceptance Scenarios** :

1. **Given** un mois avec des transactions, **When** l'écran est affiché, **Then** un `TransactionHeroWidget` remplace `TransactionSummaryCard` : label "SOLDE" (xs/uppercase/tertiary), bilan mensuel 3xl/bold (incomeColor si ≥ 0, expenseColor si < 0), meta-line revenus (`PhosphorTrendUp` + montant incomeColor), meta-line dépenses (`PhosphorTrendDown` + montant expenseColor)
2. **Given** l'écran Transactions, **When** il est rendu, **Then** aucun `ChoiceChip` n'est présent — toutes les transactions du mois sont affichées, groupées par labels sémantiques : "Aujourd'hui" / "Hier" / "Cette semaine" / "Semaine dernière" / "Plus ancien" (groupes vides omis)
3. **Given** des transactions de différentes dates, **When** la liste est rendue, **Then** chaque groupe est précédé d'un `date-label` ; le label "Aujourd'hui" est affiché en `AppColors.amber`, tous les autres en `colorScheme.onSurfaceVariant` — aucun rouge (les transactions n'ont pas de notion d'"en retard")
4. **Given** le mois sélectionné sans transaction, **When** l'écran est vide, **Then** l'`EmptyState` est affiché (icône + message, sans hero ni groupes)

---

### US-003 — Abonnements liste : hero total + sections Actifs/Inactifs + suppression filtre (P1)

L'utilisateur navigue sur l'écran Abonnements et voit le total mensuel dans un hero avec meta-lines (nombre d'actifs, total annuel). Le filtre ChoiceChip est remplacé par des sections `SectionHeaderSticky` "Actifs" / "Inactifs".

**Why this priority** : Même anti-pattern ChoiceChip que Transactions (`// TODO KKS-240` dans le code). Les 2 autres `TODO KKS-240` screens sont liés.

**Independent Test** : Naviguer sur Abonnements — aucun `ChoiceChip` visible, hero total mensuel en haut, 1 `SectionHeaderSticky` global "Abonnements · N actifs" collant, liste divisée en blocs "Actifs" / "Inactifs" séparés par des `date-label` légers.

**Acceptance Scenarios** :

1. **Given** des abonnements actifs et inactifs, **When** l'écran est affiché, **Then** un `SubscriptionHeroWidget` remplace `_SubscriptionSummaryCard` : label "ABONNEMENTS" (xs/uppercase/tertiary), total mensuel 3xl/bold (expenseColor), meta-line actifs (`PhosphorRepeat` + "N actifs"), meta-line annuel (`PhosphorCalendarBlank` + "≈ X€/an")
2. **Given** la liste d'abonnements, **When** elle est rendue, **Then** un `SectionHeaderSticky` global "Abonnements · N actifs" est affiché (collant) ; la liste est divisée par des `date-label` "Actifs" et "Inactifs" — le filtre ChoiceChip est absent
3. **Given** uniquement des abonnements actifs (aucun inactif), **When** l'écran est rendu, **Then** seule la section "Actifs" est visible (section "Inactifs" absente si vide)
4. **Given** l'écran Abonnements, **When** il est rendu, **Then** aucun `ChoiceChip` ni `SubscriptionStatusFilter` n'est référencé dans la présentation

---

### US-004 — Dettes liste : hero solde net + groupement temporel par échéance + suppression filtre (P1)

L'utilisateur navigue sur l'écran Dettes et voit le solde net dans un hero avec meta-lines (prêts, emprunts, en cours). La liste est groupée par urgence temporelle (comme Angular) : "En retard" / "Aujourd'hui" / "Cette semaine" / "Ce mois-ci" / "Plus tard" / "Sans échéance" / "Remboursées". Le filtre ChoiceChip est supprimé.

**Why this priority** : Cohérence avec les 3 autres écrans. La `_DebtSummaryCard` existante affiche déjà les données mais dans un style card non conforme DESIGN.md v5. `TODO KKS-240` dans le code.

**Independent Test** : Naviguer sur Dettes — aucun `ChoiceChip` visible, hero solde net en haut, un `SectionHeaderSticky` global "Dettes · K en cours", groupes temporels séparés par des `date-label` (rouge = en retard, amber = aujourd'hui, neutre = reste).

**Acceptance Scenarios** :

1. **Given** des prêts et emprunts, **When** l'écran est affiché, **Then** un `DebtHeroWidget` remplace `_DebtSummaryCard` : label "DETTES" (xs/uppercase/tertiary), solde net 3xl/bold (incomeColor si net > 0, expenseColor si net < 0, onSurface si 0), meta-ligne 1 : `PhosphorHandCoins` 14px + "N prêts" · `PhosphorHandshake` 14px + "M emprunts", meta-ligne 2 : `PhosphorClock` 14px + "K en cours"
2. **Given** la liste de dettes, **When** elle est rendue, **Then** les dettes sont groupées par `date-label` dans cet ordre (groupes vides omis) : "En retard" (rouge `expenseColor`) / "Aujourd'hui" (amber) / "Cette semaine" / "Ce mois-ci" / "Plus tard" / "Sans échéance" / "Remboursées" (tertiary) — le filtre ChoiceChip est absent
3. **Given** une dette avec `dueDate` dépassée et `rembourse: false`, **When** elle est affichée, **Then** elle apparaît dans le groupe "En retard" avec un `date-label` en `expenseColor`
4. **Given** une dette avec `rembourse: true`, **When** la liste est rendue, **Then** elle apparaît dans le groupe "Remboursées" en dernier, `date-label` en `onSurfaceVariant`

---

### Edge Cases

- Dashboard avec 0 comptes : l'`EmptyState` existant est conservé tel quel (pas touché par cette feature)
- Transactions mois vide : hero affiché avec montants à 0, `EmptyState` en lieu et place de la liste
- Abonnements tous inactifs : seule la section "Inactifs" est visible
- Dettes toutes sans `dueDate` : seul le groupe "Sans échéance" est visible
- Dettes toutes remboursées : seul le groupe "Remboursées" est visible
- Dettes en retard : groupe "En retard" affiché en premier avec `date-label` rouge
- Hero et devise multi-currency : si l'utilisateur n'a qu'une devise configurée, la ligne de conversion secondaire est absente
- `SectionHeaderSticky` dans un `CustomScrollView` sans `NestedScrollView` : pattern déjà validé par `SectionHeaderSticky.dart` (note incompatibilité explicite dans le composant)
- Loading state : le hero affiche un skeleton (`_HeroSkeleton`) identique au pattern shimmer existant

---

## Requirements fonctionnels

### FR-001 — Dashboard : suppression PatrimoineCard + IncomeExpenseCards

`DashboardScreen` NE DOIT PLUS référencer `PatrimoineCard` ni `IncomeExpenseCards`. Ces deux widgets sont remplacés par un `DashboardHeroWidget` unique.

### FR-002 — Dashboard : DashboardHeroWidget flat

`DashboardHeroWidget` DOIT être un `StatelessWidget` sans gradient de fond (`LinearGradient` interdit). Fond transparent sur fond page. Structure :
- Label xs/uppercase/letterSpacing 0.05/onSurfaceVariant : "PATRIMOINE TOTAL"
- Montant `AppTypography.size3xl` / bold / `incomeColor` si patrimoine ≥ 0, `expenseColor` si < 0
- Badge variation (+X€ ce mois / ±X%) — couleur incomeColor/expenseColor/onSurfaceVariant selon signe net
- [optionnel] Conversion devise secondaire xs/onSurfaceVariant (≈ X devise)
- Meta-line revenus : `PhosphorTrendUp` 14px + montant `incomeColor`
- Meta-line dépenses : `PhosphorTrendDown` 14px + montant `expenseColor`

### FR-003 — Dashboard : conservation logique métier

La logique de calcul du patrimoine total, de la variation mensuelle, et de la conversion multi-devise de `PatrimoineCard` DOIT être conservée dans `DashboardHeroWidget`. Aucune modification du `DashboardNotifier`.

### FR-004 — Transactions : suppression SegmentedFilter

L'écran `TransactionListScreen` NE DOIT PLUS afficher de `ChoiceChip` pour filtrer par type (all/dépense/recette). Le `TransactionTypeFilter` peut être conservé dans le notifier pour usage futur, mais NE DOIT PAS être exposé en UI.

### FR-005 — Transactions : TransactionHeroWidget

`TransactionHeroWidget` DOIT remplacer `TransactionSummaryCard`. Structure :
- Label xs/uppercase/letterSpacing : "SOLDE"
- Bilan mensuel `size3xl`/bold (incomeColor si ≥ 0, expenseColor si < 0)
- Meta-line revenus : Phosphor icon + "Revenus X€" (incomeColor)
- Meta-line dépenses : Phosphor icon + "Dépenses X€" (expenseColor)

### FR-006 — Transactions : SectionHeaderSticky global + groupement sémantique

`TransactionListScreen` DOIT comporter **un seul** `SectionHeaderSticky` global avec titre "Transactions" (collant sous le hero). Les transactions DOIVENT être regroupées par labels sémantiques temporels dans cet ordre (groupes vides omis) :
1. "Aujourd'hui" — transactions dont la date == aujourd'hui
2. "Hier" — transactions dont la date == hier
3. "Cette semaine" — depuis lundi de la semaine courante (hors Aujourd'hui/Hier)
4. "Semaine dernière" — semaine précédente
5. "Plus ancien" — tout le reste du mois

Chaque groupe est précédé d'un `date-label` : widget inline `Padding(child: Text(...))` — pas de widget standalone dédié. Style xs/medium. "Aujourd'hui" en `AppColors.amber`, les autres en `colorScheme.onSurfaceVariant`. Aucune couleur rouge (transactions sans notion d'"en retard").

### FR-007 — Transactions : `TransactionDayGroup` remplacé par groupement sémantique

Le groupement actuel jour-par-jour de `TransactionListScreen._buildContent()` DOIT être remplacé par le groupement sémantique ci-dessus (FR-006). `TransactionDayGroup` peut être conservé pour rendre les items d'un groupe, mais son header de date interne DOIT être retiré (le `date-label` est désormais rendu par le parent).

### FR-008 — Abonnements : suppression SegmentedFilter

`SubscriptionListScreen` NE DOIT PLUS afficher de `ChoiceChip` pour filtrer par statut. Le `SubscriptionStatusFilter` dans le notifier peut être conservé, mais NE DOIT PAS être exposé en UI.

### FR-009 — Abonnements : SubscriptionHeroWidget

`SubscriptionHeroWidget` DOIT remplacer `_SubscriptionSummaryCard`. Structure :
- Label xs/uppercase : "ABONNEMENTS"
- Total mensuel `size3xl`/bold/expenseColor
- Meta-line : `PhosphorRepeat` 14px + "N actifs"
- Meta-line : `PhosphorCalendarBlank` 14px + "≈ X€/an" (total annuel calculé)

### FR-010 — Abonnements : SectionHeaderSticky global + blocs Actifs / Inactifs

`SubscriptionListScreen` DOIT comporter **un seul** `SectionHeaderSticky` global avec titre "Abonnements · N actifs" (collant). La liste DOIT être groupée en 2 blocs séparés par des `date-label` inline (`Padding` + `Text`) :
- `date-label` "Actifs" (abonnements avec `actif == true`, couleur `onSurfaceVariant`)
- `date-label` "Inactifs" (abonnements avec `actif == false`, couleur `onSurfaceVariant`)
Un bloc est omis si aucun item ne lui correspond.

### FR-011 — Dettes : suppression SegmentedFilter

`DebtListScreen` NE DOIT PLUS afficher de `ChoiceChip`. Le `DebtStatusFilter` peut être conservé dans le notifier.

### FR-012 — Dettes : DebtHeroWidget

`DebtHeroWidget` DOIT remplacer `_DebtSummaryCard`. Structure (alignée sur Angular) :
- Label xs/uppercase : "DETTES"
- Solde net `size3xl`/bold (incomeColor si net > 0, expenseColor si net < 0, onSurface si 0)
- [optionnel] Conversion devise secondaire xs/onSurfaceVariant
- Meta-ligne 1 : `PhosphorHandCoins` 14px + "N prêts" · `PhosphorHandshake` 14px + "M emprunts"
- Meta-ligne 2 : `PhosphorClock` 14px + "K en cours" (= dettes non remboursées)

### FR-013 — Dettes : SectionHeaderSticky global + groupement temporel par échéance

`DebtListScreen` DOIT comporter **un seul** `SectionHeaderSticky` global avec titre "Dettes" + count "K en cours". La liste DOIT être groupée par urgence temporelle via `dueDate` (groupes vides omis, dans cet ordre) :
1. "En retard" — `dueDate` dépassée + non remboursée (`date-label` : `expenseColor`)
2. "Aujourd'hui" — `dueDate` == aujourd'hui (`date-label` : `AppColors.amber`)
3. "Cette semaine" — `dueDate` dans les 7 prochains jours
4. "Ce mois-ci" — `dueDate` avant fin du mois courant
5. "Plus tard" — `dueDate` au-delà
6. "Sans échéance" — `dueDate == null` + non remboursée
7. "Remboursées" — `rembourse == true` (`date-label` : `onSurfaceVariant`)

Chaque groupe est précédé d'un `date-label` : widget inline `Padding(child: Text(...))` — pas de widget standalone dédié. Style xs/medium.

Tri au sein de chaque groupe : par `dueDate` ASC (sans `dueDate` après), puis par `date` DESC. Le `_SectionHeader` statique privé existant DOIT être supprimé.

### FR-014 — Keys structurelles

Chaque hero widget DOIT exposer une `Key` constante identifiable pour les tests widget :
- `DashboardHeroWidget` → `Key('dashboard_hero')`
- `TransactionHeroWidget` → `Key('transaction_hero')`
- `SubscriptionHeroWidget` → `Key('subscription_hero')`
- `DebtHeroWidget` → `Key('debt_hero')`
Chaque skeleton DOIT utiliser `Key('<name>_hero_skeleton')`.

### FR-015 — Tokens exclusivement

Tous les nouveaux widgets DOIVENT utiliser exclusivement les design tokens Flutter (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppThemeExtension`). Aucune valeur hexadécimale, rgba, ou numérique de couleur hardcodée.

### FR-016 — Skeleton loading pour les heros

Chaque hero widget DOIT avoir un skeleton `shimmer` pour l'état loading, cohérent avec les skeletons existants (même pattern `Shimmer.fromColors`).

### FR-017 — Suppression des `TODO KKS-240`

Les commentaires `// TODO KKS-240` dans `transaction_list_screen.dart`, `subscription_list_screen.dart`, et `debt_list_screen.dart` DOIVENT être supprimés après refonte.

---

## Requirements non-fonctionnels

### NFR-001 — Tests (minimum 10)

Au moins 10 widget tests couvrant les 4 nouveaux hero widgets + les sections groupées. Pattern `forEachTheme` obligatoire (dark + light).

### NFR-002 — Analyse statique

`flutter analyze` exit 0 sur tous les fichiers modifiés/créés. Aucun warning toléré.

### NFR-003 — Aucune régression fonctionnelle

La logique métier existante (chargement, refresh, navigation vers le détail, multi-devise) doit être préservée intégralement. Aucune modification des notifiers/states.

### NFR-004 — Dépendances KKS-237+KKS-238+KKS-239

Les tokens de design (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppDurations`, `AppThemeExtension`) livrés en KKS-237, et le `SectionHeaderSticky` livré en KKS-238, sont disponibles sur la branche courante.

### NFR-005 — Documentation `///`

Chaque nouveau widget public (`DashboardHeroWidget`, `TransactionHeroWidget`, `SubscriptionHeroWidget`, `DebtHeroWidget`) DOIT avoir une documentation `///` avec au moins un exemple d'usage.

---

## Contraintes et dépendances

### Contraintes

| Ref | Contrainte |
|-----|-----------|
| CL-001 | `PatrimoineCard` est `@Deprecated` — la supprimer du code sans la déplacer |
| CL-002 | `IncomeExpenseCards` est un `StatelessWidget` avec delta vs mois précédent — seule la logique patrimoine total + variation mensuelle (net + %) migre vers `DashboardHeroWidget` ; les badges delta par card revenus/dépenses sont abandonnés (absents d'Angular) |
| CL-003 | `TransactionDayGroup` est utilisé dans `TransactionListScreen._buildContent()` — son header de date interne DOIT être retiré ; le widget peut subsister pour rendre les items d'un groupe sémantique |
| CL-004 | `SectionHeaderSticky` est incompatible avec `NestedScrollView` — les 4 écrans utilisent `CustomScrollView` directement (compatible) |
| CL-005 | `TransactionTypeFilter` (enum state) peut être conservé dans le notifier pour usage futur (ex : recherche) — mais le `setFilter()` ne doit plus être appelé depuis l'UI |
| CL-006 | Les 4 heros DOIVENT remplacer les summary cards existantes — pas de doublon |

### Dépendances

| Issue | Statut | Apport utilisé |
|-------|--------|----------------|
| KKS-237 | ✓ Done | Tokens design (`AppColors`, `AppSpacing`, `AppTypography`, `AppRadius`, `AppThemeExtension`) |
| KKS-238 | ✓ Done | `SectionHeaderSticky`, `InlineDatePicker`, `CategorySelectExpand` |
| KKS-239 | ✓ Done | `BottomSheet4RowsWidget` (prérequis KKS-241, non utilisé ici) |

---

## Questions ouvertes

Aucune question ouverte — toutes résolues par analyse des écrans Angular de référence (2026-05-10).

| # | Question | Résolution |
|---|---------|-----------|
| Q-001 | Badge variation mensuelle Dashboard | **Conservé** — présent dans `dashboard.html` Angular (`variation-badge`) |
| Q-002 | Groupement + remboursées Dettes | **Groupement temporel** (7 buckets par `dueDate`, remboursées en dernier) — aligné sur Angular `groupedDebts` |
| Q-003 | SectionHeaderSticky par jour vs global | **1 seul global** par écran + `date-label` légers pour les groupes — aligné sur Angular |

---

## Success Criteria

| SC | Description | Méthode de vérification |
|----|-------------|------------------------|
| SC-001 | `PatrimoineCard` et `IncomeExpenseCards` absents de `DashboardScreen.build()` | `grep -r "PatrimoineCard\|IncomeExpenseCards" flutter/lib/src/features/dashboard/presentation/` → 0 résultat |
| SC-002 | `DashboardHeroWidget` sans gradient : aucun `LinearGradient` dans le fichier | `grep -n "LinearGradient" flutter/lib/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart` → 0 résultat |
| SC-003 | Aucun `ChoiceChip` dans les 4 écrans liste | `grep -rn "ChoiceChip" flutter/lib/src/features/{dashboard,transactions,subscriptions,debts}/presentation/` → 0 résultat |
| SC-004 | `SectionHeaderSticky` utilisé dans Transactions, Abonnements et Dettes | `grep -rn "SectionHeaderSticky" flutter/lib/src/features/{transactions,subscriptions,debts}/` → ≥ 1 résultat par feature |
| SC-005 | Hero pattern : label xs/uppercase + montant size3xl + meta-lines → vérifiable par widget test | `flutter test` → `find(Key('dashboard_hero'))`, `find(Key('transaction_hero'))`, `find(Key('subscription_hero'))`, `find(Key('debt_hero'))` trouvés respectivement |
| SC-006 | Skeleton shimmer présent pour chaque hero | Widget test : `isLoading: true` → `find(Key('dashboard_hero_skeleton'))`, `find(Key('transaction_hero_skeleton'))`, etc. trouvés |
| SC-007 | Date label amber pour "Aujourd'hui" dans Transactions, rouge "En retard" dans Dettes | Widget test : groupe "Aujourd'hui" → amber ; groupe "En retard" → expenseColor |
| SC-008 | `flutter analyze` exit 0 sur tous les fichiers modifiés | `cd flutter && flutter analyze lib/src/features/` → No issues found! |
| SC-009 | Aucun hex hardcodé dans les nouveaux fichiers | `grep -nE "Color\(0x|#[0-9a-fA-F]{6,8}" flutter/lib/src/features/*/presentation/widgets/*_hero_widget.dart` → 0 résultat |
| SC-010 | Tests dark + light via `forEachTheme` | Suite de tests → ≥ 10 tests, tous verts |
| SC-011 | `TODO KKS-240` absents du code | `grep -rn "TODO KKS-240" flutter/lib/` → 0 résultat |
| SC-012 | Aucune régression : navigation vers détail fonctionne dans les 4 écrans | Test widget : tap sur un item → `GoRouter.push()` déclenché |

---

## Key Entities

Pas de nouvelles entités de données. Les entités existantes `MonthlySummary`, `Subscription`, `Debt`, `Account` sont consommées telles quelles par les nouveaux widgets.

**Widgets créés** (P = public, _ = privé) :
- `DashboardHeroWidget` (P) — remplace `PatrimoineCard` + `IncomeExpenseCards`
- `TransactionHeroWidget` (P) — remplace `TransactionSummaryCard`
- `SubscriptionHeroWidget` (P) — remplace `_SubscriptionSummaryCard`
- `DebtHeroWidget` (P) — remplace `_DebtSummaryCard`

**Widgets supprimés** :
- `PatrimoineCard` (supprimé — deprecated)
- `IncomeExpenseCards` (supprimé)

**Widgets modifiés** :
- `DashboardScreen` — remplace les 2 cards par `DashboardHeroWidget`
- `TransactionListScreen` — supprime ChoiceChips, ajoute hero + SectionHeaderSticky global + groupement sémantique
- `TransactionDayGroup` — retrait du header de date interne
- `SubscriptionListScreen` — supprime ChoiceChips, ajoute hero + SectionHeaderSticky global + sections temporelles
- `DebtListScreen` — supprime ChoiceChips, ajoute hero + SectionHeaderSticky global + groupement temporel par `dueDate`

---

## Assumptions

| # | Hypothèse | Impact si fausse |
|---|-----------|-----------------|
| A-001 | `SectionHeaderSticky` est livré et fonctionnel sur la branche courante (KKS-238 mergé) | BLOQUANT — à vérifier en setup |
| A-002 | `forEachTheme` helper est disponible dans les tests | Bloquant pour NFR-001 — alternative : dupliquer les tests dark/light |
| A-003 | Le `SubscriptionNotifier` calcule déjà `monthlyTotals` en normalisant : `Frequency.annuel → montant/12`, `mensuel → montant`, `hebdomadaire → montant*4.33`. Le total annuel `= monthlyTotal × 12` est valide côté widget sans modification du notifier. | Validé — source : `subscription_notifier.dart` |
| A-004 | `TransactionDayGroup` peut être adapté sans refactoring majeur (retrait du header de date uniquement) | Si fausse → créer un `TransactionGroupItems` sans header |
| A-005 | Le calcul "N en cours" pour le hero Dettes = `items.where((d) => !d.rembourse).length` | Si la définition de "en cours" change → adapter le calcul |
| A-006 | Le groupement temporel Dettes utilise `debt.dueDate` (présent dans le modèle Dart comme `DateTime? dueDate`) — pas de `montantRestant` (absent du modèle Dart, hors scope KKS-240) | Si `montantRestant` est requis → ajouter le champ au modèle `Debt` dans une issue dédiée |
