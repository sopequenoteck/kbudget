# Research: 087-angular-recurring-form

## R-001: Pattern d'enrichissement formulaire avec champs conditionnels

**Decision**: Utiliser `valueChanges` sur le FormControl `isRecurring` pour enable/disable les champs `frequency` et `nextOccurrence` via Reactive Forms.

**Rationale**: C'est le pattern standard Angular Reactive Forms. Le formulaire existant (`TransactionForm`) utilise déjà `FormBuilder.nonNullable.group()`. Les champs conditionnels sont ajoutés au groupe avec `{ value: ..., disabled: true }` par défaut, et activés dynamiquement.

**Alternatives considered**:
- Signal-based toggle avec `@if` dans le template (masque les champs mais ne les intègre pas au FormGroup → problème de validation)
- Formulaire séparé pour les récurrences (viole le principe de simplicité, double maintenance)

## R-002: Dispatch vers le bon service selon le mode

**Decision**: Dans `onSubmit()`, vérifier `form.get('isRecurring')?.value`. Si `true`, appeler `RecurringTransactionService.create()`. Sinon, appeler `TransactionService.create()` (comportement actuel).

**Rationale**: Branching simple dans le handler existant. Pas besoin d'abstraire un pattern strategy — c'est un `if/else` unique.

**Alternatives considered**:
- Service unifié qui route en interne (sur-ingénierie pour un seul point de décision)

## R-003: Mécanisme de pré-remplissage pour la conversion

**Decision**: Utiliser le `ModalService` existant avec un nouveau `ModalType` ou réutiliser le type `transaction` en passant une entité de pré-remplissage enrichie d'un flag `asRecurring: true`.

**Rationale**: Le `ModalService` gère déjà `editingEntity()` pour le pré-remplissage en mode édition. On peut réutiliser ce mécanisme en ajoutant un signal ou une propriété pour distinguer "édition" de "conversion en récurrence".

**Alternatives considered**:
- Nouveau composant `RecurringTransactionForm` (duplication, viole YAGNI)
- Query params dans l'URL (complexe, pas cohérent avec le pattern modal existant)

## R-004: Placement de l'action "Rendre récurrente" dans la liste

**Decision**: Ajouter un bouton icône (phosphorRepeat) dans chaque ligne de transaction, cohérent avec le pattern mobile-first de l'app.

**Rationale**: L'app est mobile-first. Un bouton visible sur chaque item est plus accessible qu'un menu contextuel ou un swipe.

**Alternatives considered**:
- Menu contextuel au long-press (moins discoverable)
- Swipe action (pattern iOS, pas implémenté dans l'app Angular)

## R-005: Contrat API backend existant

**Decision**: Réutiliser le contrat `POST /transactions/recurring` tel quel (KKS-085).

**Rationale**: Le backend est déjà implémenté et testé (488 tests). Le `RecurringTransactionRequest` attend : `montant`, `libelle`, `type`, `frequency`, `nextOccurrence`, `categoryId?`, `accountId?`, `note?`.

**Alternatives considered**: Aucune — le backend est fixe et hors scope.
