# Tasks: Formulaire Transaction (modal)

**Input**: Design documents from `/specs/009-transaction-form/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md
**Linear**: KKS-51

**Tests**: Non demandés explicitement dans la spec. Non inclus.

**Organization**: Tasks groupées par user story pour implémentation et test indépendants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'exécuter en parallèle (fichiers différents, pas de dépendance)
- **[Story]**: User story associée (US1+US2, US3, US4)
- Chemins exacts inclus dans les descriptions

## Phase 1: User Story 1+2 — Créer une transaction + Validation (Priority: P1) MVP

**Goal**: L'utilisateur peut créer une transaction via le formulaire avec validation complète des champs

**Independent Test**: Ouvrir la modal, remplir les champs, vérifier que l'événement `saved` émet un `TransactionRequest` valide. Tester la soumission sans champs requis et vérifier les messages d'erreur.

### Implementation

- [x] T001 [P] [US1+US2] Créer et implémenter le composant dans `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` : decorator `@Component` (standalone, OnPush, selector `app-transaction-form`), imports (`ReactiveFormsModule`, `FormField`), `input()` de type `Transaction | null` (défaut `null`), `output()` `saved` et `cancelled`, injection de `FormBuilder` et `CategoryService`, chargement des catégories via `toSignal(categoryService.getAll())`. Initialiser le formulaire réactif avec `fb.nonNullable.group()` et les valeurs par défaut (libelle: `''`, montant: `''`, type: `TransactionType.DEPENSE`, date: date du jour ISO, categoryId: `''`, note: `''`). Validators : libelle → `[Validators.required, Validators.maxLength(255)]`, montant → `[Validators.required, Validators.min(0.01)]`, type → `[Validators.required]`, date → `[Validators.required]`, note → `[Validators.maxLength(500)]`. Méthode `onSubmit()` : si invalide → `markAllAsTouched()` et return ; sinon → construire `TransactionRequest` depuis `getRawValue()` (categoryId vide → `undefined`, note vide → `undefined`) et émettre via `saved`. Méthode `onCancel()` : émettre via `cancelled`. Méthode helper `isInvalid(controlName)` : retourne `true` si le contrôle est `touched && invalid`.
- [x] T002 [P] [US1+US2] Créer et implémenter le template dans `app/src/app/features/transactions/components/transaction-form/transaction-form.html` : formulaire avec `(ngSubmit)="onSubmit()"`, 6 champs `<app-form-field>` avec `[showError]` et `[errorMessage]` conditionnels. Toggle segmenté : 2 `<button type="button">` avec `[attr.aria-pressed]`, `[class.active]` basé sur `form.get('type')?.value`, `(click)` qui fait `form.get('type')?.setValue(...)`. Select catégorie : `<option value="">Aucune catégorie</option>` + `@for (cat of categories(); track cat.id)`. Messages d'erreur : "Libellé requis" (required), "255 caractères maximum" (maxlength), "Le montant doit être supérieur à 0" (required ou min), "Date requise" (required), "500 caractères maximum" (maxlength note). Boutons : "Annuler" `type="button" (click)="onCancel()"` et "Enregistrer" `type="submit"`.
- [x] T003 [P] [US1+US2] Créer et implémenter les styles dans `app/src/app/features/transactions/components/transaction-form/transaction-form.scss` : layout formulaire vertical (flex column, gap via `--space-3`), styles du toggle segmenté (`.type-toggle` flex row, boutons flex 1 padding `--space-2`, état actif via `--color-primary`/`--color-primary-contrast`, état inactif via `--surface-raised`/`--text-secondary`, border-radius, transition), styles des boutons d'action (`.form-actions` flex row justify-content flex-end gap `--space-2`, bouton principal `.btn-primary`, bouton secondaire `.btn-outline`), textarea note (`resize: vertical`, `min-height: 80px`), responsive mobile-first (360px min, pas de scroll horizontal). Utiliser exclusivement les design tokens CSS.
- [x] T004 [US1+US2] Intégrer le composant dans le Shell : modifier `app/src/app/shared/components/shell/shell.ts` pour ajouter l'import de `TransactionForm`, et ajouter la méthode `onTransactionSaved(request: TransactionRequest)` qui appelle `TransactionService.create(request)` via `firstValueFrom()` puis ferme la modal via `this.activeModal.set(null)`. Modifier `app/src/app/shared/components/shell/shell.html` pour remplacer `<p>Formulaire de transaction — à venir</p>` par `<app-transaction-form [transaction]="null" (saved)="onTransactionSaved($event)" (cancelled)="onModalClose()" />`

**Checkpoint**: Le formulaire de création de transaction est fonctionnel avec validation complète. L'utilisateur peut créer une transaction via le FAB → modal → formulaire → soumission.

---

## Phase 2: User Story 3 — Éditer une transaction existante (Priority: P2)

**Goal**: Le formulaire peut être pré-rempli avec une transaction existante pour modification

**Independent Test**: Passer une transaction existante en entrée et vérifier le pré-remplissage, puis la soumission avec les valeurs modifiées.

### Implementation

- [x] T005 [US3] Ajouter le pré-remplissage en mode édition dans `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` : utiliser un `effect()` qui réagit au changement de l'input `transaction`. Si `transaction()` est non-null → `patchValue()` avec les valeurs de la transaction (mapping : `category?.id ?? ''` pour categoryId, `note ?? ''` pour note). Ajouter un `computed()` `isEditMode` basé sur `transaction() !== null`. Adapter le label du bouton de soumission : "Enregistrer" en création, "Modifier" en édition.
- [x] T006 [US3] Adapter le template `app/src/app/features/transactions/components/transaction-form/transaction-form.html` : utiliser `{{ isEditMode() ? 'Modifier' : 'Enregistrer' }}` pour le bouton submit.
- [x] T007 [US3] Adapter le Shell pour l'édition dans `app/src/app/shared/components/shell/shell.ts` : ajouter un signal `editingTransaction` de type `WritableSignal<Transaction | null>` (défaut `null`). Modifier `app/src/app/shared/components/shell/shell.html` pour passer `[transaction]="editingTransaction()"` au composant. Adapter `onTransactionSaved()` : si `editingTransaction()` non-null → appeler `TransactionService.update(id, request)` via `firstValueFrom()`, sinon → `create(request)`. Réinitialiser `editingTransaction` à `null` dans `onModalClose()`.

**Checkpoint**: Le formulaire supporte création ET édition. Le mode est déterminé par la présence/absence de l'input `transaction`.

---

## Phase 3: User Story 4 — Annuler la saisie (Priority: P2)

**Goal**: L'utilisateur peut annuler la saisie et fermer la modal sans effet de bord

**Independent Test**: Remplir des champs, cliquer "Annuler", vérifier que la modal se ferme sans émission de `saved`.

### Implementation

- [x] T008 [US4] Vérifier le câblage annulation dans `app/src/app/shared/components/shell/shell.html` : s'assurer que `(cancelled)="onModalClose()"` est bien connecté. Dans `onModalClose()` de `app/src/app/shared/components/shell/shell.ts` : vérifier que `activeModal` est remis à `null` ET `editingTransaction` est remis à `null`. Pas de nettoyage supplémentaire nécessaire — le formulaire est recréé à chaque ouverture de modal (détruit et recréé par le `@switch`/`@case`).

**Checkpoint**: L'annulation fonctionne dans les deux modes (création et édition). Aucun effet de bord.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Vérifications finales, lint, build

- [x] T009 Vérifier le lint et le build : exécuter `cd app && ng lint` et `cd app && ng build` pour confirmer l'absence d'erreurs
- [x] T010 Vérifier visuellement le formulaire sur mobile (360px) via DevTools : toggle segmenté lisible, champs empilés verticalement, pas de scroll horizontal, boutons accessibles

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US1+US2 MVP)** : Pas de dépendance — T001, T002, T003 en parallèle, T004 après
- **Phase 2 (US3)** : Dépend de Phase 1 — T005, T006, T007 séquentiels
- **Phase 3 (US4)** : Dépend de Phase 2 (besoin de `editingTransaction`) — T008
- **Phase 4 (Polish)** : Dépend de toutes les phases — T009, T010

### User Story Dependencies

- **US1+US2 (P1)** : Création + validation — noyau du composant. MVP.
- **US3 (P2)** : Édition — ajoute le mode édition au composant existant. Dépend de US1.
- **US4 (P2)** : Annulation — vérifie le câblage déjà en place. Dépend de US3 (pour `editingTransaction`).

### Parallel Opportunities

```text
Phase 1 : T001 ║ T002 ║ T003  (3 fichiers différents) → T004
Phase 2 : T005 → T006 → T007  (mêmes fichiers)
Phase 3 : T008  (vérification)
Phase 4 : T009 ║ T010  (lint/build + vérification visuelle)
```

---

## Implementation Strategy

### MVP First (US1+US2)

1. Compléter Phase 1 : T001, T002, T003 en parallèle (3 fichiers) puis T004 (intégration Shell)
2. **STOP et VALIDER** : Tester la création de transaction via FAB → modal → formulaire
3. Commit si fonctionnel

### Incremental Delivery

1. Phase 1 → Formulaire de création fonctionnel (MVP)
2. Phase 2 → Ajout du mode édition
3. Phase 3 → Vérification annulation
4. Phase 4 → Lint, build, vérification mobile

---

## Notes

- US1 et US2 sont fusionnées car la validation est indissociable de la création (même composant, mêmes fichiers)
- Aucun nouveau endpoint backend — utilise `TransactionService.create()` et `.update()` existants
- Le formulaire est détruit/recréé à chaque ouverture de modal (géré par `@switch`/`@case` d'Angular), donc pas besoin de reset manuel
- Les catégories sont chargées dans le composant via `toSignal(categoryService.getAll())`
- Commit recommandé après chaque phase complétée
