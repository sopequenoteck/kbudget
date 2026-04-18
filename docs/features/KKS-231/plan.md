# Implementation Plan — KKS-231 : Refonte du sélecteur de catégorie en bottom-sheet inline

**Branch** : `feature/KKS-231`
**Date** : 2026-04-18
**Spec** : [spec.md](./spec.md)
**Research** : [research.md](./research.md)
**Clarify** : [clarify-log.md](./clarify-log.md)

## Summary

Feature 100 % frontend Angular. Remplacer le sélecteur de catégorie actuel (`app-category-picker` → `app-select-picker`) par un nouveau composant `app-category-select` intégré en *inline expand* dans le pattern bottom-sheet, conformément au principe #4 de `DESIGN.md` (surface modale unique). Le composant sera un *dumb component* piloté par le form parent via le signal `expandedSection` existant (pattern `InlineDatePicker`). La création de catégorie est inline (push/pop dans l'expand). Le `CategoryForm` est refondu globalement avec externalisation du footer via outputs `(save)`/`(cancel)` + méthode publique `submit()` ; son second consommateur (`shell.html`) câble son propre footer. Migration des 3 formulaires (`transaction-form`, `subscription-form`, `debt-form`) et suppression du composant obsolète. Aucun changement backend, aucune nouvelle dépendance.

## Technical Context

**Language/Version** : TypeScript 5.9 / Angular 21+
**Primary Dependencies** : `@angular/core` (signals — `signal`, `computed`, `input`, `output`, `viewChild`, `effect`), `@angular/forms` (ReactiveForms), `@angular/animations` (`expandCollapse` existant)
**Storage** : N/A (état UI en signals locaux, persistance serveur via `CategoryService` existant)
**Testing** : Karma + Jasmine (suite `ng test`), ESLint + Prettier
**Target Platform** : PWA Angular, usage mobile-first (bottom sheet)
**Project Type** : Web application (frontend Angular — backend Spring Boot inchangé)
**Performance Goals** : ouverture d'expand instantanée (NFR-006 — catégories préchargées par le form parent, aucune requête réseau bloquante à l'ouverture)
**Constraints** : tokens CSS uniquement, standalone + OnPush, signals-first strict (CLAUDE.md)
**Scale/Scope** : impact sur 3 formulaires en bottom-sheet + 1 page Settings (non-régression). 5 fichiers créés, 9 modifiés, 4 supprimés.

## Constitution Check

Gate de vérification contre les 7 principes de `.specify/memory/constitution.md` (v2.1.2).

| # | Principe | Statut | Justification |
|---|----------|--------|---------------|
| I | API-First | ✅ N/A | Aucun endpoint créé ou modifié. Utilisation des endpoints `CategoryService` existants (`GET /categories`, `POST /categories`). |
| II | Sécurité par défaut | ✅ PASS | Pas de nouvelle surface d'attaque. L'isolation par user authentifié est garantie par les endpoints backend existants (inchangés). Pas de secrets hardcodés. |
| III | Simplicité & YAGNI | ✅ PASS | Composant minimal sans sur-ingénierie. Pas de service partagé, pas d'abstraction prématurée. Extraction du helper `normalize` justifiée (déjà dupliqué de fait). |
| IV | Mobile-First UX | ✅ PASS renforcé | La feature améliore l'UX mobile en supprimant l'empilement de bottom-sheets. Cible directe du principe : saisie en 2-3 interactions (SC-002). |
| V | Testabilité | ✅ PASS | Tests unitaires prévus sur `CategorySelect`, adaptation de `category-form.spec.ts`, test unitaire du helper `normalize`. Nommage `should_[résultat]_when_[condition]`. |
| VI | Observabilité | ✅ N/A | Pas de logs métier côté frontend (principe backend). Les erreurs API restent loggées côté Spring. |
| VII | Self-Hosted Ready | ✅ PASS | Aucune nouvelle dépendance externe. Pas d'appel à service SaaS. |

**Dérogations** : aucune. Le plan respecte intégralement la constitution.

Re-check après Phase 1 (design) : sans objet — aucun point de design ne génère de violation.

## Project Structure

### Documentation (this feature)

```text
docs/features/KKS-231/
├── plan.md              ← ce document
├── spec.md              ← spec validée (review-spec PASS)
├── research.md          ← 8 décisions techniques
├── clarify-log.md       ← 5 clarifications résolues, 5 différées
├── data-model.md        ← typage CategorySelectState (Phase 1)
├── quickstart.md        ← guide démarrage (Phase 1)
├── review-log.md        ← journal des reviews
├── state.json           ← état du workflow
└── tasks.md             ← à générer via /devflow.tasks (hors scope plan)
```

### Source Code (repository root)

```text
app/src/app/
├── shared/
│   ├── utils/
│   │   └── string.utils.ts                        # C  (helper normalize extrait)
│   ├── animations/
│   │   └── expand-collapse.ts                     # —  (inchangé, réutilisé)
│   └── components/
│       ├── autocomplete/
│       │   └── autocomplete.ts                    # M  (import normalize depuis utils)
│       ├── category-form/
│       │   ├── category-form.ts                   # M  (onSubmit → submit public)
│       │   ├── category-form.html                 # M  (suppression actions)
│       │   ├── category-form.scss                 # M  (nettoyage styles actions)
│       │   └── category-form.spec.ts              # M  (tests adaptés)
│       ├── category-select/                       # C  (nouveau composant complet)
│       │   ├── category-select.ts
│       │   ├── category-select.html
│       │   ├── category-select.scss
│       │   └── category-select.spec.ts
│       ├── category-picker/                       # D  (supprimé)
│       └── shell/
│           ├── shell.ts                           # M  (viewChild CategoryForm + submit)
│           └── shell.html                         # M  (footer custom dans Modal catégorie)
└── features/
    ├── transactions/components/transaction-form/  # M  (3 fichiers)
    ├── subscriptions/components/subscription-form/# M  (3 fichiers)
    └── debts/components/debt-form/                # M  (3 fichiers)

DESIGN.md                                          # M  (section Category Select)
DESIGN-REFONTE.md                                  # M  (session KKS-231)
```

Légende : **C** = à créer, **M** = à modifier, **D** = à supprimer.

**Structure Decision** : respecte la convention Angular existante (`shared/components/[kebab-case]/`, `features/[domain]/components/[form]/`). Pas de nouveau sous-répertoire.

## Approche par composant

### 1. Fondations partagées

**Objectif** : préparer les briques utilisées par le reste du plan.

#### 1.1. Helper `normalize` partagé (RES-001)

- **FR couverts** : FR-012 (filtre insensible à la casse/accents).
- **Fichier C** : `app/src/app/shared/utils/string.utils.ts`
- **Contenu** : fonction pure `normalize(s: string): string` copiée de `autocomplete.ts:21-26` (lowercase + `NFD` + suppression diacritiques).
- **Test unitaire** : nouveau `string.utils.spec.ts` avec cas nominaux (minuscules, accents, combinaisons, chaîne vide).
- **Refactor associé** : `autocomplete.ts` importe depuis le shared util, supprime la fonction locale. Lancer `autocomplete.spec.ts` pour vérifier zéro régression.

#### 1.2. Refonte `CategoryForm` — externalisation du footer (RES-003, RES-008)

- **FR couverts** : FR-013, FR-014, FR-015.
- **Fichiers M** :
  - `category-form.ts` : renommer `onSubmit()` → `submit()` (méthode publique). Garder le handler `async`, le `try/catch`, les signaux `submitting`/`errorMessage`, l'émission `(saved)`.
  - `category-form.html` : supprimer la section `category-form__actions` (lignes 43-48). Conserver `<form [formGroup]="form" (ngSubmit)="submit()">` pour Enter-to-submit.
  - `category-form.scss` : supprimer le bloc `.category-form__actions` orphelin. Ajuster spacing autour du dernier champ (padding-bottom à ajouter sur `.category-form__field` dernier enfant, ou retrait du margin-top de `__actions`).
  - `category-form.spec.ts` : adapter les tests qui sélectionnent les boutons internes ; ajouter un test `should_emit_saved_when_submit_called_publicly`.
- **Pas de nouveaux inputs** : le composant reste paramétré par `category = input<Category | null>()` et `initialName = input<string>('')`.
- **Alignement visuel** : pas de changement SCSS majeur dans cette tâche — la refonte visuelle du form (swatches, espacements) est reportée à la section 3.3 (visuel du nouveau composant), uniquement ce qui est nécessaire pour le contexte bottom-sheet.

### 2. Adaptation `shell.html` (non-régression)

**Objectif** : câbler le footer externe pour la Modal de gestion des catégories depuis Settings (US4).

- **FR couverts** : FR-014, US4.
- **Fichier M** : `shell.ts`, `shell.html`.
- **Modifications `shell.ts`** :
  - Ajouter `readonly categoryFormRef = viewChild<CategoryForm>('categoryFormRef');`
  - Ajouter `readonly categoryFormSubmitting = signal(false);` (relié au `submitting()` interne via `effect()`, ou simple passthrough via viewChild lecture)
  - Méthode `triggerCategorySubmit(): void { this.categoryFormRef()?.submit(); }`
- **Modifications `shell.html`** dans `@case ('category')` de la Modal :
  ```html
  <app-category-form
    #categoryFormRef
    [category]="$any(modalService.editingEntity())"
    (saved)="onModalClose()"
    (cancelled)="onModalClose()"
  />
  <div class="modal__actions">
    <button type="button" class="btn-outline" (click)="onModalClose()">Annuler</button>
    <button
      type="button"
      class="btn-primary"
      (click)="triggerCategorySubmit()"
      [disabled]="categoryFormRef()?.submitting()"
    >
      {{ categoryFormRef()?.isEditMode ? 'Modifier' : 'Créer' }}
    </button>
  </div>
  ```
- **Risque** (R1 de research.md) : régression visuelle sur Settings. **Mitigation** : SC-006 + test manuel explicite avant merge (créer / modifier / supprimer).
- **Note** : on garde temporairement les classes legacy `btn-outline` / `btn-primary` dans cette tâche — la refonte visuelle globale des boutons de Modal est hors scope de ce ticket (cohérence avec le design system actuel, qui les utilise encore).

### 3. Nouveau composant `CategorySelect`

**Objectif** : composant dédié inline bottom-sheet (liste + recherche + création inline).

- **FR couverts** : FR-001 à FR-012, FR-018, FR-019, FR-020, FR-021.
- **Fichier C** : `app/src/app/shared/components/category-select/category-select.{ts,html,scss,spec.ts}`

#### 3.1. API publique (RES-002, RES-004)

Signals-first strict, symétrique à `Autocomplete` + `InlineDatePicker` :

```ts
readonly value = model<string>('');            // ID catégorie sélectionnée
readonly categories = input<Category[]>([]);   // liste préchargée par le parent
readonly selected = output<string>();          // émet l'ID à la sélection
readonly created = output<Category>();         // émet la nouvelle catégorie après création
readonly isCreating = output<boolean>();       // émis à chaque bascule list ↔ create
```

#### 3.2. État interne

```ts
readonly mode = signal<'list' | 'create'>('list');
readonly searchTerm = signal<string>('');
readonly activeIndex = signal<number>(-1);
readonly listboxId = `category-select-listbox-${Math.random().toString(36).slice(2)}`;
```

Computed :
```ts
readonly filteredCategories = computed(() => {
  const q = normalize(this.searchTerm());
  if (!q) return this.categories();
  return this.categories().filter((c) => normalize(c.nom).includes(q));
});
readonly hasExactMatch = computed(() => {
  const q = normalize(this.searchTerm());
  return !q || this.categories().some((c) => normalize(c.nom) === q);
});
readonly showCreateButton = computed(() => this.searchTerm().length > 0 && !this.hasExactMatch());
```

Effect signalant le mode au parent :
```ts
constructor() {
  effect(() => this.isCreating.emit(this.mode() === 'create'));
}
```

#### 3.3. Template (`category-select.html`)

Deux branches principales via `@if (mode() === 'list')` / `@else`.

**Branche `list`** :
- Champ de recherche (input combobox, ARIA `role="combobox"`, `aria-autocomplete="list"`, `aria-expanded="true"`, `aria-controls="{{listboxId}}"`)
- Scroll interne (FR-020) : `<div class="cs__list" role="listbox" [id]="listboxId" [style.max-height]="'60vh'" [style.overflow-y]="'auto'">`
- `@for` sur `filteredCategories()`, chaque item avec `role="option"`, icône catégorie, nom, état highlight
- Bouton « + Créer '{searchTerm()}' » (FR-005) affiché via `showCreateButton()`, en dehors du listbox

**Branche `create`** :
- En-tête d'expand : `← Retour` (appelle `popToList()`) | `✓ Créer` (appelle `submitCategoryForm()`)
- `<app-category-form #formRef [initialName]="searchTerm()" (saved)="onCategoryCreated($event)" (cancelled)="popToList()" />`
- Le `#formRef` permet à `submitCategoryForm()` d'appeler `formRef.submit()`.

#### 3.4. Méthodes

```ts
readonly categoryForm = viewChild<CategoryForm>('formRef');

selectCategory(id: string): void {
  this.value.set(id);
  this.selected.emit(id);
}

pushToCreate(): void {
  this.mode.set('create');
  // searchTerm est déjà défini, il sera utilisé comme initialName
}

popToList(): void {
  this.mode.set('list');
  // searchTerm est CONSERVÉ (FR-009)
}

submitCategoryForm(): void {
  this.categoryForm()?.submit();
}

onCategoryCreated(cat: Category): void {
  this.created.emit(cat);
  this.value.set(cat.id);
  this.selected.emit(cat.id);
  this.searchTerm.set('');
  this.mode.set('list');
}
```

#### 3.5. Navigation clavier (FR-019, RES-007)

Handler `onKeydown(event: KeyboardEvent)` sur l'input de recherche :
- `ArrowDown` / `ArrowUp` : incrémente/décrémente `activeIndex` avec wrap
- `Enter` : si `activeIndex >= 0` → `selectCategory(filteredCategories()[activeIndex].id)` ; sinon pas d'effet (permet à Enter de submit le form dans `Autocomplete` mais ici on n'a pas besoin)
- `Escape` : émet un signal de fermeture — mais comme le composant est *dumb*, il appelle en fait `popToList()` (si en mode create) ou laisse le parent fermer l'expand (pas de mécanisme interne). Le parent form écoute via sa propre logique. **Simplification** : Escape uniquement actif en mode `create` pour pop vers list ; en mode `list`, le parent gère la fermeture de l'expand (`transaction-form.ts:295`).

#### 3.6. Styles (`category-select.scss`)

Tokens CSS uniquement (NFR-001). Classes BEM `.cs__*`. Pattern de liste dérivé de `_list-patterns.scss` (icon-circle 36px, title sm/secondary). Refonte minimale du form de création (spacing, swatches avec `--primary-border` actif) — partie "alignement design" de FR-015.

**Aucun hex/rgba hardcodé.**

#### 3.7. Tests unitaires (`category-select.spec.ts`) (NFR-005)

Cas à couvrir (convention `should_[résultat]_when_[condition]`) :
- `should_render_all_categories_when_search_is_empty`
- `should_filter_categories_when_search_matches_partially`
- `should_ignore_case_and_accents_when_filtering`
- `should_show_create_button_when_search_has_no_exact_match`
- `should_hide_create_button_when_exact_match_exists`
- `should_push_to_create_mode_when_create_button_clicked`
- `should_emit_is_creating_true_when_entering_create_mode`
- `should_emit_is_creating_false_when_popping_back_to_list`
- `should_preserve_search_term_when_popping_back_from_create`
- `should_select_and_emit_new_category_when_created_successfully`
- `should_collapse_and_emit_selected_when_category_clicked`
- `should_navigate_with_arrow_down_and_up_with_wrap`
- `should_select_active_item_on_enter`
- `should_render_with_correct_aria_attributes`
- `should_apply_max_height_on_list_container`

### 4. Migration des 3 formulaires

**Objectif** : remplacer `CategoryPicker` par `CategorySelect` dans les 3 bottom-sheets, précharger les catégories, écouter `isCreating`.

- **FR couverts** : FR-003, FR-004, FR-008, US1 AS-4.
- **Fichiers M** : pour chaque `{transaction,subscription,debt}-form.{ts,html,scss}` :

#### 4.1. Modifications `.ts`

```ts
// Ajouter (si pas déjà fait)
private readonly categoryService = inject(CategoryService);
readonly categories = toSignal(this.categoryService.getAll(), { initialValue: [] as Category[] });
readonly categoryCreating = signal(false);
```

Handler `onCategoryChange(id: string)` pour bind à la sélection si nécessaire (sinon bind via formControl direct sur `value` du composant).

#### 4.2. Modifications `.html`

Remplacer :
```html
<app-category-picker formControlName="categoryId" />
```

Par :
```html
<app-category-select
  [(value)]="categoryId"
  [categories]="categories()"
  (selected)="onCategorySelected($event)"
  (isCreating)="categoryCreating.set($event)"
/>
```

Note sur reactive forms : `CategorySelect` utilise `model()`, pas CVA. Pour garder la compatibilité avec les ReactiveForms existants :
- **Option retenue** : ajouter CVA sur `CategorySelect` (`providers: [NG_VALUE_ACCESSOR]` + `writeValue/registerOnChange/registerOnTouched`), cohérent avec `Autocomplete` et `CategoryPicker` actuel. L'usage `formControlName="categoryId"` fonctionne donc comme avant.

Donc le HTML reste :
```html
<app-category-select
  formControlName="categoryId"
  [categories]="categories()"
  (isCreating)="categoryCreating.set($event)"
/>
```

Désactiver les boutons du footer quand création en cours :
```html
<div class="bsheet__bottom-row">
  <button ... [disabled]="categoryCreating()">Annuler</button>
  <button ... [disabled]="categoryCreating() || form.invalid">Enregistrer</button>
</div>
```

#### 4.3. Modifications `.scss`

- Suppression de tout style lié à `app-category-picker` si présent (probablement aucun).
- Vérification que le `bsheet__expand` ne contraint pas la hauteur interne (sinon `max-height: 60vh` du composant ne s'applique pas).

### 5. Suppression de l'ancien

- **FR couverts** : FR-016, FR-017.
- **Fichiers D** :
  - `app/src/app/shared/components/category-picker/category-picker.ts`
  - `app/src/app/shared/components/category-picker/category-picker.html`
  - `app/src/app/shared/components/category-picker/category-picker.scss`
  - `app/src/app/shared/components/category-picker/category-picker.spec.ts`
- **Vérification** : grep `category-picker|CategoryPicker` dans `app/` — aucun résultat attendu après migration.
- **Modal inutile** : `ModalService` et `Modal` restent en usage ailleurs, pas de suppression.

### 6. Documentation

- **FR couverts** : §Documentation du ticket Linear.
- **DESIGN.md** : ajouter une section « Category Select (inline expand) » après la section Autocomplete (`DESIGN.md:118-133`) avec contrat signals-first, comportement, intégration dans bottom-sheet, ARIA.
- **DESIGN-REFONTE.md** : ajouter une session « KKS-231 — Sélecteur de catégorie inline expand » (décisions sparring : voie B, option 2 footer, push/pop, persistance recherche, scroll 60vh).

## Couverture FR → composants

| FR | Couvert par |
|----|-------------|
| FR-001 | §3 `CategorySelect` — conteneur inline |
| FR-002 | §3.4 `selectCategory()` + `(selected)` output |
| FR-003 | §4 — pattern `expandedSection` existant, déjà en place |
| FR-004 | §4 — remplacement dans les 3 forms |
| FR-005 | §3.2 `showCreateButton` computed + §3.3 template |
| FR-006 | §3.4 `pushToCreate()` + `[initialName]="searchTerm()"` |
| FR-007 | §3.3 en-tête d'expand en mode `create` |
| FR-008 | §3 effect `isCreating.emit()` + §4 désactivation footer parent |
| FR-009 | §3.4 `popToList()` conserve `searchTerm` |
| FR-010 | §3.4 `onCategoryCreated()` — select + collapse |
| FR-011 | Conservé depuis `CategoryForm` actuel (`errorMessage` banner) |
| FR-012 | §3.2 `filteredCategories` avec helper `normalize` |
| FR-013 | §1.2 suppression `category-form__actions` |
| FR-014 | §2 `shell.html` câble son footer + §4 forms câblent `isCreating` |
| FR-015 | §1.2 + §3.6 (alignement visuel) |
| FR-016 | §5 suppression |
| FR-017 | §5 — import `Modal` retiré de `category-picker` supprimé |
| FR-018 | §3.3 attributs ARIA |
| FR-019 | §3.5 navigation clavier |
| FR-020 | §3.3 style `max-height: 60vh` + `overflow-y: auto` |
| FR-021 | §3.1 API — aucun mécanisme interne d'expand |

Tous les FRs sont couverts.

## Couverture des WARNING de review-spec

| WARNING | Résolution dans le plan |
|---------|------------------------|
| W-001 (CL-007 clic hors expand) | **Comportement par défaut assumé** : perte silencieuse (YAGNI). Si l'utilisateur ferme le bottom-sheet pendant le mode création, l'état `isCreating` est reset via `ngOnDestroy`. Aucune confirmation. Documenté ici, à vérifier en manual test plan. |
| W-002 (mécanisme `isCreating`) | Résolu : output `isCreating: output<boolean>` (RES-002) + écoute côté parent (§4.2). |
| W-003 (SC-002 ambiguïté) | À reformuler lors de `/devflow.tasks` : « une fois le bottom-sheet ouvert, ≤ 2 taps pour sélectionner une catégorie existante ». |
| W-004 (NFR-006 cache catégories) | Résolu : le form parent précharge via `toSignal(getAll())` au mount (RES-004). Si cache froid au premier mount, un court spinner peut apparaître — acceptable (< 100ms attendus). |
| I-001 (US4 AS-3 suppression) | SC-006 couvre déjà « créer, modifier, supprimer ». Ajouter AS-4 optionnel lors de `/devflow.tasks`. |
| I-002 (`selectedId: string \| null`) | Corrigé dans data-model.md. |
| I-003 (ARIA SC) | Ajouter SC-011 ou étendre SC-010 lors de `/devflow.tasks`. |
| I-004 (empty state CL-006) | **Comportement par défaut assumé** : empty state minimal « Aucune catégorie — créez-en une » + CTA `+ Créer` affiché d'office. À valider en `/devflow.tasks`. |

## Risques & mitigations

| # | Risque | Prob. | Impact | Mitigation |
|---|--------|-------|--------|------------|
| R1 | `autocomplete.ts` casse après retrait du `normalize` local | Basse | Moyen | Test unitaire du helper partagé + run `autocomplete.spec.ts` avant commit |
| R2 | Régression UX de la Modal catégorie depuis Settings (US4) | Moyenne | Haut | SC-006 + test manuel explicite (créer/modifier/supprimer) avant merge |
| R3 | `viewChild(CategoryForm).submit()` appelé avant rendering | Basse | Moyen | Guard `this.categoryFormRef()?.submit()` + test `should_not_submit_when_view_not_ready` |
| R4 | État `isCreating` non reset si sheet fermé pendant création | Basse | Moyen | `ngOnDestroy` reset `mode` → `'list'` + émission `isCreating: false` |
| R5 | Duplication `toSignal(getAll())` dans 3 forms | Basse | Bas | Acceptable en v1. Refactor vers shared service cache si 5+ consommateurs (YAGNI) |
| R6 | CVA sur `CategorySelect` incompatible avec `model()` en parallèle | Moyenne | Moyen | Choisir une seule approche : CVA complet (pattern `Autocomplete`) pour compat ReactiveForms. `model` interne non exposé publiquement. |
| R7 | Scroll interne 60vh mal rendu si `bsheet__expand` a `max-height` plus restrictive | Moyenne | Moyen | Tester sur 3 viewports (small phone 320px, regular 375px, large 414px). Vérifier que l'expand peut grandir jusqu'à 60vh |

## Hors scope (rappel)

- ❌ Refonte du `SelectPicker` générique (reste utilisé hors bottom-sheet).
- ❌ Ajout de champs au `CategoryForm` (parent, budget, ordre, hiérarchie).
- ❌ Changement backend (API, DTOs, validation, migrations).
- ❌ Support de catégories hiérarchiques dans le select.
- ❌ Flutter (hors scope de ce ticket).
- ❌ Refonte visuelle globale des boutons Modal (`btn-outline`/`btn-primary` legacy conservés).
- ❌ Virtualisation de la liste (YAGNI tant que < 30 catégories par user).

## Complexity Tracking

Aucune violation de la constitution ; aucune complexité à tracker.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Artefacts complémentaires

- `research.md` — 8 décisions techniques avec rationale (déjà produit)
- `data-model.md` — typage `CategorySelectState` et contrat `Category` (Phase 1)
- `quickstart.md` — guide de démarrage pas à pas (Phase 1)
- `contracts/` — à générer via `/devflow.contracts` (contrats d'interface composant si nécessaire)
- `tasks.md` — à générer via `/devflow.tasks` (phase 2)
