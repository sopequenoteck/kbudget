# Clarify Log — KKS-230

**Feature** : Autocomplete sur le champ libellé de saisie des transactions
**Date** : 2026-04-13
**Spec analysée** : `docs/features/KKS-230/spec.md`

## Résumé

- **Points identifiés** : 5
- **Catégories couvertes** : 3 / 11 (UX/Interaction, Scope fonctionnel, Intégrations)
- **Résolus automatiquement** : 1
- **Résolus interactivement** : 4
- **Différés** : 0
- **Modifications spec.md** : FR-015, FR-016, FR-017, FR-018 (ajoutés/précisés) ; edge case "accents" (reformulé) ; table "Questions ouvertes" (marquée Résolue)

## Taxonomie et scoring

| # | Point | Catégorie | Impact | Incertitude | Score | Résolution |
|---|-------|-----------|--------|-------------|-------|------------|
| 1 | Composant Angular : Material vs maison | 5. Intégrations | Haut | Haute | **CRITIQUE** | Auto |
| 2 | Seuil de déclenchement des suggestions | 3. UX/Interaction | Moyen | Moyenne | **MOYEN** | Interactif |
| 3 | Filtre `q` : startsWith vs contains | 1. Scope fonctionnel | Moyen | Moyenne | **MOYEN** | Interactif |
| 4 | Accent-sensitivity du filtre | 3. UX/Interaction | Moyen | Moyenne | **MOYEN** | Interactif |
| 5 | Nombre de suggestions affichées côté UI | 3. UX/Interaction | Bas | Moyenne | **BAS** | Interactif |

## Détail des résolutions

### Point 1 — Composant Angular : Material vs maison (CRITIQUE, résolu auto)

- **Catégorie** : Intégrations (5)
- **Impact** : Haut — détermine la stack UI du formulaire et la cohérence avec le design system.
- **Incertitude** : Haute au départ (ambiguïté sur l'usage de `@angular/material`).
- **Question posée** : Utiliser `mat-autocomplete` (Angular Material) ou un composant maison aligné sur DESIGN.md ?
- **Source de résolution** : scan de `app/package.json` — absence de `@angular/material` dans les dépendances. Le projet n'intègre pas Material Angular.
- **Résolution** : **Composant maison** aligné sur DESIGN.md. Pattern : input natif + overlay absolu + navigation clavier signals-first. Aucune nouvelle dépendance ajoutée.
- **Impact sur spec.md** : ajout de FR-018.

### Point 2 — Seuil de déclenchement (MOYEN, résolu interactif)

- **Catégorie** : UX/Interaction (3)
- **Impact** : Moyen — conditionne le nombre d'appels backend et la fluidité perçue.
- **Incertitude** : Moyenne — dépend des préférences produit.
- **Question posée** : Suggestions dès le focus (0 car.) / après 1 car. / après 2 car. ?
- **Réponse utilisateur** : **C — après 2 caractères**.
- **Justification** : évite le bruit au focus, garantit une pertinence minimale du filtre, réduit les appels backend inutiles.
- **Impact sur spec.md** : ajout de FR-015 (remplace placeholder NEEDS CLARIFICATION).

### Point 3 — Filtre `q` backend (MOYEN, résolu interactif)

- **Catégorie** : Scope fonctionnel (1)
- **Impact** : Moyen — affecte la pertinence des suggestions et la perf côté DB.
- **Incertitude** : Moyenne — arbitrage perf/UX.
- **Question posée** : `startsWith` (plus rapide) ou `contains` (plus permissif) ?
- **Réponse utilisateur** : **B — `contains`**.
- **Justification** : permet de retrouver "Carrefour Market" en tapant "market" ou "carrefour", améliore la découverte pour des libellés composés.
- **Impact sur spec.md** : ajout de FR-017. Implique l'extension PostgreSQL `unaccent` (voir point 4).
- **Attention** : à surveiller côté perf (NFR-001 < 100ms). Un index GIN `pg_trgm` sur `(user_id, LOWER(UNACCENT(label)))` pourra être envisagé en phase `/devflow.plan` si la perf se dégrade à grande échelle.

### Point 4 — Accent-sensitivity (MOYEN, résolu interactif)

- **Catégorie** : UX/Interaction (3)
- **Impact** : Moyen — UX francophone.
- **Incertitude** : Moyenne.
- **Question posée** : "cafe" doit-il matcher "Café" ?
- **Réponse utilisateur** : **B — accent-insensible**.
- **Justification** : confort de saisie francophone, cohérent avec l'objectif de friction réduite.
- **Impact sur spec.md** : FR-017 (backend via `unaccent`) + edge case reformulé (normalisation NFD côté client pour filtre local). Jamais de normalisation sur la donnée stockée : seules les comparaisons sont normalisées.
- **Dépendance nouvelle** : extension PostgreSQL `unaccent`. À vérifier si déjà activée (import CSV KKS-099 utilise Jaro-Winkler, possiblement côté Java — à confirmer). Si non, prévoir une migration Flyway `CREATE EXTENSION IF NOT EXISTS unaccent;`.

### Point 5 — Nombre de suggestions affichées (BAS, résolu interactif)

- **Catégorie** : UX/Interaction (3)
- **Impact** : Bas — ajustable sans refactoring.
- **Incertitude** : Moyenne.
- **Question posée** : 5 / 8 / 10 suggestions affichées côté UI ?
- **Réponse utilisateur** : **A — 5**.
- **Justification** : minimaliste, Mobile-First (constitution #4), lisibilité sur petit écran au pouce.
- **Impact sur spec.md** : ajout de FR-016. Le backend reste libre de retourner jusqu'à 20/50, le frontend tronque à 5.

## Points différés

Aucun. Les 5 points identifiés ont été résolus dans cette session.

## Catégories non couvertes

Sur 11 catégories de la taxonomie, 8 ne sont pas concernées par cette feature :
2 (Modèle de données — pas de nouvelle entité), 4 (Non-fonctionnel — NFRs déjà mesurables), 6 (Edge cases — couverts dans spec.md), 7 (Contraintes — couvertes par la constitution), 8 (Terminologie — rien d'ambigu), 9 (Signaux de complétion — SC-001 à SC-007 mesurables), 10 (Placeholders — aucun), 11 (Sécurité — couvert par FR-005/FR-006 et constitution #2).

## Prochaine étape

`state.json.currentStep` → `review-spec`.
Commande suggérée : `/devflow.review-spec KKS-230`.
