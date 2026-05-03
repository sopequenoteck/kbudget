# Clarify Log: KKS-225

**Issue**: Alignement design des pages Transactions, Abonnements et Dettes
**Date**: 2026-03-22
**Points trouves**: 5
**Resolus automatiquement**: 5
**Resolus interactivement**: 0
**Differes**: 0
**Categories couvertes**: 4/11

---

## Points de clarification

### CL-001 : Dot colore sur solde a zero

| Champ | Valeur |
|-------|--------|
| **Categorie** | 6 - Edge cases |
| **Impact** | Moyen |
| **Incertitude** | Haute |
| **Score** | HAUT |
| **Source** | spec.md US2 scenario 3, marqueur `[NEEDS CLARIFICATION]` |
| **Resolution** | Automatique |

**Question** : Faut-il un dot neutre (gris) si le solde est exactement zero, ou garder vert/rouge ?

**Reponse** : Dot neutre gris (`--text-secondary`). Justification : le dashboard utilise deja une variante `--neutral` (bg-tertiary + text-secondary) pour les variation badges a zero. Coherence design. Le meme pattern s'applique au dot du solde et du solde net.

---

### CL-002 : Press feedback sur cards non cliquables

| Champ | Valeur |
|-------|--------|
| **Categorie** | 3 - UX/Interaction |
| **Impact** | Moyen |
| **Incertitude** | Moyenne |
| **Score** | MOYEN |
| **Source** | spec.md Edge Cases, marqueur `[NEEDS CLARIFICATION]` |
| **Resolution** | Automatique |

**Question** : Les summary cards Solde/Solde net sont-elles cliquables ? Si non, faut-il le press feedback ?

**Reponse** : Aucune summary card des 3 pages n'est cliquable — toutes sont des `<div>` sans `routerLink` ni `(click)`. L'issue demande explicitement le press feedback sur toutes les summary cards. Le `scale(0.97)` s'applique donc a toutes les cards via `:active`, comme sur le dashboard (les summary cards du dashboard sont aussi des `<div>` non navigables).

**Source** : `transactions.html` L19-27, `debts.html` L3-29, `subscriptions.html` L4-8 — tous des `<div class="summary__card">`.

---

### CL-003 : Tokens couleurs dark mode

| Champ | Valeur |
|-------|--------|
| **Categorie** | 4 - Non-fonctionnel |
| **Impact** | Haut |
| **Incertitude** | Basse |
| **Score** | HAUT |
| **Source** | spec.md NFR-004, marqueur `[NEEDS CLARIFICATION]` |
| **Resolution** | Automatique |

**Question** : Les tokens `--color-income`, `--color-expense`, `--color-debt-owe`, `--color-debt-owed` ont-ils des variantes dark lisibles ?

**Reponse** : Oui, les 4 tokens sont definis dans les deux themes :

| Token | Light | Dark |
|-------|-------|------|
| `--color-income` | `#16a34a` (green-600) | `#4ade80` (green-400) |
| `--color-expense` | `#dc2626` (red-600) | `#f87171` (red-400) |
| `--color-debt-owe` | `#dc2626` (red-600) | `#f87171` (red-400) |
| `--color-debt-owed` | `#16a34a` (green-600) | `#4ade80` (green-400) |

Les variantes dark (shade 400) sont plus claires, adaptees au fond sombre. Lisibilite confirmee.

**Source** : `_light.scss` L56-59, `_dark.scss` L58-61.

---

### CL-004 : Validation assumption A-002 (::before non utilise)

| Champ | Valeur |
|-------|--------|
| **Categorie** | 7 - Contraintes |
| **Impact** | Haut |
| **Incertitude** | Basse |
| **Score** | HAUT |
| **Source** | spec.md Assumptions A-002 |
| **Resolution** | Automatique |

**Question** : Le pseudo-element `::before` sur `:host` est-il deja utilise par les 3 pages ?

**Reponse** : Non. Aucun `::before` n'est present dans les 3 fichiers SCSS (`transactions.scss`, `subscriptions.scss`, `debts.scss`). Le pseudo-element est libre pour le radial gradient.

**Source** : `grep ::before` sur les 3 fichiers — 0 resultat.

---

### CL-005 : Validation assumption A-001 (structure HTML similaire)

| Champ | Valeur |
|-------|--------|
| **Categorie** | 7 - Contraintes |
| **Impact** | Haut |
| **Incertitude** | Basse |
| **Score** | HAUT |
| **Source** | spec.md Assumptions A-001 |
| **Resolution** | Automatique |

**Question** : Les 3 pages utilisent-elles une structure HTML similaire pour les summary cards ?

**Reponse** : Oui, les 3 pages utilisent la meme classe `.summary__card` dans des `<div>` :
- Transactions : 3 cards (`.summary__card--income`, `.summary__card--expense`, `.summary__card--balance`)
- Dettes : 3 cards (`.summary__card` avec classes sur les `<span>` enfants : `debt-owe`, `debt-owed`)
- Abonnements : 1-N cards (`.summary__card` dans une boucle `@for`)

**Difference notable** : Transactions utilise des modifiers BEM sur la card (`--income`, `--expense`, `--balance`), Dettes met les classes sur les `<span>` enfants. Cette difference impacte l'ajout des dots : Transactions peut utiliser les modifiers existants, Dettes necessite de nouvelles classes ou attributs pour determiner la couleur du dot.

**Source** : `transactions.html` L19-27, `debts.html` L3-29, `subscriptions.html` L4-8.

---

## Points differes

Aucun.

## Modifications appliquees a spec.md

1. US2 scenario 3 : marqueur `[NEEDS CLARIFICATION]` remplace par resolution (dot neutre gris pour zero)
2. Edge Cases : marqueur `[NEEDS CLARIFICATION]` remplace par resolution (press feedback sur toutes les cards)
3. NFR-004 : marqueur `[NEEDS CLARIFICATION]` remplace par verification (tokens dark confirmes)
