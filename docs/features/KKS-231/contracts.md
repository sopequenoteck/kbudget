# Contrats techniques — KKS-231 : Refonte du sélecteur de catégorie en bottom-sheet inline

**Date** : 2026-04-18
**Issue** : KKS-231
**Plan** : [plan.md](./plan.md)
**Data model** : [data-model.md](./data-model.md)

---

## Préambule

Feature 100 % frontend Angular. Les contrats portent donc principalement sur :

- Les **interfaces TypeScript** internes (état UI du composant)
- Les **contrats de composants** Angular (inputs / outputs / méthodes publiques)
- Un **helper utilitaire** pur (pas un service)

**Aucun nouvel endpoint** n'est créé. Le contrat `CategoryService` existant est **rappelé** pour traçabilité, mais reste inchangé (cf. data-model.md).

---

## Interfaces & Types

### `CategorySelectMode`

> Réf : FR-006, FR-008

Union type représentant la vue active de l'expand.

```typescript
export type CategorySelectMode = 'list' | 'create';
```

**Invariants** :
- Une seule valeur à la fois — jamais indéfini après init.
- Toute transition `list → create → list` doit préserver `searchTerm` (FR-009).
- Le passage à `'create'` déclenche l'émission `isCreating: true` (FR-008).

---

### `Category` (existante — rappel)

> Réf : FR-001, FR-004, FR-005, FR-012

Définie dans `app/src/app/core/models/category.model.ts`. Consommée en lecture seule par `CategorySelect`, en lecture/écriture par `CategoryForm` (via `CategoryService`).

```typescript
export interface Category {
  id: string;        // UUID serveur
  nom: string;       // 1-30 caractères, unique par user
  icone: string;     // emoji unicode
  couleur: string;   // hex #RRGGBB depuis CATEGORY_COLORS
}

export interface CategoryRequest {
  nom: string;
  icone: string;
  couleur: string;
}
```

**Invariants** :
- `nom` unique par user authentifié (contrainte backend).
- `icone` et `couleur` non vides à la création (validé côté `CategoryForm`).

---

### `CategorySelectState` (nouveau — état UI interne)

> Réf : FR-006, FR-009, FR-018, FR-019, FR-021

Cet « état » n'est pas une classe ni une interface compilée — il correspond à l'ensemble des signals exposés dans l'implémentation du composant. Il est documenté ici pour fixer le contrat de comportement interne.

```typescript
// Ces signals ne sont PAS exposés publiquement (privés au composant).
// Ils décrivent le modèle mental du composant.
interface CategorySelectInternalState {
  mode: Signal<CategorySelectMode>;                    // 'list' par défaut
  searchTerm: Signal<string>;                          // '' par défaut, conservé au pop
  activeIndex: Signal<number>;                         // -1 par défaut, pour navigation clavier
  readonly listboxId: string;                          // unique par instance (ARIA)
  readonly filteredCategories: Signal<Category[]>;     // computed de categories + searchTerm
  readonly hasExactMatch: Signal<boolean>;             // computed
  readonly showCreateButton: Signal<boolean>;          // computed (recherche non vide sans match)
}
```

**Invariants** :
- `activeIndex` borné à `[-1, filteredCategories.length - 1]` avec wrap.
- `listboxId` unique par instance (pattern `category-select-listbox-${random}`, cf. Autocomplete).
- Un effect émet `isCreating: output` à chaque changement de `mode` (source unique de vérité : `mode()`).
- `ngOnDestroy` : le composant reset `mode → 'list'` pour émettre `isCreating: false` si détruit en plein mode create (mitigation R4).

---

## Contrats composants

### `CategorySelect`

> Réf : FR-001 à FR-012, FR-018 à FR-021

| Aspect | Détail |
|--------|--------|
| Responsabilité | Sélecteur inline de catégorie pour bottom-sheet, avec recherche et création inline |
| Fichier | `app/src/app/shared/components/category-select/category-select.ts` |
| Decorators | `@Component({ standalone: true, changeDetection: ChangeDetectionStrategy.OnPush })` |
| Type | Dumb component — ne gère pas sa propre visibilité ; rendu inline par le form parent |
| ControlValueAccessor | **Oui** — implémente `ControlValueAccessor` pour compatibilité `formControlName` |

**Inputs** :

| Nom | Type | Requis | Valeur par défaut | Description |
|-----|------|--------|-------------------|-------------|
| `categories` | `input<Category[]>` | Non | `[]` | Liste complète, préchargée par le form parent via `toSignal(getAll())` (RES-004) |

**Outputs** :

| Nom | Payload | Description |
|-----|---------|-------------|
| `selected` | `string` (ID catégorie) | Émis à chaque sélection (existante ou nouvellement créée). Collapse l'expand côté parent via le signal `expandedSection`. |
| `created` | `Category` | Émis uniquement à la création réussie d'une nouvelle catégorie. Permet au parent d'alimenter son cache si nécessaire. |
| `isCreating` | `boolean` | Émis à chaque bascule `list ↔ create`. Le parent l'écoute pour désactiver `bsheet__bottom-row` (FR-008). |

**ControlValueAccessor — méthodes** :

| Méthode | Comportement |
|---------|--------------|
| `writeValue(value: string \| null): void` | Met à jour l'ID interne de la catégorie sélectionnée |
| `registerOnChange(fn: (value: string) => void): void` | Enregistre le callback ReactiveForms |
| `registerOnTouched(fn: () => void): void` | Enregistre le callback touched |
| `setDisabledState(isDisabled: boolean): void` | Active/désactive l'interaction |

**Méthodes publiques (non-CVA)** : aucune. Le composant est piloté par ses inputs et le parent.

**Méthodes internes (privées, non exposées)** :

| Méthode | Rôle |
|---------|------|
| `selectCategory(id: string): void` | Sélectionne une catégorie de la liste, émet `selected`, update CVA |
| `pushToCreate(): void` | Bascule en mode `create`, préserve `searchTerm` |
| `popToList(): void` | Revient en mode `list` en conservant `searchTerm` |
| `submitCategoryForm(): void` | Déclenche `categoryForm()?.submit()` via `viewChild` |
| `onCategoryCreated(cat: Category): void` | Handle succès création : `value`/`created`/`selected` + collapse |
| `onKeydown(e: KeyboardEvent): void` | Gère ↑ / ↓ / Enter / Esc (FR-019) |

**Accessibilité (FR-018)** :

| Élément | Attributs ARIA |
|---------|----------------|
| Input recherche | `role="combobox"`, `aria-autocomplete="list"`, `aria-expanded`, `aria-controls="{listboxId}"`, `aria-activedescendant` |
| Conteneur liste | `role="listbox"`, `id="{listboxId}"` |
| Item catégorie | `role="option"`, `id="{listboxId}-option-{i}"`, `aria-selected` |
| Bouton création | `<button type="button">` standard (hors du listbox, sémantiquement distinct) |

**Comportement clavier (FR-019)** :

| Touche | Mode `list` | Mode `create` |
|--------|-------------|---------------|
| ↓ / ↑ | Navigation `activeIndex` avec wrap | Tab standard |
| Enter | Sélectionne l'item actif si `activeIndex ≥ 0` | Soumet le form (Enter-to-submit) |
| Esc | Émis au parent (fermeture expand au niveau form) | `popToList()` |

**Contrat de désactivation** : quand `setDisabledState(true)` est appelé, ni la recherche, ni la navigation, ni la création ne doivent être possibles. Le DOM est fonctionnellement inerte (CSS `pointer-events: none` acceptable).

---

### `CategoryForm` (refondu)

> Réf : FR-013, FR-014, FR-015

| Aspect | Détail |
|--------|--------|
| Responsabilité | Formulaire de création/édition de catégorie (3 champs : nom, icône, couleur) |
| Fichier | `app/src/app/shared/components/category-form/category-form.ts` |
| Decorators | `@Component({ standalone: true, changeDetection: ChangeDetectionStrategy.OnPush })` |
| Type | Form component réutilisable — footer externalisé, piloté par le parent |

**Inputs** (inchangés) :

| Nom | Type | Requis | Valeur par défaut | Description |
|-----|------|--------|-------------------|-------------|
| `category` | `input<Category \| null>` | Non | `null` | Mode édition si fourni, création sinon |
| `initialName` | `input<string>` | Non | `''` | Nom pré-rempli en mode création (utilisé par `CategorySelect` pour injecter `searchTerm`) |

**Outputs** (inchangés) :

| Nom | Payload | Description |
|-----|---------|-------------|
| `saved` | `Category` | Émis après sauvegarde réussie (création ou mise à jour) |
| `cancelled` | `void` | Émis sur annulation explicite par l'utilisateur (via parent) |

**Méthodes publiques** (⚠️ changement) :

| Méthode | Signature | Description |
|---------|-----------|-------------|
| `submit()` | `async submit(): Promise<void>` | **Nouvelle méthode publique** (renommage de `onSubmit()`). Valide le form, appelle `CategoryService.create()` ou `update()`, émet `saved` ou met à jour `errorMessage`. Appelable via `viewChild<CategoryForm>`. |

**Méthodes internes retirées** :

- `onSubmit()` — renommée en `submit()` publique.
- `onCancel()` — l'émission `cancelled` est désormais déclenchée par le parent qui câble son propre bouton « Annuler » (plus de bouton interne au form).

**Signals exposés (lecture)** :

| Signal | Type | Usage |
|--------|------|-------|
| `submitting` | `Signal<boolean>` | Lu par le parent pour `[disabled]` du bouton submit externe |
| `isEditMode` | `boolean` (getter) | Lu par le parent pour afficher « Créer » vs « Modifier » |
| `errorMessage` | `Signal<string>` | Lu dans le template via banner d'erreur interne (inchangé) |

**Contrat de compatibilité `shell.html`** :

Le `shell.ts` utilise `viewChild<CategoryForm>('categoryFormRef')` et déclenche `submit()` depuis son propre bouton dans la Modal. Le test `category-form.spec.ts` doit couvrir :

- `should_emit_saved_when_submit_called_publicly`
- `should_update_error_message_when_api_fails`
- `should_not_submit_when_form_invalid`

**Template HTML** : `<form (ngSubmit)="submit()">` est conservé pour Enter-to-submit. Aucun `<button type="submit">` interne.

---

### Consommation de `CategorySelect` dans les 3 forms parents

> Réf : FR-003, FR-004, FR-008, US1 AS-4

Contrat d'intégration identique pour `transaction-form`, `subscription-form`, `debt-form`.

| Aspect | Détail |
|--------|--------|
| Localisation | Remplace `<app-category-picker>` dans le `bsheet__expand` `@if (expandedSection() === 'category')` |
| Binding sélection | `formControlName="categoryId"` (CVA) |
| Binding données | `[categories]="categories()"` (préchargé via `toSignal(categoryService.getAll())`) |
| Écoute mode création | `(isCreating)="categoryCreating.set($event)"` |
| Désactivation footer | `[disabled]="categoryCreating()"` sur boutons de `bsheet__bottom-row` |

**Signal parent attendu** :

```typescript
// Dans transaction-form.ts, subscription-form.ts, debt-form.ts
readonly categories = toSignal(this.categoryService.getAll(), {
  initialValue: [] as Category[],
});
readonly categoryCreating = signal(false);
```

**Reset attendu** : quand `expandedSection()` bascule de `'category'` vers autre chose, `categoryCreating` doit être remis à `false` (via `effect` ou dans le handler de toggle). Garantit que le footer du sheet n'est jamais bloqué en état stale.

---

## Contrats utils

### `normalize(s: string): string`

> Réf : FR-012, RES-001

| Aspect | Détail |
|--------|--------|
| Responsabilité | Normalise une chaîne pour comparaison insensible à la casse et aux accents |
| Fichier | `app/src/app/shared/utils/string.utils.ts` |
| Type | Fonction pure, pas de service, pas d'état |

**Signature** :

```typescript
export function normalize(s: string): string;
```

**Comportement** :

| Entrée | Sortie |
|--------|--------|
| `'Abonnement'` | `'abonnement'` |
| `'Café'` | `'cafe'` |
| `'ÉCONOMIE'` | `'economie'` |
| `''` | `''` |
| `'  Espace  '` | `'  espace  '` (pas de trim — responsabilité de l'appelant) |

**Implémentation de référence** :

```typescript
export function normalize(s: string): string {
  return s.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
}
```

**Invariants** :
- Idempotente : `normalize(normalize(s)) === normalize(s)`.
- Pas d'allocation inutile : prévue pour être appelée dans des computed signals.
- Ne modifie jamais l'espacement ou la ponctuation — seulement la casse et les diacritiques.

---

## Contrats services (rappel)

### `CategoryService` (existant — inchangé)

> Réf : FR-001, FR-004, FR-010, FR-011

| Aspect | Détail |
|--------|--------|
| Responsabilité | Accès REST aux endpoints `/categories` |
| Fichier | `app/src/app/core/services/category.ts` |
| Injection | `providedIn: 'root'` |

**Méthodes consommées par cette feature** :

| Méthode | Paramètres | Retour | Erreurs | Usage |
|---------|------------|--------|---------|-------|
| `getAll()` | — | `Observable<Category[]>` | HTTP 401, 500 | Précharge des catégories dans les 3 forms (FR-001) |
| `create(request)` | `CategoryRequest` | `Observable<Category>` | HTTP 400 (validation), 409 (duplicate), 500 | Création inline depuis l'expand (FR-010). Déclenche `refreshTrigger` automatiquement. |

**Signal d'invalidation** :

| Signal | Type | Usage |
|--------|------|-------|
| `refreshTrigger` | `Signal<number>` | Incrémenté par `create()`/`update()`/`delete()`. Les forms parents peuvent y souscrire via `effect` pour rafraîchir leur cache de catégories si nécessaire. |

**Aucune modification** n'est apportée à ce service dans le cadre de KKS-231.

---

## API Endpoints (rappel)

Aucun nouvel endpoint créé. Les endpoints existants consommés sont :

| Méthode | Path | Auth | Usage |
|---------|------|------|-------|
| GET | `/api/categories` | JWT | Chargement de la liste (via `CategoryService.getAll()`) |
| POST | `/api/categories` | JWT | Création (via `CategoryService.create()` depuis `CategoryForm.submit()`) |

Contrats détaillés de ces endpoints : voir `docs/api-examples.md` (inchangé).

---

## Traçabilité FR → Contrat

| FR | Contrat |
|----|---------|
| FR-001 | `CategorySelect` — conteneur inline + `categories: input` |
| FR-002 | `CategorySelect` — output `selected` |
| FR-003 | Contrat d'intégration dans forms parents — pattern `expandedSection` |
| FR-004 | Contrat d'intégration — remplacement `category-picker` par `category-select` |
| FR-005 | `CategorySelect` — computed `showCreateButton` + template conditionnel |
| FR-006 | `CategorySelect` — méthode `pushToCreate()` + `CategoryForm.initialName` input |
| FR-007 | `CategorySelect` — template mode `create` avec `← Retour` / `✓ Créer` |
| FR-008 | `CategorySelect` — output `isCreating` + contrat d'intégration `[disabled]` footer |
| FR-009 | `CategorySelect` — `popToList()` sans reset de `searchTerm` |
| FR-010 | `CategorySelect` — `onCategoryCreated` : emit `selected` + collapse |
| FR-011 | `CategoryForm` — banner `errorMessage` conservé |
| FR-012 | `normalize()` util + `CategorySelect` computed `filteredCategories` |
| FR-013 | `CategoryForm` — suppression footer interne, `submit()` public |
| FR-014 | `CategoryForm` — outputs `saved`/`cancelled` + contrat parents (shell.html + category-select) |
| FR-015 | `CategoryForm` — tokens CSS, swatches `--primary-border` (implémentation) |
| FR-016 | Aucun contrat — suppression de `category-picker` (vide de contrat) |
| FR-017 | Aucun contrat — suppression de l'import `Modal` associé |
| FR-018 | `CategorySelect` — table ARIA documentée |
| FR-019 | `CategorySelect` — table clavier documentée |
| FR-020 | `CategorySelect` — contrat implicite `max-height: 60vh` + `overflow-y: auto` (cf. plan §3.3) |
| FR-021 | `CategorySelect` — type « dumb component », aucune méthode publique de contrôle d'expand |

Tous les FRs sont tracés à un contrat.

---

## Résumé

| Type | Nombre |
|------|--------|
| Interfaces & Types | 3 (`CategorySelectMode`, `Category` (rappel), `CategorySelectInternalState`) |
| API Endpoints | 0 nouveaux (2 rappels) |
| Contrats composants | 2 (`CategorySelect`, `CategoryForm` refondu) + 1 contrat d'intégration (3 forms parents) |
| Contrats utils | 1 (`normalize`) |
| Contrats services | 0 nouveaux (1 rappel : `CategoryService`) |
| FR couverts | 21 / 21 |
