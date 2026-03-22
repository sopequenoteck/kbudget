# Tasks: Formulaire Debt (modal)

**Input**: Design documents from `/specs/011-debt-form/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md
**Linear**: KKS-53

**Organization**: Tasks groupees par user story. Pas de phase Setup ni Foundational — tous les prerequis existent (modeles, services, shell, FormField).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut etre execute en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story associee (US1, US2, US3, US4)

---

## Phase 1: User Story 1+2 - Creer une dette + Validation (Priority: P1) MVP

**Goal**: Le formulaire permet de creer une dette avec validation des champs obligatoires. C'est le MVP minimal.

**Independent Test**: Ouvrir la modal via (+) > "Dette", remplir personne/montant/date, soumettre. Verifier que `DebtRequest` est emis. Tenter de soumettre vide et verifier les messages d'erreur.

### Implementation

- [x] T001 [P] [US1] Creer le composant DebtForm (classe, decorateurs, inputs/outputs, FormGroup avec validateurs, injection `CategoryService` + signal `categories = toSignal(categoryService.getAll())`) dans `app/src/app/features/debts/components/debt-form/debt-form.ts`
- [x] T002 [P] [US1] Creer le template du formulaire (champs personne, montant, toggle sens, date, checkbox rembourse, select categorie, boutons actions) dans `app/src/app/features/debts/components/debt-form/debt-form.html`
- [x] T003 [P] [US1] Creer les styles du formulaire (layout responsive, toggle segmente, checkbox, form-actions) dans `app/src/app/features/debts/components/debt-form/debt-form.scss`
- [x] T004 [US1] [US2] Integrer les messages d'erreur de validation dans le template via FormField (showError, errorMessage) pour chaque champ requis dans `app/src/app/features/debts/components/debt-form/debt-form.html`

**Checkpoint**: Le composant DebtForm est fonctionnel en standalone. Il emet `saved` avec un `DebtRequest` valide et affiche les erreurs de validation.

---

## Phase 2: Integration Shell (Priority: P1)

**Goal**: Le formulaire est accessible depuis la modal du Shell via le bouton flottant (+).

**Independent Test**: Cliquer (+) > "Dette" → le formulaire s'affiche. Remplir et soumettre → la dette est creee via `DebtService`.

- [x] T005 [US1] [US3] Integrer DebtForm dans le Shell : importer `DebtForm`, `DebtService`, `Debt`, `DebtRequest` ; ajouter le signal `editingDebt = signal<Debt | null>(null)` ; ajouter le handler `onDebtSaved(request: DebtRequest)` avec create/update via `DebtService` ; mettre a jour `onModalClose()` pour reset `editingDebt` ; mettre a jour le `modalTitle` computed pour le cas 'debt' en mode edition ("Modifier la dette") dans `app/src/app/shared/components/shell/shell.ts`
- [x] T006 [US1] [US3] Remplacer le placeholder `<p>Formulaire de dette — à venir</p>` par le composant `<app-debt-form>` avec bindings `[debt]="editingDebt()"` `(saved)="onDebtSaved($event)"` `(cancelled)="onModalClose()"` dans `app/src/app/shared/components/shell/shell.html`

**Checkpoint**: Flux complet creation de dette fonctionnel de bout en bout (bouton + → formulaire → soumission → API).

---

## Phase 3: User Story 3 - Editer une dette existante (Priority: P2)

**Goal**: Le formulaire se pre-remplit avec les valeurs d'une dette existante pour permettre la modification.

**Independent Test**: Passer un objet `Debt` en input du formulaire, verifier que tous les champs sont pre-remplis, modifier le montant, soumettre et verifier que le `DebtRequest` emis contient le nouveau montant.

### Implementation

- [x] T007 [US3] Implementer le `effect()` de pre-remplissage du formulaire en mode edition (patch des valeurs depuis `debt()` input, extraction de `categoryId` depuis `debt.category?.id`) dans `app/src/app/features/debts/components/debt-form/debt-form.ts`

**Checkpoint**: Le formulaire fonctionne en mode creation ET edition.

---

## Phase 4: User Story 4 - Annuler la saisie (Priority: P2)

**Goal**: Le bouton Annuler emet `cancelled` sans effet de bord.

**Independent Test**: Remplir des champs, cliquer "Annuler", verifier que `cancelled` est emis et qu'aucun `saved` n'est emis.

### Implementation

- [x] T008 [US4] Verification : confirmer que `onCancel()` (cree en T001) emet correctement l'output `cancelled` et que le binding `(cancelled)="onModalClose()"` (T006) ferme la modal. Pas de code supplementaire sauf correctif si necessaire.

**Checkpoint**: L'annulation fonctionne sans effet de bord.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T009 Verifier le rendu responsive sur mobile (360px min) et ajuster les styles si necessaire dans `app/src/app/features/debts/components/debt-form/debt-form.scss`
- [x] T010 Executer `ng lint` et `npm run format` pour verifier la conformite ESLint/Prettier dans `app/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US1+US2)**: Pas de dependance — les modeles, services et shell existent deja
- **Phase 2 (Integration Shell)**: Depend de Phase 1 (le composant doit exister pour etre integre)
- **Phase 3 (US3)**: Depend de Phase 1 (le composant doit exister). Peut etre fait en parallele de Phase 2
- **Phase 4 (US4)**: Depend de Phase 1 (le handler `onCancel` est dans le composant)
- **Phase 5 (Polish)**: Depend de toutes les phases precedentes

### Parallel Opportunities

- T001, T002, T003 peuvent etre executes en parallele (3 fichiers distincts)
- Phase 3 (T007) peut etre faite en parallele de Phase 2 (T005-T006) car ils touchent des fichiers differents

### Within Phase 1

```text
T001 (debt-form.ts) ─┐
T002 (debt-form.html) ├─→ T004 (integration validation dans template)
T003 (debt-form.scss) ┘
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2)

1. Creer le composant DebtForm (T001-T004) — formulaire fonctionnel en standalone
2. Integrer dans le Shell (T005-T006) — flux complet de creation
3. **STOP et VALIDER** : tester la creation d'une dette de bout en bout

### Incremental Delivery

1. Phase 1+2 → Creation de dette fonctionnelle (MVP)
2. Phase 3 → Ajout du mode edition
3. Phase 4 → Verification annulation
4. Phase 5 → Polish et conformite

---

## Notes

- Pattern identique a `TransactionForm` (009) et `SubscriptionForm` (010)
- Les modeles `Debt`, `DebtRequest`, `DebtType` existent deja dans `debt.model.ts`
- Le `DebtService` existe deja dans `core/services/debt.ts`
- Le `CategoryService` existe deja dans `core/services/category.ts`
- Le toggle sens utilise les labels "Emprunt" / "Pret" (clarification spec)
- Pas de tests dans ce scope — couverts par KKS-59 (Tests unitaires services Phase 4, statut Backlog dans Linear)
