# Tasks: Recherche & Filtres Transactions

**Input**: `docs/features/search-filter-transactions/spec.md`, `plan.md`
**Date**: 2026-04-11

## Phase 1: Fondations (prerequis bloquants)

**But** : Signals de filtrage + chargement des donnees necessaires aux filtres. Bloque toutes les US.

- [x] T-001 [US1,US2,US3,US4] Ajouter les signals de filtrage dans `app/src/app/features/transactions/transactions.ts` : `searchOpen`, `searchQuery`, `filterOpen`, `typeFilter`, `categoryFilter`, `accountFilter`, `hasActiveFilters` computed — Ref: FR-002, FR-006, FR-008
- [x] T-002 [US2,US3,US4] Charger categories et comptes dans `loadData()` via `forkJoin` (ajouter `categoryService.getAll()` et `accountService.getAll()`), stocker dans `categories` et `accounts` signals — Ref: FR-005
- [x] T-003 [US1,US2,US3,US4] Enrichir le `filteredTransactions` computed pour chainer les filtres : mois/annee (existant) → type → categorie → compte → recherche texte (libelle, case-insensitive). Tous en AND — Ref: FR-002, FR-003, FR-006
- [x] T-004 [US2,US3] Ajouter le computed `monthCategories` : categories presentes dans les transactions du mois selectionne, triees par nombre de transactions decroissant — Ref: FR-005

**Checkpoint** : Les signals existent, le computed filtre correctement. Pas encore de UI.

---

## Phase 2: US1 — Recherche textuelle rapide (P1) — MVP

**Goal** : L'icone loupe ouvre un champ de recherche inline dans le section header, filtre par libelle en temps reel.

**Independent Test** : Taper "loyer", verifier que seules les transactions matchant apparaissent.

- [x] T-005 [US1] Ajouter les handlers `toggleSearch()` dans `transactions.ts` : toggle `searchOpen`, reset `searchQuery` a la fermeture, focus input via `viewChild` — Ref: FR-001
- [x] T-006 [US1] Ajouter l'import `phosphorX` dans les providers du composant — Ref: FR-001
- [x] T-007 [US1] Modifier le template `transactions.html` : conditionnel `@if (searchOpen())` dans le section header, input remplace le titre, icone loupe bascule en X — Ref: FR-001, FR-003
- [x] T-008 [US1] Ajouter les styles `.section-header__search-input` et `.section-header__action-btn.active` dans `app/src/styles/_list-patterns.scss` — Ref: NFR-002, NFR-003
- [x] T-009 [US1] Modifier l'empty state dans `transactions.html` : distinguer le cas recherche sans resultat (icone phosphorMagnifyingGlass + "Aucune transaction trouvee", pas de CTA) — Ref: FR-009

**Checkpoint** : La recherche fonctionne de bout en bout. Tester : ouvrir/fermer, filtrage live, empty state, Escape pour fermer.

---

## Phase 3: US2 — Filtre par type (P1)

**Goal** : L'icone entonnoir ouvre un panneau slide-down avec des chips Tout/Depenses/Recettes.

**Independent Test** : Activer "Depenses", verifier que seules les DEPENSE apparaissent. Indicateur dot visible.

- [x] T-010 [US2] Ajouter les handlers `toggleFilter()`, `setTypeFilter()`, `resetFilters()` dans `transactions.ts` — Ref: FR-004, FR-007
- [x] T-011 [US2] Ajouter le template du panneau filtres dans `transactions.html` : bloc `@if (filterOpen())`, ligne chips type (Tout/Depenses/Recettes) + lien Reinitialiser — Ref: FR-004, FR-005
- [x] T-012 [US2] Ajouter les styles `.filter-panel`, `.filter-chip`, `@keyframes filter-slide-down` dans `app/src/app/features/transactions/transactions.scss` — Ref: NFR-002, NFR-003
- [x] T-013 [US2] Ajouter le dot indicateur filtre actif : `position: relative` sur `.section-header__action-btn`, element `.section-header__filter-dot` dans `_list-patterns.scss` + template — Ref: FR-007
- [x] T-014 [US2] Modifier l'empty state : distinguer le cas filtres sans resultat (icone phosphorFunnel + message contextuel + lien "Reinitialiser les filtres") — Ref: FR-009

**Checkpoint** : Filtre par type fonctionne. Dot visible. Empty state contextuel. Tester combinaison recherche + filtre type.

---

## Phase 4: US3 — Filtre par categorie (P2)

**Goal** : Ligne de chips categories dans le panneau filtres, combinable avec le filtre type.

**Independent Test** : Activer "Alimentation", verifier que seules ces transactions apparaissent.

- [x] T-015 [US3] Ajouter le handler `setCategoryFilter()` dans `transactions.ts` (toggle pattern) — Ref: FR-005
- [x] T-016 [US3] Ajouter la ligne categories dans le template du panneau filtres : `@if (monthCategories().length > 0)`, chips avec emoji + nom, scroll horizontal — Ref: FR-005
- [x] T-017 [US3] Ajouter le style `.filter-panel__row--scroll` si pas deja fait (scrollbar hidden, overflow-x auto) — Ref: NFR-003

**Checkpoint** : Filtre categorie fonctionne. Tester combinaison type + categorie. Chips mois-dependantes.

---

## Phase 5: US4 + US5 — Filtre compte + Recherche etendue (P3)

**Goal** : Chips comptes (si multi-comptes) + recherche etendue a categorie.nom et note.

- [x] T-018 [P] [US4] Ajouter le handler `setAccountFilter()` dans `transactions.ts` (toggle pattern) — Ref: FR-005
- [x] T-019 [P] [US4] Ajouter la ligne comptes dans le template du panneau filtres : `@if (accounts().length > 1)`, chips emoji + nom — Ref: FR-005
- [x] T-020 [P] [US5] Etendre le filtre recherche dans le computed `filteredTransactions` : ajouter `category?.nom` et `note` au scope de recherche (en plus de `libelle`) — Ref: FR-003

**Checkpoint** : Filtre compte fonctionne (masque si mono-compte). Recherche trouve dans libelle + categorie + note.

---

## Phase 6: Polish

- [x] T-021 Verification visuelle cross-pages : verifier que `position: relative` sur `.section-header__action-btn` ne casse pas les section headers des autres pages (Abonnements, Dettes, Budgets, Boutique) — Ref: plan.md risques
- [x] T-022 Test mobile : verifier le comportement sur iPhone (clavier + recherche, scroll horizontal chips, panneau filtres) — Ref: NFR-001, Constitution IV
- [x] T-023 Verification FR-010 : confirmer visuellement que le hero (solde, recettes, depenses) ne change pas quand les filtres sont actifs — Ref: FR-010

**Checkpoint** : Feature complete, aucune regression.

---

## Requirements → Tasks Mapping

| Requirement | Taches |
|-------------|--------|
| FR-001 | T-005, T-006, T-007, T-008 |
| FR-002 | T-001, T-003 |
| FR-003 | T-003, T-007, T-020 |
| FR-004 | T-010, T-011 |
| FR-005 | T-002, T-004, T-011, T-015, T-016, T-018, T-019 |
| FR-006 | T-001, T-003 |
| FR-007 | T-010, T-013 |
| FR-008 | T-001 |
| FR-009 | T-009, T-014 |
| FR-010 | T-023 |
| NFR-001 | T-022 |
| NFR-002 | T-008, T-012 |
| NFR-003 | T-008, T-012, T-017 |
| NFR-004 | T-001, T-003 (signals-first) |
| NFR-005 | Implicite (composant existant deja standalone + OnPush) |

---

## Dependencies & Execution Order

### Graphe

```
T-001 ──┬──→ T-005 → T-006 → T-007 → T-008 → T-009  (US1)
T-002 ──┤
T-003 ──┤──→ T-010 → T-011 → T-012 → T-013 → T-014  (US2)
T-004 ──┘──→ T-015 → T-016 → T-017                    (US3)
             T-018, T-019, T-020                        (US4+5, paralleles)
             T-021, T-022, T-023                        (Polish)
```

### Parallel Opportunities

| Groupe | Taches | Condition |
|--------|--------|-----------|
| Fondations | T-001, T-002, T-004 en parallele, T-003 apres T-001 | Fichiers differents non |
| P3 | T-018, T-019, T-020 | Apres Phase 4 (US3) |
| Polish | T-021, T-022, T-023 | Apres Phase 5 |

### Implementation Strategy

**MVP First** (US1 seule) :
1. Phase 1 (T-001 a T-004) → fondations
2. Phase 2 (T-005 a T-009) → recherche fonctionnelle
3. **STOP et VALIDER** : la recherche marche seule, l'icone loupe est fonctionnelle

**Incremental Delivery** :
1. Fondations + US1 → recherche textuelle (MVP)
2. + US2 → filtre par type (valeur immediate)
3. + US3 → filtre par categorie (combinaison puissante)
4. + US4 + US5 → filtres avances (completude)
5. Polish → verification cross-page + mobile

---

## Resume

| Phase | Taches | Priorite |
|-------|--------|----------|
| 1 — Fondations | 4 | Bloquant |
| 2 — US1 Recherche | 5 | P1 |
| 3 — US2 Filtre type | 5 | P1 |
| 4 — US3 Filtre categorie | 3 | P2 |
| 5 — US4+US5 Compte + Etendue | 3 | P3 |
| 6 — Polish | 3 | — |
| **Total** | **23** | |
