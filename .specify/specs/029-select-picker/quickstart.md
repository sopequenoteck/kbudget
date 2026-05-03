# Quickstart: SelectPicker generique

**Feature**: 029-select-picker | **Date**: 2026-02-17

## Usage basique — Selection de compte

```html
<!-- Dans un formulaire reactif -->
<app-form-field label="Compte" fieldId="accountId">
  <app-select-picker
    formControlName="accountId"
    [items]="accountItems()"
    placeholder="Selectionner un compte"
    [clearable]="false"
  />
</app-form-field>
```

```typescript
// Dans le composant parent
readonly accountItems = computed(() =>
  this.activeAccounts().map(account => ({
    id: account.id,
    label: account.nom,
    icon: account.icone,
    secondaryText: `${account.solde.toFixed(2)} €`,
    color: account.couleur,
  }))
);
```

## Usage avec recherche toujours active — Categories

```html
<app-form-field label="Categorie" fieldId="categoryId">
  <app-category-picker formControlName="categoryId" />
</app-form-field>
```

Le `CategoryPicker` est un wrapper qui utilise internement le `SelectPicker` avec `searchable=true` et ajoute la creation inline.

## Usage dans le formulaire de virement

```html
<app-form-field label="Depuis" fieldId="fromAccountId">
  <app-select-picker
    formControlName="fromAccountId"
    [items]="accountItems()"
    placeholder="Compte source"
  />
</app-form-field>

<app-form-field label="Vers" fieldId="toAccountId">
  <app-select-picker
    formControlName="toAccountId"
    [items]="accountItems()"
    placeholder="Compte destination"
  />
</app-form-field>
```

La validation `differentAccountsValidator` reste dans le `FormGroup` parent.

## Usage avec compte optionnel — Abonnement

```html
<app-select-picker
  formControlName="accountId"
  [items]="accountItems()"
  placeholder="Aucun compte"
  [clearable]="true"
/>
```

`clearable=true` permet a l'utilisateur de vider la selection (valeur emise : `''`).

## Transformation des entites en SelectPickerItem

### Comptes

```typescript
function toAccountPickerItems(accounts: Account[]): SelectPickerItem[] {
  return accounts.map(a => ({
    id: a.id,
    label: a.nom,
    icon: a.icone,
    secondaryText: `${a.solde.toFixed(2)} €`,
    color: a.couleur,
  }));
}
```

### Categories

```typescript
function toCategoryPickerItems(categories: Category[]): SelectPickerItem[] {
  return categories.map(c => ({
    id: c.id,
    label: c.nom,
    icon: c.icone,
    secondaryText: null,
    color: null,
  }));
}
```

## Comportement responsive

- **Desktop (>=768px)** : dropdown positionne sous le champ (ou au-dessus si espace insuffisant)
- **Mobile (<768px)** : bottom-sheet ancre en bas de l'ecran avec overlay sombre

Le basculement est automatique via CSS media queries, aucune configuration necessaire.

## Tests

```typescript
// Setup standard
const fixture = TestBed.createComponent(SelectPicker);
fixture.componentRef.setInput('items', mockItems);
fixture.detectChanges();

// Simuler une selection
const component = fixture.componentInstance;
component.selectItem(mockItems[0]);
expect(onChangeSpy).toHaveBeenCalledWith(mockItems[0].id);
```
