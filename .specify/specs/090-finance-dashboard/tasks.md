# Tasks: Dashboard Finance (Angular)

**Input**: Design documents from `/specs/090-finance-dashboard/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: Non demandes explicitement dans la spec. Pas de taches de tests generees.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Nettoyage du dashboard existant)

**Purpose**: Retirer les sections obsoletes du dashboard existant et preparer la structure pour les nouveaux composants

- [x] T001 Nettoyer dashboard.ts — retirer les injections SubscriptionService, DebtService, ModalService et tous les signals associes (subscriptions, debts, accounts list, accountTotalsByCurrency) dans `app/src/app/features/dashboard/dashboard.ts`
- [x] T002 [P] Nettoyer dashboard.html — retirer les sections cartes de comptes individuels, mini-cartes abos/dettes, section abonnements actifs, section dettes actives, selecteur de mois dans `app/src/app/features/dashboard/dashboard.html`
- [x] T003 [P] Nettoyer dashboard.scss — retirer les styles lies aux sections supprimees dans `app/src/app/features/dashboard/dashboard.scss`

**Checkpoint**: Le dashboard compile et s'affiche avec uniquement les sections conservees (transactions recentes, budgets, currency pill). Pas de regression.

---

## Phase 2: Foundational (Signals derives et chargement des donnees)

**Purpose**: Mettre en place la logique de chargement des donnees et les computed signals qui alimenteront tous les sous-composants

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Ajouter les signals currentSummary, previousSummary, summaryLoading, summaryError, budgetOverview, budgetLoading dans `app/src/app/features/dashboard/dashboard.ts`
- [x] T005 Implementer loadSummaries() — appel parallele getSummary() pour le mois courant ET le mois precedent dans `app/src/app/features/dashboard/dashboard.ts`
- [x] T006 Implementer les computed signals derives : netDuMois, patrimoineDebutMois, variationPatrimoinePct, variationRevenus, variationDepenses, previousMonthName, sortedBudgetItems, recentTransactions dans `app/src/app/features/dashboard/dashboard.ts`
- [x] T007 Refactorer loadAll() pour charger en parallele : total-balance, summaries (mois courant + mois-1), budget overview, transactions, exchange-rates dans `app/src/app/features/dashboard/dashboard.ts`

**Checkpoint**: Les signals derives calculent les bonnes valeurs. loadAll() charge toutes les donnees necessaires en parallele. Le dashboard compile.

---

## Phase 3: User Story 1 - Patrimoine total (Priority: P1) MVP

**Goal**: L'utilisateur voit son patrimoine total avec variation nette du mois (montant + %) et contre-valeur dans la devise selectionnee

**Independent Test**: Acceder au dashboard avec un compte ayant des transactions. Le patrimoine total s'affiche avec variation et contre-valeur.

### Implementation for User Story 1

- [x] T008 [P] [US1] Creer le composant PatrimoineCard (standalone, OnPush) avec inputs totalBalance, netDuMois, variationPct, currency, convertedTotal, convertedCurrency, isLoading, hasError et output retry dans `app/src/app/features/dashboard/components/patrimoine-card/patrimoine-card.ts`
- [x] T009 [P] [US1] Creer les styles de PatrimoineCard — montant principal (font-size-3xl, rouge si negatif via --color-expense), ligne variation (vert si positif via --color-income, rouge si negatif via --color-expense, neutre si 0% via --text-tertiary), contre-valeur (text-secondary), skeleton loading, etat erreur dans `app/src/app/features/dashboard/components/patrimoine-card/patrimoine-card.scss`
- [x] T010 [US1] Integrer PatrimoineCard dans le template du dashboard — passer les signals convertedTotalBalance, netDuMois, variationPatrimoinePct, activeCurrency, convertedTotal via ConversionService dans `app/src/app/features/dashboard/dashboard.html`
- [x] T011 [US1] Gerer l'etat vide patrimoine — si aucun compte, afficher 0 avec message d'incitation a creer un compte dans le template PatrimoineCard dans `app/src/app/features/dashboard/components/patrimoine-card/patrimoine-card.ts`

**Checkpoint**: Le patrimoine total s'affiche avec variation "+1 276 EUR ce mois (+104,2%)" en vert, contre-valeur "≈ 1 639 892 FCFA". Etats loading/erreur/vide fonctionnels.

---

## Phase 4: User Story 2 - Bilan mensuel revenus/depenses (Priority: P1)

**Goal**: Deux cartes cote a cote montrent revenus et depenses du mois avec variation vs mois precedent et contre-valeurs

**Independent Test**: Avec des transactions sur 2 mois, les cartes affichent les montants et "+200 vs fev." correctement.

### Implementation for User Story 2

- [x] T012 [P] [US2] Creer le composant SummaryCards (standalone, OnPush) avec inputs totalRecettes, totalDepenses, variationRevenus, variationDepenses, previousMonthName, currency, convertedRecettes, convertedDepenses, convertedCurrency, isLoading dans `app/src/app/features/dashboard/components/summary-cards/summary-cards.ts`
- [x] T013 [P] [US2] Creer les styles de SummaryCards — 2 cartes flexbox (gap space-3, flex 1), pastille coloree, montant AmountPipe, variation avec fleche, contre-valeur dans `app/src/app/features/dashboard/components/summary-cards/summary-cards.scss`
- [x] T014 [US2] Integrer SummaryCards dans le template du dashboard — passer currentSummary, variationRevenus, variationDepenses, previousMonthName, contre-valeurs via ConversionService dans `app/src/app/features/dashboard/dashboard.html`
- [x] T015 [US2] Gerer l'etat vide revenus/depenses — si aucune transaction ce mois, afficher 0 dans les deux cartes dans `app/src/app/features/dashboard/components/summary-cards/summary-cards.ts`

**Checkpoint**: Les cartes revenus/depenses s'affichent cote a cote avec "+200 vs fev." et contre-valeurs. Etat vide affiche 0.

---

## Phase 5: User Story 3 - Budgets du mois (Priority: P2)

**Goal**: Resume des 4 budgets les plus urgents avec barres de progression et indicateurs de depassement

**Independent Test**: Avec des budgets actifs, la section affiche le total et les 4 plus urgents. Un budget depasse montre un indicateur visuel.

### Implementation for User Story 3

- [x] T016 [US3] Modifier BudgetSummary — ajouter input maxItems (default 4), recevoir les items tries par urgence du parent, ajouter en-tete avec total global "MENSUEL · EN EUR 1 736 / 2 030" dans `app/src/app/features/dashboard/components/budget-summary/budget-summary.ts`
- [x] T017 [US3] Modifier les styles BudgetSummary — barre de progression coloree (primary < 80%, warning 80-100%, expense > 100%), indicateur depassement, lien "Voir tout" vers /budgets dans `app/src/app/features/dashboard/components/budget-summary/budget-summary.scss`
- [x] T018 [US3] Integrer BudgetSummary modifie dans le dashboard — passer sortedBudgetItems (computed, 4 max tries par urgence), conditionner sur isEnabled('BUDGETS'), gerer l'etat vide dans `app/src/app/features/dashboard/dashboard.html`

**Checkpoint**: La section budgets affiche max 4 items tries par urgence (depasses en premier), barres colorees, lien "Voir tout". Masquee si feature BUDGETS desactivee.

---

## Phase 6: User Story 4 - Transactions recentes (Priority: P2)

**Goal**: Les 5 dernieres transactions s'affichent avec contre-valeurs multi-devises

**Independent Test**: Avec des transactions en differentes devises, les 5 dernieres s'affichent avec contre-valeurs.

### Implementation for User Story 4

- [x] T019 [US4] Restructurer la section transactions recentes dans le template — utiliser recentTransactions (computed, 5 max), afficher via app-list-item avec icone categorie, libelle, montant signe, date dans `app/src/app/features/dashboard/dashboard.html`
- [x] T020 [US4] Ajouter les contre-valeurs sur les transactions — pour chaque transaction dont la devise differe de activeCurrency, calculer la contre-valeur via ConversionService.convert() et l'afficher dans valueSubtitle de app-list-item dans `app/src/app/features/dashboard/dashboard.html`
- [x] T021 [US4] Ajouter le lien "Voir tout" transactions redirigant vers /transactions et gerer l'etat vide (message "Aucune transaction") dans `app/src/app/features/dashboard/dashboard.html`

**Checkpoint**: Les 5 dernieres transactions s'affichent avec contre-valeurs. Lien "Voir tout" fonctionne. Etat vide gere.

---

## Phase 7: User Story 5 - Selecteur de devise (Priority: P3)

**Goal**: Le changement de devise met a jour toutes les contre-valeurs instantanement

**Independent Test**: Changer la devise dans le selecteur met a jour les contre-valeurs patrimoine, revenus/depenses et transactions.

### Implementation for User Story 5

- [x] T022 [US5] Verifier que le CurrencyPillSelector existant fonctionne avec le nouveau layout — repositionner apres l'en-tete, conditionner l'affichage si > 1 devise dans `app/src/app/features/dashboard/dashboard.html`
- [x] T023 [US5] S'assurer que le changement de activeCurrency() met a jour toutes les contre-valeurs (patrimoine, revenus/depenses, transactions) via les computed signals et ConversionService dans `app/src/app/features/dashboard/dashboard.ts`
- [x] T024 [US5] Gerer le cas ou une devise selectionnee n'a pas de taux de change — ne pas afficher la contre-valeur (pas de "N/A", pas de 0) dans `app/src/app/features/dashboard/dashboard.html`

**Checkpoint**: Le selecteur de devise fonctionne. Toutes les contre-valeurs se mettent a jour instantanement. Devise sans taux = pas de contre-valeur affichee.

---

## Phase 8: User Story 6 - En-tete personnalise (Priority: P3)

**Goal**: Le header affiche "Bonjour [userName]" sur le dashboard avec acces notifications et profil

**Independent Test**: Se connecter avec un utilisateur ayant un nom. L'en-tete affiche "Bonjour Kelly SOSSOE".

### Implementation for User Story 6

- [x] T025 [US6] Ajouter la salutation personnalisee dans le header du shell — conditionner sur la route /dashboard, afficher "Bonjour [name]" via userService.profile()?.name, "Bonjour" seul si name vide dans `app/src/app/shared/components/shell/shell.html`
- [x] T026 [US6] Ajouter les styles de la salutation — font-size-lg, font-weight-semibold, positionnement a cote du logo dans `app/src/app/shared/components/shell/shell.scss`

**Checkpoint**: Le header affiche "Bonjour Kelly SOSSOE" sur le dashboard. Notifications et profil accessibles. "Bonjour" seul si pas de nom.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Auto-refresh, responsive, etats globaux

- [x] T027 Implementer l'auto-refresh 60s — setInterval dans ngOnInit, clearInterval dans ngOnDestroy, silentRefresh() sans flag loading, silent fail en cas d'erreur dans `app/src/app/features/dashboard/dashboard.ts`
- [x] T028 Implementer le refresh au retour sur le dashboard — effect() reagissant au refreshTrigger de AccountService pour recharger les donnees dans `app/src/app/features/dashboard/dashboard.ts`
- [x] T029 Verifier le responsive — layout mobile-first coherent, cartes revenus/depenses empilees en mobile tres petit (< 360px), barres de progression lisibles sur mobile dans `app/src/app/features/dashboard/dashboard.scss`
- [x] T030 Verifier les etats de chargement globaux — skeleton shimmer sur patrimoine, summary cards et budgets pendant le chargement initial dans `app/src/app/features/dashboard/dashboard.html`
- [x] T031 Verifier l'etat d'erreur global — si le serveur est injoignable, afficher un etat d'erreur avec bouton "Reessayer" couvrant tout le dashboard dans `app/src/app/features/dashboard/dashboard.html`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - US1 et US2 sont P1 — a implementer en priorite, peuvent etre en parallele
  - US3 et US4 sont P2 — dependent de la fondation, independants entre eux
  - US5 et US6 sont P3 — polish, independants entre eux
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 - No dependencies on other stories
- **US2 (P1)**: Can start after Phase 2 - No dependencies on other stories (parallele avec US1)
- **US3 (P2)**: Can start after Phase 2 - No dependencies on other stories
- **US4 (P2)**: Can start after Phase 2 - No dependencies on other stories (parallele avec US3)
- **US5 (P3)**: Can start after Phase 2 - Integrates with US1/US2/US4 but testable independently
- **US6 (P3)**: Can start after Phase 2 - Fully independent (modifie le shell, pas le dashboard)

### Within Each User Story

- Composant (TS + SCSS) avant integration dans le template parent
- Integration avant gestion des etats vides/erreurs

### Parallel Opportunities

- T002 et T003 (Phase 1) : Paralleles (fichiers distincts .html et .scss), mais apres T001 (.ts — retire les references)
- T008 et T009 (US1) : Paralleles (TS et SCSS distincts)
- T012 et T013 (US2) : Paralleles (TS et SCSS distincts)
- US1 et US2 : Paralleles entre eux (composants differents)
- US3 et US4 : Paralleles entre eux (composants differents)
- US5 et US6 : Paralleles entre eux (dashboard vs shell)

---

## Parallel Example: User Story 1

```bash
# Launch TS and SCSS in parallel (different files):
Task: "T008 Creer PatrimoineCard composant dans patrimoine-card.ts"
Task: "T009 Creer styles PatrimoineCard dans patrimoine-card.scss"

# Then sequentially:
Task: "T010 Integrer PatrimoineCard dans dashboard.html"
Task: "T011 Gerer etat vide patrimoine"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Nettoyage (T001-T003)
2. Complete Phase 2: Fondation (T004-T007)
3. Complete Phase 3: Patrimoine total (T008-T011) — US1
4. Complete Phase 4: Revenus/depenses (T012-T015) — US2
5. **STOP and VALIDATE**: Le dashboard affiche patrimoine + revenus/depenses avec variations et contre-valeurs

### Incremental Delivery

1. Setup + Foundational → Dashboard nettoye avec donnees chargees
2. Add US1 → Patrimoine total visible (MVP!)
3. Add US2 → Revenus/depenses avec variations
4. Add US3 → Budgets 4 max par urgence
5. Add US4 → Transactions recentes avec contre-valeurs
6. Add US5 → Selecteur devise fonctionnel
7. Add US6 → Salutation personnalisee
8. Polish → Auto-refresh, responsive, etats globaux

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Pas de nouveau service Angular — tout dans les computed signals du composant
- Pas de nouvel endpoint backend — consomme les endpoints existants
- Commit apres chaque phase ou checkpoint valide
