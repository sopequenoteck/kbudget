# Quickstart: Écran Subscriptions (liste + filtre actif)

**Feature**: 013-subscription-list
**Date**: 2026-02-12

## Prérequis

- Node.js installé
- Backend API en cours d'exécution (`cd api && mvn spring-boot:run`)
- Au moins 1 abonnement créé via la modal (bouton FAB +)

## Lancer le dev server

```bash
cd app && ng serve
```

Naviguer vers `http://localhost:4200/subscriptions`.

## Fichiers à modifier

| Fichier | Action |
|---------|--------|
| `app/src/app/features/subscriptions/subscriptions.ts` | Implémenter le composant (signals, effect, loadData) |
| `app/src/app/features/subscriptions/subscriptions.html` | Implémenter le template (filtre, résumé, liste, états) |
| `app/src/app/features/subscriptions/subscriptions.scss` | Implémenter les styles (BEM, design tokens) |

## Dépendances existantes (ne pas modifier)

| Dépendance | Chemin | Usage |
|------------|--------|-------|
| SubscriptionService | `core/services/subscription.ts` | `getAll(actif?)`, `refreshTrigger` |
| Subscription model | `core/models/subscription.model.ts` | Interface + Frequency enum |
| ListItem | `shared/components/list-item/` | Composant d'affichage par élément |
| AmountPipe | `shared/pipes/amount.pipe.ts` | Formatage montant EUR |
| RelativeDatePipe | `shared/pipes/relative-date.pipe.ts` | Formatage date relative |

## Pattern de référence

L'écran Transactions (`features/transactions/`) est le modèle exact à suivre pour :
- La structure du composant (signals + effect + loadData)
- Le template (filtre toggle + états + @for liste)
- Les styles SCSS (BEM + design tokens)

## Vérification

1. L'écran affiche la liste des abonnements
2. Le filtre Tous/Actifs/Inactifs fonctionne
3. Le total mensuel s'affiche correctement (annuels convertis /12)
4. Les états loading/error/empty s'affichent
5. La liste se rafraîchit après ajout via la modal
6. Le badge "Inactif" apparaît sur les abonnements inactifs

## Tests

```bash
cd app && npx vitest run --reporter=verbose
```
