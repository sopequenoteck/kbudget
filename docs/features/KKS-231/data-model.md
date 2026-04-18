# Data Model — KKS-231 : Refonte du sélecteur de catégorie en bottom-sheet inline

**Date** : 2026-04-18
**Spec** : [spec.md](./spec.md)
**Plan** : [plan.md](./plan.md)

---

## Préambule

Cette feature n'introduit **aucune entité de persistance**. La seule entité serveur concernée, `Category`, est inchangée (pas de nouveau champ, pas de nouvelle table, pas de migration SQL). Ce document documente :

1. Le typage TypeScript de l'état UI interne du composant `CategorySelect` (`CategorySelectState`).
2. Un rappel du contrat `Category` tel qu'il est déjà consommé via `CategoryService`.

Aucune migration backend n'est requise.

## Entités

### Category (existante — inchangée)

Type côté frontend défini dans `app/src/app/core/models/category.model.ts`.

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | `string` | UUID, PK serveur | Identifiant unique |
| `nom` | `string` | 1-30 caractères, requis | Libellé affiché |
| `icone` | `string` | requis, emoji unicode | Emoji illustratif (30x30 rendu) |
| `couleur` | `string` | hex `#RRGGBB`, pris dans `CATEGORY_COLORS` | Couleur visuelle |

**Invariants (serveur)** :
- `nom` est unique par user authentifié.
- `couleur` et `icone` sont obligatoires à la création (validé côté form via `selectedEmoji`/`selectedColor` non vides).

**Accès** : via `CategoryService` (`core/services/category.ts`). Endpoints consommés :
- `GET /categories` — liste complète pour le user authentifié (utilisé par le préchargement dans les 3 forms parents).
- `POST /categories` — création (utilisé par `CategoryForm.submit()`).
- `PUT /categories/{id}` et `DELETE /categories/{id}` — utilisés hors scope de ce ticket (page Settings).

### CategorySelectState (nouvelle — typage UI interne)

État UI local au composant `app-category-select`. Jamais persisté, jamais partagé.

| Champ | Type | Valeur initiale | Description |
|-------|------|-----------------|-------------|
| `mode` | `'list' \| 'create'` | `'list'` | Vue active dans l'expand |
| `searchTerm` | `string` | `''` | Terme de recherche actuel (conservé au push/pop) |
| `selectedId` | `string \| null` | `null` | ID de la catégorie sélectionnée (`null` = aucune) |
| `activeIndex` | `number` | `-1` | Index de l'option highlightée (navigation clavier) |
| `listboxId` | `string` | `\`category-select-listbox-${random}\`` | ID unique pour ARIA (évite conflits multi-instances) |

**Invariants (UI)** :
- Si `mode === 'create'`, l'interface cache la liste et affiche `CategoryForm`.
- `searchTerm` survit aux transitions `list → create → list` (FR-009).
- `activeIndex` est borné à `[-1, filteredCategories.length - 1]` avec wrap à la navigation clavier.
- Quand `mode` change, un `effect` émet `isCreating: (mode === 'create')` au parent (FR-008).

**Implémentation** : signals Angular (`signal()`, `computed()`), pas de classe — chaque champ est un signal indépendant dans le composant.

## Relations

```
Form parent (transaction/subscription/debt-form)
   │ précharge
   ▼
CategoryService.getAll() → signal Category[]
   │ injecté via [categories]
   ▼
CategorySelect  ───emits selected───►  Form parent (patch control)
   │                                     │
   │ ───emits isCreating───►  Form parent (disable bottom-row)
   │
   │ en mode 'create'
   ▼
CategoryForm (viewChild)
   │ submit() async → CategoryService.create()
   │ ───emits saved───►  CategorySelect.onCategoryCreated()
   │                        │
   │                        ▼
   │                     émet 'selected' + 'created'
```

| Relation | Type | Cardinalité | Contrainte |
|----------|------|-------------|------------|
| Form parent → CategorySelect | Composition Angular | 1:1 par pill catégorie | Le parent détient le signal `expandedSection` pilotant le rendu |
| CategorySelect → CategoryForm | Composition via viewChild | 1:1 en mode `create` | Le form n'existe DOM que si `mode === 'create'` |
| CategorySelect → CategoryService | Aucune (dumb) | N/A | Le service est injecté côté parent uniquement |

## Contraintes globales

| # | Contrainte | Type | Entités concernées |
|---|-----------|------|-------------------|
| DC-001 | `selectedId` DOIT correspondre à un ID présent dans `categories()` *ou* à `null` | Invariant UI | CategorySelectState, Category |
| DC-002 | Après `CategoryService.create()` succès, la nouvelle catégorie DOIT être ajoutée à la liste parent (via `refreshTrigger` existant ou rechargement explicite) avant `selected` emission | Cohérence UI | CategorySelectState, Category |
| DC-003 | `searchTerm` ne DOIT pas être reset en `popToList()` (sauf explicite) | Invariant UX | CategorySelectState |
| DC-004 | `isCreating` émis DOIT refléter strictement `mode === 'create'` (pas d'émission parasite) | Contrat d'output | CategorySelectState |

## Migrations

**Aucune migration SQL n'est requise.**

L'entité `Category` côté serveur (`api/src/main/java/fr/kksdev/budget/api/model/Category.java` et sa table) reste strictement inchangée. Aucun endpoint n'est ajouté ni modifié. Les seuls changements sont côté `app/` (frontend Angular).

## Index

**Aucun nouvel index requis.**

Le filtre de recherche s'exécute **côté client** sur la liste déjà chargée (`filteredCategories` computed dans `CategorySelect`). Pas de requête serveur par caractère tapé, donc pas de besoin d'index `pg_trgm` ou `unaccent` comme pour KKS-230.
