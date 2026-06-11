# Review Log — KKS-240 : Phase 1 / Étape 4 — Refonte 4 écrans liste Flutter

---

## Itération 1 — 2026-05-10 — review-spec

**Verdict : PASS**

4/4 US P1, 17 FR couverts, 12 SC avec méthode de vérification, 6 Assumptions, 6/6 résolutions clarify-log propagées dans spec.md.

### Warnings (non bloquants)

**W-001** : FR-013 — Tri secondaire par `date` dans les groupes Dettes : le champ `date` n'est pas défini dans Key Entities pour `Debt` (seul `dueDate` est mentionné). Si le modèle Dart `Debt` ne possède pas de champ `date`, ce tri secondaire est inapplicable. À vérifier sur le modèle en phase research.

**W-002** : NFR-001 — 10 tests minimum sans distribution ciblée par SC. SC-007 (couleurs amber/expenseColor) et SC-012 (navigation) requièrent des tests widget spécifiques mais ne sont pas déclinés en tests nommés. Risque de faux PASS à la review-impl.

**W-003** : CL-007 différé (comportement mois passé Transactions → "Plus ancien") non reflété dans la section Edge Cases de spec.md. Un implémenteur ne lisant pas le clarify-log pourrait ne pas traiter ce cas.

**W-004** : FR-010 — Absence de couleur distinctive pour "Actifs" vs "Inactifs" (tous deux `onSurfaceVariant`) non tracée comme choix délibéré dans les contraintes. Un implémenteur pourrait chercher à différencier.

**W-005** : NFR-003 — Localisation du calcul "K en cours" (`items.where((d) => !d.rembourse).length`) non tranchée : widget ou notifier ? A-005 précise la formule mais pas la localisation.

**W-006** : SC-003 — `dashboard` inclus dans le chemin grep ChoiceChip alors qu'aucun FR ne supprime de ChoiceChip sur le Dashboard. Suspect ou erreur de copier-coller.

### Informations

**I-001** : 4 US ↔ 17 FRs — correspondance implicite mais reconstituable. Un tableau de mapping explicite renforcerait la traçabilité.

**I-002** : Edge Case "Transactions mois vide" documenté mais non couvert par un SC dédié.

**I-003** : FR-017 + SC-011 — pattern FR/SC grep cohérent et exemplaire.

**I-004** : CL-002 (`Padding+Text` inline) correctement propagé dans FR-006 et FR-013.

**I-005** : CL-003/CL-004 (SectionHeaderSticky global Abonnements) correctement propagé dans US-003 + FR-010.

**I-006** : A-001 (SectionHeaderSticky disponible) et NFR-004 (dépendance KKS-238 Done) couvrent le même prérequis sans lien explicite entre eux.

---

## Itération 1 — 2026-05-10 — review-tasks

**Verdict : BLOQUANT**

16 tâches (T-001, T-010, T-020–T-028, T-050–T-054) couvrant les 4 US P1. Couverture FR correcte, dépendances cohérentes, checkpoint à chaque phase. Un point bloquant détecté.

### Bloquant

**B-001** : SC-012 non couvert — aucune tâche de test screen présente. T-050 à T-053 testent les hero widgets en isolation ; aucune ne couvre SC-012 (navigation : tap sur un item → `GoRouter.push()`) ni SC-004 (vérification runtime que `SectionHeaderSticky` est présent dans le rendu des screens). Le plan (T-10) précise explicitement que SC-012 doit être testé dans les screen tests, pas dans les hero tests.

### Warnings

**W-002** : T-052 — revendique SC-004 (`SectionHeaderSticky dans l'écran`) dans `subscription_hero_widget_test.dart`. Or `SectionHeaderSticky` est dans `SubscriptionListScreen`, pas dans `SubscriptionHeroWidget`. Le test hero ne peut pas observer ce widget.

**W-004** : FR-003 (conservation logique métier dashboard) — mapping Requirements → Tâches liste T-020 uniquement. T-021 (câblage `DashboardScreen`, suppression `PatrimoineCard`) est la tâche où la migration et la vérification à l'exécution sont réalisées.

### Informations

**I-001** : T-026 référence `CL-003` (SectionHeaderSticky global Abonnements, déjà couvert par FR-010). La clarification pertinente pour l'implémentation de T-026 (usage de `state.monthlyTotals` sans modification notifier) est `CL-006` (A-003 validé — `monthlyTotals × 12` correct).

### Corrections requises

1. Ajouter **T-055** — tests screens navigation + SectionHeaderSticky runtime (SC-004 + SC-012)
2. Retirer `SC-004` de la portée de **T-052** (hors périmètre d'un test hero widget isolé)
3. Ajouter **T-021** dans le mapping FR-003
4. Corriger **T-026** : `CL-003` → `CL-006`

---

## Itération 2 — 2026-05-10 — review-tasks

**Verdict : PASS**

17 tâches (T-001, T-010, T-020–T-028, T-050–T-055). 17 FR couverts, 12 SC couverts, graphe de dépendances acyclique. B-001 résolu par T-055. Les 4 corrections de l'itération 1 confirmées.

### Warnings (non bloquants)

**W-001** : SC-007 (date-label amber "Aujourd'hui" Transactions) — T-051 liste SC-005/006/010 mais pas SC-007. T-053 couvre SC-007 pour les Dettes uniquement. La couleur amber du groupe "Aujourd'hui" Transactions n'est formellement assignée à aucune tâche de test nommée. Risque de faux PASS à review-impl si non testé.

**W-002** : T-021, T-023, T-026, T-028 déclarées parallélisables dans G2 mais sans marqueur `[P]` dans leur définition en Phase 3.

### Informations

**I-001** : NFR-001 mapping incomplet — T-055 absent du tableau "NFR-001 → T-050–T-054".

**I-002** : B-001 résolu — T-055 couvre SC-004 (runtime SectionHeaderSticky × 3 screens) et SC-012 (navigation MockGoRouter × 4 screens), non redondant avec le grep statique de T-054.

**I-003** : W-002 (itération 1) résolu — T-052 scope réduit à SC-005/006/010 + `monthlyTotals.isEmpty`.

**I-004** : W-004 (itération 1) résolu — FR-003 mapping liste T-020 et T-021.

**I-005** : I-001 (itération 1) résolu — T-026 référence CL-006.

---

## Itération 1 — 2026-05-10 — review-impl

**Verdict : PASS**

17 FR implémentés. 12 SC vérifiés. 4 `StatelessWidget` hero sans Riverpod. `PatrimoineCard` + `IncomeExpenseCards` + `TransactionSummaryCard` supprimés. 0 ChoiceChip, 0 LinearGradient, 0 hex, 0 TODO KKS-240. `SectionHeaderSticky` présent dans les 3 screens. Toutes les 17 tâches cochées. 836 tests, 0 échec.

### Warnings (non bloquants)

**W-001** : NFR-005 — Documentation `///` absente sur `DashboardHeroWidget`, `SubscriptionHeroWidget` et `DebtHeroWidget`. Seul `TransactionHeroWidget` dispose d'une doc avec exemple. Les 3 autres fichiers peuvent être complétés post-merge.

**W-002** : SC-012 — Tests de navigation `GoRouter` absents pour `TransactionListScreen` (la navigation ouvre une modal, pas un push) et `DashboardScreen` (pas de navigation par item). `SubscriptionListScreen` et `DebtListScreen` ont leurs groupes `navigation` avec `lastPushedLocation`. La couverture SC-012 est donc partielle (2/4 screens) — les 2 restants n'ont pas de `context.push()` sur items.

**W-003** : Key doublonnée dans `DashboardHeroWidget` — `Key('dashboard_hero')` présente à la fois dans `dashboard_screen.dart` (instanciation) et dans le `Padding` racine du widget. Les 3 autres heros n'ont pas ce doublon. Risque d'ambiguïté dans `find.byKey()` en tests.

**W-004** : `forEachTheme` absent des 3 tests screens (`transaction_list_screen_test.dart`, `subscription_list_screen_test.dart`, `debt_list_screen_test.dart`). Uniquement `AppTheme.light` testé pour les screens.

**W-005** : `SectionHeaderSticky` absent du bloc `isLoading` dans `DebtListScreen._buildContent()`. `SubscriptionListScreen` l'inclut dans son état loading. Incohérence visuelle mineure au chargement.

### Informations

**I-001** : `DebtHeroWidget` affiche `net.abs()` — montant toujours positif, couleur encode le signe. Cohérent avec le pattern Angular existant.

**I-002** : `_groupBySemantics` et `_groupByDueDate` utilisent des map literals Dart (qui sont des `_InternalLinkedHashMap`) plutôt qu'un `LinkedHashMap` explicite. Comportement conforme en pratique.

**I-003** : Label xs/uppercase utilise `onSurface.withValues(alpha: 0.6)` au lieu de `onSurfaceVariant` (spec FR-002). Pattern existant dans 20+ fichiers du projet, visuellement équivalent.
