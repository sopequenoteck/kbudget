# Tasks: Refonte Dashboard Flutter

**Input**: Design documents from `/specs/096-flutter-dashboard-refonte/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus (demandes dans SC-006 de la spec)

**Organization**: Tasks groupees par user story pour implementation et tests independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Foundational (State & Notifier)

**Purpose**: Modifier le DashboardState et DashboardNotifier pour supporter la nouvelle structure. BLOQUE toutes les user stories.

- [x] T001 Modifier DashboardState : ajouter currentSummary/previousSummary, supprimer champs MiniCards/MonthSelector dans `flutter/lib/src/features/dashboard/application/dashboard_state.dart`
- [x] T002 Regenerer le code Freezed apres modification du state (`dart run build_runner build --delete-conflicting-outputs` depuis `flutter/`)
- [x] T003 Modifier DashboardNotifier : charger mois courant + precedent en parallele, supprimer chargement subscriptions/debts, supprimer methode changeMonth() dans `flutter/lib/src/features/dashboard/application/dashboard_notifier.dart`

**Checkpoint**: State et Notifier compiles, les providers sous-jacents sont charges correctement. Le dashboard ne compile pas encore (widgets pas encore mis a jour).

---

## Phase 2: User Story 1 - Carte Patrimoine Total (Priority: P1)

**Goal**: Afficher une carte "Patrimoine Total" avec la somme des soldes convertis, la variation mensuelle (montant + %), et la conversion en devise secondaire.

**Independent Test**: Ouvrir le dashboard → la carte patrimoine affiche le bon montant total, la variation %, et la conversion secondaire si multi-devise.

### Implementation for User Story 1

- [x] T004 [US1] Creer le widget PatrimoineCard dans `flutter/lib/src/features/dashboard/presentation/widgets/patrimoine_card.dart` — affiche label "PATRIMOINE TOTAL", montant total converti en devise active, badge variation mensuelle (montant + % vert/rouge), sous-texte conversion en devise secondaire si currencies.length >= 2, icone warning si taux manquants. Parametres : accounts, activeCurrency, exchangeRates, currencies, currentSummary. Calculs patrimoine/variation dans le widget ou via helper.
- [x] T005 [US1] Creer le skeleton shimmer _PatrimoineCardSkeleton dans le meme fichier `flutter/lib/src/features/dashboard/presentation/widgets/patrimoine_card.dart`

**Checkpoint**: PatrimoineCard peut etre instancie et affiche les bonnes donnees.

---

## Phase 3: User Story 2 - Cartes Revenus / Depenses (Priority: P1)

**Goal**: Afficher deux cartes cote-a-cote Revenus (vert) et Depenses (rouge) avec montants en devise principale, delta vs mois precedent, et conversion secondaire.

**Independent Test**: Ouvrir le dashboard → les cartes montrent les bons totaux du mois en devise principale avec le delta correct par rapport au mois precedent.

### Implementation for User Story 2

- [x] T006 [US2] Creer le widget IncomeExpenseCards dans `flutter/lib/src/features/dashboard/presentation/widgets/income_expense_cards.dart` — Row avec 2 Expanded cards. Chaque carte : dot couleur (vert revenus, rouge depenses), label, montant en devise principale (currencies[0]), badge delta vs mois precedent (fleche + montant + "vs [mois]"), sous-texte conversion devise secondaire. Parametres : currentSummary, previousSummary, currencies, exchangeRates, activeCurrency. Utiliser CurrencyConverter et AmountFormatter existants.
- [x] T007 [US2] Creer le skeleton shimmer _IncomeExpenseCardsSkeleton dans le meme fichier `flutter/lib/src/features/dashboard/presentation/widgets/income_expense_cards.dart`

**Checkpoint**: IncomeExpenseCards peut etre instancie et affiche revenus/depenses avec delta correct.

---

## Phase 4: User Story 3 - Header (Priority: P2)

**Goal**: Header enrichi avec salutation personnalisee, cloche notifications (ouvre NotificationPanel ou noop), et avatar avec menu dropdown (nom, parametres, deconnexion).

**Independent Test**: Ouvrir le dashboard → le header affiche "Bonjour [Prenom]", une cloche, et un avatar. Taper sur l'avatar → menu avec Parametres et Deconnexion.

### Implementation for User Story 3

- [x] T008 [US3] Creer le widget DashboardHeader dans `flutter/lib/src/features/dashboard/presentation/widgets/dashboard_header.dart` — Row avec : Text salutation a gauche (Expanded), cloche PhosphorIconsRegular.bell a droite (avec badge conditionnel si notifications non lues), avatar CircleAvatar avec initiale du nom. Cloche : tap ouvre NotificationPanel si disponible (verifier existence du provider), sinon noop. Avatar : tap ouvre PopupMenuButton avec 3 items : nom utilisateur (non cliquable, header du menu), "Parametres" (navigue vers /settings via context.push), "Deconnexion" (appelle logout + navigue vers /login). Parametres : userName (String?). ConsumerWidget pour acceder aux providers notifications et auth.

**Checkpoint**: DashboardHeader affiche les 3 elements, le menu avatar fonctionne avec navigation et logout.

---

## Phase 5: User Story 4 - Transactions enrichies (Priority: P2)

**Goal**: Enrichir la liste des 5 dernieres transactions avec badges devise et sous-texte de conversion quand la devise differe de la devise active.

**Independent Test**: Avoir des transactions dans differentes devises → les badges et conversions s'affichent correctement dans la section "Dernieres operations".

### Implementation for User Story 4

- [x] T009 [US4] Modifier RecentTransactionsSection dans `flutter/lib/src/features/dashboard/presentation/widgets/recent_transactions_section.dart` — ajouter au ListItem : badge devise (petit Container avec texte devise) si la devise du compte de la transaction differe de la devise active, sous-texte de conversion "~ X,XX [DEVISE]" via CurrencyConverter. Lire activeCurrency et exchangeRates depuis dashboardNotifierProvider. Ajouter le nom du compte dans le subtitle (date + " . " + account.nom), aligne sur Angular.

**Checkpoint**: Les transactions multi-devises affichent le badge et la conversion. Les transactions mono-devise sont inchangees.

---

## Phase 6: User Story 5 - Section Budgets alignee (Priority: P3)

**Goal**: Aligner la section budgets avec le wireframe : tri par % consommation decroissant (depasses en premier), max 4 items.

**Independent Test**: Avoir des budgets dont certains depasses → la section les affiche tries correctement, max 4 visibles.

### Implementation for User Story 5

- [x] T010 [US5] Modifier BudgetSummarySection dans `flutter/lib/src/features/dashboard/presentation/widgets/budget_summary_section.dart` — trier les budgets par pourcentage decroissant (depasses en premier), limiter a 4 items max. Ajouter le mois en cours dans le titre de section ("Budgets - [Mois]"). Verifier que la section est masquee si feature BUDGETS desactivee (comportement existant a confirmer).

**Checkpoint**: Les budgets sont tries par % decroissant, max 4 affiches, avec titre incluant le mois.

---

## Phase 7: User Story 6 - Restructuration DashboardScreen + Nettoyage (Priority: P3)

**Goal**: Restructurer le DashboardScreen pour utiliser les nouveaux widgets dans le bon ordre, supprimer les anciens widgets, passer a CustomScrollView.

**Independent Test**: Ouvrir le dashboard → les sections s'affichent dans l'ordre : header, currency pills, patrimoine, revenus/depenses, budgets (conditionnel), transactions recentes. Plus de MiniCards ni MonthSelector.

### Implementation for User Story 6

- [x] T011 [US6] Refactorer DashboardScreen dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — remplacer SingleChildScrollView par CustomScrollView + SliverList pour la performance. Nouveau layout : DashboardHeader, CurrencyPillSelector (conditionnel multi-devise), PatrimoineCard, IncomeExpenseCards, BudgetSummarySection (conditionnel feature BUDGETS), RecentTransactionsSection. Supprimer les references a HeroAccountSection, MonthlySummarySection, MiniCardsSection. Conserver RefreshIndicator + pull-to-refresh. Conserver l'etat vide (aucun compte).
- [x] T012 [US6] Supprimer les fichiers obsoletes : `flutter/lib/src/features/dashboard/presentation/widgets/hero_account_section.dart`, `flutter/lib/src/features/dashboard/presentation/widgets/monthly_summary_section.dart`, `flutter/lib/src/features/dashboard/presentation/widgets/mini_cards_section.dart`
- [x] T013 [US6] Verifier qu'aucun autre fichier n'importe les widgets supprimes (grep dans `flutter/lib/` et `flutter/test/`) et corriger si necessaire

**Checkpoint**: Le dashboard compile, s'affiche avec le nouveau layout, et les anciens widgets sont supprimes.

---

## Phase 8: Tests & Polish

**Purpose**: Tests unitaires et widget, code generation, validation finale.

### Tests

- [x] T014 [P] Creer/modifier les tests DashboardNotifier dans `flutter/test/src/features/dashboard/application/dashboard_notifier_test.dart` — tester : loadDashboard charge currentSummary et previousSummary, patrimoine total = somme des soldes convertis, variation % correcte (positif, negatif, zero, debut mois = 0), refresh recharge toutes les donnees, setActiveCurrencyAndCurrencies met a jour l'etat
- [x] T015 [P] Creer les tests widget PatrimoineCard dans `flutter/test/src/features/dashboard/presentation/widgets/patrimoine_card_test.dart` — tester : affiche "PATRIMOINE TOTAL", montant formate correctement, variation badge vert/rouge, conversion secondaire si multi-devise, icone warning si taux manquant, skeleton pendant chargement
- [x] T016 [P] Creer les tests widget IncomeExpenseCards dans `flutter/test/src/features/dashboard/presentation/widgets/income_expense_cards_test.dart` — tester : 2 cartes cote-a-cote, montants en devise principale, delta vs mois precedent correct, conversion secondaire si multi-devise
- [x] T017 [P] Creer les tests widget DashboardHeader dans `flutter/test/src/features/dashboard/presentation/widgets/dashboard_header_test.dart` — tester : salutation avec nom, cloche affichee, avatar avec initiale, tap avatar ouvre menu, menu contient Parametres et Deconnexion

### Polish

- [x] T018 Lancer `dart run build_runner build --delete-conflicting-outputs` depuis `flutter/` pour regenerer le code Freezed
- [x] T019 Lancer `flutter analyze` depuis `flutter/` et corriger les warnings
- [x] T020 Lancer `flutter test` depuis `flutter/` et verifier que tous les tests passent
- [x] T021 Valider le quickstart.md : ouvrir l'app, verifier les 5 points de verification rapide

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: BLOQUE toutes les user stories — DashboardState et DashboardNotifier doivent etre modifies en premier
- **US1 (Phase 2)**: Depend de Phase 1 — PatrimoineCard
- **US2 (Phase 3)**: Depend de Phase 1 — IncomeExpenseCards (peut etre en parallele avec US1)
- **US3 (Phase 4)**: Depend de Phase 1 — DashboardHeader (peut etre en parallele avec US1/US2)
- **US4 (Phase 5)**: Depend de Phase 1 — RecentTransactions enrichi (peut etre en parallele avec US1/US2/US3)
- **US5 (Phase 6)**: Depend de Phase 1 — BudgetSummarySection (peut etre en parallele avec US1-US4)
- **US6 (Phase 7)**: Depend de US1 + US2 + US3 + US4 + US5 — Integration dans DashboardScreen + suppression anciens widgets
- **Polish (Phase 8)**: Depend de US6 — Tests + validation finale

### User Story Dependencies

- **US1 (PatrimoineCard)**: Independant apres Phase 1
- **US2 (IncomeExpenseCards)**: Independant apres Phase 1
- **US3 (DashboardHeader)**: Independant apres Phase 1
- **US4 (RecentTransactions)**: Independant apres Phase 1
- **US5 (BudgetSummarySection)**: Independant apres Phase 1
- **US6 (DashboardScreen)**: Depend de US1-US5 (integration finale)

### Parallel Opportunities

- US1, US2, US3, US4, US5 peuvent tous etre implementes en parallele apres Phase 1
- T014, T015, T016, T017 (tests) peuvent etre ecrits en parallele

---

## Parallel Example: User Stories 1-5 apres Phase 1

```bash
# Tous ces widgets peuvent etre crees en parallele (fichiers differents) :
Task T004: "PatrimoineCard dans patrimoine_card.dart"
Task T006: "IncomeExpenseCards dans income_expense_cards.dart"
Task T008: "DashboardHeader dans dashboard_header.dart"
Task T009: "RecentTransactionsSection modifie dans recent_transactions_section.dart"
Task T010: "BudgetSummarySection modifie dans budget_summary_section.dart"
```

---

## Implementation Strategy

### MVP First (US1 + US2 + US6)

1. Complete Phase 1: Foundational (State + Notifier)
2. Complete Phase 2: US1 (PatrimoineCard)
3. Complete Phase 3: US2 (IncomeExpenseCards)
4. Complete Phase 7: US6 (DashboardScreen restructure)
5. **STOP and VALIDATE**: Le dashboard affiche patrimoine + revenus/depenses
6. Ajouter US3-US5 incrementalement

### Incremental Delivery

1. Phase 1 → State pret
2. US1 + US2 → Coeur financier du dashboard
3. US6 (partiel) → Screen restructure avec nouveaux widgets
4. US3 → Header enrichi
5. US4 → Transactions enrichies
6. US5 → Budgets alignes
7. US6 (complet) → Nettoyage final
8. Phase 8 → Tests + validation
