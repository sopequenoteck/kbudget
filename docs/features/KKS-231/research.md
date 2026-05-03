# Research — KKS-231 : Refonte du sélecteur de catégorie en bottom-sheet inline

**Date** : 2026-04-18
**Spec** : `docs/features/KKS-231/spec.md`
**Clarify** : `docs/features/KKS-231/clarify-log.md`
**Constitution** : `.specify/memory/constitution.md` (7 principes)

## Résumé

Feature 100 % frontend Angular. Les questions UX/fonctionnelles ont été tranchées en `/devflow.clarify` (5 points). Ce document traite les **inconnues techniques** restantes, toutes vérifiées par lecture du codebase.

| # | Inconnue | Domaine | Décision |
|---|----------|---------|----------|
| RES-001 | Helper `normalize` (NFD + diacritiques) — extraction ou duplication | Refactor partagé | Extraire dans `shared/utils/string.utils.ts` |
| RES-002 | Communication `mode création → footer parent` (W-002) | Architecture composant | Output `isCreating: output<boolean>` |
| RES-003 | Soumission du `CategoryForm` depuis parent externe | Architecture composant | `viewChild()` + méthode publique `submit()` |
| RES-004 | Stratégie de chargement des catégories (W-004) | Performance / cache | Parent précharge, passe via `categories = input<Category[]>()` |
| RES-005 | Réutilisation de l'animation expand | DX / patterns | Réutiliser `shared/animations/expand-collapse.ts` |
| RES-006 | Animation push/pop liste ↔ création dans l'expand | UX | Pas d'animation (YAGNI) |
| RES-007 | Pattern ARIA pour `CategorySelect` | Accessibilité | Réplication du pattern `Autocomplete` (KKS-230) |
| RES-008 | Refonte `CategoryForm` — stratégie d'externalisation footer | Architecture composant | Externalisation complète (suppression de `category-form__actions`) |

**Nouvelles dépendances** : aucune.
**Nouveaux fichiers shared** : `shared/utils/string.utils.ts` (extraction helper).
**Impacts hors scope immédiat** : `autocomplete.ts` perd sa fonction locale `normalize` au profit du helper partagé (refactor minimal, 1 import + 1 suppression).

---

## Inconnues techniques identifiées

| # | Domaine | Question | Criticité |
|---|---------|----------|-----------|
| RES-001 | Refactor partagé | Le helper `normalize` est inline dans `autocomplete.ts:21-26`. Le dupliquer dans `CategorySelect` ou l'extraire ? | Haute |
| RES-002 | Architecture composant | Comment `CategorySelect` (dumb) communique-t-il son mode création au form parent pour désactiver le footer du sheet ? | Haute (W-002) |
| RES-003 | Architecture composant | Comment soumettre le `CategoryForm` depuis un parent qui câble son propre bouton « ✓ Créer » (footer externalisé) ? | Haute |
| RES-004 | Performance / cache | Les catégories sont-elles rechargées à chaque ouverture d'expand ? Comment éviter une requête réseau bloquante ? | Haute (W-004) |
| RES-005 | DX / patterns | L'animation d'ouverture/fermeture de l'expand réutilise-t-elle l'animation existante ou en faut-il une nouvelle ? | Basse |
| RES-006 | UX | Quand l'expand passe en mode création (push), faut-il une animation ? | Basse |
| RES-007 | Accessibilité | Quel pattern ARIA adopter pour un composant « liste + recherche + création inline » ? | Moyenne |
| RES-008 | Architecture composant | Comment refondre `CategoryForm` pour qu'il serve les 2 consommateurs (`category-select` inline + `shell.html` Modal) sans duplication ? | Haute |

---

## Décisions techniques

### RES-001 — Extraction du helper `normalize` (NFD + diacritiques)

**Contexte**
Le helper `normalize(s: string): string` est aujourd'hui défini localement dans `autocomplete.ts:21-26` :

```ts
function normalize(s: string): string {
  return s.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
}
```

Il sera nécessaire dans `CategorySelect` pour le filtre de recherche (FR-012). Deux copies ou extraction partagée ?

**Options évaluées**

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Duplication locale dans `category-select.ts` | Zéro impact hors scope. YAGNI. | Duplication de code identique (DRY violé). | ⚠️ Acceptable mais fragile |
| B — Extraction dans `shared/utils/string.utils.ts` | DRY respecté. Pattern ready pour d'autres composants futurs. Modif de `autocomplete.ts` minimale (1 ligne). | Touche à un fichier hors scope direct du ticket. | ✅ Retenu |
| C — Créer une pipe Angular `NormalizePipe` | Utilisable dans les templates. | Overkill : on ne l'utilise pas dans des templates, seulement dans du code TS. | ❌ |

**Décision** : Option B — extraire dans un shared util.

**Rationale**
- La fonction est pure, sans état, sans dépendance framework. Elle mérite d'être dans `shared/utils/`.
- Le refactor d'`autocomplete.ts` est minimal (1 import + suppression de la fonction locale), faible risque de régression.
- Aligne sur le principe de simplicité (constitution #3) sans créer d'abstraction prématurée — c'est juste une fonction déplacée.
- Ouvre la porte à une utilisation future sans dette technique immédiate.

**Impact sur le plan** : créer `app/src/app/shared/utils/string.utils.ts`, y exporter `normalize`, mettre à jour `autocomplete.ts` (import + usage). Ajouter un test unitaire minimal du helper.

---

### RES-002 — Communication « mode création » → footer du sheet parent

**Contexte**
FR-008 impose que le footer du bottom-sheet parent (`bsheet__bottom-row` avec `Annuler` / `Enregistrer`) soit désactivé pendant le mode création de catégorie — mais reste visible. Le composant `CategorySelect` est `dumb` (FR-021) : il ne gère pas sa propre visibilité. Comment informe-t-il le form parent qu'il est en train de créer une catégorie, pour que le form désactive son footer ?

**Options évaluées**

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Output `isCreating = output<boolean>()` émis à chaque changement de mode | Idiomatique signals-first. Découplage parent/enfant clair. Testable isolément. | Parent doit conserver un state local miroir (signal `isCategoryCreating`). | ✅ Retenu |
| B — `viewChild<CategorySelect>()` + lecture publique d'un signal `mode` | Pas d'output à gérer. | Viole l'encapsulation (parent lit l'état interne de l'enfant). Difficile à tester. | ❌ |
| C — Service partagé `CategoryCreationStore` | État centralisé. | Overkill pour 1 feature. Ajoute une injection, complique le test. Contredit la constitution #3 (YAGNI). | ❌ |
| D — Two-way via `model<boolean>()` sur le composant | Signals-first. | Sémantique confuse : ce n'est pas un modèle bidirectionnel, c'est un événement de changement d'état. | ❌ |

**Décision** : Option A — output `isCreating: output<boolean>`.

**Rationale**
- Cohérent avec le reste du projet : `Autocomplete` émet `selected` et `queryChange` en output ; `InlineDatePicker` utilise `model()` pour la valeur, mais ses changements d'état internes ne sortent pas (cas non pertinent ici).
- Le parent détient la vérité du footer du sheet (il est dans son template, lui-même pilote `bsheet__bottom-row`) — il est logique qu'il soit l'abonné, pas le propriétaire.
- Permet une suite de tests unitaires simples : `fixture.componentRef.instance.onCreateClicked(); expect(emittedValues).toEqual([true]);`.

**Impact sur le plan**
- Le form parent (`transaction-form.ts` etc.) ajoute un `signal categoryCreating = signal(false)` et un handler `(isCreating)="categoryCreating.set($event)"`.
- Le template du form applique `[disabled]="categoryCreating()"` sur les boutons du `bsheet__bottom-row`.

---

### RES-003 — Soumission du `CategoryForm` depuis un parent externe

**Contexte**
Actuellement `CategoryForm` possède `<form (ngSubmit)="onSubmit()">` avec un `<button type="submit">` dans son footer (`category-form.html:45-47`). Après externalisation du footer (FR-013), le bouton submit disparaît — mais `onSubmit()` reste la bonne méthode à appeler (elle gère la validation, le try/catch, les signaux `submitting`/`errorMessage` et émet `(saved)`). Comment le parent déclenche-t-il cette méthode depuis son propre footer externe ?

**Options évaluées**

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — `viewChild(CategoryForm)` + méthode publique `submit()` sur `CategoryForm` | API claire (`categoryFormRef()?.submit()`). Signals-first via `viewChild`. Typage fort. | Nécessite d'exposer explicitement une méthode publique. | ✅ Retenu |
| B — Template reference `#categoryForm` + `categoryForm.onSubmit()` | Pas de viewChild. | Moins signals-first. Template-based coupling. | ⚠️ Acceptable |
| C — Input trigger `submitRequest: input<number>()`, `effect()` déclenche submit | Pure signals. | Anti-pattern : utiliser un compteur comme signal d'événement complique le mental model. | ❌ |
| D — Service partagé événement bus | Découple complètement. | Overkill — deux composants toujours rendus ensemble. | ❌ |

**Décision** : Option A — `viewChild()` + méthode publique `submit()`.

**Rationale**
- Signals-first est la convention active du projet (CLAUDE.md). `viewChild()` est l'API signals-first (Angular 17.3+).
- Renommer `onSubmit()` (handler DOM) en `submit()` (méthode publique) clarifie la sémantique : c'est désormais une API publique du composant.
- Le form HTML garde son `(ngSubmit)` sur la submit du form (si l'utilisateur appuie Enter dans un champ, la soumission fonctionne aussi), ce qui appelle la même méthode publique.
- Idiomatique Angular moderne. Lisible dans les tests (`await fixture.whenStable(); categoryFormRef.submit();`).

**Impact sur le plan**
- `CategoryForm` expose `async submit(): Promise<void>` (renommage de `onSubmit()`).
- `CategorySelect` et `shell.html` utilisent `viewChild<CategoryForm>()` + déclenchent `submit()` sur clic du bouton externalisé.
- Maintenir `(ngSubmit)` dans le HTML pour Enter-to-submit.

---

### RES-004 — Stratégie de chargement des catégories

**Contexte**
NFR-006 exige une ouverture instantanée de l'expand. Or `transaction-form.html:93` utilise `@if (expandedSection() === 'category')` — si le composant fils se charge les catégories lui-même au mount (comme `CategoryPicker` actuel via `toSignal(getAll())`), chaque ouverture d'expand provoque un démount/remount → nouvelle requête réseau à chaque clic.

**Options évaluées**

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Parent précharge via `toSignal(getAll())` et passe via `categories = input<Category[]>()` | CategorySelect = vraiment dumb. Parent contrôle le cache. Une seule requête par ouverture du form. | Léger couplage parent ↔ composant (3 forms à mettre à jour). | ✅ Retenu |
| B — `CategorySelect` gère son propre chargement comme actuel `CategoryPicker` | Zéro impact sur les forms parents. | Requête à chaque @if → violation NFR-006. Régression par rapport au comportement actuel (`CategoryPicker` subit déjà ce problème). | ❌ |
| C — `CategoryService` cache au niveau service, expose signal partagé | Cache global, une seule requête pour toute la session. | Change l'API de `CategoryService` (hors scope). Risque de stale data entre writes. | ⚠️ À long terme mais out of scope |
| D — Cache côté composant via `provideInExistingZone` + shareReplay | Complexité RxJS accrue. | Contredit la consigne signals-first. | ❌ |

**Décision** : Option A — parent précharge.

**Rationale**
- Respecte FR-021 (dumb component) littéralement.
- Élimine les requêtes redondantes. Cohérent avec le pattern adopté pour `Autocomplete` (suggestions passées en input par le parent).
- Impact limité : 3 forms à modifier, chacun ajoute 1 ligne `readonly categories = toSignal(this.categoryService.getAll(), { initialValue: [] });`.
- Si cache global devient nécessaire plus tard (Option C), migration triviale (on remplace `getAll()` par le signal du service).

**Impact sur le plan**
- `CategorySelect` : `readonly categories = input<Category[]>([])`.
- 3 forms parents : injection `CategoryService` et préchargement via `toSignal()`. Vérifier qu'ils n'injectent pas déjà le service (nombre probable d'instances à créer : 0-3, selon l'existant).
- Ajoute une assumption A-006 dans spec.md : « les 3 forms parents préchargent les catégories via `toSignal(getAll())` au mount ».

---

### RES-005 — Animation d'ouverture/fermeture de l'expand

**Contexte**
L'expand catégorie dans le form parent utilise déjà `@expandCollapse` (`transaction-form.html:94`). Faut-il modifier l'animation ou réutiliser telle quelle ?

**Décision** : Réutiliser `shared/animations/expand-collapse.ts` sans modification.

**Rationale**
- Animation déjà testée sur les 4 autres expands de `transaction-form` (category, recurring, note, date, account). Cohérence visuelle garantie.
- `maxHeight: 500px` dans l'animation (`expand-collapse.ts:6`) est compatible avec le `max-height: 60vh` de la liste catégories (FR-020) : la liste scrolle, l'animation cadre le contenant.

**Impact sur le plan** : aucun. Juste `animations: [expandCollapse]` dans le composant parent (déjà présent).

---

### RES-006 — Animation push/pop liste ↔ création

**Contexte**
Quand l'utilisateur clique « + Créer '{terme}' », le contenu de l'expand change. Animer ce changement (crossfade, slide) ou le rendre brut ?

**Options évaluées**

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Pas d'animation | Simple. YAGNI. Zéro risque de jank perçu. | Changement abrupt. | ✅ Retenu |
| B — Crossfade 150ms | Doux. Réutilise des tokens existants. | Complexifie le component, nécessite une animation dédiée. | ❌ |
| C — Slide horizontal façon wizard | Expressif. | Overkill. Nouvelle animation à créer. Peut créer du mal de mer sur mobile. | ❌ |

**Décision** : Option A — rendu brut.

**Rationale**
- Constitution #3 (YAGNI) : pas d'effet visuel sans demande explicite.
- L'utilisateur sait ce qu'il fait en cliquant sur un bouton « + Créer » — la transition brutale est *informative* (confirme que l'action a été prise).
- Peut être ajoutée plus tard si retour utilisateur le demande.

**Impact sur le plan** : aucun.

---

### RES-007 — Pattern ARIA pour `CategorySelect`

**Contexte**
FR-018 impose un ARIA cohérent avec `Autocomplete`. Le composant est un hybride « liste + recherche + bouton création » qui ne correspond pas exactement à un combobox standard.

**Analyse du pattern `Autocomplete` existant** (`autocomplete.ts:47-219`)

- `role="combobox"` sur l'input de recherche
- `aria-autocomplete="list"` sur l'input
- `aria-expanded` binding sur `isOpen()`
- `aria-controls` pointe vers l'id du listbox
- `aria-activedescendant` pointe vers l'id de l'option active
- `role="listbox"` sur le conteneur `<ul>`
- `role="option"` sur chaque `<li>`
- ID unique généré par instance pour éviter les conflits multi-instances (pattern `autocomplete-listbox-${random}`)

**Décision** : répliquer ce pattern dans `CategorySelect`.

**Rationale**
- Pattern déjà validé en review (KKS-230), testé (spec Angular), et accessible.
- La nature du composant (liste avec recherche) se mappe parfaitement sur `combobox + listbox`.
- Le bouton « + Créer '{terme}' » peut rester en dehors du listbox (simple `<button>`), sémantiquement distinct.
- Pendant le mode création, le listbox et combobox sont remplacés par le formulaire → rien de spécial côté ARIA (c'est juste un autre arbre DOM).

**Impact sur le plan** : recopier l'approche d'ID unique + les attributs ARIA. Pas de nouvelle dépendance.

---

### RES-008 — Stratégie d'externalisation du footer `CategoryForm`

**Contexte**
Le `CategoryForm` actuel a un footer interne (`category-form__actions`, `category-form.html:43-48`) utilisé par ses deux consommateurs :
1. `category-picker` (via Modal) — à supprimer dans ce ticket.
2. `shell.html:101-107` (Modal de gestion globale) — à conserver.

Trois options pour la refonte :

**Options évaluées**

| Option | Avantages | Inconvénients | Score |
|--------|-----------|---------------|-------|
| A — Supprimer totalement `category-form__actions`. Les 2 consommateurs câblent leur propre footer | Architecture propre. Un seul contrat composant (outputs). Cohérent avec la décision de sparring « refonte globale ». | Modifie `shell.html` (ajout footer custom dans la Modal). | ✅ Retenu |
| B — Garder le footer interne, ajouter `hideInternalFooter: input<boolean>(false)` | Zéro impact sur `shell.html`. | Paramétrage conditionnel (`@if`). Contredit la décision sparring (« pas de paramétrage »). Deux chemins de submit (interne + viewChild) à maintenir. | ❌ |
| C — Duplication locale : créer un `CategoryFormCompact` pour l'expand, garder `CategoryForm` intact | Zéro risque pour `shell`. | Duplication condamnée en sparring (cf. résumé clarify). | ❌ |

**Décision** : Option A — externalisation totale.

**Rationale**
- Respecte la décision de sparring (refonte globale, outputs `(save)` / `(cancel)` sont la seule API).
- Le `shell.html` câble son propre footer dans son `<app-modal>`. Ajout de 2 boutons (`Annuler`, `Créer`/`Modifier`) + wiring via `viewChild(CategoryForm)` pour déclencher `submit()`.
- Cohérent avec FR-014 (« les consommateurs câblent leurs propres actions »).
- Le template du form HTML garde `(ngSubmit)="submit()"` pour Enter-to-submit (préserve le comportement clavier utilisateur).

**Impact sur le plan**
- Suppression de `category-form__actions` dans `category-form.html`.
- Méthode publique `submit()` remplace `onSubmit()`.
- `shell.html` ajoute un footer custom dans la branche `@case ('category')` de sa Modal — 2 boutons + wiring viewChild.
- `shell.ts` ajoute `readonly categoryFormRef = viewChild<CategoryForm>('categoryFormRef');` + méthode déclenchant le submit.
- Tests : le test existant `category-form.spec.ts` devra être mis à jour (plus de bouton dans le template du form).

---

## Analyse du codebase

### Patterns existants identifiés (réutilisés)

- **`Autocomplete`** (`shared/components/autocomplete/`) — pattern signals-first avec CVA, ARIA combobox, navigation clavier, filtre case/accent-insensible. Modèle direct pour `CategorySelect`.
- **`InlineDatePicker`** (`shared/components/inline-date-picker/`) — dumb component rendu dans un `bsheet__expand`, piloté par le parent. Modèle d'intégration pour `CategorySelect`.
- **`expandCollapse`** (`shared/animations/expand-collapse.ts`) — animation partagée pour les sections expand.
- **`expandedSection` signal** (`transaction-form.ts:120,295`) — pattern single-expand parent. Déjà en place dans les 3 forms cibles.
- **`CategoryService`** (`core/services/category.ts`) — expose `getAll()`, `create()`, `update()`, `delete()`, `refreshTrigger`. Pas de changement nécessaire.
- **`EmojiInput`** (`shared/components/emoji-input/`) — utilisé dans `CategoryForm`. Inchangé.
- **`CATEGORY_COLORS` et `randomColor()`** (`core/constants/category.constants.ts`) — palette utilisée par `CategoryForm`. Inchangé.

### Fichiers nouveaux à créer

| Fichier | Rôle |
|---------|------|
| `app/src/app/shared/utils/string.utils.ts` | Helper `normalize` extrait (+ test unitaire) |
| `app/src/app/shared/components/category-select/category-select.ts` | Nouveau composant |
| `app/src/app/shared/components/category-select/category-select.html` | Template |
| `app/src/app/shared/components/category-select/category-select.scss` | Styles (tokens uniquement) |
| `app/src/app/shared/components/category-select/category-select.spec.ts` | Tests unitaires |

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `app/src/app/shared/components/autocomplete/autocomplete.ts` | Import helper partagé, suppression fonction locale |
| `app/src/app/shared/components/category-form/category-form.ts` | `onSubmit()` → méthode publique `submit()` |
| `app/src/app/shared/components/category-form/category-form.html` | Suppression de `category-form__actions` (boutons) |
| `app/src/app/shared/components/category-form/category-form.scss` | Nettoyage styles actions orphelines |
| `app/src/app/shared/components/category-form/category-form.spec.ts` | Adaptation tests (boutons retirés, test submit via viewChild) |
| `app/src/app/shared/components/shell/shell.ts` | `viewChild<CategoryForm>` + méthode submit externe |
| `app/src/app/shared/components/shell/shell.html` | Ajout footer custom dans `@case ('category')` de la Modal |
| `app/src/app/features/transactions/components/transaction-form/*` | Remplace `CategoryPicker` par `CategorySelect` + préchargement catégories + écoute `(isCreating)` |
| `app/src/app/features/subscriptions/components/subscription-form/*` | Idem |
| `app/src/app/features/debts/components/debt-form/*` | Idem |
| `DESIGN.md`, `DESIGN-REFONTE.md` | Documentation de la nouvelle section |

### Fichiers à supprimer

| Fichier | Raison |
|---------|--------|
| `app/src/app/shared/components/category-picker/category-picker.ts` | Remplacé par `CategorySelect` |
| `app/src/app/shared/components/category-picker/category-picker.html` | idem |
| `app/src/app/shared/components/category-picker/category-picker.scss` | idem |
| `app/src/app/shared/components/category-picker/category-picker.spec.ts` | idem |

### Dépendances techniques

| Dépendance | Version | Usage prévu | Risque |
|------------|---------|-------------|--------|
| `@angular/core` | 19+ | `signal`, `computed`, `input`, `output`, `viewChild`, `effect` | Aucun |
| `@angular/forms` | 19+ | `ReactiveFormsModule` pour `CategoryForm` | Aucun |
| `@angular/animations` | 19+ | Animation `expandCollapse` réutilisée | Aucun |

**Aucune nouvelle dépendance externe.**

---

## Risques techniques identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| `autocomplete.ts` casse en retirant la fonction `normalize` locale | Basse | Moyen (tests autocomplete cassent) | Test unitaire sur `normalize` partagé + run de `autocomplete.spec.ts` après refactor |
| `shell.html` footer custom rompt l'UX de gestion des catégories depuis Settings | Moyenne | Haut (US4 non-régression) | Ajouter un test manuel explicite dans SC-006 avant merge. Test visuel sur les 3 parcours (créer/modifier/supprimer) |
| `viewChild` appelle `submit()` avant que `CategoryForm` soit rendu (initial rendering) | Basse | Moyen (null check) | Signal `viewChild` retourne `undefined` si pas encore rendu. Guard `this.categoryFormRef()?.submit()` dans le handler. |
| Le préchargement des catégories dans 3 forms crée une duplication de `toSignal(getAll())` | Basse | Bas | Acceptable en phase v1. Refactor vers un shared service cache possible si 5+ consommateurs (YAGNI). |
| Le mode création → `isCreating` ne se reset pas si l'utilisateur ferme le bottom-sheet pendant création | Basse | Moyen (footer du prochain sheet potentiellement disabled) | `ngOnDestroy` reset `isCreating` à `false`. Tester en spec. |

---

## Résumé

| Métrique | Valeur |
|----------|--------|
| Inconnues identifiées | 8 |
| Décisions prises | 8 |
| Nouvelles dépendances | 0 |
| Patterns réutilisés | 6 (Autocomplete, InlineDatePicker, expandCollapse, expandedSection, CategoryService, EmojiInput) |
| Nouveaux fichiers | 5 (string.utils + 4 category-select) |
| Fichiers modifiés | 9 |
| Fichiers supprimés | 4 (category-picker complet) |
| Risques identifiés | 5 (tous mitigés) |

**Next step** : `/devflow.plan KKS-231` — construire le plan technique détaillé à partir de ces décisions.
