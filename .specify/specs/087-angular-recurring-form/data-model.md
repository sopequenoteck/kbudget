# Data Model: 087-angular-recurring-form

## Entités

### RecurringTransactionRequest (nouveau — interface TypeScript)

Interface de création envoyée au backend via POST /transactions/recurring.

| Champ | Type | Obligatoire | Validation | Description |
|-------|------|-------------|------------|-------------|
| montant | number | oui | > 0 | Montant de la transaction |
| libelle | string | oui | max 255 chars | Libellé |
| type | TransactionType | oui | DEPENSE ou RECETTE | Type de transaction |
| frequency | Frequency | oui | HEBDOMADAIRE, MENSUEL, ANNUEL | Fréquence de récurrence |
| nextOccurrence | string (yyyy-MM-dd) | oui | aujourd'hui ou futur | Date de la prochaine occurrence |
| categoryId | string (UUID) | non | — | Catégorie associée |
| accountId | string (UUID) | non | — | Compte associé (défaut : compte principal) |
| note | string | non | max 500 chars | Note optionnelle |

### RecurringTransactionResponse (existant — KKS-086)

Déjà défini dans `recurring-transaction.model.ts`. Pas de modification nécessaire.

### TransactionForm (enrichissement — champs ajoutés au FormGroup)

| Champ | Type | Défaut | Conditionnel | Description |
|-------|------|--------|--------------|-------------|
| isRecurring | boolean | false | — | Toggle activation récurrence |
| frequency | Frequency | MENSUEL | affiché si isRecurring = true | Fréquence |
| nextOccurrence | string | '' | affiché si isRecurring = true | Date prochaine occurrence |

## Relations

- `RecurringTransactionRequest` → consommé par `RecurringTransactionService.create()` → POST /transactions/recurring
- `TransactionForm.isRecurring` → détermine le service appelé dans `onSubmit()` (RecurringTransactionService vs TransactionService)

## Transitions d'état

Le formulaire a 2 modes mutuellement exclusifs :

```
Mode normal (isRecurring = false)
  → champs : libelle, montant, date, categoryId, note, accountId
  → submit → TransactionService.create()

Mode récurrent (isRecurring = true)
  → champs : libelle, montant, frequency, nextOccurrence, categoryId, note, accountId
  → submit → RecurringTransactionService.create()
```

Le toggle `isRecurring` :
- `false → true` : masque `date`, affiche et enable `frequency` + `nextOccurrence`
- `true → false` : affiche `date`, masque et disable `frequency` + `nextOccurrence`
