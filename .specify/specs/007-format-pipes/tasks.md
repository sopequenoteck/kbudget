# Tasks: Créer AmountPipe et RelativeDatePipe

**Input**: Design documents from `/specs/007-format-pipes/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Inclus — les pipes purs requièrent des tests unitaires (principe V. Testabilité de la constitution).

**Organization**: Tasks groupées par user story. Les deux stories (US1 et US2) sont indépendantes et parallélisables.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Vérifier que le projet compile et que l'environnement de test fonctionne.

- [x] T001 Vérifier le build initial — exécuter `cd app && npx ng build` sans erreur

**Checkpoint**: Build OK, prêt pour l'implémentation.

---

## Phase 2: User Story 1 — Affichage formaté des montants (Priority: P1)

**Goal**: L'utilisateur voit les montants formatés en euros fr-FR avec signe conditionnel (+/-) selon le type métier.

**Independent Test**: Instancier `new AmountPipe()` et vérifier les transformations entrée/sortie.

### Implementation

- [x] T002 [US1] Implémenter AmountPipe dans `app/src/app/shared/pipes/amount.pipe.ts`

  Standalone pipe, `name: 'amount'`, `pure: true`. Signature : `transform(value: number | null | undefined, type?: string | null): string`.

  Logique :
  - Si `value` est `null` ou `undefined` → retourner `''`
  - Formater via `Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR', signDisplay: 'never' })`
  - Si `value === 0` → retourner le montant formaté sans signe
  - Mapping signe selon `type` :
    - `'RECETTE'` / `'ON_ME_DOIT'` → préfixe `+`
    - `'DEPENSE'` / `'JE_DOIS'` → préfixe `-`
    - `null` / `undefined` / autre → pas de préfixe

### Tests

- [x] T003 [US1] Écrire les tests unitaires AmountPipe dans `app/src/app/shared/pipes/amount.pipe.spec.ts`

  Instanciation directe (`new AmountPipe()`, pas de TestBed). Cas à couvrir :
  - `should_format_with_plus_when_RECETTE` : `transform(2100, 'RECETTE')` → `+2 100,00 €` (ou avec espace insécable)
  - `should_format_with_minus_when_DEPENSE` : `transform(9.99, 'DEPENSE')` → `-9,99 €`
  - `should_format_with_plus_when_ON_ME_DOIT` : `transform(500, 'ON_ME_DOIT')` → `+500,00 €`
  - `should_format_with_minus_when_JE_DOIS` : `transform(150, 'JE_DOIS')` → `-150,00 €`
  - `should_format_without_sign_when_no_type` : `transform(1500.50)` → `1 500,50 €`
  - `should_format_zero_without_sign` : `transform(0, 'DEPENSE')` → `0,00 €`
  - `should_return_empty_string_when_null` : `transform(null)` → `''`
  - `should_return_empty_string_when_undefined` : `transform(undefined)` → `''`
  - `should_handle_large_amounts` : `transform(1000000, 'RECETTE')` → `+1 000 000,00 €`
  - `should_handle_negative_value_without_type` : `transform(-50)` → résultat avec signe négatif natif

  Note : les espaces dans les résultats `Intl.NumberFormat` sont des espaces insécables (U+00A0 ou U+202F). Les assertions doivent utiliser `.toContain()` ou normaliser les espaces.

**Checkpoint**: `cd app && npx vitest run amount.pipe` — tous les tests passent.

---

## Phase 3: User Story 2 — Affichage des dates relatives (Priority: P1)

**Goal**: L'utilisateur voit les dates récentes en langage naturel relatif et les dates anciennes au format long français.

**Independent Test**: Instancier `new RelativeDatePipe()` et vérifier les transformations entrée/sortie.

### Implementation

- [x] T004 [P] [US2] Implémenter RelativeDatePipe dans `app/src/app/shared/pipes/relative-date.pipe.ts`

  Standalone pipe, `name: 'relativeDate'`, `pure: true`. Signature : `transform(value: string | null | undefined): string`.

  Logique :
  - Si `value` est `null`, `undefined` ou chaîne vide → retourner `''`
  - Parser la date via `new Date(value)` — si `isNaN(date.getTime())` → retourner `''`
  - Calculer `diffJours` = différence en jours entre aujourd'hui (minuit local) et la date (minuit local)
  - Mapping :
    - `diffJours === 0` → `'Aujourd'hui'`
    - `diffJours === 1` → `'Hier'`
    - `diffJours === -1` → `'Demain'`
    - `diffJours >= 2 && diffJours <= 7` → `'il y a ${diffJours} jours'`
    - `diffJours >= 8 && diffJours <= 30` → `'il y a ${Math.floor(diffJours / 7)} semaine(s)'` (pluraliser : "semaine" si 1, "semaines" si >1)
    - `diffJours > 30` ou `diffJours < -1` → `Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })`.format(date)

### Tests

- [x] T005 [P] [US2] Écrire les tests unitaires RelativeDatePipe dans `app/src/app/shared/pipes/relative-date.pipe.spec.ts`

  Instanciation directe (`new RelativeDatePipe()`, pas de TestBed). Utiliser des dates calculées dynamiquement par rapport à `new Date()` pour éviter les tests fragiles.

  Cas à couvrir :
  - `should_return_aujourdhui_when_today` : date du jour → `'Aujourd'hui'`
  - `should_return_hier_when_yesterday` : date d'hier → `'Hier'`
  - `should_return_demain_when_tomorrow` : date de demain → `'Demain'`
  - `should_return_il_y_a_X_jours_when_2_to_7_days` : il y a 3 jours → `'il y a 3 jours'`
  - `should_return_il_y_a_7_jours_when_exactly_7_days` : il y a 7 jours → `'il y a 7 jours'`
  - `should_return_il_y_a_1_semaine_when_8_days` : il y a 8 jours → `'il y a 1 semaine'`
  - `should_return_il_y_a_X_semaines_when_14_to_30_days` : il y a 14 jours → `'il y a 2 semaines'`
  - `should_return_long_date_when_over_30_days` : il y a 45 jours → format long fr-FR (ex: `'26 décembre 2025'`)
  - `should_return_long_date_when_future_beyond_tomorrow` : dans 5 jours → format long fr-FR
  - `should_return_empty_string_when_null` : `transform(null)` → `''`
  - `should_return_empty_string_when_undefined` : `transform(undefined)` → `''`
  - `should_return_empty_string_when_invalid_date` : `transform('abc')` → `''`
  - `should_return_empty_string_when_empty_string` : `transform('')` → `''`

  Helper utile : fonction `daysAgo(n: number): string` qui retourne la date ISO `YYYY-MM-DD` de `n` jours avant aujourd'hui.

**Checkpoint**: `cd app && npx vitest run relative-date.pipe` — tous les tests passent.

---

## Phase 4: Polish & Validation

**Purpose**: Vérification finale cross-cutting.

- [x] T006 Exécuter tous les tests — `cd app && npx vitest run` — aucune régression
- [x] T007 Exécuter le lint — `cd app && npx ng lint` — aucune erreur
- [x] T008 Exécuter le build — `cd app && npx ng build` — aucune erreur ni warning
- [x] T009 Valider quickstart.md — parcourir les étapes de `specs/007-format-pipes/quickstart.md` et confirmer

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Aucune dépendance — vérification initiale
- **US1 (Phase 2)**: Dépend de Phase 1 (build OK)
- **US2 (Phase 3)**: Dépend de Phase 1 (build OK) — **indépendant de US1**
- **Polish (Phase 4)**: Dépend de Phase 2 ET Phase 3

### User Story Dependencies

- **US1 (AmountPipe)**: Aucune dépendance sur US2. Peut démarrer dès Phase 1 complète.
- **US2 (RelativeDatePipe)**: Aucune dépendance sur US1. Peut démarrer dès Phase 1 complète.

### Within Each User Story

- Implementation (T002/T004) avant tests (T003/T005) car les tests importent le pipe
- Mais les tests sont écrits pour vérifier le comportement attendu, pas l'implémentation

### Parallel Opportunities

- **T002 et T004** sont parallélisables (fichiers différents, aucune dépendance croisée)
- **T003 et T005** sont parallélisables (fichiers de test différents)
- **Phase 2 et Phase 3 entières** sont parallélisables

---

## Parallel Example

```bash
# Les deux user stories en parallèle (fichiers différents, aucune dépendance) :
Agent 1: T002 (AmountPipe) → T003 (tests AmountPipe)
Agent 2: T004 (RelativeDatePipe) → T005 (tests RelativeDatePipe)

# Puis séquentiellement :
T006 → T007 → T008 → T009 (validation finale)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001 : Vérifier build
2. T002 : Implémenter AmountPipe
3. T003 : Tests AmountPipe
4. **STOP and VALIDATE** : `npx vitest run amount.pipe` — MVP livrable

### Full Delivery

1. T001 : Setup
2. T002 + T004 en parallèle : Implémenter les deux pipes
3. T003 + T005 en parallèle : Tests des deux pipes
4. T006 → T009 : Validation finale

---

## Notes

- Les pipes sont purs (pas de DI) → instanciation directe dans les tests (`new Pipe()`)
- Les espaces dans `Intl.NumberFormat('fr-FR')` sont des espaces insécables (U+00A0 ou U+202F selon l'environnement) — les tests doivent normaliser ou utiliser `.toContain()`
- Pas de barrel file dans `shared/pipes/` (convention YAGNI du projet)
- Les pipes seront consommés par KKS-49 (ListItem), KKS-54-57 (écrans) — mais pas dans le scope de cette feature
