# Quickstart: Formulaire Subscription (modal)

**Feature**: 010-subscription-form | **Date**: 2026-02-09

## Prerequis

- Node.js installe
- `cd app && npm install` execute
- Serveur de dev : `cd app && ng serve`

## Fichiers a creer

1. `app/src/app/features/subscriptions/components/subscription-form/subscription-form.ts`
2. `app/src/app/features/subscriptions/components/subscription-form/subscription-form.html`
3. `app/src/app/features/subscriptions/components/subscription-form/subscription-form.scss`

## Fichiers a modifier

1. `app/src/app/shared/components/shell/shell.ts` — Ajouter l'import de `SubscriptionForm`
2. `app/src/app/shared/components/shell/shell.html` — Remplacer `<p>Formulaire d'abonnement — a venir</p>` par `<app-subscription-form>`

## Patterns a suivre

### Composant (reference : transaction-form.ts)

```
- Standalone : true (defaut Angular 21)
- ChangeDetectionStrategy.OnPush
- inject() pour DI (pas de constructor injection)
- input() / output() signals-first
- FormBuilder.nonNullable.group() pour le formulaire reactif
- toSignal() pour les categories
- effect() pour le pre-remplissage en mode edition
- firstValueFrom() au lieu de subscribe()
```

### FormField (reference : transaction-form.html)

```
<app-form-field
  label="Nom"
  fieldId="nom"
  [errorMessage]="..."
  [showError]="isInvalid('nom')">
  <input id="nom" formControlName="nom" />
</app-form-field>
```

### Integration Shell (remplacement du placeholder)

```
@case ('subscription') {
  <app-subscription-form
    [subscription]="editingSubscription()"
    (saved)="onSubscriptionSaved($event)"
    (cancelled)="onModalClose()" />
}
```

## Verification

```bash
cd app && ng serve    # Verifier que le formulaire s'affiche dans la modal
cd app && ng lint     # Pas d'erreurs ESLint
cd app && ng build    # Build sans erreurs
```

## Tests

```bash
cd app && npx vitest run    # Tests unitaires
```
