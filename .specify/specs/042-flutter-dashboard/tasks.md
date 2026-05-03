# Tasks: Flutter Dashboard Complet

**Input**: Design documents from `/specs/042-flutter-dashboard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Non demandes explicitement dans la spec — non inclus.

**Organization**: Taches groupees par user story pour implementation et test independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story associee (US1, US2, US3, US4, US5)
- Chemins exacts relatifs a `flutter/lib/src/`

## Path Conventions

- **Projet Flutter**: `flutter/lib/src/` (racine source)
- **Features**: `flutter/lib/src/features/dashboard/`
- **Data layer**: `flutter/lib/src/data/`, `flutter/lib/src/domain/`

---

## Phase 1: Setup

**Purpose**: Creation de la structure de dossiers pour la feature dashboard

- [x] T001 Creer les dossiers `features/dashboard/application/` et `features/dashboard/presentation/widgets/` dans `flutter/lib/src/`

---

## Phase 2: Foundational — Data Layer & Orchestration

**Purpose**: Modeles, couche data (DTO, data source, DAO, repositories, providers) et notifier central. DOIT etre complete avant toute user story.

**CRITICAL**: Aucune user story ne peut commencer avant la fin de cette phase.

### Modeles Freezed

- [x] T002 [P] Creer le domain model MonthlySummary (Freezed) dans `flutter/lib/src/domain/models/monthly_summary.dart` — champs: month, year, totalRecettes, totalDepenses, solde, currency (Currency enum)
- [x] T003 [P] Creer le state model DashboardState (Freezed) dans `flutter/lib/src/features/dashboard/application/dashboard_state.dart` — voir data-model.md pour les champs complets (accounts, defaultAccount, monthlySummaries, selectedMonth/Year, subscriptionMonthlyTotal, activeSubscriptionCount, debtNetBalance, activeDebtCount, recentTransactions, userName, isLoading, error)
- [x] T004 [P] Ajouter le DTO MonthlySummaryResponse (Freezed + fromJson) dans `flutter/lib/src/data/remote/dtos/transaction_dtos.dart` — champs: month, year, totalRecettes, totalDepenses, solde, currency (String)
- [x] T005 Executer `dart run build_runner build --delete-conflicting-outputs` dans `flutter/` pour generer le code Freezed (depend de T002-T004)

### Couche data — Repository interface + implementations

- [x] T006 [P] Ajouter la methode abstraite `Future<List<MonthlySummary>> getMonthlySummary(int month, int year)` dans `flutter/lib/src/domain/repositories/transaction_repository.dart`
- [x] T007 [P] Ajouter `getMonthlySummary(int month, int year)` dans `flutter/lib/src/data/remote/data_sources/transaction_remote_data_source.dart` — appel GET `/transactions/summary?month=X&year=Y`, parse List<MonthlySummaryResponse>
- [x] T008 [P] Ajouter `getMonthlySummary(int month, int year)` dans `flutter/lib/src/data/local/daos/transaction_dao.dart` — query Drift SUM(montant) GROUP BY type filtre par mois/annee
- [x] T009 [P] Implementer `getMonthlySummary()` dans `flutter/lib/src/features/transactions/data/transaction_repository_remote.dart` — mapper MonthlySummaryResponse vers MonthlySummary domain model (depend de T006, T007)
- [x] T010 [P] Implementer `getMonthlySummary()` dans `flutter/lib/src/features/transactions/data/transaction_repository_local.dart` — mapper resultat Drift vers MonthlySummary domain model (depend de T006, T008)

### Providers & Notifier

- [x] T011 Ajouter `monthlySummaryProvider` (FutureProvider.family) dans `flutter/lib/src/data/data_mode_provider.dart` — switch local/remote selon dataModeProvider, signature: `({int month, int year})` (depend de T009, T010)
- [x] T012a Modifier `AuthRepositoryImpl` dans `flutter/lib/src/features/auth/data/auth_repository_impl.dart` — ajouter la persistance du `name` dans FlutterSecureStorage (cle `user_name`) lors du `saveTokens()`. Mettre a jour la methode pour accepter le name optionnel. Egalement persister le name dans `login()` et `register()` apres appel reussi. Vider la cle au `logout()`.
- [x] T012b [P] Creer `currentUserNameProvider` (FutureProvider<String?>) dans `flutter/lib/src/features/dashboard/application/dashboard_notifier.dart` — lire la cle `user_name` depuis FlutterSecureStorage. Fallback null en mode local ou si cle absente → message generique "Bonjour" (voir research R-002 corrige). (depend de T012a)
- [x] T013 Creer `DashboardNotifier` (Notifier<DashboardState>) et `dashboardNotifierProvider` dans `flutter/lib/src/features/dashboard/application/dashboard_notifier.dart` — methodes: `loadDashboard()` (charge toutes les donnees via les notifiers existants + monthlySummaryProvider + currentUserNameProvider), `refresh()` (recharge tout), `changeMonth(int month, int year)` (recharge uniquement le summary). Calculs derives: subscriptionMonthlyTotal, debtNetBalance, activeDebtCount, defaultAccount (premier compte actif si aucun isDefault), recentTransactions (5 max tries par date desc, tous comptes, tous types inclus AJUSTEMENT). Voir data-model.md pour les formules de calcul (depend de T011, T012b)

**Checkpoint**: Couche data et notifier prets — les widgets de section peuvent etre implementes

---

## Phase 3: User Story 1 — Voir le solde de ses comptes d'un coup d'oeil (Priority: P1) MVP

**Goal**: Afficher le compte par defaut en hero (icone, nom, solde calcule) + liste des autres comptes actifs en lignes simples. Navigation vers detail au tap. Lien "Voir tout" si >= 5 comptes.

**Independent Test**: Verifier que le dashboard affiche le hero compte avec solde correct et la liste des autres comptes actifs.

### Implementation User Story 1

- [x] T014 [US1] Creer le widget `HeroAccountSection` (ConsumerWidget) dans `flutter/lib/src/features/dashboard/presentation/widgets/hero_account_section.dart` — affiche le compte par defaut en grand (icone, nom, solde = soldeInitial + somme transactions), liste les autres comptes actifs en lignes (icone, nom, montant avec devise propre), lien "Voir tout" si >= 5 comptes actifs, tap sur un compte → `context.push('/accounts/{id}')`. Utiliser `AmountFormatter.format()` pour les montants. Skeleton shimmer en etat loading. Comptes inactifs exclus. En cas d'erreur: afficher message inline avec bouton "Reessayer" qui relance le chargement des comptes.
- [x] T015 [US1] Refactorer `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — convertir en ConsumerWidget, ajouter `RefreshIndicator` global qui appelle `dashboardNotifier.refresh()`, ajouter le message de bienvenue personnalise (FR-015: "Bonjour {prenom}" ou generique si null), integrer `HeroAccountSection`, gerer l'etat vide global (aucun compte → incitation a creer), afficher skeleton/shimmer pendant le chargement (FR-013). Appeler `dashboardNotifier.loadDashboard()` au build initial.

**Checkpoint**: US1 fonctionnelle — le hero compte et la liste des comptes s'affichent avec soldes corrects

---

## Phase 4: User Story 2 — Consulter le resume financier du mois (Priority: P1)

**Goal**: Afficher le resume mensuel (recettes, depenses, barres proportionnelles, solde colore) avec selecteur de mois navigable.

**Independent Test**: Verifier que le resume affiche les totaux recettes/depenses du mois selectionne avec barres visuelles et solde colore (vert/rouge/neutre).

### Implementation User Story 2

- [x] T016 [US2] Creer le widget `MonthlySummarySection` (ConsumerWidget) dans `flutter/lib/src/features/dashboard/presentation/widgets/monthly_summary_section.dart` — integrer `MonthSelector` (onChanged → `dashboardNotifier.changeMonth(month, year)`), afficher total recettes et depenses avec barres de progression proportionnelles a max(recettes, depenses), solde du mois colore (vert si positif, rouge si negatif, couleur texte defaut si zero — FR-006), filtrer sur devise par defaut uniquement. Utiliser `AmountFormatter.format()` pour les montants. Skeleton shimmer en loading. Mois sans transaction → barres vides, solde 0. En cas d'erreur: afficher message inline avec bouton "Reessayer" qui relance `changeMonth()` sur le mois courant.
- [x] T017 [US2] Integrer `MonthlySummarySection` dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — ajouter apres la section hero dans le Column du body

**Checkpoint**: US1 + US2 fonctionnelles — hero comptes et resume mensuel avec navigation mois

---

## Phase 5: User Story 3 — Voir les dernieres operations (Priority: P2)

**Goal**: Afficher les 5 dernieres transactions avec categorie, libelle, montant, date relative. Lien "Voir tout" vers la page Transactions.

**Independent Test**: Verifier que les 5 dernieres transactions s'affichent avec les bonnes informations et que "Voir tout" navigue vers `/transactions`.

### Implementation User Story 3

- [x] T018 [US3] Creer le widget `RecentTransactionsSection` (ConsumerWidget) dans `flutter/lib/src/features/dashboard/presentation/widgets/recent_transactions_section.dart` — afficher les 5 dernieres transactions via `ListItem` widget existant (icon: emoji categorie, title: libelle, value: montant formate, subtitle: nom categorie, rightSubtitle: date relative via `RelativeDateFormatter.format()`). Header "Dernieres operations" + lien "Voir tout" → `context.go(RouteNames.transactions)`. Etat vide: "Aucune operation recente". Couleur montant via `AmountFormatter.amountColor()`. Skeleton via `ListItem.skeleton()`. En cas d'erreur: afficher message inline avec bouton "Reessayer" qui relance le chargement des transactions.
- [x] T019 [US3] Integrer `RecentTransactionsSection` dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — ajouter apres la section resume mensuel

**Checkpoint**: US1 + US2 + US3 fonctionnelles

---

## Phase 6: User Story 4 — Mini-cards modules (Priority: P2)

**Goal**: Afficher 2 mini-cards cote a cote (Abonnements, Dettes) avec chiffre cle, sous-texte et navigation au tap.

**Independent Test**: Verifier que les 2 cards s'affichent en row avec les donnees agregees correctes et naviguent vers les pages dediees.

### Implementation User Story 4

- [x] T020 [US4] Creer le widget `MiniCardsSection` (ConsumerWidget) dans `flutter/lib/src/features/dashboard/presentation/widgets/mini_cards_section.dart` — layout Row avec 2 cards Expanded: (1) Abonnements: icone, montant total normalise mensuel (annuel/12 + mensuel), sous-texte "{n} abonnements actifs", tap → `context.go(RouteNames.subscriptions)`. (2) Dettes: icone, solde net (prets - emprunts non rembourses), sous-texte "{n} dettes en cours", tap → `context.go(RouteNames.debts)`. Design tokens: `AppSpacing`, `AppRadius`, `AppColors`. Skeleton shimmer en loading. En cas d'erreur: afficher message inline avec bouton "Reessayer" qui relance le chargement des abonnements/dettes.
- [x] T021 [US4] Integrer `MiniCardsSection` dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — ajouter entre la section resume mensuel et les dernieres transactions

**Checkpoint**: US1 + US2 + US3 + US4 fonctionnelles — dashboard complet en contenu

---

## Phase 7: User Story 5 — Scroll fluide et contenu condense (Priority: P3)

**Goal**: Verifier et ajuster le layout pour que le dashboard tienne en ~1.5 ecrans de scroll vertical, sans scroll horizontal, avec un scroll fluide.

**Independent Test**: Verifier visuellement que le dashboard complet ne depasse pas ~1.5 ecrans et qu'aucun scroll horizontal n'est possible.

### Implementation User Story 5

- [x] T022 [US5] Revue et ajustement du layout final dans `flutter/lib/src/features/dashboard/presentation/dashboard_screen.dart` — verifier que le SingleChildScrollView est vertical uniquement (pas de scroll horizontal), ajuster les `AppSpacing` entre sections pour que le contenu total tienne en ~1.5 ecrans, verifier la fluidite du scroll (~60fps), s'assurer que le `RefreshIndicator` fonctionne correctement sur tout le contenu scrollable

**Checkpoint**: Dashboard complet et ergonomique

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validation finale, nettoyage

- [x] T023 Executer `dart run build_runner build --delete-conflicting-outputs` puis `flutter analyze` et `flutter build apk --debug` dans `flutter/` pour valider la compilation sans erreur

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dependance — demarre immediatement
- **Foundational (Phase 2)**: Depend de Phase 1 — BLOQUE toutes les user stories
- **US1 (Phase 3)**: Depend de Phase 2 complete
- **US2 (Phase 4)**: Depend de Phase 2 complete (independant de US1 pour le widget, mais s'integre apres US1 dans le screen)
- **US3 (Phase 5)**: Depend de Phase 2 complete
- **US4 (Phase 6)**: Depend de Phase 2 complete
- **US5 (Phase 7)**: Depend de Phase 3-6 (toutes les sections doivent exister)
- **Polish (Phase 8)**: Depend de toutes les phases precedentes

### User Story Dependencies

- **US1 (P1)**: Peut demarrer des que Phase 2 est complete — Pas de dependance sur d'autres stories
- **US2 (P1)**: Peut demarrer des que Phase 2 est complete — Le widget est independant, l'integration screen depend de US1 (T015)
- **US3 (P2)**: Peut demarrer des que Phase 2 est complete — Le widget est independant, l'integration screen depend de US2 (T017)
- **US4 (P2)**: Peut demarrer des que Phase 2 est complete — Le widget est independant, l'integration screen depend de US2 (T017)
- **US5 (P3)**: Depend de US1-US4 toutes completes (layout final)

### Within Phase 2 (Foundational)

```
T001 (setup) → T002, T003, T004 (parallel: modeles Freezed)
            → T005 (build_runner)
            → T006, T007, T008, T012a (parallel: interface, data sources, auth storage)
            → T009, T010, T012b (parallel: repo implementations, user name provider)
            → T011 (provider)
            → T013 (DashboardNotifier)
```

### Parallel Opportunities

**Phase 2 — Batch 1**: T002, T003, T004 (3 fichiers Freezed differents)
**Phase 2 — Batch 2**: T006, T007, T008, T012a (4 fichiers differents)
**Phase 2 — Batch 3**: T009, T010, T012b (3 fichiers differents)
**Phase 3-6 — Widgets**: T014, T016, T018, T020 peuvent etre crees en parallele (4 fichiers widget differents) si Phase 2 est complete. Les integrations screen (T015, T017, T019, T021) doivent etre sequentielles (meme fichier).

---

## Parallel Example: Phase 2 Foundational

```bash
# Batch 1 — Modeles Freezed (parallel):
T002: "MonthlySummary domain model dans domain/models/monthly_summary.dart"
T003: "DashboardState dans features/dashboard/application/dashboard_state.dart"
T004: "MonthlySummaryResponse DTO dans data/remote/dtos/transaction_dtos.dart"

# Sequentiel:
T005: "build_runner code generation"

# Batch 2 — Data layer + auth (parallel):
T006: "Interface TransactionRepository"
T007: "TransactionRemoteDataSource.getMonthlySummary()"
T008: "TransactionDao.getMonthlySummary()"
T012a: "Persister user_name dans AuthRepositoryImpl"

# Batch 3 — Repo impls + user name provider (parallel):
T009: "TransactionRepositoryRemote"
T010: "TransactionRepositoryLocal"
T012b: "currentUserNameProvider (FlutterSecureStorage)"

# Sequentiel:
T011: "monthlySummaryProvider"
T013: "DashboardNotifier"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — bloque toutes les stories)
3. Complete Phase 3: User Story 1 (Hero compte + welcome + skeleton + pull-to-refresh)
4. **STOP et VALIDER**: Tester US1 independamment — le dashboard affiche le hero compte avec solde correct
5. Livrable MVP minimal

### Incremental Delivery

1. Setup + Foundational → Data layer et notifier prets
2. US1 (Hero comptes) → Test → MVP livrable
3. US2 (Resume mensuel) → Test → Dashboard avec comptes + resume
4. US3 (Dernieres operations) → Test → + transactions recentes
5. US4 (Mini-cards) → Test → + raccourcis modules
6. US5 (Polish layout) → Test → Dashboard final compact
7. Polish → Build validation

### Suggested MVP Scope

**US1 uniquement** (Phase 1 + 2 + 3): Le dashboard affiche le hero compte avec solde, la liste des autres comptes, le message de bienvenue, le skeleton loading et le pull-to-refresh. C'est l'information la plus consultee au quotidien.

---

## Notes

- [P] tasks = fichiers differents, pas de dependances mutuelles
- [Story] label mappe la tache a une user story specifique
- Chaque user story est testable independamment a son checkpoint
- Commiter apres chaque tache ou groupe logique
- Formules de calcul (montant mensuel abonnements, solde net dettes, ratio barres) dans data-model.md
- Utilitaires existants: `AmountFormatter`, `RelativeDateFormatter`, `ListItem`, `MonthSelector`
- Design tokens: `AppSpacing`, `AppColors`, `AppTypography`, `AppRadius`, `AppThemeExtension`
