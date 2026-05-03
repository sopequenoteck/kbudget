# Clarify Log: Recherche & Filtres Transactions

**Date**: 2026-04-11
**Spec**: `docs/features/search-filter-transactions/spec.md`
**Points identifies**: 5
**Categories couvertes**: 3/11 (UX/Interaction, Scope fonctionnel, Non-fonctionnel)

## Points de clarification

### CLR-001 — UX recherche : comportement du champ dans le section header

| Champ | Valeur |
|-------|--------|
| Categorie | 3 — UX/Interaction |
| Impact | Haut |
| Incertitude | Haute |
| Score | **CRITIQUE** |
| Source | US1, scenario 1 — "remplace ou s'ajoute au titre" (ambigu) |
| Resolution | **Automatique** |

**Probleme** : La spec disait "remplace ou s'ajoute au titre" — deux comportements tres differents en termes de layout et d'implementation.

**Resolution** : Le titre "Transactions" est **remplace** par un `<input>` de recherche. L'icone loupe devient X (fermer). Le champ prend toute la largeur disponible a gauche des icones filtre/recurrences. Animation `duration-fast`. Coherent avec le pattern mobile standard (TickTick, Revolut) et le vocabulaire quiet utility (pas de surface supplementaire).

**Spec modifiee** : US1 scenario 1

---

### CLR-002 — UX filtres : layout du panneau inline

| Champ | Valeur |
|-------|--------|
| Categorie | 3 — UX/Interaction |
| Impact | Haut |
| Incertitude | Haute |
| Score | **CRITIQUE** |
| Source | US2, scenario 1 — "un panneau de filtres" (non specifie visuellement) |
| Resolution | **Automatique** |

**Probleme** : Le panneau de filtres n'avait aucune specification visuelle — ni structure, ni tokens, ni animation.

**Resolution** : Panneau slide-down sous le section header. Fond `surface-default`, `radius-xl` en bas, padding `space-3`, animation `duration-fast`. Structure en 3 lignes : (1) chips type segmented (Tout/Depenses/Recettes), (2) chips categories scrollables horizontalement, (3) chips comptes si multi-comptes. Lien "Reinitialiser" en `text-tertiary` xs. Coherent avec le pattern inline expand des formulaires bottom sheet.

**Spec modifiee** : US2 scenario 1

---

### CLR-003 — Filtre par compte : pertinence si mono-compte

| Champ | Valeur |
|-------|--------|
| Categorie | 1 — Scope fonctionnel |
| Impact | Moyen |
| Incertitude | Moyenne |
| Score | **MOYEN** |
| Source | US4, marqueur `[NEEDS CLARIFICATION]` |
| Resolution | **Automatique** |

**Probleme** : Le nombre de comptes par utilisateur n'etait pas connu, remettant en question la pertinence du filtre.

**Resolution** : L'utilisateur principal a 2 comptes (EUR + CFA), donc le filtre est pertinent. La section comptes est deja specifiee comme masquee si mono-compte (US4 scenario 3 + FR-005). US4 reste en P3, pas de changement de priorite.

**Spec modifiee** : US4, "Why this priority"

---

### CLR-004 — Debounce sur la saisie recherche

| Champ | Valeur |
|-------|--------|
| Categorie | 4 — Non-fonctionnel |
| Impact | Bas |
| Incertitude | Moyenne |
| Score | **BAS** |
| Source | Edge Cases, marqueur `[NEEDS CLARIFICATION]` |
| Resolution | **Automatique** |

**Probleme** : Faut-il un debounce si le volume de transactions depasse 5000 ?

**Resolution** : Non. Pour un single-user, le volume realiste est < 2000 transactions. Un `computed()` Angular avec `filter()` + `includes()` sur 2000 objets prend < 1ms. Le debounce ajouterait de la latence perceptible sans benefice. Si le volume explose un jour, un debounce de 150ms pourra etre ajoute a posteriori.

**Spec modifiee** : Edge Cases, point "Performance"

---

### CLR-005 — Hero inchange par les filtres

| Champ | Valeur |
|-------|--------|
| Categorie | 3 — UX/Interaction |
| Impact | Moyen |
| Incertitude | Moyenne |
| Score | **MOYEN** |
| Source | FR-010 — absence de justification explicite |
| Resolution | **Interactive** (valide par l'utilisateur) |

**Probleme** : FR-010 affirmait que le hero ne change pas, mais sans justification. Un utilisateur pourrait s'attendre a ce que les filtres affectent aussi le resume financier.

**Resolution** : Confirme — le hero ne change pas. Le hero repond a "quel est mon solde ce mois-ci ?", les filtres repondent a "quelles transactions correspondent a X ?". Deux questions distinctes. Coherent avec le pattern des autres pages (hero dettes = solde net global, jamais filtre).

**Spec modifiee** : FR-010, ajout justification

---

## Points differes

Aucun. Les 5 points identifies ont tous ete resolus.

## Resume

| Metrique | Valeur |
|----------|--------|
| Points identifies | 5 |
| Resolus automatiquement | 4 |
| Resolus interactivement | 1 |
| Differes | 0 |
| Marqueurs `[NEEDS CLARIFICATION]` retires | 2/2 |
| Modifications spec.md | 5 sections |
