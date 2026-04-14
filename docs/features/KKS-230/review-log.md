# Review Log — KKS-230

## 2026-04-13 — review-impl (itération 1) — **PASS**

**Commits analysés** : b214b32, 16c9066, ae702cb, 306fa1f, 85328e3 (5 commits sur `feature/KKS-230-autocomplete-libelle-transactions`)

**Conformité FR/NFR/SC** : 18 FR, 8 NFR, 7 SC implémentés. Architecture conforme au plan. Tests couvrant US1..US5.

**Constats BLOQUANT** : aucun.

**Constats WARNING** (3 — à corriger avant merge) :
- **W-001** — `subscribe()` manuel dans `transaction-form.ts:onLibelleQuery` (ligne ~280). Risque : pas d'unsubscription à destruction. Correction : `takeUntilDestroyed()` ou pattern `toSignal()` piloté par signal query.
- **W-002** — `controller.addListener()` appelé dans `LibelleAutocompleteField.fieldViewBuilder` de `libelle_autocomplete_field.dart`. Appelé à chaque rebuild → listeners s'accumulent (memory leak). Correction : déplacer dans `initState()` + `removeListener` dans `dispose()`.
- **W-003** — `@Parameter(description=...)` absents sur `q` et `limit` dans `TransactionController.getLibelleSuggestions`. SC-006 partiel (visible dans Swagger mais descriptions manquantes). Correction : ajouter annotations `@Parameter` SpringDoc.

**Constats INFO** (6 — observations, pas de correction requise) :
- **I-001** Test 401 chevauche un test existant (regroupable stylistiquement).
- **I-002** `visibleSuggestions` ne filtre pas sous `minChars` — cohérent mais non testé.
- **I-003** Test Flutter `should_display_suggestions_from_provider_after_2_chars` a une branche else affaiblie (fallback RawAutocomplete focus).
- **I-004** `limit` sans `@Min(1) @Max(50)` — clamp au service, acceptable.
- **I-005** `TransactionRepositoryLocal` accepte `query=""` (filtré en amont par provider).
- **I-006** `autocomplete.scss` utilise `radius-xl` alors que DESIGN.md "Autocomplete" mentionne `radius-md` — écart cosmétique doc/code.

**Verdict** : **PASS** — aucun bloquant, 3 warnings à corriger avant merge. Les tâches ouvertes (T-083, T-084, T-085, T-087, T-088) sont explicitement manuelles.

**Recommandation** : corriger W-001, W-002, W-003 en un micro-commit, puis exécuter T-087 (pre-commit-review + frontend-design-review) avant la PR.

---

## 2026-04-13 — review-tasks (itération 1) — **PASS**

**Fichiers analysés** : `spec.md`, `plan.md`, `contracts.md`, `tasks.md`

**Couverture** : 18 FR, 8 NFR, 7 SC — 100% mappés à au moins une tâche.

**Ordonnancement** : API-First respecté (Phase 2 bloquante avant fronts). Graphe de dépendances cohérent, sans cycle.

**Constats BLOQUANT** : aucun.

**Constats WARNING** :
- **W-01** — Incohérence de nommage endpoint : `spec.md` parle de `/api/transactions/labels` (FR-001, FR-006), `plan.md`/`contracts.md`/`tasks.md` adoptent `/api/transactions/libelles`. À trancher avant T-013. Recommandation : `/libelles` (cohérence avec `Transaction.libelle`).
- **W-02** — T-031 (création AutocompleteComponent) potentiellement > 1 jour. Limite floue avec T-032, T-060..T-064.
- **W-03** — Tags `[USX]` absents en Phase 2 (T-010..T-014) et Phase 4 (T-080..T-088).
- **W-04** — Marqueur `[P]` incohérent sur T-086 (listé dans G4 mais non marqué).
- **W-05** — Validation Bean Validation `@Size(max=255)` sur `q` non mentionnée dans T-013.
- **W-06** — Absence de checkpoint intermédiaire Phase 3 entre P1 et P2.

**Constats INFO** :
- **I-01** — SC-007 mappé uniquement à T-010 (devrait aussi couvrir T-087).
- **I-02** — T-003 sans critère de sortie précis.
- **I-03** — NFR-002 peu tracé en Phase 3 Angular (absence mention `_bottom-sheet.scss`).
- **I-04** — Comptage tâches cohérent (49 total, numérotation séquentielle, aucun doublon).
- **I-05** — T-084 "archiver les observations" sans destination définie.

**Verdict** : **PASS** — aucun bloquant. W-01 à trancher avant l'implémentation de T-013 (décision simple, à consigner).

**Prochaine étape** : `/devflow.implement KKS-230` après correction mineure de W-01 (recommandée mais non bloquante).

---

## 2026-04-13 — review-spec (itération 1) — **PASS**

**Fichiers analysés** : `spec.md`, `clarify-log.md`, `.specify/memory/constitution.md`

### Synthèse

- **BLOQUANT** : 0
- **WARNING** : 5
- **INFO** : 6
- **Verdict** : **PASS** — aucun constat bloquant

### Warnings — **Tous résolus le 2026-04-13**

- **W-001** — ✅ **Résolu** : US1 Independent Test et Acceptance Scenarios réalignés sur FR-015 (taper 2 caractères au lieu de "focus"). Scenario 4 ajouté pour expliciter qu'aucune requête n'est émise sous le seuil.
- **W-002** — ✅ **Résolu** : SC-002 reformulé pour indiquer "au moins 2 caractères" (cohérent avec FR-015).
- **W-003** — ✅ **Résolu** : vérification effectuée — aucune extension Postgres activée dans V1 → V26. Décision : migration Flyway DDL-only `V27__enable_unaccent_extension.sql` acceptée. SC-007 amendé pour autoriser explicitement cette migration. Principe #7 (Self-Hosted Ready) clarifié : `unaccent` fait partie de `postgresql-contrib` standard, pas une nouvelle dépendance infra.
- **W-004** — ✅ **Résolu** : convention `ResponseEntity<List<X>>` vérifiée dans `AccountController`, `BankController`, `BudgetController`. Décision : endpoint retourne `ResponseEntity<List<String>>` directement, pas de DTO wrapper. Key Entities et A3 mis à jour.
- **W-005** — ✅ **Résolu** : FR-012 reformulé pour inclure explicitement la normalisation accent-insensible (NFD + suppression diacritiques) côté client, cohérent avec FR-017 backend.

### Infos également traitées

- **I-003** — ✅ **Résolu** : context path `/api` ajouté à toutes les mentions d'endpoint (`GET /api/transactions/labels`).
- **I-004** — ✅ **Résolu** : A4 mise à jour pour refléter FR-018 (composant maison confirmé, pas Angular Material).

### Infos (améliorations non bloquantes)

- **I-001** — FR-010 : préciser que Flutter n'implémente pas la navigation clavier.
- **I-002** — SC-001 : la méthode "test manuel scripté" mériterait d'être complétée par une référence aux NFR-006/NFR-007.
- **I-003** — Context path `/api` absent de la spec (tous les endpoints doivent l'inclure pour être cohérents avec la constitution et `docs/api-examples.md`).
- **I-004** — A4 partiellement obsolète depuis l'ajout de FR-018 (composant maison confirmé).
- **I-005** — Hors scope offline Flutter à justifier brièvement pour respecter le principe IV de la constitution.
- **I-006** — Frontend devrait appeler `limit=5` directement pour éviter de transférer 15 résultats inutiles.

### Points notables

- Les 5 US sont correctement priorisées (4 P1, 1 P2)
- Toutes les US ont Why this priority + Independent Test
- FR mesurables, NFR quantifiés, 7 SC avec méthode de vérification
- 5 questions de clarification toutes résolues et tracées
- Hors scope explicite et bien délimité
- Conformité aux 7 principes de la constitution : OK

### Prochaine étape

`state.currentStep` → `research`. Commande : `/devflow.research KKS-230`.

**Recommandation** : corriger W-001, W-002, W-005 avant `/devflow.plan` (corrections triviales, 5 min) et trancher W-003 (vérifier `unaccent` en prod) en début de plan.
