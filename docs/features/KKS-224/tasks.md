# Tasks: KKS-224 — Mettre a jour DESIGN.md avec les patterns du dashboard redesigne

**Input**: `docs/features/KKS-224/`
**Prerequisites**: plan.md, spec.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre executee en parallele
- **[Story]**: User Story concernee (US1, US2, US3, US4)

---

## Phase 1: Setup

**Purpose**: Creer la branche feature

- [x] T-001 [US1] Creer la branche `sopequenotech/kks-224-mettre-a-jour-designmd-avec-les-patterns-du-dashboard` depuis `develop`

**Checkpoint**: Branche prete, DESIGN.md lisible

---

## Phase 2: User Story 1 — Documenter les nouveaux tokens (Priority: P1)

**Goal**: Les 11 nouveaux tokens sont documentes dans la section "Tokens existants a utiliser"

**Independent Test**: Verifier que la section tokens contient les 11 nouveaux tokens avec description et contexte

- [x] T-020 [US1] Ajouter `--bg-success`, `--text-success`, `--bg-error`, `--text-error` dans la sous-section "Couleurs" de `app/DESIGN.md` — Ref: FR-001, FR-005
- [x] T-021 [P] [US1] Creer la sous-section "Glass / Effects" dans "Tokens existants a utiliser" avec `--glass-bg`, `--glass-border`, `--glass-blur`, `--hero-gradient`, `--page-gradient-color` — Ref: FR-001, FR-005
- [x] T-022 [P] [US1] Ajouter `--font-size-hero` dans "Typography" et `--shadow-hero-text` dans "Shadows" de `app/DESIGN.md` — Ref: FR-001, FR-005
- [x] T-023 [US1] Ajouter un tableau des variantes dark/light significatives pour les tokens glass dans la sous-section "Glass / Effects" — Ref: FR-001

**Checkpoint**: 11 tokens documentes, section tokens coherente et sans doublons

---

## Phase 3: User Story 2 — Documenter les nouveaux composants de reference (Priority: P1)

**Goal**: Les 5 nouveaux composants visuels ont chacun une section dediee avec specs completes

**Independent Test**: Chaque composant a description, proprietes CSS, contexte d'utilisation, dimensions/spacing

- [x] T-024 [P] [US2] Ajouter la sous-section "Hero Card (Patrimoine)" dans "Composants de reference" de `app/DESIGN.md` avec specs extraites de `dashboard.scss` L39-76 — Ref: FR-002, FR-003, FR-006
- [x] T-025 [P] [US2] Ajouter la sous-section "Glassmorphism Summary Cards" dans "Composants de reference" de `app/DESIGN.md` avec specs extraites de `dashboard.scss` L139-201 — Ref: FR-002, FR-003
- [x] T-026 [P] [US2] Ajouter la sous-section "Variation Badges (Pills)" dans "Composants de reference" de `app/DESIGN.md` avec specs extraites de `dashboard.scss` L85-108 — Ref: FR-002, FR-003
- [x] T-027 [P] [US2] Ajouter la sous-section "Radial Gradient (Fond de page)" dans "Composants de reference" de `app/DESIGN.md` avec specs extraites de `dashboard.scss` L8-18 — Ref: FR-002, FR-003
- [x] T-028 [P] [US2] Ajouter la sous-section "Section Headers (Titre + Lien)" dans "Composants de reference" de `app/DESIGN.md` avec specs extraites de `dashboard.scss` L209-237 — Ref: FR-002, FR-003

**Checkpoint**: 5 composants documentes avec specs completes

---

## Phase 4: User Story 3 — Formaliser les regles "quand utiliser quoi" (Priority: P1)

**Goal**: Un tableau de decision avec les 7 patterns et leurs criteres d'usage

**Independent Test**: Le tableau contient les 7 patterns avec critere explicite

- [x] T-030 [US3] Creer la section "Regles de design" dans `app/DESIGN.md` (apres "Composants de reference") avec le tableau des 7 patterns (glassmorphism, surface solide, items separes, bloc + dividers, radial gradient, variation badges, press feedback) — Ref: FR-004, FR-006

**Checkpoint**: Regles de decision documentees, tableau complet

---

## Phase 5: User Story 4 — Mettre a jour la section tokens existants (Priority: P2)

**Goal**: Section tokens integree sans doublons ni rupture de structure

**Independent Test**: Pas de doublons, organisation logique par categories

- [x] T-040 [US4] Relecture et reorganisation finale de la section "Tokens existants a utiliser" : verifier absence de doublons, ordre logique des categories, coherence des descriptions — Ref: FR-005

**Checkpoint**: Section tokens propre et coherente

---

## Phase 6: Polish

**Purpose**: Verification finale

- [x] T-050 Relecture complete de `app/DESIGN.md` : verifier NFR-001 (pas de section > 30 lignes sans sous-titre), NFR-003 (fichier unique), coherence globale
- [x] T-051 Verification que les 11 noms de tokens correspondent exactement aux variables CSS dans `_light.scss` et `_dark.scss` — Ref: NFR-002

---

## Requirements → Taches

| Requirement | Tache(s) |
|-------------|----------|
| FR-001 | T-020, T-021, T-022, T-023 |
| FR-002 | T-024, T-025, T-026, T-027, T-028 |
| FR-003 | T-024, T-025, T-026, T-027, T-028 |
| FR-004 | T-030 |
| FR-005 | T-020, T-021, T-022, T-040 |
| FR-006 | T-024, T-030 |
| NFR-001 | T-050 |
| NFR-002 | T-051 |
| NFR-003 | T-050 |

## Resume

| Phase | Taches | Parallelisables |
|-------|--------|-----------------|
| Phase 1 — Setup | 1 | 0 |
| Phase 2 — US1 Tokens (P1) | 4 | 2 |
| Phase 3 — US2 Composants (P1) | 5 | 5 |
| Phase 4 — US3 Regles (P1) | 1 | 0 |
| Phase 5 — US4 Integration (P2) | 1 | 0 |
| Phase 6 — Polish | 2 | 0 |
| **Total** | **14** | **7** |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** : Aucune dependance
- **Phase 2 (US1 Tokens)** : Depend de Phase 1
- **Phase 3 (US2 Composants)** : Depend de Phase 1 — independant de Phase 2
- **Phase 4 (US3 Regles)** : Depend de Phase 1 — independant de Phases 2 et 3
- **Phase 5 (US4 Integration)** : Depend de Phases 2, 3, 4 (reorganise apres ajout)
- **Phase 6 (Polish)** : Depend de toutes les phases precedentes

### Parallel Opportunities

| Groupe | Taches | Condition |
|--------|--------|-----------|
| Tokens | T-021, T-022 | Sous-sections differentes dans "Tokens existants" |
| Composants | T-024, T-025, T-026, T-027, T-028 | Sous-sections independantes dans "Composants de reference" |
| Cross-US | Phases 2, 3, 4 | Sections differentes de DESIGN.md, pas de conflit |

### Attention: conflit fichier

Toutes les taches modifient le meme fichier (`app/DESIGN.md`). En execution sequentielle par un seul developpeur, pas de conflit. En parallele multi-developpeur, merge conflicts possibles → preferer l'execution sequentielle Phase 2 → 3 → 4 → 5 → 6.

---

## Implementation Strategy

### MVP First (US1 + US3)

1. Phase 1 : Setup
2. Phase 2 : US1 — documenter les 11 tokens
3. Phase 4 : US3 — tableau de regles de decision
4. **STOP et VALIDER** : DESIGN.md utilisable pour les prochaines issues

### Incremental Delivery

1. Phase 1 → branche prete
2. Phase 2 (US1) → tokens documentes (valeur : reference tokens pour les devs)
3. Phase 3 (US2) → composants documentes (valeur : specs visuelles completes)
4. Phase 4 (US3) → regles de decision (valeur : guide "quand utiliser quoi")
5. Phase 5 (US4) → integration propre (valeur : section tokens unifiee)
6. Phase 6 → verification finale → commit + PR
