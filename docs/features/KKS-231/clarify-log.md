# Clarify Log — KKS-231

**Feature** : Refonte du sélecteur de catégorie en bottom-sheet inline
**Date** : 2026-04-18
**Spec analysée** : `docs/features/KKS-231/spec.md`

## Résumé

| Métrique | Valeur |
|----------|--------|
| Points identifiés | 10 |
| Catégories couvertes | 4 / 11 (UX/Interaction, Scope fonctionnel, Intégrations, Edge cases) |
| Résolus automatiquement | 4 |
| Résolus interactivement | 1 |
| Différés | 5 |
| Modifications spec.md | Edge Cases (2 résolus, 2 différés, 1 neutre) ; FR-020 et FR-021 ajoutés ; Assumptions A-001/A-002/A-004 passées à « validé » ; table « Questions ouvertes » restructurée (statut + résolution) |

## Taxonomie et scoring

| # | Point | Source | Catégorie | Impact | Incertitude | Score | Résolution |
|---|-------|--------|-----------|--------|-------------|-------|------------|
| CL-001 | Scroll de la liste (hauteur max vs expand qui grandit) | spec.md §Edge Cases, §Questions ouvertes | 3. UX/Interaction | Haut | Haute | **CRITIQUE** | Interactif |
| CL-002 | Mécanisme single-expand (parent vs service) | spec.md §Edge Cases, §Questions ouvertes, A-001 | 3. UX/Interaction | Haut | Haute | **CRITIQUE** | Auto |
| CL-003 | Consommateurs effectifs de `CategoryForm` | spec.md A-002 | 1. Scope fonctionnel | Haut | Basse | **HAUT** | Auto |
| CL-004 | Backend change requis ou non | spec.md A-004 | 5. Intégrations | Haut | Basse | **HAUT** | Auto |
| CL-005 | API `InlineDatePicker` comme modèle | spec.md A-001 | 5. Intégrations | Haut | Basse | **HAUT** | Auto |
| CL-006 | Empty state si aucune catégorie | spec.md §Edge Cases | 3. UX/Interaction | Moyen | Moyenne | **MOYEN** | Différé |
| CL-007 | Clic hors expand pendant création | spec.md §Edge Cases | 6. Edge cases | Moyen | Haute | **HAUT** | Différé |
| CL-008 | Tolérance de `shell.html` à l'externalisation du footer | spec.md A-005 | 1. Scope fonctionnel | Moyen | Moyenne | **MOYEN** | Différé (couvert par CL-003) |
| CL-009 | Volume moyen de catégories par user | spec.md A-003 | 4. Non-fonctionnel | Bas | Moyenne | **BAS** | Différé |
| CL-010 | Comportement de création offline | spec.md §Edge Cases | 6. Edge cases | Bas | Moyenne | **BAS** | Différé (couvert par FR-011) |

Tri par score décroissant : CRITIQUE × 2 → HAUT × 3 → MOYEN × 2 → BAS × 2 (avec 1 HAUT différé car 5 places déjà consommées). Top 5 résolu.

## Détail des résolutions

### CL-001 — Scroll de la liste (CRITIQUE, résolu interactif)

- **Catégorie** : UX/Interaction (3)
- **Impact** : Haut — affecte directement l'utilisabilité dès qu'un utilisateur dépasse ~10 catégories. Détermine aussi la contrainte visuelle du bottom-sheet (hauteur stable ou variable).
- **Incertitude** : Haute — trois options plausibles avec tradeoffs UX différents.
- **Question posée** : Quand la liste dépasse la hauteur de l'expand, (1) scroll interne à l'expand, (2) expand qui grandit jusqu'au haut du sheet, ou (3) hybride (grandit jusqu'à une limite puis scroll) ?
- **Réponse utilisateur** : **Option 1 — scroll interne à l'expand avec hauteur max fixe**.
- **Justification** : préserve la prévisibilité de la hauteur du sheet, garde le footer toujours accessible, implémentation simple, pattern familier (Revolut-like).
- **Décision** : `max-height: 60vh` + `overflow-y: auto` sur le conteneur de liste.
- **Impact sur spec.md** : ajout de FR-020 ; edge case « Liste longue dépassant la hauteur » résolu ; question 2 passée à « Résolu » dans la table.

### CL-002 — Mécanisme single-expand (CRITIQUE, résolu auto)

- **Catégorie** : UX/Interaction (3)
- **Impact** : Haut — fondation architecturale du composant et de son intégration dans les 3 formulaires.
- **Incertitude** : Haute au départ (parent vs service, coordination inter-pills).
- **Source de résolution** : lecture de `transaction-form.ts:120,295` et `transaction-form.html:91-127`.
- **Constat** :
  - `expandedSection = signal<ExpandableSection>(null)` pilote l'expansion.
  - `toggleExpand(section)` applique `update((current) => (current === section ? null : section))` — un clic sur une autre section ferme automatiquement la précédente.
  - Le template rend conditionnellement chaque expand via `@if (expandedSection() === 'category')` avec animation `@expandCollapse`.
- **Décision** : le nouveau `CategorySelect` est un **dumb component** rendu directement dans un `<div class="bsheet__expand">` du form parent, comme le fait déjà `InlineDatePicker`. Aucun service partagé, aucun mécanisme propre d'expansion. Le form parent continue de piloter via `expandedSection`.
- **Impact sur spec.md** : ajout de FR-021 ; edge case « Deux pills ouvertes simultanément » résolu ; assumption A-001 passée à « validé » ; question 3 passée à « Résolu » dans la table.

### CL-003 — Consommateurs effectifs de `CategoryForm` (HAUT, résolu auto)

- **Catégorie** : Scope fonctionnel (1)
- **Impact** : Haut — la refonte globale du `CategoryForm` (externalisation du footer, outputs `(save)`/`(cancel)`) casse silencieusement tout consommateur oublié.
- **Incertitude** : Basse — vérifiable via grep exhaustif.
- **Source de résolution** : `Grep "app-category-form|CategoryForm" app/` + inspection de `shell.ts:49,74` et `shell.html:102`.
- **Constat** : seulement **2 consommateurs** côté Angular :
  1. `category-picker.ts` (via `Modal`) — sera supprimé (FR-016).
  2. `shell.html:102` — recevra le footer externe (FR-014).
- **Décision** : aucune duplication de composant, refonte globale confirmée.
- **Impact sur spec.md** : assumption A-002 passée à « validé » avec référence au grep.

### CL-004 — Backend change requis (HAUT, résolu auto)

- **Catégorie** : Intégrations (5)
- **Impact** : Haut — changerait la nature du ticket (frontend-only → full-stack).
- **Incertitude** : Basse — vérifiable via inspection du service existant.
- **Source de résolution** : lecture de `app/src/app/core/services/category.ts`.
- **Constat** : `CategoryService` expose déjà `getAll()` (GET `/categories`), `create(request)` (POST `/categories` avec refresh trigger), `update()`, `delete()`. Le modèle `CategoryRequest` est déjà typé côté frontend.
- **Décision** : aucun changement backend. Scope frontend-only confirmé.
- **Impact sur spec.md** : assumption A-004 passée à « validé ».

### CL-005 — API `InlineDatePicker` comme modèle (HAUT, résolu auto)

- **Catégorie** : Intégrations (5)
- **Impact** : Haut — structure l'API signals-first du nouveau composant.
- **Incertitude** : Basse — vérifiable par lecture directe.
- **Source de résolution** : `inline-date-picker.ts:60-63`.
- **Constat** : InlineDatePicker utilise `value = model<string>('')` + `originalValue/min/max = input<string>()`. Pas de mécanisme interne d'ouverture/fermeture — c'est un composant de *rendu pur*.
- **Décision** : le nouveau `CategorySelect` suit le même pattern : `value = model<string>('')` pour l'ID catégorie, `categories = input()` pour la liste (ou injection `CategoryService`), outputs `selected` et éventuel `created` pour la nouvelle catégorie. Pas de gestion d'ouverture interne.
- **Impact sur spec.md** : assumption A-001 passée à « validé » (fusionnée avec CL-002).

## Points différés

> Points non résolus dans cette session (au-delà du top 5), à traiter lors d'une prochaine itération `/devflow.clarify` ou en phase `/devflow.plan`.

| # | Source | Point identifié | Catégorie | Impact | Incertitude | Score | Raison du report |
|---|--------|-----------------|-----------|--------|-------------|-------|------------------|
| CL-006 | spec.md §Edge Cases | Empty state si aucune catégorie | 3. UX/Interaction | Moyen | Moyenne | MOYEN | Cas bord (premier usage). Recommandation de départ : empty state avec message « Aucune catégorie — créez-en une » + CTA `+ Créer` affiché d'office. À confirmer à la planification. |
| CL-007 | spec.md §Edge Cases | Clic hors expand pendant création | 6. Edge cases | Moyen | Haute | HAUT | Priorité inférieure à la structure (top 5 consommé par CRITIQUE et fondations). Recommandation de départ : perte silencieuse (pas de confirmation) pour rester dans la philosophie YAGNI, mais à valider avec l'utilisateur. |
| CL-008 | spec.md A-005 | `shell.html` tolère l'externalisation | 1. Scope fonctionnel | Moyen | Moyenne | MOYEN | Partiellement couvert par CL-003 (seuls 2 consommateurs identifiés). Vérification finale lors de la phase d'implémentation (FR-014). |
| CL-009 | spec.md A-003 | Volume moyen catégories par user | 4. Non-fonctionnel | Bas | Moyenne | BAS | Scope hors ticket ; FR-020 (scroll 60vh) atténue l'impact. Virtualisation restera hors scope tant que la perf n'est pas dégradée. |
| CL-010 | spec.md §Edge Cases | Création offline | 6. Edge cases | Bas | Moyenne | BAS | Déjà couvert par FR-011 (banner d'erreur, mode création préservé). Pas d'action supplémentaire requise. |

## Décisions clés issues du clarify

1. **Architecture du composant** : `CategorySelect` est un dumb component inline, géré par le form parent via `expandedSection` (pattern `InlineDatePicker`).
2. **Scroll** : `max-height: 60vh` + `overflow-y: auto` sur le conteneur de liste.
3. **Pas de duplication** : refonte globale de `CategoryForm` avec externalisation du footer via outputs `(save)`/`(cancel)`.
4. **Pas de backend change** : tous les endpoints sont en place.
5. **API signals-first symétrique** à `InlineDatePicker` : `value = model<string>()`, `categories = input()`, outputs `selected` et `created`.
