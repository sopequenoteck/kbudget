# Data Model: Formulaire Debt (modal)

**Feature**: 011-debt-form | **Date**: 2026-02-11

## Entites

### Debt (lecture — mode edition)

Source : `app/src/app/core/models/debt.model.ts`

| Champ | Type | Description |
|-------|------|-------------|
| id | string (UUID) | Identifiant unique |
| personne | string | Nom de la personne |
| montant | number | Montant de la dette (> 0) |
| sens | DebtType | JE_DOIS ou ON_ME_DOIT |
| date | string | Date au format YYYY-MM-DD |
| rembourse | boolean | Statut rembourse ou non |
| category | Category \| null | Categorie associee (optionnelle) |

### DebtRequest (ecriture — emission)

Source : `app/src/app/core/models/debt.model.ts`

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| personne | string | Oui | Nom de la personne |
| montant | number | Oui | Montant (> 0) |
| sens | DebtType | Oui | JE_DOIS ou ON_ME_DOIT |
| date | string | Oui | Date au format YYYY-MM-DD |
| rembourse | boolean | Non | Defaut false |
| categoryId | string | Non | UUID de la categorie |

### DebtType (enum)

Source : `app/src/app/core/models/debt.model.ts`

| Valeur | Label UI |
|--------|----------|
| JE_DOIS | Emprunt |
| ON_ME_DOIT | Pret |

### Category (reference)

Source : `app/src/app/core/models/category.model.ts`

Utilisee pour le select categories. Chargee via `CategoryService.getAll()`.

## Mapping formulaire → DTO

| Champ formulaire | FormControl | Valeur par defaut | → DebtRequest |
|------------------|-------------|-------------------|---------------|
| Personne | `personne` (required, maxLength 255) | `''` | `personne` |
| Montant | `montant` (required, min 0.01) | `null` | `montant` |
| Sens | `sens` (required) | `DebtType.JE_DOIS` | `sens` |
| Date | `date` (required) | Aujourd'hui (YYYY-MM-DD) | `date` |
| Rembourse | `rembourse` | `false` | `rembourse` |
| Categorie | `categoryId` | `''` (aucune) | `categoryId` (omis si vide) |

## Regles de validation

| Champ | Regle | Message d'erreur |
|-------|-------|-----------------|
| personne | required | "Personne requise" |
| personne | maxLength(255) | "255 caracteres maximum" |
| montant | required | "Montant requis" |
| montant | min(0.01) | "Le montant doit etre superieur a 0" |
| date | required | "Date requise" |

## Notes

- Le formulaire n'appelle pas le backend. Il emet un `DebtRequest` via l'output `saved`.
- Le composant parent (Shell) recoit l'evenement et appelle `DebtService.create()` ou `DebtService.update()`.
- En mode edition, le `categoryId` est extrait de `debt.category?.id`.
