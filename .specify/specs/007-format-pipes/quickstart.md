# Quickstart: 007-format-pipes

**Date**: 2026-02-09
**Objectif**: Vérifier que les deux pipes fonctionnent correctement dans l'application.

## Prérequis

- Node.js installé
- Dépendances installées (`cd app && npm install`)

## Tests automatisés

```bash
cd app && npx vitest run --reporter=verbose
```

Les tests couvrent :
- AmountPipe : formatage nominal, signe +/-, montant 0, null/undefined, sans type
- RelativeDatePipe : aujourd'hui, hier, demain, jours, semaines, date longue, null/undefined, date invalide

## Test manuel

### 1. Vérifier AmountPipe

Dans un template Angular existant (ex: transactions), utiliser :

```html
<!-- Avec type (affiche signe) -->
{{ transaction.montant | amount:transaction.type }}

<!-- Sans type (pas de signe) -->
{{ subscription.montant | amount }}
```

**Résultats attendus** :
- Recette 2100 → `+2 100,00 €`
- Dépense 9.99 → `-9,99 €`
- Abonnement 14.99 → `14,99 €`
- Montant 0 → `0,00 €`

### 2. Vérifier RelativeDatePipe

```html
{{ transaction.date | relativeDate }}
```

**Résultats attendus** :
- Date du jour → `Aujourd'hui`
- Date d'hier → `Hier`
- Il y a 3 jours → `il y a 3 jours`
- Il y a 14 jours → `il y a 2 semaines`
- Date ancienne → `26 décembre 2025` (format long fr-FR)

### 3. Vérifier les cas limites

```html
{{ null | amount }}           <!-- chaîne vide -->
{{ undefined | relativeDate }} <!-- chaîne vide -->
{{ null | amount:'RECETTE' }} <!-- chaîne vide -->
```

### 4. Vérifier le build

```bash
cd app && npx ng build
```

Pas d'erreur ni de warning.

### 5. Vérifier le lint

```bash
cd app && npx ng lint
```

Pas d'erreur.
