# Data Model: 007-format-pipes

**Date**: 2026-02-09
**Status**: Complete

## Entités consommées (existantes, non modifiées)

Cette feature ne crée pas de nouvelles entités. Les pipes consomment les champs des entités existantes :

### Transaction (existante)
- `montant: number` → consommé par AmountPipe
- `type: TransactionType` (`'DEPENSE'` | `'RECETTE'`) → paramètre du AmountPipe pour le signe
- `date: string` (ISO YYYY-MM-DD) → consommé par RelativeDatePipe

### Subscription (existante)
- `montant: number` → consommé par AmountPipe (sans type = pas de signe)
- `dateDebut: string` (ISO YYYY-MM-DD) → consommé par RelativeDatePipe

### Debt (existante)
- `montant: number` → consommé par AmountPipe
- `sens: DebtType` (`'JE_DOIS'` | `'ON_ME_DOIT'`) → paramètre du AmountPipe pour le signe
- `date: string` (ISO YYYY-MM-DD) → consommé par RelativeDatePipe

## Types créés par cette feature

### AmountPipe — Signature de transformation

```
Input:  value: number | null | undefined
Param:  type?: string | null  (valeurs attendues: 'RECETTE', 'DEPENSE', 'ON_ME_DOIT', 'JE_DOIS')
Output: string
```

**Mapping signe** :

| Valeur type | Signe | Exemple sortie |
|-------------|-------|----------------|
| `'RECETTE'` | `+` | `+2 100,00 €` |
| `'ON_ME_DOIT'` | `+` | `+500,00 €` |
| `'DEPENSE'` | `-` | `-9,99 €` |
| `'JE_DOIS'` | `-` | `-150,00 €` |
| `null` / `undefined` / autre | aucun | `1 500,50 €` |
| (tout type, montant = 0) | aucun | `0,00 €` |
| `null` / `undefined` (value) | — | `''` (chaîne vide) |

### RelativeDatePipe — Signature de transformation

```
Input:  value: string | null | undefined  (ISO date YYYY-MM-DD)
Output: string
```

**Mapping temporel** :

| Condition | Sortie | Exemple |
|-----------|--------|---------|
| Même jour | `Aujourd'hui` | — |
| Veille | `Hier` | — |
| Lendemain | `Demain` | — |
| 2-7 jours passés | `il y a X jours` | `il y a 3 jours` |
| 8-30 jours passés | `il y a X semaines` | `il y a 2 semaines` |
| >30 jours passés | Date longue fr-FR | `26 décembre 2025` |
| >1 jour futur | Date longue fr-FR | `15 mars 2026` |
| `null` / `undefined` / invalide | `''` (chaîne vide) | — |

**Calcul semaines** : `Math.floor(diffJours / 7)` — arrondi inférieur.
