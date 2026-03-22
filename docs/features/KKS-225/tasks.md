# Tasks: KKS-225 — Alignement design pages Transactions, Abonnements et Dettes

**Input**: `docs/features/KKS-225/`
**Prerequisites**: plan.md, spec.md, contracts.md
**Design reference**: `app/DESIGN.md`

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre executee en parallele (fichiers differents)
- **[Story]**: User Story concernee (US1, US2, US3, US4)

---

## Phase 1: Setup

**Purpose**: Creer la branche feature

- [x] T-001 Creer la branche `sopequenotech/kks-225-alignement-design-des-pages-transactions-abonnements-et` depuis `develop`

**Checkpoint**: Branche prete

---

## Phase 2: User Story 1 — Typographie + press feedback summary cards (Priority: P1)

**Goal**: Montants en `font-size-xl`, labels en `font-weight-semibold`, press feedback `scale(0.97)` sur les 3 pages

**Independent Test**: Ouvrir chaque page, verifier typo et press feedback au toucher

- [x] T-020 [P] [US1] Transactions SCSS : changer `.summary__value` `font-size-lg` → `font-size-xl`, `.summary__label` `font-weight-medium` → `font-weight-semibold`, ajouter press feedback `scale(0.97)` sur `.summary__card` dans `app/src/app/features/transactions/transactions.scss` — Ref: FR-001, FR-002, FR-003
- [x] T-021 [P] [US1] Abonnements SCSS : changer `.summary__value` `font-size-2xl` → `font-size-xl`, `.summary__label` `font-weight-medium` → `font-weight-semibold`, ajouter press feedback `scale(0.97)` sur `.summary__card`, ajouter `white-space: nowrap` sur `.summary__value` dans `app/src/app/features/subscriptions/subscriptions.scss` — Ref: FR-001, FR-002, FR-003
- [x] T-022 [P] [US1] Dettes SCSS : changer `.summary__value` `font-size-lg` → `font-size-xl`, `.summary__label` `font-weight-medium` → `font-weight-semibold`, ajouter press feedback `scale(0.97)` sur `.summary__card` dans `app/src/app/features/debts/debts.scss` — Ref: FR-001, FR-002, FR-003

**Checkpoint**: Les 3 pages ont la meme typo et le meme feedback tactile que le dashboard

---

## Phase 3: User Story 2 — Dots colores (Priority: P1)

**Goal**: Dots 8px colores sur Transactions (3 cards) et Dettes (3 cards), absents sur Abonnements

**Independent Test**: Verifier visuellement la presence des dots sur Transactions et Dettes, absence sur Abonnements

- [x] T-030 [P] [US2] Transactions HTML : ajouter `<span class="summary__dot summary__dot--income">` dans la card Recettes, `--expense` dans Depenses, et un dot conditionnel (income/expense/neutral selon signe) dans Solde dans `app/src/app/features/transactions/transactions.html` — Ref: FR-004
- [x] T-031 [P] [US2] Transactions SCSS : ajouter les styles `.summary__dot` (8px, border-radius 50%) avec modifiers `--income`, `--expense`, `--neutral` dans `app/src/app/features/transactions/transactions.scss` — Ref: FR-004
- [x] T-032 [P] [US2] Dettes HTML : ajouter `<span class="summary__dot summary__dot--owe">` dans la card Emprunts, `--owed` dans Prets, et un dot conditionnel (owe/owed/neutral selon signe) dans Solde net dans `app/src/app/features/debts/debts.html` — Ref: FR-005
- [x] T-033 [P] [US2] Dettes SCSS : ajouter les styles `.summary__dot` (8px, border-radius 50%) avec modifiers `--owe`, `--owed`, `--neutral` dans `app/src/app/features/debts/debts.scss` — Ref: FR-005

**Checkpoint**: Dots visibles sur Transactions et Dettes, absents sur Abonnements (FR-006 verifie)

---

## Phase 4: User Story 3 — Radial gradient fond de page (Priority: P1)

**Goal**: Gradient radial amber en haut des 3 pages, fixe au scroll

**Independent Test**: Verifier visuellement le gradient en light et dark mode sur les 3 pages

- [x] T-040 [P] [US3] Transactions SCSS : ajouter `::before` radial gradient sur `:host` dans `app/src/app/features/transactions/transactions.scss` — Ref: FR-007
- [x] T-041 [P] [US3] Abonnements SCSS : ajouter `::before` radial gradient sur `:host` dans `app/src/app/features/subscriptions/subscriptions.scss` — Ref: FR-007
- [x] T-042 [P] [US3] Dettes SCSS : ajouter `::before` radial gradient sur `:host` dans `app/src/app/features/debts/debts.scss` — Ref: FR-007

**Checkpoint**: Gradient visible sur les 3 pages en light et dark mode

---

## Phase 5: User Story 4 — Non-regression + polish (Priority: P2)

**Goal**: Listes inchangees, coherence globale

- [x] T-050 [US4] Verification visuelle non-regression : comparer les listes de chaque page avant/apres (bloc + dividers intact) — Ref: FR-008
- [x] T-051 Verification light/dark mode sur les 3 pages : dots, gradient, typo — Ref: NFR-004
- [x] T-052 Mettre a jour `app/DESIGN.md` section "Cards (Summary) — pages interieures" : montants `font-size-xl` (au lieu de `font-size-2xl`), labels `font-weight-semibold`, dots colores obligatoires (Transactions/Dettes), press feedback `scale(0.97)` — Ref: contracts.md

**Checkpoint**: Pas de regression, dark mode OK, DESIGN.md a jour

---

## Requirements → Taches

| Requirement | Tache(s) |
|-------------|----------|
| FR-001 | T-020, T-021, T-022 |
| FR-002 | T-020, T-021, T-022 |
| FR-003 | T-020, T-021, T-022 |
| FR-004 | T-030, T-031 |
| FR-005 | T-032, T-033 |
| FR-006 | T-050 (verification absence dots Abonnements) |
| FR-007 | T-040, T-041, T-042 |
| FR-008 | T-050 |
| NFR-001 | T-020, T-021, T-022, T-031, T-033, T-040, T-041, T-042 (tokens uniquement) |
| NFR-004 | T-051 |

## Resume

| Phase | Taches | Parallelisables |
|-------|--------|-----------------|
| Phase 1 — Setup | 1 | 0 |
| Phase 2 — US1 Typo + feedback (P1) | 3 | 3 |
| Phase 3 — US2 Dots (P1) | 4 | 4 |
| Phase 4 — US3 Gradient (P1) | 3 | 3 |
| Phase 5 — US4 Polish (P2) | 3 | 0 |
| **Total** | **14** | **10** |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** : Aucune dependance
- **Phase 2 (US1 Typo)** : Depend de Phase 1 — independant des autres phases
- **Phase 3 (US2 Dots)** : Depend de Phase 1 — independant de Phase 2
- **Phase 4 (US3 Gradient)** : Depend de Phase 1 — independant de Phases 2 et 3
- **Phase 5 (US4 Polish)** : Depend de Phases 2, 3, 4 (verification post-implementation)

### Parallel Opportunities

| Groupe | Taches | Condition |
|--------|--------|-----------|
| Typo par page | T-020, T-021, T-022 | Fichiers SCSS differents |
| Dots par page | T-030+T-031, T-032+T-033 | Fichiers differents (transactions vs debts) |
| Gradient par page | T-040, T-041, T-042 | Fichiers SCSS differents |
| Cross-phase | Phases 2, 3, 4 | Modifications independantes par page |

### Note : meme fichier intra-page

T-020 (typo transactions), T-031 (dots CSS transactions) et T-040 (gradient transactions) modifient le meme fichier `transactions.scss`. En sequentiel par un seul developpeur : pas de conflit. Execution recommandee : toutes les modifications d'une page ensemble (T-020 → T-031 → T-040 pour transactions, etc.).

---

## Implementation Strategy

### MVP First (US1 seul)

1. Phase 1 : Setup
2. Phase 2 : Typo + press feedback sur les 3 pages
3. **STOP et VALIDER** : coherence typographique immediate

### Incremental Delivery

1. Phase 1 → branche prete
2. Phase 2 (US1) → typo + feedback harmonises
3. Phase 3 (US2) → dots colores (valeur : identification visuelle instantanee)
4. Phase 4 (US3) → gradient (valeur : atmosphere coherente)
5. Phase 5 (US4) → verification + DESIGN.md a jour → commit + PR

### Execution recommandee (par page)

Pour minimiser les conflits fichier, grouper par page :
1. **Transactions** : T-020 → T-030 + T-031 → T-040
2. **Abonnements** : T-021 → T-041
3. **Dettes** : T-022 → T-032 + T-033 → T-042
4. **Polish** : T-050 → T-051 → T-052
