# Research: Redesign page Dettes

**Date**: 2026-02-13 | **Branch**: `022-debt-page-redesign`

## Résultat

Aucun inconnu technique identifié (`NEEDS CLARIFICATION` = 0). Cette feature est un changement purement frontend sur des patterns déjà maîtrisés dans le projet.

## Décisions

### D-001: Filtrage côté client vs côté API

- **Decision**: Filtrage côté client (charger toutes les dettes, filtrer dans les computed signals)
- **Rationale**: Permet de calculer les KPI sur les dettes en cours indépendamment du filtre affiché, sans double appel API. App single-user, dataset petit.
- **Alternatives considered**: Garder le filtrage API + appel séparé pour KPI → rejeté car complexité inutile pour un dataset petit.

### D-002: Badge "Remboursé" inline

- **Decision**: Concaténation dans le `subtitle` input de `ListItem` (ex: `"Personnel · Remboursé"`)
- **Rationale**: Pas de modification du composant partagé `ListItem`. Conforme à l'assumption "aucun nouveau composant partagé". L'opacité réduite sur l'item compense le manque de style distinct sur le texte "Remboursé".
- **Alternatives considered**:
  - Ajout d'un input `badge` sur `ListItem` → rejeté car modifie un composant partagé pour un usage unique
  - Badge via `::after` CSS pseudo-element → rejeté car fragile et non-sémantique

### D-003: Structure des sections groupées

- **Decision**: 2 `<section>` distinctes dans le template, chacune avec son `<ul>` interne
- **Rationale**: Structure HTML sémantique, chaque section est indépendante et peut disparaître via `@if`. Pas besoin d'un composant dédié (YAGNI).
- **Alternatives considered**: Composant `DebtSection` réutilisable → rejeté car ce pattern n'existe que dans cette page, pas de réutilisation.

### D-004: KPI périmètre de calcul

- **Decision**: KPI calculés sur `activeDebts` (dettes non remboursées uniquement)
- **Rationale**: Reflète la situation financière réelle actuelle. Cohérent avec les apps financières (Splitwise, Tricount). Clarification spec validée par l'utilisateur.
- **Alternatives considered**: Total global incluant remboursées → rejeté par clarification spec.
