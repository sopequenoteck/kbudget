# Research: Écran Subscriptions (liste + filtre actif)

**Feature**: 013-subscription-list
**Date**: 2026-02-12

## Résumé

Aucun NEEDS CLARIFICATION dans le Technical Context. Cette feature réutilise intégralement les patterns et composants existants. La recherche se concentre sur les décisions techniques spécifiques à l'écran Subscriptions.

## Décisions

### D1 — Calcul de la prochaine date de renouvellement

**Decision**: Calcul côté client à partir de `dateDebut` et `frequence`.

**Rationale**: L'API ne retourne pas de champ `prochainRenouvellement`. Le calcul est simple : avancer de 1 mois (MENSUEL) ou 1 an (ANNUEL) depuis `dateDebut` jusqu'à dépasser la date du jour. Volume faible (~50 abonnements), pas de problème de performance.

**Algorithme**:
```
nextDate = dateDebut
while (nextDate <= today):
  if frequence == MENSUEL: nextDate += 1 mois
  if frequence == ANNUEL: nextDate += 1 an
return nextDate
```

**Alternatives considered**:
- Calcul côté backend (endpoint dédié) — rejeté : over-engineering pour un calcul trivial, ajouterait un endpoint non nécessaire.

### D2 — Formatage montant avec fréquence combiné

**Decision**: Créer un helper `formatSubscriptionAmount()` dans le composant (pas un pipe dédié).

**Rationale**: Le format "24,90 €/mois" combine montant + fréquence. L'AmountPipe existant ne gère pas les suffixes "/mois" ou "/an". Un helper local dans le composant suffit (appelé 1 seul endroit). Un pipe dédié serait du YAGNI.

**Format**:
- MENSUEL : `{montant formaté} €/mois`
- ANNUEL : `{montant formaté} €/an`

**Alternatives considered**:
- Pipe dédié `SubscriptionAmountPipe` — rejeté : utilisé uniquement dans ce composant, YAGNI.
- Extension de l'AmountPipe existant — rejeté : ajouterait de la complexité à un pipe stable utilisé ailleurs.

### D3 — Calcul du total mensuel

**Decision**: Computed signal dans le composant calculant le total à partir des abonnements actifs chargés.

**Rationale**: Le total mensuel est dérivé des données déjà en mémoire. Pour les abonnements annuels, diviser par 12. Pas besoin d'endpoint API dédié.

**Formule**: `sum(actifs.map(s => s.frequence === 'ANNUEL' ? s.montant / 12 : s.montant))`

**Alternatives considered**:
- Endpoint API `/subscriptions/summary` — rejeté : ajouterait un endpoint backend non nécessaire pour un calcul trivial côté client.

### D4 — Stratégie de filtrage (serveur vs client)

**Decision**: Filtrage côté serveur via le paramètre `actif` du `SubscriptionService.getAll(actif?)`.

**Rationale**: L'API supporte déjà le paramètre `?actif=true/false`. Cohérent avec la spec (FR-006). Le filtre "Tous" appelle `getAll()` sans paramètre.

**Alternatives considered**:
- Filtrage côté client (charger tout, filtrer en mémoire) — rejeté : même si le volume est faible, rester cohérent avec l'API existante et la spec.

### D5 — Tri par défaut

**Decision**: Tri alphabétique par nom (`nom`), côté client après réception des données.

**Rationale**: Assumé dans la spec (section Assumptions). Les Transactions trient par date (pertinent pour les transactions datées), mais les abonnements sont récurrents — le tri par nom est plus naturel pour retrouver un abonnement.

**Alternatives considered**:
- Tri par montant décroissant — rejeté : moins intuitif pour retrouver un abonnement.
- Tri par prochaine date de renouvellement — possible mais plus complexe à calculer, laissé pour une future itération.
