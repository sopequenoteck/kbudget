# Tasks: Formulaire Subscription (modal)

**Input**: Design documents from `/specs/010-subscription-form/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md
**Linear**: KKS-52

**Tests**: Non demandes explicitement dans la spec. Non inclus.

**Organization**: Tasks groupees par user story pour implementation et test independants.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'executer en parallele (fichiers differents, pas de dependance)
- **[Story]**: User story associee (US1+US2, US3, US4)
- Chemins exacts inclus dans les descriptions

## Phase 1: User Story 1+2 — Creer un abonnement + Validation (Priority: P1) MVP

**Goal**: L'utilisateur peut creer un abonnement via le formulaire avec validation complete des champs

**Independent Test**: Ouvrir la modal, remplir les champs, verifier que l'evenement `saved` emet un `SubscriptionRequest` valide. Tester la soumission sans champs requis et verifier les messages d'erreur.

### Implementation

- [x] T001 [P] [US1+US2] Creer et implementer le composant dans `app/src/app/features/subscriptions/components/subscription-form/subscription-form.ts` : decorator `@Component` (standalone, OnPush, selector `app-subscription-form`), imports (`ReactiveFormsModule`, `FormField`), `input()` de type `Subscription | null` (defaut `null`), `output()` `saved` et `cancelled`, injection de `FormBuilder` et `CategoryService`, chargement des categories via `toSignal(categoryService.getAll())`. Initialiser le formulaire reactif avec `fb.nonNullable.group()` et les valeurs par defaut (nom: `''`, montant: `''`, frequence: `Frequency.MENSUEL`, dateDebut: date du jour ISO, actif: `true`, categoryId: `''`). Validators : nom → `[Validators.required, Validators.maxLength(255)]`, montant → `[Validators.required, Validators.min(0.01)]`, frequence → `[Validators.required]`, dateDebut → `[Validators.required]`. Methode `onSubmit()` : si invalide → `markAllAsTouched()` et return ; sinon → construire `SubscriptionRequest` depuis `getRawValue()` (categoryId vide → `undefined`, actif explicite) et emettre via `saved`. Methode `onCancel()` : emettre via `cancelled`. Methode helper `isInvalid(controlName)` : retourne `true` si le controle est `touched && invalid`.
- [x] T002 [P] [US1+US2] Creer et implementer le template dans `app/src/app/features/subscriptions/components/subscription-form/subscription-form.html` : formulaire avec `(ngSubmit)="onSubmit()"`, 5 champs `<app-form-field>` avec `[showError]` et `[errorMessage]` conditionnels + 1 checkbox. Toggle segmente pour frequence : 2 `<button type="button">` avec `[attr.aria-pressed]`, `[class.active]` base sur `form.get('frequence')?.value`, `(click)` qui fait `form.get('frequence')?.setValue(...)`. Select categorie : `<option value="">Aucune categorie</option>` + `@for (cat of categories(); track cat.id)`. Checkbox actif : `<label class="checkbox-field"><input type="checkbox" formControlName="actif" /> Abonnement actif</label>`. Messages d'erreur : "Nom requis" (required), "255 caracteres maximum" (maxlength), "Le montant doit etre superieur a 0" (required ou min), "Date de debut requise" (required). Boutons : "Annuler" `type="button" (click)="onCancel()"` et "Enregistrer" `type="submit"`.
- [x] T003 [P] [US1+US2] Creer et implementer les styles dans `app/src/app/features/subscriptions/components/subscription-form/subscription-form.scss` : layout formulaire vertical (flex column, gap via `--space-3`), styles du toggle segmente (`.type-toggle` flex row, boutons flex 1 padding `--space-2`, etat actif via `--color-primary`/`--color-primary-contrast`, etat inactif via `--surface-raised`/`--text-secondary`, border-radius, transition), styles checkbox (`.checkbox-field` flex row align-items center gap `--space-2`, label font-size `--font-size-sm`), styles des boutons d'action (`.form-actions` flex row justify-content flex-end gap `--space-2`, bouton principal `.btn-primary`, bouton secondaire `.btn-outline`), responsive mobile-first (360px min, pas de scroll horizontal). Utiliser exclusivement les design tokens CSS.
- [x] T004 [US1+US2] Integrer le composant dans le Shell : modifier `app/src/app/shared/components/shell/shell.ts` pour ajouter l'import de `SubscriptionForm` et `SubscriptionService`, ajouter la methode `onSubscriptionSaved(request: SubscriptionRequest)` qui appelle `SubscriptionService.create(request)` via `firstValueFrom()` puis ferme la modal via `this.activeModal.set(null)`. Modifier `app/src/app/shared/components/shell/shell.html` pour remplacer `<p>Formulaire d'abonnement — à venir</p>` par `<app-subscription-form [subscription]="null" (saved)="onSubscriptionSaved($event)" (cancelled)="onModalClose()" />`

**Checkpoint**: Le formulaire de creation d'abonnement est fonctionnel avec validation complete. L'utilisateur peut creer un abonnement via FAB → modal → formulaire → soumission.

---

## Phase 2: User Story 3 — Editer un abonnement existant (Priority: P2)

**Goal**: Le formulaire peut etre pre-rempli avec un abonnement existant pour modification

**Independent Test**: Passer un abonnement existant en entree et verifier le pre-remplissage, puis la soumission avec les valeurs modifiees.

### Implementation

- [x] T005 [US3] Ajouter le pre-remplissage en mode edition dans `app/src/app/features/subscriptions/components/subscription-form/subscription-form.ts` : utiliser un `effect()` qui reagit au changement de l'input `subscription`. Si `subscription()` est non-null → `patchValue()` avec les valeurs de l'abonnement (mapping : `category?.id ?? ''` pour categoryId). Ajouter un `computed()` `isEditMode` base sur `subscription() !== null`. Adapter le label du bouton de soumission : "Enregistrer" en creation, "Modifier" en edition.
- [x] T006 [US3] Adapter le template `app/src/app/features/subscriptions/components/subscription-form/subscription-form.html` : utiliser `{{ isEditMode() ? 'Modifier' : 'Enregistrer' }}` pour le bouton submit.
- [x] T007 [US3] Adapter le Shell pour l'edition dans `app/src/app/shared/components/shell/shell.ts` : ajouter un signal `editingSubscription` de type `WritableSignal<Subscription | null>` (defaut `null`). Modifier `app/src/app/shared/components/shell/shell.html` pour passer `[subscription]="editingSubscription()"` au composant. Adapter `onSubscriptionSaved()` : si `editingSubscription()` non-null → appeler `SubscriptionService.update(id, request)` via `firstValueFrom()`, sinon → `create(request)`. Adapter `modalTitle` pour retourner `'Modifier l'abonnement'` quand `activeModal() === 'subscription' && editingSubscription()`. Ajouter `editingSubscription.set(null)` dans `onModalClose()` (meme pattern que `editingTransaction`).

**Checkpoint**: Le formulaire supporte creation ET edition. Le mode est determine par la presence/absence de l'input `subscription`.

---

## Phase 3: User Story 4 — Annuler la saisie (Priority: P2)

**Goal**: L'utilisateur peut annuler la saisie et fermer la modal sans effet de bord

**Independent Test**: Remplir des champs, cliquer "Annuler", verifier que la modal se ferme sans emission de `saved`.

### Implementation

- [x] T008 [US4] Verifier le cablage annulation dans `app/src/app/shared/components/shell/shell.html` : s'assurer que `(cancelled)="onModalClose()"` est bien connecte. Verifier que `onModalClose()` remet bien `activeModal` et `editingSubscription` a `null` (deja implemente en T007). Pas de nettoyage supplementaire necessaire — le formulaire est recree a chaque ouverture de modal (detruit et recree par le `@switch`/`@case`).

**Checkpoint**: L'annulation fonctionne dans les deux modes (creation et edition). Aucun effet de bord.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Verifications finales, lint, build

- [x] T009 Verifier le lint et le build : executer `cd app && ng lint` et `cd app && ng build` pour confirmer l'absence d'erreurs
- [x] T010 Verifier visuellement le formulaire sur mobile (360px) via DevTools : toggle segmente lisible, champs empiles verticalement, checkbox accessible, pas de scroll horizontal, boutons accessibles

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US1+US2 MVP)** : Pas de dependance — T001, T002, T003 en parallele, T004 apres
- **Phase 2 (US3)** : Depend de Phase 1 — T005, T006, T007 sequentiels
- **Phase 3 (US4)** : Depend de Phase 2 (besoin de `editingSubscription`) — T008
- **Phase 4 (Polish)** : Depend de toutes les phases — T009, T010

### User Story Dependencies

- **US1+US2 (P1)** : Creation + validation — noyau du composant. MVP.
- **US3 (P2)** : Edition — ajoute le mode edition au composant existant. Depend de US1.
- **US4 (P2)** : Annulation — verifie le cablage deja en place. Depend de US3 (pour `editingSubscription`).

### Parallel Opportunities

```text
Phase 1 : T001 ║ T002 ║ T003  (3 fichiers differents) → T004
Phase 2 : T005 → T006 → T007  (memes fichiers)
Phase 3 : T008  (verification)
Phase 4 : T009 ║ T010  (lint/build + verification visuelle)
```

---

## Implementation Strategy

### MVP First (US1+US2)

1. Completer Phase 1 : T001, T002, T003 en parallele (3 fichiers) puis T004 (integration Shell)
2. **STOP et VALIDER** : Tester la creation d'abonnement via FAB → modal → formulaire
3. Commit si fonctionnel

### Incremental Delivery

1. Phase 1 → Formulaire de creation fonctionnel (MVP)
2. Phase 2 → Ajout du mode edition
3. Phase 3 → Verification annulation
4. Phase 4 → Lint, build, verification mobile

---

## Notes

- US1 et US2 sont fusionnees car la validation est indissociable de la creation (meme composant, memes fichiers)
- Aucun nouveau endpoint backend — utilise `SubscriptionService.create()` et `.update()` existants
- Le formulaire est detruit/recree a chaque ouverture de modal (gere par `@switch`/`@case` d'Angular), donc pas besoin de reset manuel
- Les categories sont chargees dans le composant via `toSignal(categoryService.getAll())`
- Pattern identique a KKS-51 (transaction-form) avec adaptations : frequence au lieu de type, checkbox actif, pas de note
- Commit recommande apres chaque phase completee
