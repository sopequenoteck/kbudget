# Quickstart: Écran Transactions (liste + filtres)

**Feature**: 012-transaction-list
**Date**: 2026-02-11

## Prérequis

- Node.js installé
- `cd app && npm install` exécuté
- Backend API lancé (`cd api && mvn spring-boot:run`)

## Développement

```bash
cd app && ng serve
```

Naviguer vers `http://localhost:4200/transactions` (authentification requise).

## Tests

```bash
cd app && npx vitest run
```

## Fichiers à modifier

| Fichier | Action |
|---------|--------|
| `app/src/app/features/transactions/transactions.ts` | Implémenter le composant |
| `app/src/app/features/transactions/transactions.html` | Implémenter le template |
| `app/src/app/features/transactions/transactions.scss` | Implémenter les styles |

## Composants réutilisés

| Composant | Import | Usage |
|-----------|--------|-------|
| `ListItem` | `../../shared/components/list-item/list-item` | Ligne de transaction |
| `AmountPipe` | `../../shared/pipes/amount.pipe` | Formatage montant |
| `RelativeDatePipe` | `../../shared/pipes/relative-date.pipe` | Date relative |

## Services injectés

| Service | Méthodes utilisées |
|---------|-------------------|
| `TransactionService` | `getAll()`, `getSummary(month, year)`, `refreshTrigger` |

## Validation

1. Ouvrir l'écran Transactions → liste du mois courant visible
2. Cliquer ◀/▶ → changement de mois, liste et résumé mis à jour
3. Cliquer Dépenses/Recettes/Tous → filtrage instantané
4. Vérifier l'état vide (mois sans transactions)
5. Vérifier l'état erreur (couper le backend)
6. Créer une transaction via le FAB → liste rafraîchie automatiquement
