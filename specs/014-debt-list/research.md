# Research: Ecran Debts (liste + filtres)

**Date**: 2026-02-12
**Status**: Complete — aucun NEEDS CLARIFICATION a resoudre

## Contexte

Feature purement frontend. Tous les services, composants, pipes et tokens necessaires existent deja. Aucune recherche externe requise.

## Decisions

### D1 : Pattern de composant

- **Decision** : Suivre le pattern de `Subscriptions` (KKS-55) avec `firstValueFrom()` et `effect()`
- **Rationale** : Pattern le plus recent dans le codebase, utilise `async/await` au lieu de `subscribe()` (conforme a la conformite precedente)
- **Alternatives** : Pattern `Transactions` (KKS-54) avec `forkJoin` et `subscribe()` — rejete car moins conforme aux conventions actuelles

### D2 : Filtre statut — implementation via API

- **Decision** : Le filtre statut appelle `DebtService.getAll(rembourse?: boolean)` a chaque changement
- **Rationale** : L'API supporte deja le parametre `?rembourse=true/false`. Coherent avec le pattern `SubscriptionService.getAll(actif?: boolean)`
- **Alternatives** : Charger toutes les dettes et filtrer cote client — rejete car ne tire pas parti de l'API existante et charge des donnees inutiles

### D3 : Filtre sens — implementation cote client

- **Decision** : Filtrer par `DebtType` dans un `computed()` sur les dettes deja chargees
- **Rationale** : L'API ne supporte pas le filtrage par sens. Le volume de dettes est faible (dizaines). Un `computed()` est reactif et performant.
- **Alternatives** : Ajouter un parametre API `?sens=JE_DOIS` — rejete car hors scope (backend non modifie dans cette feature)

### D4 : Resume calcule cote client

- **Decision** : Calculer les totaux dans des `computed()` a partir des dettes filtrees
- **Rationale** : Pas d'endpoint API de resume pour les dettes. Le calcul est trivial (somme de montants). Coherent avec YAGNI.
- **Alternatives** : Creer un endpoint `/debts/summary` — rejete car over-engineering pour un calcul simple sur un petit volume

### D5 : Icones par sens

- **Decision** : Utiliser des emojis : `💸` pour JE_DOIS, `💰` pour ON_ME_DOIT
- **Rationale** : Coherent avec le pattern des transactions (emoji par categorie). Differenciation visuelle immediate sans dependance a une librairie d'icones.
- **Alternatives** : Icones SVG — rejete car les ecrans existants utilisent des emojis

### D6 : Classes CSS pour les couleurs de dettes

- **Decision** : Definir `.debt-owe` et `.debt-owed` dans le SCSS du composant, utilisant `var(--color-debt-owe)` et `var(--color-debt-owed)`
- **Rationale** : Les tokens CSS sont deja definis dans les themes light et dark. Pas besoin de classes utilitaires globales car seul cet ecran les utilise.
- **Alternatives** : Ajouter des classes dans `_utilities.scss` — rejete car violation de YAGNI (un seul usage)
