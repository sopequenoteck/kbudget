# Tasks: Fix checkboxes non fonctionnelles dans les formulaires

**Input**: Design documents from `/specs/020-fix-checkbox-forms/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, quickstart.md

**Tests**: Non demandés dans la spec — pas de tâches de test générées.

**Organization**: Tasks groupées par user story pour permettre l'implémentation et le test indépendants de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Corriger le sélecteur global `input` dans `_forms.scss` qui est la cause racine du bug pour toutes les checkboxes

**CRITICAL**: Aucune user story ne peut être validée tant que cette phase n'est pas complète

- [x] T001 Modifier le sélecteur `input` en `input:not([type='checkbox']):not([type='radio'])` dans `app/src/styles/_forms.scss` (lignes 5-7) pour exclure checkboxes et radios des styles globaux de formulaire
- [x] T002 Ajouter un bloc de styles global dédié `input[type='checkbox'], input[type='radio']` avec `width: auto`, `accent-color: var(--color-primary)`, `cursor: pointer` à la fin de `app/src/styles/_forms.scss`

**Checkpoint**: Les checkboxes natives sont restaurées dans tous les formulaires de l'application

---

## Phase 2: User Story 1 — Checkbox "actif" dans SubscriptionForm (Priority: P1)

**Goal**: La checkbox "Abonnement actif" fonctionne correctement (bascule visuelle, valeur soumise, état en édition)

**Independent Test**: Ouvrir le formulaire abonnement → cliquer la checkbox "actif" → vérifier la bascule visuelle → soumettre → vérifier `actif` = état visuel

### Implementation for User Story 1

- [x] T003 [US1] Supprimer le bloc `input[type='checkbox']` dupliqué (width, height, accent-color, cursor) dans `app/src/app/features/subscriptions/components/subscription-form/subscription-form.scss` — conserver uniquement le layout `.checkbox-field` (display flex, align-items, gap, font-size, color, cursor)

**Checkpoint**: La checkbox "actif" dans SubscriptionForm fonctionne et est stylée via les styles globaux

---

## Phase 3: User Story 2 — Checkbox "remboursé" dans DebtForm (Priority: P1)

**Goal**: La checkbox "Remboursé" fonctionne correctement (bascule visuelle, valeur soumise, état en édition)

**Independent Test**: Ouvrir le formulaire dette → cliquer la checkbox "remboursé" → vérifier la bascule visuelle → soumettre → vérifier `rembourse` = état visuel

### Implementation for User Story 2

- [x] T004 [P] [US2] Supprimer le bloc `input[type='checkbox']` dupliqué (width, height, accent-color, cursor) dans `app/src/app/features/debts/components/debt-form/debt-form.scss` — conserver uniquement le layout `.checkbox-field` (display flex, align-items, gap, font-size, color, cursor)

**Checkpoint**: La checkbox "remboursé" dans DebtForm fonctionne et est stylée via les styles globaux

---

## Phase 4: User Story 3 — Apparence visuelle cohérente (Priority: P2)

**Goal**: Les checkboxes ont une apparence cohérente avec le design system (couleur Amber, taille confortable sur mobile)

**Independent Test**: Inspecter visuellement les checkboxes dans les deux formulaires — taille >= 20x20px, couleur primaire Amber en état coché

> Note : Cette user story est entièrement couverte par T002 (styles globaux checkbox) et les `.checkbox-field` existants dans les composants. Aucune tâche supplémentaire nécessaire.

**Checkpoint**: Les checkboxes sont visuellement cohérentes dans les deux formulaires

---

## Phase 5: Polish & Validation

**Purpose**: Vérifier l'absence de régressions et valider le fix complet

- [x] T005 Vérifier la compilation frontend (`cd app && ng build`) — aucune erreur SCSS
- [x] T006 Valider le quickstart.md : lancer `cd app && ng serve`, tester manuellement les checkboxes dans les 2 formulaires + vérifier l'absence de régression visuelle sur les champs texte/select/textarea

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: Pas de dépendances — démarrage immédiat
- **US1 (Phase 2)**: Dépend de Phase 1 (T001, T002)
- **US2 (Phase 3)**: Dépend de Phase 1 (T001, T002) — peut être parallèle à US1
- **US3 (Phase 4)**: Couvert par Phase 1 — aucune tâche dédiée
- **Polish (Phase 5)**: Dépend de toutes les phases précédentes

### User Story Dependencies

- **User Story 1 (P1)**: Dépend uniquement de Phase 1 — indépendante de US2
- **User Story 2 (P1)**: Dépend uniquement de Phase 1 — indépendante de US1
- **User Story 3 (P2)**: Aucune tâche dédiée — couverte par T002

### Parallel Opportunities

- T003 [US1] et T004 [US2] peuvent être exécutées en parallèle (fichiers différents, aucune dépendance croisée)

---

## Parallel Example: US1 + US2

```bash
# Après Phase 1 complétée, lancer en parallèle :
Task: "T003 — Cleanup subscription-form.scss"
Task: "T004 — Cleanup debt-form.scss"
```

---

## Implementation Strategy

### MVP First (Phase 1 Only)

1. Compléter T001 + T002 (fix global `_forms.scss`)
2. **STOP and VALIDATE**: Les 3 user stories sont fonctionnelles dès ce point
3. Les tâches T003/T004 sont du cleanup (suppression de duplication)

### Delivery complet

1. Phase 1: T001 + T002 → Checkboxes fonctionnelles
2. Phase 2 + 3: T003 + T004 (parallèle) → Cleanup duplication CSS
3. Phase 5: T005 + T006 → Validation build + test manuel

---

## Notes

- 6 tâches au total, dont 2 parallélisables (T003, T004)
- Le MVP est atteint dès Phase 1 (2 tâches) — les checkboxes fonctionnent immédiatement
- T003 et T004 sont du nettoyage de code (suppression de duplication) — pas fonctionnellement bloquants
- Aucun fichier créé, uniquement des modifications de fichiers existants
