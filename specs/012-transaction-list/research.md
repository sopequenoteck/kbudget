# Research: Écran Transactions (liste + filtres)

**Feature**: 012-transaction-list
**Date**: 2026-02-11

## Résultat

Aucun unknown identifié dans le Technical Context. Toutes les technologies et dépendances sont déjà utilisées dans le projet.

## Décisions

### 1. Stratégie de chargement des données

- **Décision** : Charger toutes les transactions via `getAll()` et filtrer côté client par mois/année. Le résumé mensuel est chargé via `getSummary(month, year)` côté serveur.
- **Raison** : L'API ne supporte pas le filtrage par date. Le volume single-user est limité.
- **Alternatives considérées** : Ajout d'un endpoint API filtré par date — rejeté car over-engineering pour un single-user (principe III. YAGNI).

### 2. Gestion de l'état du composant

- **Décision** : Signals locaux au composant (pas de state management global).
- **Raison** : Les données sont locales à l'écran. Le `refreshTrigger` du service suffit pour la synchronisation post-CRUD.
- **Alternatives considérées** : NgRx store — rejeté, complexité excessive pour un écran de liste simple.

### 3. Pattern de rafraîchissement

- **Décision** : Utiliser `effect()` sur `TransactionService.refreshTrigger` pour recharger les données après un CRUD.
- **Raison** : Pattern déjà établi dans le projet. Le refresh trigger s'incrémente après chaque create/update/delete.
- **Alternatives considérées** : EventEmitter depuis Shell — rejeté, le signal est plus simple et découplé.

### 4. Icône par défaut pour transactions sans catégorie

- **Décision** : Utiliser l'emoji `📝` comme icône de fallback quand `category` est null.
- **Raison** : Icône neutre qui évoque une note/transaction générique.
- **Alternatives considérées** : `💳` (carte bancaire), `📋` (presse-papiers) — moins universels.
