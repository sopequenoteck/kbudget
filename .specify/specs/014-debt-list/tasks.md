# Tasks: Ecran Debts (liste + filtres)

**Input**: Design documents from `/specs/014-debt-list/`
**Prerequisites**: plan.md (required), spec.md (required), research.md

**Tests**: Non demandes dans la spec. Aucune tache de test generee.

**Organization**: Tasks groupees par user story. Toutes les taches modifient les memes 3 fichiers (`debts.ts`, `debts.html`, `debts.scss`), donc les stories sont implementees sequentiellement comme increments progressifs.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story associee (US1, US2, US3, US4, US5)
- Chemins exacts dans les descriptions

## Path Conventions

- **Frontend**: `app/src/app/` (monorepo, module Angular)
- **Composant cible**: `app/src/app/features/debts/`

---

## Phase 1: Setup

**Purpose**: Preparation des imports et structure de base du composant

- [x] T001 Ajouter les imports necessaires (signals, inject, isDevMode, firstValueFrom, NgClass) et injecter DebtService dans `app/src/app/features/debts/debts.ts`
- [x] T002 Importer les composants et pipes dans le decorator @Component imports : ListItem, AmountPipe, RelativeDatePipe, NgClass dans `app/src/app/features/debts/debts.ts`

**Checkpoint**: Le composant compile sans erreur avec tous les imports necessaires

---

## Phase 2: User Story 1 + 5 - Liste des dettes + Etats (Priority: P1)

**Goal**: Afficher la liste de toutes les dettes avec differenciation visuelle par sens, plus gestion des etats loading/error/empty

**Independent Test**: Naviguer vers l'ecran des dettes et verifier que les dettes s'affichent avec les bonnes couleurs et icones. Verifier le spinner au chargement, le message d'erreur avec retry en cas d'echec, et "Aucune dette" si la liste est vide.

### Implementation

- [x] T003 [US1] Declarer les signals de base dans `app/src/app/features/debts/debts.ts` : `loading: signal<boolean>(true)`, `error: signal<boolean>(false)`, `debts: signal<Debt[]>([])`, et le type alias `StatusFilter = 'ALL' | 'EN_COURS' | 'REMBOURSE'` et `SensFilter = 'ALL' | 'JE_DOIS' | 'ON_ME_DOIT'` avec `statusFilter: signal<StatusFilter>('ALL')`
- [x] T004 [US1] Implementer la methode `async loadData()` dans `app/src/app/features/debts/debts.ts` : appel `firstValueFrom(this.debtService.getAll(rembourse))` avec gestion loading/error, pattern identique a `Subscriptions.loadData()`
- [x] T005 [US1] Ajouter le `constructor()` avec `effect()` qui ecoute `this.debtService.refreshTrigger()` et `this.statusFilter()` puis appelle `this.loadData()` dans `app/src/app/features/debts/debts.ts`
- [x] T006 [US1] Implementer les methodes helper dans `app/src/app/features/debts/debts.ts` : `getIcon(debt: Debt): string` (retourne emoji selon sens — FR-012 : `💸` pour JE_DOIS, `💰` pour ON_ME_DOIT), `getValueClass(debt: Debt): string` (retourne classe CSS selon sens — FR-002)
- [x] T007 [US1] Ecrire le template HTML dans `app/src/app/features/debts/debts.html` : section etats (loading spinner, error avec bouton retry, empty "Aucune dette") et liste `<ul>` avec `@for` sur `debts()` utilisant `app-list-item` avec les pipes AmountPipe et RelativeDatePipe
- [x] T008 [US1] Ecrire les styles de base dans `app/src/app/features/debts/debts.scss` : `:host` layout (flex column, gap, padding), `.debt-list` (list-style none), `.state-loading/.state-empty/.state-error` (centrage, padding), `.spinner` (animation), `.debt-owe` et `.debt-owed` (couleurs via tokens CSS)

**Checkpoint**: L'ecran affiche la liste des dettes avec couleurs, icones, etats loading/error/empty fonctionnels

---

## Phase 3: User Story 2 - Filtre par statut (Priority: P2)

**Goal**: Permettre de filtrer les dettes par statut de remboursement (tous / en cours / rembourse) via appel API

**Independent Test**: Cliquer sur chaque bouton de filtre statut et verifier que seules les dettes correspondantes sont affichees. Verifier que le filtre "En cours" sur une liste 100% remboursee affiche "Aucune dette".

### Implementation

- [x] T009 [US2] Ajouter la methode `setStatusFilter(filter: StatusFilter)` dans `app/src/app/features/debts/debts.ts` qui met a jour le signal `statusFilter` (le effect existant declenchera le rechargement)
- [x] T010 [US2] Ajouter la section filtre statut dans `app/src/app/features/debts/debts.html` : 3 boutons toggle ("Tous" / "En cours" / "Rembourse") avec `[class.active]` et `(click)="setStatusFilter(...)"`, role="group" et aria-label
- [x] T011 [US2] Ajouter les styles `.status-filter` dans `app/src/app/features/debts/debts.scss` : flex row, boutons avec border, active state via `--color-primary`, meme pattern que `.type-filter` de Transactions

**Checkpoint**: Les 3 boutons de filtre statut fonctionnent et declenchent le rechargement via API

---

## Phase 4: User Story 3 - Filtre par sens (Priority: P2)

**Goal**: Permettre de filtrer les dettes par sens (tous / je dois / on me doit) cote client sans nouvel appel API

**Independent Test**: Cliquer sur chaque bouton de filtre sens et verifier que seules les dettes du sens choisi sont affichees. Combiner avec le filtre statut pour verifier le fonctionnement croise.

### Implementation

- [x] T012 [US3] Ajouter le signal `sensFilter: signal<SensFilter>('ALL')` et le `computed() filteredDebts` dans `app/src/app/features/debts/debts.ts` : filtre par sens cote client + tri par date descendante. Ajouter la methode `setSensFilter(filter: SensFilter)`
- [x] T013 [US3] Mettre a jour le template dans `app/src/app/features/debts/debts.html` : ajouter la section filtre sens (3 boutons toggle "Tous" / "Je dois" / "On me doit") et remplacer `debts()` par `filteredDebts()` dans le `@for` et la condition empty
- [x] T014 [US3] Ajouter les styles `.sens-filter` dans `app/src/app/features/debts/debts.scss` : meme pattern que `.status-filter`

**Checkpoint**: Les deux filtres (statut + sens) fonctionnent en combinaison

---

## Phase 5: User Story 4 - Resume financier (Priority: P3)

**Goal**: Afficher un resume avec total "je dois" (rouge), total "on me doit" (vert) et solde net

**Independent Test**: Verifier que les totaux correspondent a la somme des montants des dettes visibles. Verifier les couleurs du solde net (vert si positif, rouge si negatif). Verifier que le resume disparait quand il n'y a aucune dette.

### Implementation

- [x] T015 [US4] Ajouter les computed de resume dans `app/src/app/features/debts/debts.ts` : `totalJeDois` (somme JE_DOIS des filteredDebts), `totalOnMeDoit` (somme ON_ME_DOIT des filteredDebts), `netBalance` (totalOnMeDoit - totalJeDois), `hasDebts` (debts().length > 0)
- [x] T016 [US4] Ajouter la section resume dans `app/src/app/features/debts/debts.html` : 3 cartes conditionnelles (`@if (hasDebts())`) avec total je dois (classe debt-owe), total on me doit (classe debt-owed), solde net (classe dynamique via NgClass selon positif/negatif). Utiliser AmountPipe pour le formatage.
- [x] T017 [US4] Ajouter les styles `.summary` dans `app/src/app/features/debts/debts.scss` : flex row, 3 cartes avec background raised, labels en text-secondary, valeurs en semibold avec couleurs semantiques. Meme pattern que `.summary` de Transactions.

**Checkpoint**: Le resume affiche les 3 totaux avec les bonnes couleurs et disparait quand la liste est vide

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verification finale et ajustements

- [x] T018 Verifier le lint Angular (`cd app && npx ng lint`) et corriger les eventuelles erreurs dans `app/src/app/features/debts/debts.ts`
- [x] T019 Verifier le formatage Prettier (`cd app && npm run format:check`) et formater si necessaire les fichiers modifies
- [x] T020 Tester manuellement les edge cases : nom de personne tres long (troncature), montant 0 (pas de signe), combinaison des deux filtres, resume apres filtrage par sens

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Pas de dependance — imports et injection
- **US1+US5 (Phase 2)**: Depend de Phase 1 — liste de base + etats
- **US2 (Phase 3)**: Depend de Phase 2 — filtre statut sur la liste existante
- **US3 (Phase 4)**: Depend de Phase 3 — filtre sens ajoute le `filteredDebts` computed
- **US4 (Phase 5)**: Depend de Phase 4 — resume calcule a partir de `filteredDebts`
- **Polish (Phase 6)**: Depend de toutes les phases precedentes

### User Story Dependencies

- **US1 + US5 (P1)**: Aucune dependance inter-story. Fondation de l'ecran.
- **US2 (P2)**: Depend de US1 (la liste doit exister pour etre filtree)
- **US3 (P2)**: Depend de US2 (le signal statusFilter doit exister, le `filteredDebts` computed remplace `debts()` dans le template)
- **US4 (P3)**: Depend de US3 (le computed `filteredDebts` doit exister pour calculer les totaux)

### Within Each User Story

- TypeScript (`.ts`) avant template (`.html`) avant styles (`.scss`)
- Chaque increment ajoute du code aux 3 memes fichiers sans casser le precedent

### Parallel Opportunities

- **Limitees** : toutes les taches modifient les 3 memes fichiers, donc l'execution est sequentielle par design
- Les taches T001 et T002 (setup imports) peuvent etre faites en une seule passe

---

## Implementation Strategy

### MVP First (User Stories 1 + 5)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: US1+US5 (T003-T008)
3. **STOP and VALIDATE**: L'ecran affiche les dettes avec couleurs et gere les 3 etats
4. Deployable comme MVP

### Incremental Delivery

1. Setup + US1+US5 → Liste fonctionnelle avec etats (MVP)
2. + US2 → Filtre par statut via API
3. + US3 → Filtre par sens cote client + combinaison des filtres
4. + US4 → Resume financier avec totaux et solde net
5. + Polish → Lint, format, edge cases valides

---

## Notes

- Toutes les taches modifient les 3 memes fichiers : `debts.ts`, `debts.html`, `debts.scss`
- Pattern de reference : `Subscriptions` (KKS-55) pour la structure du composant
- US1 et US5 sont fusionnees car les etats (loading/error/empty) sont indissociables de la liste
- Pas de tests unitaires demandes dans la spec
- Commit recommande apres chaque phase completee
