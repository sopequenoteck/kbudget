# Implementation Plan: Alignement design des pages Transactions, Abonnements et Dettes

**Branch**: `sopequenotech/kks-225-alignement-design-des-pages-transactions-abonnements-et` | **Date**: 2026-03-22 | **Spec**: [spec.md](spec.md)

## Summary

Harmoniser les summary cards et le fond de page des 3 pages interieures (Transactions, Abonnements, Dettes) avec le langage visuel du dashboard redesigne. Modifications CSS + HTML mineures sur 6 fichiers (3 SCSS + 3 HTML). Pas de changement sur les listes.

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21, SCSS
**Primary Dependencies**: Design tokens (`app/src/styles/themes/`)
**Storage**: N/A
**Testing**: Verification visuelle (light/dark mode)
**Target Platform**: PWA mobile-first
**Constraints**: Tokens existants uniquement, pas de valeurs hardcodees

## Constitution Check

| # | Principe | Statut | Commentaire |
|---|----------|--------|-------------|
| I | API-First | N/A | Pas de modification backend |
| II | Securite par defaut | N/A | Pas de donnees sensibles |
| III | Simplicite & YAGNI | PASS | Modifications minimales (CSS + dots HTML) |
| IV | Mobile-First UX | PASS | Press feedback tactile, typographie lisible |
| V | Testabilite | N/A | Modifications CSS, test visuel |
| VI | Observabilite | N/A | Pas de logging |
| VII | Self-Hosted Ready | N/A | Pas d'infra |

Aucune violation. Aucune derogation.

## Project Structure

```text
app/src/app/features/
├── transactions/
│   ├── transactions.html        # (M) Ajout dots HTML
│   └── transactions.scss        # (M) Typo, press feedback, gradient, dots
├── subscriptions/
│   ├── subscriptions.html       # Pas de modification (pas de dot)
│   └── subscriptions.scss       # (M) Typo, press feedback, gradient
└── debts/
    ├── debts.html               # (M) Ajout dots HTML
    └── debts.scss               # (M) Typo, press feedback, gradient, dots
```

**5 fichiers modifies, 0 cree.**

## Architecture des modifications

### Composant 1 : Radial gradient fond de page (FR-007)

**Fichiers**: `transactions.scss`, `subscriptions.scss`, `debts.scss` (M)

Ajouter dans le bloc `:host` existant de chaque fichier :

```scss
&::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 40vh;
  background: radial-gradient(ellipse at top center, var(--page-gradient-color) 0%, transparent 70%);
  pointer-events: none;
  z-index: -1;
}
```

Pattern identique au dashboard (`dashboard.scss` L8-18). Les 3 pages ont deja `position: relative` implicite via flex — le pseudo-element `fixed` fonctionne sans conflit. Aucun `::before` existant sur `:host`.

### Composant 2 : Typographie summary cards (FR-001, FR-002)

**Fichiers**: `transactions.scss`, `subscriptions.scss`, `debts.scss` (M)

Changements SCSS :

| Page | Propriete | Avant | Apres |
|------|-----------|-------|-------|
| Transactions | `.summary__value font-size` | `var(--font-size-lg)` (L116) | `var(--font-size-xl)` |
| Transactions | `.summary__label font-weight` | `var(--font-weight-medium)` (L110) | `var(--font-weight-semibold)` |
| Abonnements | `.summary__value font-size` | `var(--font-size-2xl)` (L30) | `var(--font-size-xl)` |
| Abonnements | `.summary__label font-weight` | `var(--font-weight-medium)` (L24) | `var(--font-weight-semibold)` |
| Dettes | `.summary__value font-size` | `var(--font-size-lg)` (L35) | `var(--font-size-xl)` |
| Dettes | `.summary__label font-weight` | `var(--font-weight-medium)` (L29) | `var(--font-weight-semibold)` |

### Composant 3 : Press feedback (FR-003)

**Fichiers**: `transactions.scss`, `subscriptions.scss`, `debts.scss` (M)

Ajouter sur `.summary__card` de chaque fichier :

```scss
transition: transform var(--duration-fast) var(--easing-default);

&:active {
  transform: scale(0.97);
}
```

Pattern identique au dashboard (`dashboard.scss` L49-52, L157-158).

### Composant 4 : Dots colores — Transactions (FR-004)

**Fichiers**: `transactions.html` (M), `transactions.scss` (M)

**HTML** — Ajouter un `<span class="summary__dot summary__dot--income">` (resp. `--expense`, `--balance`) dans chaque `.summary__card`, avant le label. Pour la card `--balance`, ajouter un binding conditionnel : `[ngClass]="balance >= 0 ? 'summary__dot--income' : 'summary__dot--expense'"`, et si balance === 0 : `'summary__dot--neutral'`.

**SCSS** — Ajouter dans le bloc `.summary` :

```scss
&__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;

  &--income { background-color: var(--color-income); }
  &--expense { background-color: var(--color-expense); }
  &--neutral { background-color: var(--text-secondary); }
}
```

### Composant 5 : Dots colores — Dettes (FR-005)

**Fichiers**: `debts.html` (M), `debts.scss` (M)

**HTML** — Ajouter un `<span class="summary__dot">` dans chaque `.summary__card`. Pour Emprunts : `summary__dot--owe`, pour Prets : `summary__dot--owed`, pour Solde net : binding conditionnel sur le signe.

**SCSS** — Ajouter dans le bloc `.summary` :

```scss
&__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;

  &--owe { background-color: var(--color-debt-owe); }
  &--owed { background-color: var(--color-debt-owed); }
  &--neutral { background-color: var(--text-secondary); }
}
```

### Composant 6 : Pas de dot — Abonnements (FR-006)

Aucune modification HTML pour les abonnements. FR-006 est un requirement negatif (verification d'absence).

### Composant 7 : Non-regression listes (FR-008)

Aucune modification des sections liste (`transaction-list`, `subscription-list`, `debt-list`, `debt-section`). Verification visuelle post-implementation.

### Mapping FR → Composants

| FR | Composant(s) | Fichiers |
|----|-------------|----------|
| FR-001 | Composant 2 | 3 SCSS |
| FR-002 | Composant 2 | 3 SCSS |
| FR-003 | Composant 3 | 3 SCSS |
| FR-004 | Composant 4 | transactions.html + .scss |
| FR-005 | Composant 5 | debts.html + .scss |
| FR-006 | Composant 6 | Aucun (verification) |
| FR-007 | Composant 1 | 3 SCSS |
| FR-008 | Composant 7 | Aucun (verification) |

## Risques

| Risque | Impact | Probabilite | Mitigation |
|--------|--------|-------------|------------|
| Debordement montant long avec font-size-xl sur petit ecran | Moyen | Basse | `white-space: nowrap` deja en place sur Transactions/Dettes. Abonnements n'a pas ce style → l'ajouter. Comportement identique au dashboard (meme token) |
| Press feedback sur cards non cliquables peut confondre l'utilisateur | Bas | Basse | Decision explicite de l'issue : feedback sensoriel sur toutes les cards. Coherent avec le dashboard |

## Hors scope

- Modification des listes (transactions, abonnements, dettes)
- Glassmorphism (specifique dashboard)
- Items separes avec shadow individuelle (specifique dashboard)
- Modification du HTML des listes
- Modification du composant `app-list-item`

## Complexity Tracking

Aucune complexite ajoutee. Modifications CSS directes sur des fichiers existants avec des patterns deja en place dans le dashboard.

## Artefacts complementaires

- `research.md` : non requis (patterns deja valides dans le dashboard)
- `data-model.md` : non requis (pas d'entites de donnees)
- `quickstart.md` : non requis (modifications CSS/HTML mineures)
