# Contracts: KKS-225 — Alignement design pages interieures

**Date**: 2026-03-22 | **Plan**: [plan.md](plan.md)
**Reference design**: [`app/DESIGN.md`](../../app/DESIGN.md)

## Contrats visuels (reference DESIGN.md)

### Summary Cards — pages interieures

Reference : DESIGN.md > "Cards (Summary) — pages interieures" + "Regles de design"

**Regle DESIGN.md** : "Surface solide + dots colores → Pages interieures (listes longues)"

| Propriete | Valeur DESIGN.md actuelle | Valeur cible KKS-225 | Action |
|-----------|--------------------------|----------------------|--------|
| Montant font-size | `font-size-2xl` | `font-size-xl` | Modifier SCSS + mettre a jour DESIGN.md |
| Montant font-weight | `font-weight-bold` | `font-weight-bold` | Inchange |
| Label font-weight | non specifie | `font-weight-semibold` | Modifier SCSS + mettre a jour DESIGN.md |
| Dot colore | "optionnel" | Obligatoire (Transactions, Dettes) | Ajouter HTML + CSS |
| Press feedback | non documente | `scale(0.97)` sur `:active` | Ajouter CSS |
| Background | `--surface-raised` | `--surface-default` (existant) | Verifier coherence |

**Impact DESIGN.md** : la section "Cards (Summary) — pages interieures" (L38-49) DOIT etre mise a jour apres implementation pour refleter les nouvelles valeurs. Ref: FR-001, FR-002, FR-003, FR-004, FR-005.

### Radial Gradient fond de page

Reference : DESIGN.md > "Radial Gradient (Fond de page)" (L188-193)

Contrat identique au dashboard, aucun ecart :
- `::before` sur `:host`, `position: fixed`, `height: 40vh`
- `radial-gradient(ellipse at top center, var(--page-gradient-color) 0%, transparent 70%)`
- `pointer-events: none`, `z-index: -1`

Ref: FR-007.

### Listes — non-regression

Reference : DESIGN.md > "Cards (Content)" (L51-60) + "Regles de design"

**Regle DESIGN.md** : "Bloc unique + dividers → Listes longues (transactions, abonnements)"

Contrat : les listes existantes NE DOIVENT PAS etre modifiees. Le style actuel (bloc + dividers) est conforme a la regle DESIGN.md. Ref: FR-008.

### Dot colore — contrat CSS BEM

Nouvelle classe `.summary__dot` avec modifiers :

```scss
// Transactions
.summary__dot--income   { background-color: var(--color-income); }
.summary__dot--expense  { background-color: var(--color-expense); }

// Dettes
.summary__dot--owe      { background-color: var(--color-debt-owe); }
.summary__dot--owed     { background-color: var(--color-debt-owed); }

// Commun (solde a zero)
.summary__dot--neutral  { background-color: var(--text-secondary); }
```

Dimensions : `width: 8px`, `height: 8px`, `border-radius: 50%`. Ref: FR-004, FR-005.

## Pas de contrat TypeScript/API/Service

Feature CSS/HTML pure. Pas d'interface, d'endpoint API ni de service Angular a formaliser.
