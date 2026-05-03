---
description: "Task list — KKS-231 Refonte du sélecteur de catégorie en bottom-sheet inline"
---

# Tasks — KKS-231 : Refonte du sélecteur de catégorie en bottom-sheet inline

**Date** : 2026-04-18
**Input** : `docs/features/KKS-231/` (spec.md, plan.md, research.md, contracts.md, data-model.md)
**Prerequisites** : plan.md ✅, spec.md ✅, research.md ✅, contracts.md ✅, data-model.md ✅

**Tests** : inclus (NFR-005 l'exige explicitement — couverture ≥ 80 % sur `CategorySelect`).

**Organisation** : tâches groupées par User Story pour permettre une livraison incrémentale.

## Format

`- [ ] [T-XXX] [P?] [USX?] Description — Réf: FR-XXX/NFR-XXX`

- `[P]` : tâche parallélisable (fichier indépendant, aucune dépendance bloquante).
- `[USX]` : tag de la User Story couverte.
- Réf : FR/NFR/SC tracés depuis `spec.md`.

---

## Phase 1 — Setup

**Objectif** : pré-requis techniques. Minimal pour cette feature (branche et dossier feature déjà créés par `setup-feature.sh`).

- [x] **T-001** Vérifier la branche `feature/KKS-231` et lancer `cd app && ng serve` pour valider la baseline (aucune erreur de compilation). — Réf : quickstart.md Phase 1

**Checkpoint Phase 1** : dev server OK, `category-picker` actuel fonctionne.

---

## Phase 2 — Fondations (bloquantes)

**Objectif** : toutes les briques partagées (helper, refactor `CategoryForm`, adaptation `shell.html`) qui débloquent les US. **Aucune US ne peut commencer tant que cette phase n'est pas terminée.**

### 2.1 — Helper partagé `normalize`

- [x] **T-010** [P] Créer `app/src/app/shared/utils/string.utils.ts` exportant `normalize(s: string): string` (implémentation lowercase + NFD + suppression diacritiques). — Réf : FR-012, RES-001
- [x] **T-011** [P] Créer `app/src/app/shared/utils/string.utils.spec.ts` avec cas nominaux (minuscules, accents, chaîne vide, idempotence). — Réf : NFR-005
- [x] **T-012** Refactorer `app/src/app/shared/components/autocomplete/autocomplete.ts` pour importer `normalize` depuis le shared util et supprimer la fonction locale. Lancer `ng test --include="**/autocomplete.spec.ts"` pour vérifier la non-régression. — Réf : RES-001, risque R1

### 2.2 — Refonte `CategoryForm` (externalisation footer)

- [x] **T-013** Renommer la méthode `onSubmit()` → `submit()` (méthode publique async) dans `app/src/app/shared/components/category-form/category-form.ts`. Conserver le handler `async`, le try/catch, les signaux `submitting`/`errorMessage`, l'émission `(saved)`. — Réf : FR-013, RES-003
- [x] **T-014** Supprimer la section `category-form__actions` (lignes 43-48) dans `app/src/app/shared/components/category-form/category-form.html`. Conserver `<form (ngSubmit)="submit()">` pour Enter-to-submit. — Réf : FR-013
- [x] **T-015** Nettoyer les styles `.category-form__actions` orphelins dans `app/src/app/shared/components/category-form/category-form.scss` ; ajuster le spacing du dernier champ. — Réf : FR-013, FR-015
- [x] **T-016** Adapter `app/src/app/shared/components/category-form/category-form.spec.ts` : retirer les tests de boutons internes, ajouter `should_emit_saved_when_submit_called_publicly`, `should_update_error_message_when_api_fails`, `should_not_submit_when_form_invalid`. — Réf : NFR-005

### 2.3 — Adaptation `shell.html` (non-régression — couvre **US4** mais bloquant Phase 2)

- [x] **T-017** Ajouter `readonly categoryFormRef = viewChild<CategoryForm>('categoryFormRef')` et la méthode `triggerCategorySubmit(): void` dans `app/src/app/shared/components/shell/shell.ts`. — Réf : FR-014, RES-008
- [x] **T-018** Dans `app/src/app/shared/components/shell/shell.html`, branche `@case ('category')` : ajouter `#categoryFormRef` sur `<app-category-form>` et un footer custom avec les 2 boutons (« Annuler » via `onModalClose()` + « Créer/Modifier » via `triggerCategorySubmit()`). Lire `submitting()` et `isEditMode` depuis `categoryFormRef()`. — Réf : FR-014, US4
- [ ] **T-019** Test manuel non-régression sur Settings (`/settings` → catégories) : créer / modifier / supprimer une catégorie. Valider visuellement que rien n'a régressé. — Réf : SC-006, US4, risque R2 ⏸ *À valider par l'utilisateur après `ng serve`*

**Checkpoint Phase 2** :
- `ng test` : tous les tests précédemment verts restent verts (incluant `autocomplete.spec.ts`, `category-form.spec.ts`).
- Settings → gestion catégories fonctionne comme avant la refonte.
- `CategoryForm` expose désormais la méthode publique `submit()` et n'a plus de footer interne.
- Les fondations sont prêtes, les US peuvent démarrer en parallèle.

---

## Phase 3 — User Stories (P1 → P2)

### US1 — Sélectionner une catégorie existante sans quitter le sheet (P1) 🎯 MVP

**Goal** : remplacer l'empilement bottom-sheet/overlay par une liste inline dans l'expand du form parent. Sélection collapse l'expand et patch la valeur du form.

**Independent Test** : ouvrir le bottom-sheet transaction, cliquer sur la pill catégorie, vérifier qu'aucun overlay ne se superpose, sélectionner une catégorie, confirmer que la pill affiche la sélection.

#### Implémentation `CategorySelect` (liste seule — pas encore de création)

- [x] **T-020** [US1] Créer `app/src/app/shared/components/category-select/category-select.ts` — squelette standalone + OnPush + CVA (`NG_VALUE_ACCESSOR` + `writeValue`/`registerOnChange`/`registerOnTouched`/`setDisabledState`). Déclarer `categories = input<Category[]>([])`, `selected = output<string>()`, `created = output<Category>()`, `isCreating = output<boolean>()`. — Réf : FR-001, FR-002, FR-021, contracts.md § CategorySelect
- [x] **T-021** [US1] Ajouter les signals internes `mode = signal<'list' \| 'create'>('list')`, `searchTerm = signal('')`, `activeIndex = signal(-1)`, `listboxId = \`category-select-listbox-${random}\`` dans `category-select.ts`. — Réf : FR-018, data-model.md § CategorySelectState
- [x] **T-022** [US1] Ajouter les computed `filteredCategories` (filtre via `normalize`), `hasExactMatch`, `showCreateButton` dans `category-select.ts`. — Réf : FR-005, FR-012 (posé mais exploité pleinement en US2/US3)
- [x] **T-023** [P] [US1] Créer `app/src/app/shared/components/category-select/category-select.html` — branche `list` uniquement : input recherche + listbox avec `@for` sur `filteredCategories()`, chaque item avec icône (cercle couleur), nom, état highlight. **Empty state premier usage** : si `categories()` est vide et `searchTerm()` vide, afficher « Aucune catégorie — créez-en une » avec CTA `+ Créer` affiché d'office (cf. plan.md W-I-004). ARIA cohérent avec Autocomplete (`role="combobox"`, `role="listbox"`, `role="option"`, `aria-activedescendant`). — Réf : FR-001, FR-018, CL-006 (plan I-004)
- [x] **T-024** [P] [US1] Créer `app/src/app/shared/components/category-select/category-select.scss` — tokens CSS uniquement, pattern `.cs__list` / `.cs__item` dérivé de `_list-patterns.scss` (icon-circle 36px, title sm/secondary). `max-height: 60vh` + `overflow-y: auto` sur `.cs__list`. Aucun hex/rgba hardcodé. — Réf : FR-020, NFR-001, SC-007
- [x] **T-025** [US1] Ajouter les méthodes `selectCategory(id: string)` (set value + emit selected + update CVA) et `onKeydown(e: KeyboardEvent)` (↓/↑/Enter/Esc partiel) dans `category-select.ts`. — Réf : FR-002, FR-019
- [x] **T-026** [US1] Ajouter l'effect `effect(() => this.isCreating.emit(this.mode() === 'create'))` et `ngOnDestroy` qui force `mode = 'list'` (reset). — Réf : FR-008, risque R4

#### Tests `CategorySelect` (US1)

- [x] **T-027** [P] [US1] Créer `app/src/app/shared/components/category-select/category-select.spec.ts` avec les tests US1 : `should_render_all_categories_when_search_is_empty`, `should_select_and_emit_when_category_clicked`, `should_apply_max_height_on_list_container`, `should_render_with_correct_aria_attributes`. — Réf : NFR-005, SC-010

#### Migration `transaction-form` (US1 minimal)

- [x] **T-028** [US1] Dans `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` : injecter `CategoryService`, ajouter `readonly categories = toSignal(categoryService.getAll(), { initialValue: [] })` + `readonly categoryCreating = signal(false)`. — Réf : FR-004, RES-004
- [x] **T-029** [US1] Dans `app/src/app/features/transactions/components/transaction-form/transaction-form.html` : remplacer `<app-category-picker formControlName="categoryId" />` par `<app-category-select formControlName="categoryId" [categories]="categories()" (isCreating)="categoryCreating.set($event)" />`. Importer `CategorySelect` dans le composant. — Réf : FR-004, FR-008

**Checkpoint US1** : ouvrir le bottom-sheet transaction → clic pill catégorie → liste inline (aucun overlay) → sélection → expand collapse → form reçoit la valeur. Le bouton « + Créer » n'existe pas encore (US2). Taille liste respecte 60vh. Tests US1 passent.

---

### US2 — Créer une nouvelle catégorie sans quitter le flow (P1) 🎯 MVP

**Goal** : ajouter le mode `create` dans l'expand avec push/pop, intégration du `CategoryForm` refondu, et désactivation du footer du sheet pendant la création.

**Independent Test** : expand catégorie → taper un nom inexistant → clic `+ Créer` → form avec nom pré-rempli → valider → catégorie auto-sélectionnée, expand collapse.

#### Extension `CategorySelect` — mode création

- [x] **T-030** [US2] Ajouter le bouton `+ Créer '{terme}'` dans `category-select.html`, conditionnel sur `showCreateButton()`, en dehors du listbox (sémantiquement distinct). — Réf : FR-005
- [x] **T-031** [US2] Ajouter les méthodes `pushToCreate()`, `popToList()`, `submitCategoryForm()`, `onCategoryCreated(cat: Category)` dans `category-select.ts`. `pushToCreate` bascule `mode → 'create'` sans reset de `searchTerm`. `popToList` repasse en `'list'` en conservant `searchTerm` (FR-009). `onCategoryCreated` set value, emit `selected` + `created`, reset `searchTerm`, bascule en `'list'`. — Réf : FR-006, FR-009, FR-010
- [x] **T-032** [US2] Ajouter la branche `@if (mode() === 'create')` / `@else` dans `category-select.html`. Mode create : en-tête d'expand avec `← Retour` (appelle `popToList()`) et `✓ Créer` (appelle `submitCategoryForm()`), suivi de `<app-category-form #formRef [initialName]="searchTerm()" (saved)="onCategoryCreated($event)" (cancelled)="popToList()" />`. — Réf : FR-006, FR-007
- [x] **T-033** [US2] Ajouter `readonly categoryForm = viewChild<CategoryForm>('formRef')` dans `category-select.ts`. `submitCategoryForm()` appelle `this.categoryForm()?.submit()` (guard null). — Réf : FR-007, RES-003, risque R3
- [x] **T-034** [US2] Étendre les styles SCSS pour le mode création : header d'expand (2 boutons inline, `← Retour` secondary + `✓ Créer` primary amber), bouton « + Créer '{terme}' » (style CTA compact). Tokens uniquement. — Réf : FR-007, FR-015, NFR-001
- [x] **T-035** [US2] Étendre `onKeydown` pour que Esc en mode `create` appelle `popToList()` au lieu d'émettre la fermeture de l'expand. — Réf : FR-019

#### Intégration footer parent désactivé (FR-008)

- [x] **T-036** [US2] Dans `transaction-form.html`, ajouter `[disabled]="categoryCreating()"` sur les boutons `Annuler` et `Enregistrer` du `bsheet__bottom-row`. Ajouter reset de `categoryCreating` quand `expandedSection()` sort de `'category'` (via effect ou dans le handler toggle). — Réf : FR-008, contracts.md § contrat intégration
- [x] **T-037** [US2] Adapter `transaction-form.ts` : effect qui surveille `expandedSection()` → si != `'category'`, appeler `categoryCreating.set(false)` (safety net). — Réf : FR-008

#### Tests US2

- [x] **T-038** [P] [US2] Compléter `category-select.spec.ts` avec les tests US2 : `should_show_create_button_when_search_has_no_exact_match`, `should_hide_create_button_when_exact_match_exists`, `should_push_to_create_mode_when_create_button_clicked`, `should_emit_is_creating_true_when_entering_create_mode`, `should_emit_is_creating_false_when_popping_back_to_list`, `should_preserve_search_term_when_popping_back_from_create`, `should_select_and_emit_new_category_when_created_successfully`, `should_not_submit_when_view_not_ready`, `should_display_error_banner_in_expand_when_api_fails` (test d'intégration FR-011 — le banner d'erreur reste visible dans l'expand sans sortir du mode création). — Réf : NFR-005, SC-004, FR-011

**Checkpoint US2** : le flow complet de création inline fonctionne dans `transaction-form`. Footer du sheet désactivé pendant le mode création. Recherche préservée au retour. Création auto-sélectionne la catégorie.

---

### US3 — Filtrer la liste par recherche (P2)

**Goal** : rendre la recherche pleinement opérationnelle avec insensibilité casse/accents.

**Independent Test** : ouvrir l'expand, taper `cafe`, vérifier que `Café` apparaît ; taper `ECO`, vérifier que `économie` apparaît.

- [x] **T-040** [US3] Brancher l'input de recherche au signal `searchTerm` dans `category-select.html` (via `(input)="searchTerm.set($event.target.value)"` ou similaire). Reset `activeIndex` à -1 à chaque changement. — Réf : FR-012
- [x] **T-041** [US3] Vérifier que `filteredCategories` (déjà implémenté en T-022) gère correctement les cas `cafe`/`Café`, `ECO`/`économie`, espacements. Si besoin, ajuster le computed. — Réf : FR-012, SC-005
- [x] **T-042** [P] [US3] Compléter `category-select.spec.ts` avec les tests US3 : `should_filter_categories_when_search_matches_partially`, `should_ignore_case_when_filtering`, `should_ignore_accents_when_filtering`, `should_reset_active_index_on_search_change`. — Réf : NFR-005, SC-005
- [x] **T-043** [US3] Tester la navigation clavier avec wrap : `should_navigate_with_arrow_down_and_up_with_wrap`, `should_select_active_item_on_enter`. — Réf : FR-019, SC-010

**Checkpoint US3** : recherche fonctionnelle avec casse/accents, navigation clavier opérationnelle, tests passent.

---

### US4 — Gérer les catégories depuis Settings sans régression (P2)

**Goal** : confirmer que la refonte de `CategoryForm` + adaptation de `shell.html` (faites en Phase 2) fonctionnent sans régression côté Settings.

**Independent Test** : depuis Settings, créer / modifier / supprimer une catégorie.

> Les tâches de cette US ont été **anticipées en Phase 2** (T-017 à T-019) car elles sont prérequises à la refonte globale du `CategoryForm`. Reste ici la validation finale et les tests.

- [ ] **T-050** [US4] Re-tester manuellement la page Settings après que la Phase 3 (US1-US3) soit intégrée : vérifier que les catégories créées depuis `CategorySelect` apparaissent bien dans la liste Settings (via `refreshTrigger`), et que les CRUD depuis Settings fonctionnent. — Réf : SC-006
- [x] **T-051** [P] [US4] Ajouter un test d'intégration `shell.ts` ou un test manuel documenté dans `docs/manual-test-plan.md` : section « Catégories — Settings » couvrant créer/modifier/supprimer. — Réf : SC-006, US4

**Checkpoint US4** : aucune régression sur Settings. Les deux contextes (Settings et bottom-sheet forms) cohabitent sans interférence.

---

## Phase 4 — Migration & nettoyage

**Objectif** : propager la migration aux 2 autres forms (`subscription-form`, `debt-form`) et supprimer l'ancien composant.

- [x] **T-060** [P] Migrer `subscription-form` selon le même pattern que `transaction-form` : TS (préchargement catégories via `toSignal(getAll())` + signal `categoryCreating` + **effect de reset** de `categoryCreating` quand `expandedSection()` sort de `'category'`, équivalent T-037), HTML (remplacement `app-category-picker` → `app-category-select`, écoute `(isCreating)`, footer `[disabled]="categoryCreating()"` pendant création). — Réf : FR-004, FR-008, US1 AS-4, risque R4
- [x] **T-061** [P] Migrer `debt-form` selon le même pattern, incluant **l'effect de reset** de `categoryCreating` équivalent à T-037. — Réf : FR-004, FR-008, US1 AS-4, risque R4
- [x] **T-062** Grep final : `grep -r "category-picker\|CategoryPicker" app/src` doit renvoyer **0 résultat**. — Réf : FR-016, SC-009
- [x] **T-063** Supprimer le dossier `app/src/app/shared/components/category-picker/` (4 fichiers : `.ts`, `.html`, `.scss`, `.spec.ts`). — Réf : FR-016, FR-017
- [x] **T-064** Lancer `ng lint` → 0 erreur ; `ng build` → OK. — Réf : FR-016

**Checkpoint Phase 4** : les 3 formulaires utilisent `CategorySelect` ; l'ancien `CategoryPicker` n'existe plus dans le code.

---

## Phase 5 — Polish & Documentation

**Objectif** : finitions cross-cutting, documentation design, reviews automatisées.

- [x] **T-070** [P] Ajouter une section « Category Select (inline expand) » dans `DESIGN.md`, symétrique à la section Autocomplete (API, comportement, ARIA). — Réf : §Documentation ticket Linear
- [x] **T-071** [P] Ajouter une session « KKS-231 — Sélecteur de catégorie inline expand » dans `DESIGN-REFONTE.md` (décisions : voie B, option 2 footer, push/pop, persistance recherche, scroll 60vh). — Réf : §Documentation ticket Linear
- [x] **T-072** [P] Exécuter `ng test --code-coverage` et vérifier que `CategorySelect` atteint ≥ 80 % de couverture. — Réf : NFR-005, SC-008
- [x] **T-073** [P] Vérifier l'absence de hex/rgba hardcodés : `grep -rE "#[0-9a-fA-F]{3,8}|rgba?\(" app/src/app/shared/components/category-select/` → 0 résultat. — Réf : NFR-001, SC-007
- [ ] **T-074** Vérifier manuellement l'ARIA : DevTools Accessibility sur un expand catégorie ouvert (US1) et un mode création (US2). — Réf : FR-018
- [ ] **T-075** Test responsive manuel : 320px, 375px, 414px, 768px. Vérifier que l'expand 60vh scrolle correctement et que le footer du sheet reste accessible. — Réf : FR-020, risque R7
- [x] **T-076** Lancer `/design-check` (skill local) — audit cohérence visuelle. — Réf : design-coherence skill
- [x] **T-077** Mettre à jour `docs/manual-test-plan.md` section Angular avec les nouveaux parcours (sélection inline, création inline, désactivation footer). — Réf : NFR-005
- [ ] **T-078** Exécuter la checklist finale de `quickstart.md`. — Réf : quickstart.md

**Checkpoint Phase 5** : documentation à jour, tests passent, couverture OK, aucun warning lint ou token hardcodé.

---

## Phase 6 — Dependencies & Execution Order

### Phase Dependencies

```
Setup (Phase 1)  →  Fondations (Phase 2) ═BLOCK═► User Stories (Phase 3)
                                                    │
                                                    ├─ US1 (P1) ┐
                                                    ├─ US2 (P1) ┼─► Migration (Phase 4) ─► Polish (Phase 5)
                                                    ├─ US3 (P2) ┤
                                                    └─ US4 (P2) ┘
```

### User Story Dependencies

| US | Tâches | Dépend de |
|----|--------|-----------|
| US1 | T-020 → T-029 | Phase 2 complète (T-010 à T-019) |
| US2 | T-030 → T-038 | Phase 2 complète + US1 (T-020 à T-029) pour le squelette `CategorySelect` |
| US3 | T-040 → T-043 | US1 (T-022 déjà posé le computed `filteredCategories`) |
| US4 | T-050 → T-051 | Phase 2 (T-017-T-019) — déjà livrée lors des fondations |

### Graphe de dépendances tâches clés

```
T-010 (string.utils.ts) ─┬─► T-011 (spec) ─[P]
                         └─► T-012 (refactor autocomplete)

T-013 (submit public) ──► T-014 (html) ──► T-015 (scss) ─[P]
                                       └─► T-016 (spec)

T-017 (shell.ts viewChild) ──► T-018 (shell.html footer) ──► T-019 (test manuel Settings)

T-020 (skeleton CategorySelect) ─┬─► T-021 (signals internes)
                                 ├─► T-022 (computed)
                                 ├─► T-023 (html liste) ─[P]
                                 ├─► T-024 (scss) ─[P]
                                 ├─► T-025 (select/keydown)
                                 ├─► T-026 (effect isCreating)
                                 └─► T-027 (tests US1) ─[P]

T-028 (transaction-form ts) ──► T-029 (transaction-form html)

T-020-T-029 ──► T-030 à T-037 (US2) ──► T-038 (tests US2)

T-022 ──► T-040 → T-043 (US3)

T-019 ──► T-050 → T-051 (US4 final)

Phase 4 (migration) ──► Phase 5 (polish)
```

### Parallel Opportunities

| Groupe | Tâches parallélisables | Condition |
|--------|------------------------|-----------|
| G1 (Phase 2 — utils) | T-010, T-011 | Différents fichiers, indépendants |
| G2 (Phase 2 — CategoryForm) | T-015 ([P]), T-016 ([P]) | Après T-013 + T-014 |
| G3 (US1 — création composant) | T-023, T-024, T-027 | Après T-020 + T-021 |
| G4 (US2 — tests) | T-038 en parallèle d'autres US tests | Après T-030-T-037 |
| G5 (US3 — tests et nav) | T-042, T-043 | Après T-041 |
| G6 (Phase 4 — migrations restantes) | T-060 ([P]), T-061 ([P]) | Indépendants ; après US1-US3 dans transaction-form validées |
| G7 (Phase 5 — doc et audits) | T-070, T-071, T-072, T-073 | Tous `[P]` |

### Within Each User Story

- Les **tests** sont écrits en parallèle de l'implémentation (convention Karma + signals — TDD strict non requis par le projet, cf. NFR-005).
- **API publique** (inputs/outputs/signals) **avant** template et styles.
- **Squelette composant** (T-020, T-021) **avant** computed (T-022) et méthodes (T-025).
- **Template HTML + SCSS** parallélisables (fichiers différents).
- **Core implementation** **avant** intégration dans les forms parents (T-028, T-029).

---

## Implementation Strategy

### MVP First (US1 + US2 dans `transaction-form` uniquement)

1. **Phase 1** (T-001) — setup rapide
2. **Phase 2** (T-010 à T-019) — fondations + shell adapté
3. **Phase 3.US1** (T-020 à T-029) — sélection inline fonctionnelle dans `transaction-form`
4. **Phase 3.US2** (T-030 à T-038) — création inline dans `transaction-form`
5. **STOP & VALIDATE** : MVP démontrable sur `transaction-form` — la violation principe #4 DESIGN.md est corrigée sur le parcours critique.
6. Décision : continuer migration ou livrer comme incrément 1.

### Incremental Delivery

| Incrément | Portée | Valeur livrée |
|-----------|--------|---------------|
| **INC-1** (MVP) | Phase 1 + Phase 2 + US1 + US2 sur `transaction-form` | Violation principe #4 corrigée sur le parcours principal. Settings inchangé (US4 validé en Phase 2). |
| **INC-2** | US3 (recherche opérationnelle) | Utilisabilité améliorée pour les utilisateurs avec > 10 catégories. |
| **INC-3** | Phase 4 (migration `subscription-form` + `debt-form` + suppression ancien) | Cohérence complète, dette supprimée. |
| **INC-4** | Phase 5 (polish, doc, audits) | Documentation DS à jour, couverture tests validée, responsive vérifié. |

### Parallel Team Strategy

Avec plusieurs développeurs :

1. Phase 1 + Phase 2 réalisées par un seul dev (cohérence des fondations).
2. Une fois Phase 2 terminée :
   - **Dev A** : US1 (T-020 à T-029)
   - **Dev B** : en attente de skeleton (T-020) puis US3 (T-040 à T-043)
3. Une fois US1 terminée :
   - **Dev A** : US2 (T-030 à T-038)
   - **Dev B** : Phase 4 (T-060 migration subscription-form)
   - **Dev C** : Phase 4 (T-061 migration debt-form)

---

## Mapping Requirements → Tasks

| FR / NFR | Tâches couvrantes |
|----------|-------------------|
| FR-001 | T-020, T-023 |
| FR-002 | T-020, T-025 |
| FR-003 | T-029, T-036 (déjà en place via pattern `expandedSection`) |
| FR-004 | T-028, T-029, T-060, T-061 |
| FR-005 | T-022, T-030 |
| FR-006 | T-031, T-032 |
| FR-007 | T-032, T-033, T-034 |
| FR-008 | T-026, T-036, T-037 |
| FR-009 | T-031 |
| FR-010 | T-031 |
| FR-011 | Hérité du `CategoryForm` existant (banner `errorMessage`, T-013 conserve le comportement) |
| FR-012 | T-010, T-022, T-040, T-041 |
| FR-013 | T-013, T-014, T-015 |
| FR-014 | T-017, T-018 (shell) + T-032 (category-select consomme les outputs) |
| FR-015 | T-015, T-034 |
| FR-016 | T-062, T-063 |
| FR-017 | T-063 (suppression supprime l'import `Modal` associé) |
| FR-018 | T-021, T-023, T-074 |
| FR-019 | T-025, T-035, T-043 |
| FR-020 | T-024, T-075 |
| FR-021 | T-020 (pas de méthode publique d'expand) |
| NFR-001 | T-024, T-034, T-073 |
| NFR-002 | Implicite dans T-020, T-021, T-022 (signals-first) |
| NFR-003 | T-020 (standalone + OnPush dès la création) |
| NFR-004 | Hérité — backend inchangé |
| NFR-005 | T-011, T-016, T-027, T-038, T-042, T-043, T-051, T-072 |
| NFR-006 | T-028, T-060, T-061 (préchargement dans les 3 forms) |
| NFR-007 | Vérifié visuellement (T-075) — implicite pattern `_list-patterns.scss` |

**Tous les FR sont couverts par au moins une tâche.**

---

## Résumé

| Phase | Tâches | Parallélisables (`[P]`) |
|-------|--------|-------------------------|
| Phase 1 — Setup | 1 (T-001) | 0 |
| Phase 2 — Fondations | 10 (T-010 à T-019) | 4 ([P] : T-010, T-011, T-015, T-016) |
| Phase 3 — US1 (P1) | 10 (T-020 à T-029) | 3 ([P] : T-023, T-024, T-027) |
| Phase 3 — US2 (P1) | 9 (T-030 à T-038) | 1 ([P] : T-038) |
| Phase 3 — US3 (P2) | 4 (T-040 à T-043) | 1 ([P] : T-042) |
| Phase 3 — US4 (P2) | 2 (T-050 à T-051) | 1 ([P] : T-051) |
| Phase 4 — Migration | 5 (T-060 à T-064) | 2 ([P] : T-060, T-061) |
| Phase 5 — Polish | 9 (T-070 à T-078) | 4 ([P] : T-070, T-071, T-072, T-073) |
| **Total** | **50 tâches** | **~15 `[P]`** |

| Priorité | Tâches | Couverture |
|----------|--------|------------|
| P1 (US1 + US2) | 19 tâches | FR-001 à FR-012 (cœur fonctionnel) |
| P2 (US3 + US4) | 6 tâches | FR-012 (recherche) + non-régression Settings |
| Fondations + Polish + Migration | 25 tâches | FR-013 à FR-021, NFR-001/005, documentation |

---

## Notes

- `[P]` = fichiers indépendants, aucune dépendance. Peut être lancé en parallèle par plusieurs devs ou plusieurs outils.
- Les tags `[USX]` garantissent la traçabilité aux User Stories et la possibilité de livraison incrémentale.
- Respecter le convention de nommage des tests : `should_[résultat]_when_[condition]`.
- Commit après chaque tâche ou groupe logique (ex : 1 commit par phase ou par US).
- S'arrêter à chaque checkpoint pour valider l'intégrité de la feature en mode incrémental.
- Éviter : tâches vagues, conflits sur le même fichier entre tâches `[P]`, dépendances cross-US qui cassent l'indépendance.
