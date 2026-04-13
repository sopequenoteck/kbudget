# Tasks — KKS-230 Autocomplete libellé

**Date** : 2026-04-13
**Feature** : Autocomplete sur le champ libellé de saisie des transactions
**Branche** : `feature/KKS-230-autocomplete-libelle-transactions`
**Spec** : [`spec.md`](spec.md) · **Plan** : [`plan.md`](plan.md) · **Contracts** : [`contracts.md`](contracts.md)

## Légende

- `[P]` = parallélisable (fichiers disjoints, aucune dépendance avec d'autres `[P]` du même groupe)
- `[USX]` = tag de la User Story couverte (US1..US5)
- `[PX]` = priorité (P1/P2/P3)

---

## Phase 1 — Setup

- [x] **T-001** Créer la branche `feature/KKS-230-autocomplete-libelle-transactions` depuis `develop` — Réf: plan.md
- [x] **T-002** Vérifier le prochain numéro Flyway disponible dans `api/src/main/resources/db/migration/` et ajuster `V27__enable_unaccent_extension.sql` si collision — Réf: research.md R3 (V27 disponible — V26 est la dernière)
- [x] **T-003** Ajouter `diacritic: ^0.1.6` dans `flutter/pubspec.yaml` — Réf: research.md R7

### ✅ Checkpoint Phase 1
- Branche créée, numéro de migration validé, décision diacritiques Flutter tranchée.

---

## Phase 2 — Fondations (backend + infra)

Ces tâches sont bloquantes pour les fronts (API-First, constitution #1).

- [x] **T-010** Créer la migration Flyway `V27__enable_unaccent_extension.sql` — contenu : `CREATE EXTENSION IF NOT EXISTS unaccent;` — Réf: FR-017, data-model.md
- [x] **T-011** Ajouter la méthode `findLibelleSuggestions(userId, q, limit)` dans `TransactionRepository` avec `@Query` native SQL `GROUP BY libelle ORDER BY COUNT(*) DESC, MAX(date) DESC` + filtre `unaccent` — Réf: FR-004, FR-005, FR-017
- [x] **T-012** Ajouter la méthode `getLibelleSuggestions(userId, q, limit)` dans `TransactionService` avec clamp `limit ∈ [1, 50]` et défaut 20 — Réf: FR-003
- [x] **T-013** Ajouter l'endpoint `GET /libelles` dans `TransactionController` avec `@Operation` SpringDoc, `@RequestParam q/limit`, log SLF4J INFO — Réf: FR-001, FR-002, FR-003, FR-013, FR-014
- [x] **T-014** Vérifier que la route hérite bien du filtre JWT global dans `SecurityConfig` (pas d'ajout à la whitelist publique) — Réf: FR-006

### ✅ Checkpoint Phase 2
- Endpoint fonctionnel en local, testable via `curl` + Swagger UI, JWT obligatoire, extension `unaccent` active.

---

## Phase 3 — User Stories

### 🟢 Priorité P1 — MVP fonctionnel

#### Backend — tests d'intégration (US1, US2, US4, US5)

- [x] **T-020** [P] [P1] [US5] Test `TransactionControllerTest.should_return_401_when_unauthenticated` — Réf: FR-006, SC-004
- [x] **T-021** [P] [P1] [US5] Test `TransactionControllerTest.should_isolate_libelles_by_user` (2 users, assertions croisées) — Réf: FR-005, SC-004
- [x] **T-022** [P] [P1] [US1] Test `TransactionRepositoryTest.should_return_distinct_libelles_for_user` — Réf: FR-001, FR-005
- [x] **T-023** [P] [P1] [US2] Test `TransactionRepositoryTest.should_order_by_frequency_desc` (10×Carrefour vs 2×Monoprix) — Réf: FR-004
- [x] **T-024** [P] [P1] [US2] Test `TransactionRepositoryTest.should_tiebreak_by_last_date_desc` — Réf: FR-004
- [x] **T-025** [P] [P1] [US1] Test `TransactionServiceTest.should_clamp_limit_between_1_and_50` (null→20, -1→1, 100→50) — Réf: FR-003
- [x] **T-026** [P] [P1] [US1] Test performance `TransactionRepositoryTest.should_respond_under_100ms_on_10k_transactions` — Réf: NFR-001, SC-003

#### Angular — US1, US2, US4, US5 (P1)

- [x] **T-030** [P] [P1] [US1] Créer `TransactionLibelleService` (`app/src/app/features/transactions/services/transaction-libelle.service.ts`) avec méthode `search(q, limit)` + gestion erreur → `of([])` — Réf: FR-007
- [x] **T-031** [P1] [US1] Créer le composant partagé `AutocompleteComponent` (`app/src/app/shared/components/autocomplete/autocomplete.ts|html|scss`) — standalone, OnPush, signals-first, conforme au contrat 3.1 — Réf: FR-007, FR-018
- [x] **T-032** [P1] [US4] Implémenter dans `AutocompleteComponent` : saisie libre non bloquante + `Escape` ferme sans modifier — Réf: FR-009
- [x] **T-033** [P1] [US1] Intégrer `AutocompleteComponent` dans `TransactionFormComponent` : remplacement du champ libellé, two-way binding, signal `libelleSuggestions`, handler `onQueryChange` qui appelle le service — Réf: FR-007, NFR-008
- [x] **T-034** [P] [P1] [US1] Tests unitaires `transaction-libelle.service.spec.ts` (HttpTestingController, gestion erreur) — Réf: NFR-007
- [x] **T-035** [P] [P1] [US4] Test `transaction-form.spec.ts` : saisie d'un libellé inédit → formulaire valide → création transaction OK — Réf: FR-009, SC-005

#### Flutter — US1, US2, US4, US5 (P1)

- [x] **T-040** [P] [P1] [US1] Ajouter `getLibelleSuggestions(query, {limit})` dans `TransactionRepository` (interface abstraite) — Réf: FR-008
- [x] **T-041** [P] [P1] [US1] Implémenter `getLibelleSuggestions` dans `TransactionRepositoryRemote` (Dio) avec fallback `[]` sur erreur — Réf: FR-008
- [x] **T-042** [P] [P1] [US1] Implémenter `getLibelleSuggestions` dans `TransactionRepositoryLocal` (Drift) — requête `GROUP BY libelle ORDER BY COUNT DESC, MAX(date) DESC` — Réf: FR-008, FR-004
- [x] **T-043** [P1] [US1] Créer `libelleSuggestionsProvider` (`application/libelle_suggestions_provider.dart`) `FutureProvider.family<List<String>, String>` avec garde `query.length < 2` — Réf: FR-008, FR-015
- [x] **T-044** [P1] [US1] Créer le widget `LibelleAutocompleteField` (`presentation/widgets/libelle_autocomplete_field.dart`) basé sur `RawAutocomplete<String>`, stylé via tokens `AppColors/AppSpacing/AppTypography/AppRadius/AppShadows` — Réf: FR-008, NFR-004
- [x] **T-045** [P1] [US1] Intégrer `LibelleAutocompleteField` dans `transaction_form.dart` Flutter, validation `required` conservée — Réf: FR-008, NFR-008
- [x] **T-046** [P] [P1] [US4] Widget test `libelle_autocomplete_field_test.dart` : saisie inédite + sélection + seuil 2 chars — Réf: FR-009, FR-015, SC-005

### 🟡 Priorité P2 — Filtrage en cours de frappe (US3)

#### Backend

- [x] **T-050** [P] [P2] [US3] Test `TransactionRepositoryTest.should_filter_contains_case_insensitive` ("market" → "Carrefour Market") — Réf: FR-017
- [x] **T-051** [P] [P2] [US3] Test `TransactionRepositoryTest.should_filter_accent_insensitive` ("cafe" → "Café du coin") — Réf: FR-017

#### Angular

- [x] **T-060** [P2] [US3] Implémenter dans `AutocompleteComponent` : debounce 200ms (`Subject + debounceTime + distinctUntilChanged`) + émission `queryChange` uniquement si `value.length >= minChars` — Réf: FR-011, FR-015
- [x] **T-061** [P2] [US3] Implémenter filtrage local additionnel case/accent-insensible via NFD (`visibleSuggestions` computed) — Réf: FR-012
- [x] **T-062** [P2] [US3] Implémenter troncature UI à `maxDisplay=5` dans `visibleSuggestions` — Réf: FR-016
- [x] **T-063** [P2] [US3] Implémenter navigation clavier (ArrowUp/Down/Enter/Escape) + `activeIndex` — Réf: FR-010
- [x] **T-064** [P2] [US3] Ajouter attributs ARIA (`role=combobox`, `aria-autocomplete`, `aria-expanded`, `aria-activedescendant`, listbox, options) — Réf: NFR-005
- [x] **T-065** [P] [P2] [US3] Tests `autocomplete.spec.ts` : debounce (fakeAsync), seuil 2 chars, filtrage accent-insensible, navigation clavier, troncature 5, ARIA — Réf: NFR-007

#### Flutter

- [x] **T-070** [P2] [US3] Ajouter debounce 200ms (`Timer?`) dans `LibelleAutocompleteField` avant résolution du provider — Réf: FR-011
- [x] **T-071** [P2] [US3] Troncature `take(5)` dans l'`optionsBuilder` de `RawAutocomplete` — Réf: FR-016
- [x] **T-072** [P2] [US3] Filtrage accent-insensible en Dart sur les résultats local (Drift) via helper `removeDiacritics` — Réf: FR-012
- [x] **T-073** [P] [P2] [US3] Widget test Flutter : debounce + troncature 5 + accent-insensible — Réf: NFR-007

---

## Phase 4 — Polish

- [ ] **T-080** [P] Mettre à jour `docs/api-examples.md` : ajouter exemple requête/réponse `GET /api/transactions/libelles` — Réf: FR-014
- [ ] **T-081** [P] Ajouter note dans `docs/dette-technique.md` : migration future `Merchant` (réf KKS-099 dédup Jaro-Winkler) — Réf: plan.md
- [ ] **T-082** [P] Documenter le pattern `autocomplete` dans `DESIGN.md` si absent (vérifier d'abord) — Réf: NFR-003
- [ ] **T-083** Lancer `/design-check` sur les fichiers SCSS modifiés et corriger les écarts éventuels — Réf: NFR-003
- [ ] **T-084** Exécuter le quickstart manuel (`quickstart.md`) sur les deux fronts (Angular + Flutter) et archiver les observations — Réf: SC-001, SC-002
- [ ] **T-085** Test performance manuel : seed 10k transactions + mesure `curl -w @timing` < 100ms — Réf: NFR-001, SC-003
- [ ] **T-086** [P] `mvn test` + `ng lint` + `ng test` + `flutter analyze` + `flutter test` tout vert — Réf: NFR-006, NFR-007
- [ ] **T-087** Pre-commit review via `pre-commit-review` + `frontend-design-review` — Réf: CLAUDE.md
- [ ] **T-088** Créer la PR vers `develop` avec lien Linear KKS-230 et checklist des SC — Réf: plan.md

### ✅ Checkpoint Phase 4
- Tous les tests verts, docs à jour, design check OK, PR ouverte.

---

## Phase 5 — Dependencies & Execution Order

### Graphe de dépendances

```
T-001 (branche)
  └─▶ T-002, T-003 (vérifs setup)
        └─▶ Phase 2 (T-010 → T-014 séquentiel dans le back)
              ├─▶ T-020..T-026 [tests back, tous [P]]
              ├─▶ T-030 (service Angular) ─▶ T-031 (composant) ─▶ T-032 ─▶ T-033 (intégration form) ─▶ T-034, T-035 [P]
              │     │                         │
              │     │                         └─▶ T-060..T-064 (P2 signals/debounce/ARIA) ─▶ T-065 [P]
              │     │
              └─▶ T-040 (interface repo Flutter) ─▶ T-041, T-042 [P] ─▶ T-043 (provider) ─▶ T-044 (widget) ─▶ T-045 (form) ─▶ T-046 [P]
                                                                                                       └─▶ T-070..T-072 ─▶ T-073 [P]

Phase 4 (polish) dépend de la complétion des US P1 (T-033/T-045 au minimum).
```

### US Dependencies

| User Story | Tâches clés | Dépend de |
|------------|-------------|-----------|
| **US1 — Suggestions basiques** (P1) | T-022, T-030..T-033, T-040..T-045 | Phase 2 backend (T-010..T-014) |
| **US2 — Tri par fréquence** (P1) | T-023, T-024 + query T-011 | T-011 |
| **US3 — Filtrage en cours de frappe** (P2) | T-050, T-051, T-060..T-065, T-070..T-073 | US1 complète |
| **US4 — Saisie libre** (P1) | T-032, T-035, T-046 | T-031, T-044 |
| **US5 — Isolation cross-user** (P1) | T-020, T-021 | T-013 |

### Parallel Opportunities

| Groupe | Tâches | Condition |
|--------|--------|-----------|
| **G1 — Tests backend** | T-020, T-021, T-022, T-023, T-024, T-025, T-026 | Après Phase 2 complète |
| **G2 — Frontends indépendants** | Tout le bloc Angular (T-030..T-035) **en parallèle** avec tout le bloc Flutter (T-040..T-046) | Après Phase 2 complète ; 2 devs/agents distincts |
| **G3 — Tests P2** | T-050, T-051 [backend] // T-065 [Angular] // T-073 [Flutter] | Après implémentation US3 respective |
| **G4 — Doc polish** | T-080, T-081, T-082, T-086 | Après implémentation complète |

---

## Implementation Strategy

### MVP First

**Livrable MVP minimal** : US1 + US2 + US4 + US5 (toutes P1) **sans** US3 (P2).

- Backend complet : T-010 → T-014 + T-020 → T-026
- Angular : T-030, T-031 (version sans debounce ni clavier), T-032, T-033, T-035
- Flutter : T-040 → T-046

Dès ce stade, un utilisateur peut :
- Taper un libellé et voir des suggestions (après 2 chars, sans filtrage dynamique fin)
- Cliquer pour sélectionner
- Taper un libellé inédit
- Ne voir que ses propres libellés
- Bénéficier du tri par fréquence

**Valeur livrée** : couvre 4 des 5 US et tous les SC sauf SC-002 (rafraîchissement dynamique fluide).

### Incremental Delivery

1. **Incrément 1 — API** (Phase 2) : endpoint documenté + JWT + tests back → merge intermédiaire possible si on veut livrer l'API avant les fronts (API-First, constitution #1).
2. **Incrément 2 — Angular MVP** : fronts Angular P1 → déploiement PWA testable.
3. **Incrément 3 — Flutter MVP** : fronts Flutter P1 → TestFlight / APK interne.
4. **Incrément 4 — US3 (P2)** : debounce, filtrage dynamique, navigation clavier, ARIA, troncature 5 — améliorations UX.
5. **Incrément 5 — Polish** : docs, design check, pre-commit review, PR.

Les incréments 2 et 3 sont **parallélisables** (G2).

---

## Requirements Coverage

| Requirement | Tâches |
|-------------|--------|
| FR-001 | T-013, T-022 |
| FR-002 | T-013 |
| FR-003 | T-012, T-013, T-025 |
| FR-004 | T-011, T-023, T-024, T-042 |
| FR-005 | T-011, T-014, T-021, T-022 |
| FR-006 | T-014, T-020 |
| FR-007 | T-030, T-031, T-033 |
| FR-008 | T-040, T-041, T-042, T-043, T-044, T-045 |
| FR-009 | T-032, T-035, T-046 |
| FR-010 | T-063 |
| FR-011 | T-060, T-070 |
| FR-012 | T-061, T-072 |
| FR-013 | T-013 |
| FR-014 | T-013, T-080 |
| FR-015 | T-043, T-060, T-065, T-070 |
| FR-016 | T-062, T-071 |
| FR-017 | T-010, T-011, T-050, T-051 |
| FR-018 | T-031 |
| NFR-001 | T-026, T-085 |
| NFR-002 | T-044, T-084 |
| NFR-003 | T-031, T-082, T-083 |
| NFR-004 | T-044 |
| NFR-005 | T-064, T-065 |
| NFR-006 | T-020..T-026, T-050, T-051, T-086 |
| NFR-007 | T-034, T-035, T-046, T-065, T-073, T-086 |
| NFR-008 | T-033, T-045 |
| SC-001 | T-084 |
| SC-002 | T-060, T-061, T-070 |
| SC-003 | T-026, T-085 |
| SC-004 | T-020, T-021 |
| SC-005 | T-035, T-046 |
| SC-006 | T-013, T-080 |
| SC-007 | T-010 |

**Couverture** : 100% des FR, NFR et SC de la spec sont mappés à au moins une tâche.

---

## Résumé

| Phase | Tâches | P1 | P2 | P3 | `[P]` |
|-------|:------:|:--:|:--:|:--:|:-----:|
| Phase 1 — Setup | 3 | — | — | — | 0 |
| Phase 2 — Fondations | 5 | 5 | — | — | 0 |
| Phase 3 P1 — Backend tests | 7 | 7 | — | — | 7 |
| Phase 3 P1 — Angular | 6 | 6 | — | — | 3 |
| Phase 3 P1 — Flutter | 7 | 7 | — | — | 4 |
| Phase 3 P2 — Backend | 2 | — | 2 | — | 2 |
| Phase 3 P2 — Angular | 6 | — | 6 | — | 1 |
| Phase 3 P2 — Flutter | 4 | — | 4 | — | 1 |
| Phase 4 — Polish | 9 | — | — | — | 4 |
| **Total** | **49** | **25** | **12** | **0** | **22** |
