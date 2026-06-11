# Research — KKS-240 : Phase 1 / Étape 4 — Refonte 4 écrans liste Flutter

> Date : 2026-05-10
> Issue : KKS-240
> Spec : [spec.md](./spec.md)

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Architecture widgets | StatelessWidget ou ConsumerWidget pour les 4 heros | Haute |
| RES-002 | Modèle données | Champ `date` dans `Debt` — existe-t-il pour le tri secondaire FR-013 ? | Haute |
| RES-003 | Architecture | Localisation calcul "K en cours" (hero Dettes) et solde net — widget ou notifier ? | Haute |
| RES-004 | Algorithme | Groupement sémantique Transactions : implémentation 5 buckets en Dart | Moyenne |
| RES-005 | Algorithme | Groupement temporel Dettes : implémentation 7 buckets par `dueDate` en Dart | Moyenne |
| RES-006 | API composant | SectionHeaderSticky : API publique et mode d'intégration dans `CustomScrollView` | Basse |
| RES-007 | Pattern UI | Skeleton shimmer pour hero widgets : structure et dimensions | Basse |
| RES-008 | Modèle données | `remainingAmount` dans `Debt` Flutter — présent ou absent ? | Basse |

---

## Décisions techniques

### RES-001 — Architecture des hero widgets : StatelessWidget passant paramètres

- **Contexte** : `PatrimoineCard` est un `ConsumerWidget` qui accède directement à `dashboardNotifierProvider` pour son état loading. Les nouveaux heros doivent-ils adopter le même pattern ou être plus composables ?

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `ConsumerWidget` accédant au notifier | Moins de prop-drilling depuis le screen | Couplage fort au provider, difficile à tester isolément | 2/5 |
| B — `StatelessWidget` avec paramètres explicites | Testable isolément, réutilisable, conforme principe V (testabilité) + principe III (simplicité) | Le screen parent (ConsumerWidget) fournit les données | 5/5 |

- **Décision** : **Option B** — `StatelessWidget` avec tous les paramètres passés explicitement (données + `isLoading: bool`). `incomeColor`/`expenseColor` accessibles via `Theme.of(context).extension<AppThemeExtension>()` sans besoin de Riverpod.

- **Rationale** : Conforme constitution principes III (YAGNI, simplicité) et V (testabilité). Les tests widget peuvent fournir des données directement sans mock de notifier. `AppThemeExtension` est un `ThemeExtension` Flutter standard, accessible depuis n'importe quel `BuildContext`.

- **Alternatives rejetées** : Option A — trop couplée. `PatrimoineCard` était ConsumerWidget par héritage de l'ancien pattern, pas par nécessité.

- **Impact sur le plan** : Chaque hero widget déclare ses paramètres explicitement. Les screens `DashboardScreen`, `TransactionListScreen`, `SubscriptionListScreen`, `DebtListScreen` (tous `ConsumerStatefulWidget`) passent les données nécessaires.

---

### RES-002 — Champ `date` dans `Debt` : confirmé + `remainingAmount` découvert

- **Contexte** : W-001 du review-spec signalait que le tri secondaire FR-013 par `date` DESC pouvait être invalide si le modèle `Debt` n'avait pas ce champ.

- **Analyse** : Lecture de `flutter/lib/src/domain/models/debt.dart` :
  ```dart
  @freezed
  class Debt with _$Debt {
    const factory Debt({
      required String id,
      required String personne,
      required double montant,
      required DebtType sens,
      required DateTime date,        // ← CONFIRMÉ
      @Default(false) bool rembourse,
      DateTime? dueDate,             // ← pour FR-013
      double? remainingAmount,       // ← présent (= montantRestant backend)
      ...
    }) = _Debt;
  }
  ```

- **Décision** : Tri secondaire `debt.date` DESC valide ✓. Le tri par groupe dans FR-013 est implémentable sans modification du modèle.

- **Bonus RES-008** : `double? remainingAmount` est présent dans le modèle Flutter (mappé depuis `montantRestant` dans `DebtResponse.java`). Ce champ est hors scope KKS-240 (A-006), mais son existence annule l'assertion "absent du modèle Dart" de la session précédente. À exploiter dans une future issue (affichage `remainingAmount` sur le `ListItem`).

- **Impact sur le plan** : Aucun. Le plan peut directement utiliser `debt.date` pour le tri secondaire dans les 7 buckets de FR-013.

---

### RES-003 — Localisation des calculs dans le hero Dettes : côté widget

- **Contexte** : W-005 du review-spec signalait l'ambiguïté sur où placer le calcul "K en cours" et le "solde net" : dans `DebtListState` (notifier) ou dans `DebtHeroWidget` (widget).

- **Analyse** : `DebtListState` expose :
  - `items: List<Debt>` — liste complète
  - `summary: Map<Currency, DebtCurrencySummary>` avec `totalEmprunts` + `totalPrets`
  - NFR-003 interdit toute modification des notifiers

- **Options évaluées** :

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Calculs dans `DebtHeroWidget` | NFR-003 respecté, cohérent avec RES-001 | Widget doit recevoir `items` + `summary` | 5/5 |
| B — Computed dans `DebtNotifier` | Calcul centralisé | Viole NFR-003 (modification notifier interdite) | 0/5 |

- **Décision** : **Option A** — calculs dans le widget :
  - **Solde net** = `(summary[currency]?.totalPrets ?? 0) - (summary[currency]?.totalEmprunts ?? 0)` — par currency si multi-devise
  - **K en cours** = `items.where((d) => !d.rembourse).length` — passé en paramètre au `SectionHeaderSticky(count: kEnCours)` et à `DebtHeroWidget`

- **Rationale** : NFR-003 est non négociable. Les calculs sont simples (O(n) sur `items`), sans logique métier complexe.

- **Impact sur le plan** : `DebtListScreen` calcule `kEnCours` et le passe à `DebtHeroWidget(enCours: kEnCours, summary: state.summary)` et à `SectionHeaderSticky(title: 'Dettes', count: kEnCours)`.

---

### RES-004 — Groupement sémantique Transactions : algorithme 5 buckets

- **Contexte** : Le groupement actuel est jour-par-jour (`groupBy` sur `DateTime(y,m,d)`). FR-006 impose 5 buckets sémantiques alignés sur Angular.

- **Analyse** : Package `collection` déjà importé dans `transaction_list_screen.dart` (`groupBy`). `DateTime.now()` disponible. Pas de dépendance externe nécessaire.

- **Décision** : Méthode privée `_semanticLabel(DateTime txDate, DateTime today)` dans `TransactionListScreen` :
  ```dart
  // Pseudo-code :
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1)); // lundi
  final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
  
  if (txDate == today)         → "Aujourd'hui"
  else if (txDate == yesterday) → "Hier"
  else if (txDate >= startOfWeek) → "Cette semaine"
  else if (txDate >= startOfLastWeek) → "Semaine dernière"
  else → "Plus ancien"
  ```
  
  Résultat : `Map<String, List<Transaction>>` avec ordre garanti par `LinkedHashMap` ou liste ordonnée de clés fixes.

- **Alternatives rejetées** : Modification du `TransactionListNotifier` (violerait NFR-003). Package externe `jiffy` ou `clock` (non nécessaire — `DateTime` natif suffit).

- **Impact sur le plan** : Méthode privée dans `_TransactionListScreenState`. Utilise `state.allMonthTransactions` (toutes les transactions, pas `filteredTransactions` qui dépend du filtre actif supprimé).

---

### RES-005 — Groupement temporel Dettes : algorithme 7 buckets

- **Contexte** : FR-013 impose 7 buckets par `dueDate`. `Debt.dueDate` est `DateTime?`. `Debt.rembourse` est `bool`.

- **Analyse** : Pas de package externe nécessaire. `DateTime.now()` + calculs de début de semaine/mois.

- **Décision** : Méthode privée `_debtBucket(Debt d, DateTime today)` retournant un `_DebtGroup` (enum ou constante de chaîne ordonnée) :
  ```dart
  // Pseudo-code :
  if (d.rembourse) → "Remboursées"
  if (d.dueDate == null) → "Sans échéance"
  final due = DateTime(d.dueDate!.year, d.dueDate!.month, d.dueDate!.day);
  if (due.isBefore(today)) → "En retard"
  if (due == today) → "Aujourd'hui"
  if (due.isBefore(today.add(Duration(days: 7)))) → "Cette semaine"
  if (due.month == today.month && due.year == today.year) → "Ce mois-ci"
  else → "Plus tard"
  ```
  
  Tri au sein de chaque bucket : `dueDate` ASC sauf "Sans échéance" et "Remboursées" (tri par `date` DESC). "Remboursées" toujours en dernier.

- **Impact sur le plan** : Méthode privée dans `_DebtListScreenState`. Utilise `state.items` (liste complète non filtrée).

---

### RES-006 — SectionHeaderSticky : API publique confirmée

- **Contexte** : Comment intégrer `SectionHeaderSticky` (livré KKS-238) dans `CustomScrollView` ?

- **Analyse** : Lecture de `flutter/lib/src/common_widgets/section_header_sticky.dart` :
  - `SectionHeaderSticky` est un `StatelessWidget` qui `build()` un `SliverPersistentHeader(pinned: true, delegate: ...)`.
  - API : `SectionHeaderSticky(title: String, count: int?, actions: List<Widget>?)`.
  - Hauteur fixe : **48px**.
  - S'utilise directement dans la liste de slivers de `CustomScrollView` — pas de wrapper supplémentaire.
  - Le `count` accepte un `int?` — passé sous forme `count: kEnCours` ou `count: actifCount`.

- **Décision** : Usage direct dans la liste `slivers: [...]` du `CustomScrollView` existant :
  ```dart
  CustomScrollView(slivers: [
    SliverToBoxAdapter(child: HeroWidget(...)),   // hero
    SectionHeaderSticky(title: 'Transactions'),   // sticky global
    SliverList.builder(...),                       // items avec date-labels
  ])
  ```

- **Impact sur le plan** : Aucune dépendance supplémentaire. `SectionHeaderSticky` remplace le `SliverToBoxAdapter(child: _SectionHeader(...))` existant dans `DebtListScreen`.

---

### RES-007 — Skeleton hero : pattern Shimmer + Container rectangulaire

- **Contexte** : NFR-005 et FR-016 imposent un skeleton pour chaque hero.

- **Analyse** : Pattern existant dans `PatrimoineCard._PatrimoineCardSkeleton` :
  ```dart
  Shimmer.fromColors(
    baseColor: colorScheme.surfaceContainerHighest,
    highlightColor: colorScheme.surface,
    child: Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
  )
  ```
  Les heros refactorisés seront plus compacts que l'ancienne `PatrimoineCard` (pas de gradient, flat). Hauteur estimée : **96px** (label + montant 3xl + 2 meta-lines avec AppSpacing).

- **Décision** : `_HeroSkeleton` privé dans chaque fichier hero : `Shimmer.fromColors` + `Container(height: 96)` avec `AppRadius.lg`. Même pattern que `_PatrimoineCardSkeleton`, sans copier son fichier.

- **Impact sur le plan** : Chaque fichier hero widget embarque sa propre classe `_XxxHeroSkeleton` privée.

---

## Analyse du codebase

### Patterns existants identifiés

- **Skeleton pattern** : `Shimmer.fromColors(baseColor: colorScheme.surfaceContainerHighest, highlightColor: colorScheme.surface, child: Container(...))` — uniforme dans tous les screens (`AccountListSkeleton`, `_SummaryCardSkeleton`, `_PatrimoineCardSkeleton`)
- **Hero data API** : Le screen parent (`ConsumerStatefulWidget`) lit le notifier et passe les données au widget enfant — pattern utilisé par `_SubscriptionSummaryCard(monthlyTotals: state.monthlyTotals, isLoading: state.isLoading)`
- **Calculs inline** : `PatrimoineCard` calcule patrimoine + variation + devise secondaire dans `build()` — migre tel quel dans `DashboardHeroWidget.build()`
- **AppThemeExtension** : `theme.extension<AppThemeExtension>()!.incomeColor` et `.expenseColor` — disponibles dans tout `BuildContext` sans Riverpod
- **AmountFormatter** : `AmountFormatter.format(amount, currency: currency)` — utilitaire existant réutilisé par tous les heros
- **Collection groupBy** : `package:collection/collection.dart` déjà importé dans `TransactionListScreen` — réutilisé pour le groupement sémantique
- **nextRenewalDate** : `package:k_budget/src/utils/next_renewal_date.dart` déjà importé dans `SubscriptionListScreen` — réutilisé si besoin pour le tri Abonnements

### Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| `shimmer` | déjà installé | Skeleton des 4 heros | Nul — déjà utilisé |
| `phosphor_flutter` | déjà installé | Icônes meta-lines (PhosphorRepeat, PhosphorCalendarBlank, etc.) | Nul — déjà utilisé |
| `collection` | déjà installé | `groupBy` pour groupement sémantique Transactions | Nul — déjà importé |
| `AppThemeExtension` | KKS-237 ✓ | `incomeColor`, `expenseColor` dans les heros | Nul — livré et disponible |
| `SectionHeaderSticky` | KKS-238 ✓ | 1 header global par écran Transactions/Abonnements/Dettes | Nul — livré et disponible |

**Aucune nouvelle dépendance requise.**

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 8 |
| Décisions prises | 8 |
| Nouvelles dépendances | 0 |
| Patterns réutilisés | 6 (Shimmer, AppThemeExtension, AmountFormatter, groupBy, nextRenewalDate, SectionHeaderSticky) |

### Points clés pour le plan

1. **RES-001** : Tous les heros = `StatelessWidget` avec paramètres — testable isolément
2. **RES-002** : `Debt.date` confirmé → tri secondaire FR-013 valide ; `remainingAmount` présent mais hors scope
3. **RES-003** : Calculs "K en cours" + "solde net" = côté widget (NFR-003)
4. **RES-004** : Groupement sémantique = méthode privée + `DateTime` natif (pas de package)
5. **RES-005** : Groupement temporel Dettes = méthode privée avec 7 buckets ordonnés
6. **RES-006** : `SectionHeaderSticky` = sliver direct dans `CustomScrollView`, hauteur 48px
7. **RES-007** : Skeleton = `Container(height: 96)` + `Shimmer.fromColors` par hero
8. **RES-008** : `remainingAmount` présent dans Flutter — note pour future issue, hors scope ici
