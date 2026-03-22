# Quickstart: Formulaire Transaction (modal)

**Feature**: 009-transaction-form | **Date**: 2026-02-09

## Prérequis

- Node.js installé
- `cd app && npm install` exécuté
- Serveur de dev : `cd app && ng serve`

## Fichiers à créer

1. `app/src/app/features/transactions/components/transaction-form/transaction-form.ts`
2. `app/src/app/features/transactions/components/transaction-form/transaction-form.html`
3. `app/src/app/features/transactions/components/transaction-form/transaction-form.scss`

## Fichiers à modifier

1. `app/src/app/shared/components/shell/shell.ts` — Ajouter l'import de `TransactionForm`
2. `app/src/app/shared/components/shell/shell.html` — Remplacer `<p>Formulaire de transaction — à venir</p>` par `<app-transaction-form>`

## Patterns à suivre

### Composant (référence : auth.ts)

```
- Standalone : true (défaut Angular 21)
- ChangeDetectionStrategy.OnPush
- inject() pour DI (pas de constructor injection)
- input() / output() signals-first
- FormBuilder.nonNullable.group() pour le formulaire réactif
- firstValueFrom() au lieu de subscribe()
```

### FormField (référence : auth.html)

```
<app-form-field
  label="Libellé"
  fieldId="libelle"
  [errorMessage]="..."
  [showError]="control.touched && control.invalid">
  <input id="libelle" formControlName="libelle" />
</app-form-field>
```

### Intégration Shell (remplacement du placeholder)

```
@case ('transaction') {
  <app-transaction-form
    [transaction]="null"
    (saved)="onTransactionSaved($event)"
    (cancelled)="onModalClose()" />
}
```

## Vérification

```bash
cd app && ng serve    # Vérifier que le formulaire s'affiche dans la modal
cd app && ng lint     # Pas d'erreurs ESLint
cd app && ng build    # Build sans erreurs
```

## Tests

```bash
cd app && npx vitest run    # Tests unitaires
```
