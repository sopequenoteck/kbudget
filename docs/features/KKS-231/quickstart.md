# Quickstart — KKS-231 : Refonte du sélecteur de catégorie en bottom-sheet inline

**Date** : 2026-04-18
**Issue** : KKS-231
**Branche** : `feature/KKS-231`

---

## Pré-requis

- [x] Constitution lue (`.specify/memory/constitution.md` v2.1.2)
- [x] Spec validée (`spec.md` — review-spec PASS)
- [x] Clarify complété (`clarify-log.md` — 5 résolus, 5 différés documentés)
- [x] Research complétée (`research.md` — 8 décisions techniques)
- [x] Plan approuvé (`plan.md` — Constitution Check PASS, aucune dérogation)
- [ ] Tasks générées (`tasks.md` — à produire via `/devflow.tasks`)

## Phase 1 — Setup

```bash
# Branche déjà créée par setup-feature.sh
git branch --show-current   # → feature/KKS-231

# Lancer le dev server Angular pour itérer
cd app && ng serve
# → http://localhost:4200
```

**Vérification** :
- L'app démarre sans erreur de compilation.
- L'écran transactions s'ouvre, le bottom-sheet de saisie est accessible.
- Le `category-picker` actuel fonctionne encore (baseline).

## Phase 2 — Fondations

### Fichiers à créer

| Fichier | Template/Base | Description |
|---------|---------------|-------------|
| `app/src/app/shared/utils/string.utils.ts` | Extraction de `autocomplete.ts:21-26` | Helper `normalize()` partagé |
| `app/src/app/shared/utils/string.utils.spec.ts` | Convention tests projet | Tests unitaires du helper |
| `app/src/app/shared/components/category-select/category-select.ts` | Modèle : `Autocomplete` + `InlineDatePicker` | Nouveau composant |
| `app/src/app/shared/components/category-select/category-select.html` | — | Template (mode list + create) |
| `app/src/app/shared/components/category-select/category-select.scss` | Tokens + `_list-patterns.scss` | Styles |
| `app/src/app/shared/components/category-select/category-select.spec.ts` | Pattern projet | Tests unitaires |

### Étapes

1. **Créer le helper partagé** : `string.utils.ts` + sa spec, lancer `ng test --include="**/string.utils.spec.ts"`.
2. **Refactor `autocomplete.ts`** : importer `normalize` depuis le shared util, supprimer la fonction locale. Lancer `ng test --include="**/autocomplete.spec.ts"` — doit rester vert.
3. **Refondre `CategoryForm`** :
   - Renommer `onSubmit()` → `submit()` (méthode publique async).
   - Supprimer `category-form__actions` dans HTML et SCSS.
   - Adapter `category-form.spec.ts`.
   - Lancer les tests : `ng test --include="**/category-form.spec.ts"`.
4. **Adapter `shell.html` + `shell.ts`** :
   - Ajouter `viewChild<CategoryForm>('categoryFormRef')` dans `shell.ts`.
   - Méthode `triggerCategorySubmit()`.
   - Dans `shell.html` `@case ('category')` : ajouter `#categoryFormRef` sur le form + footer custom avec les 2 boutons.
5. **Test manuel non-régression** : sur la page Settings (gestion des catégories), créer / modifier / supprimer une catégorie → doit fonctionner comme avant.

**Vérification fondations** :
- `ng test` : tous les tests précédemment verts restent verts.
- `ng serve` : aucune erreur console. Settings catégories fonctionne.
- Le `category-picker` actuel (à migrer après) n'est pas encore supprimé — baseline intacte.

## Phase 3 — Implémentation User Stories

### US1 — Sélectionner une catégorie existante sans quitter le sheet (P1)

1. Implémenter `category-select.ts` (API + signals + computed) selon plan §3.1 et §3.2.
2. Implémenter le template `category-select.html` branche `list` uniquement (sans création pour cette US).
3. Implémenter les styles `.cs__list`, `.cs__item` avec scroll 60vh (FR-020).
4. Ajouter la CVA (ControlValueAccessor) pour compatibilité `formControlName`.
5. Écrire les tests unitaires US1 (navigation, sélection, single-expand via signal parent).
6. Migrer `transaction-form` : remplacer `app-category-picker` par `app-category-select`, ajouter préchargement catégories.
7. Tester manuellement : ouvrir le bottom-sheet transaction → clic pill catégorie → liste inline s'affiche → sélection → expand collapse → valeur dans le form.

**Test US1** :
- Inspecter le DOM : aucun élément avec classe `select-picker__sheet` ou `select-picker__overlay` ne doit apparaître.
- Inspecter la hauteur : liste avec scroll interne, hauteur max ~60vh.
- Tester sur mobile : 320px, 375px, 414px.

### US2 — Créer une nouvelle catégorie sans quitter le flow (P1)

1. Ajouter le mode `create` dans `category-select.ts` (signal `mode`, méthodes `pushToCreate` / `popToList` / `submitCategoryForm` / `onCategoryCreated`).
2. Ajouter l'effect `isCreating.emit(mode() === 'create')`.
3. Implémenter la branche `create` du template : en-tête avec `← Retour` et `✓ Créer`, puis `<app-category-form>`.
4. Ajouter le bouton `+ Créer '{terme}'` en mode list (conditionnel via `showCreateButton`).
5. Écouter `(isCreating)` dans les 3 forms parents et désactiver le footer `bsheet__bottom-row` en conséquence.
6. Tester : ouvrir expand catégorie → taper un nom inexistant → clic `+ Créer` → form s'affiche avec nom pré-rempli → créer → catégorie sélectionnée + expand collapse.

**Test US2** :
- Vérifier que `isCreating` émet `true` au push et `false` au pop/succès.
- Vérifier la préservation de la recherche au pop.
- Vérifier que le footer du sheet est désactivé (pas masqué) pendant le mode create.

### US3 — Filtrer la liste par recherche (P2)

1. Vérifier que `filteredCategories` est branché sur l'input de recherche.
2. Tester avec accents (`cafe` → `Café`) et casse (`ECO` → `économie`).
3. Vérifier que le bouton `+ Créer` apparaît si aucun match exact.
4. Ajouter les tests unitaires de filtrage.

**Test US3** : saisir « cour » dans un compte avec 15 catégories, vérifier que seules les catégories contenant « cour » sont affichées.

### US4 — Gérer les catégories depuis Settings (non-régression) (P2)

Déjà couverte en Phase 2 étape 4-5. Test manuel complet :
1. Settings → page catégories → créer une catégorie
2. Éditer une catégorie existante
3. Supprimer une catégorie
4. Vérifier que les 3 parcours fonctionnent à l'identique avant/après refonte.

## Phase 4 — Migration & nettoyage

1. Migrer `subscription-form` (même pattern que transaction-form).
2. Migrer `debt-form` (même pattern).
3. Supprimer le dossier `app/src/app/shared/components/category-picker/`.
4. Grep final : `grep -r "category-picker\|CategoryPicker" app/src` → aucun résultat.
5. Vérifier qu'aucun import orphelin ne subsiste (`ng lint`).

## Phase 5 — Polish

1. Exécuter tous les tests : `cd app && ng test`.
2. Vérifier la couverture : `ng test --code-coverage` → `CategorySelect` ≥ 80 %.
3. Vérifier les tokens CSS : `grep -E "#[0-9a-fA-F]{3,8}|rgba?\(" app/src/app/shared/components/category-select/*.scss` → 0 résultat.
4. Vérifier ARIA : inspecter DevTools Accessibility sur un expand ouvert.
5. Vérifier navigation clavier : ↓ / ↑ / Enter / Esc fonctionnels.
6. Lancer `ng lint` → 0 erreur.
7. `/design-check` : audit de cohérence visuelle.
8. `/review` : audit dette introduite + alignement constitution.
9. Mettre à jour `DESIGN.md` et `DESIGN-REFONTE.md`.

## Commandes utiles

| Action | Commande |
|--------|----------|
| Lancer les tests | `cd app && ng test` |
| Tests avec couverture | `cd app && ng test --code-coverage` |
| Test d'un seul fichier | `cd app && ng test --include="**/category-select.spec.ts"` |
| Vérifier le lint | `cd app && ng lint` |
| Formatter | `cd app && npm run format` |
| Build | `cd app && ng build` |
| Dev server | `cd app && ng serve` |
| Grep tokens | `grep -rE "#[0-9a-fA-F]{3,8}" app/src/app/shared/components/category-select/` |
| Grep ancien composant après migration | `grep -r "category-picker\|CategoryPicker" app/src` |

## Checklist finale

- [ ] Tous les tests passent (`ng test`)
- [ ] Couverture `CategorySelect` ≥ 80 %
- [ ] Pas de warning lint (`ng lint`)
- [ ] Aucun hex/rgba hardcodé dans les fichiers du scope
- [ ] ARIA vérifié (DevTools Accessibility)
- [ ] Navigation clavier fonctionnelle
- [ ] Test manuel des 3 formulaires (transaction, subscription, debt) : sélection + création inline OK
- [ ] Test manuel Settings : créer / modifier / supprimer catégorie OK
- [ ] `app-category-picker` supprimé du code et aucun reste
- [ ] `DESIGN.md` section Category Select ajoutée
- [ ] `DESIGN-REFONTE.md` session KKS-231 ajoutée
- [ ] Review-impl PASS (`/devflow.review-impl`)
- [ ] `docs.md` généré (`/devflow.docs`)
