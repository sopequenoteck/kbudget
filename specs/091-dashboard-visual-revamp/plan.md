# Implementation Plan: Dashboard Visual Revamp

**Branch**: `091-dashboard-visual-revamp` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/091-dashboard-visual-revamp/spec.md`

## Summary

Refonte visuelle du dashboard finance Angular pour une expérience premium inspirée iOS. Les changements sont exclusivement CSS/SCSS avec des ajustements HTML mineurs (classes CSS pour badges). Aucun changement backend, aucune nouvelle entité. 5 axes : hero card gradient, glassmorphism cards, barres budget enrichies, badges variation, et ambiance page.

## Technical Context

**Language/Version**: TypeScript 5.9, SCSS
**Primary Dependencies**: Angular 21 (standalone components, OnPush, Signals)
**Storage**: N/A (aucun changement de données)
**Testing**: `ng test` (Vitest) — tests existants doivent passer sans modification
**Target Platform**: Mobile-first PWA (Safari iOS, Chrome Android, Chrome Desktop)
**Project Type**: Web application (frontend Angular uniquement)
**Performance Goals**: Rendu dashboard ≤ 200ms de plus qu'avant (`backdrop-filter` impact)
**Constraints**: `prefers-reduced-motion` respecté, fallback pour navigateurs sans `backdrop-filter`
**Scale/Scope**: 1 page (dashboard), ~5 fichiers modifiés

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Aucun changement backend |
| II. Sécurité par défaut | N/A | Aucun changement d'auth ou de données |
| III. Simplicité & YAGNI | PASS | Uniquement du SCSS, pas de nouvelle abstraction, pas de composant supplémentaire |
| IV. Mobile-First UX | PASS | Tous les changements sont mobile-first, responsive conservé |
| V. Testabilité | PASS | Tests existants suffisants, changements purement visuels |
| VI. Observabilité | N/A | Aucun log ajouté (pas de logique métier) |
| VII. Self-Hosted Ready | N/A | Aucune dépendance externe ajoutée |

**GATE RESULT**: PASS — Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/091-dashboard-visual-revamp/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: recherche technique
├── data-model.md        # Phase 1: modèle de données (N/A)
├── quickstart.md        # Phase 1: guide démarrage rapide
├── checklists/
│   └── requirements.md  # Checklist qualité spec
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/
├── app/features/dashboard/
│   ├── dashboard.html                          # Template (badges classes)
│   ├── dashboard.scss                          # Styles principaux (hero, glass, page gradient, transactions)
│   ├── dashboard.ts                            # Composant (inchangé ou ajustement mineur)
│   └── components/
│       ├── budget-summary/budget-summary.ts    # Inline styles (barres enrichies, animation)
│       └── currency-pill-selector.ts           # Inchangé
├── shared/components/list-item/
│   └── list-item.scss                          # Déjà OK (cercles emoji existants)
└── styles/
    └── themes/
        ├── _dark.scss                          # Nouveaux tokens glassmorphism
        └── _light.scss                         # Variantes light mode
```

**Structure Decision**: Feature purement frontend Angular. Modifications dans le module dashboard existant + tokens de thème. Pas de nouveau composant, pas de nouveau service.

### Fichiers modifiés (inventaire exhaustif)

| Fichier | Changement | FR couvertes |
|---------|-----------|--------------|
| `dashboard.scss` | Hero gradient, glassmorphism cards, transactions gap, page gradient `::before`, micro-interactions `:active` | FR-001, FR-002, FR-004, FR-005, FR-008, FR-010, FR-011, FR-012 |
| `dashboard.html` | Classes badges sur variations patrimoine/revenus/dépenses | FR-003, FR-014 |
| `budget-summary.ts` | Inline styles : hauteur 7→10px, animation apparition `@keyframes`, seuil couleur inchangé (80% déjà en place) | FR-006, FR-007 |
| `_dark.scss` | Tokens glassmorphism (`--glass-bg`, `--glass-border`, `--glass-blur`) | FR-004, FR-013 |
| `_light.scss` | Hero gradient light, fond opaque stylé pour cards (pas de glassmorphism) | FR-004, FR-013 |

### Fichiers NON modifiés (confirmé par research)

| Fichier | Raison |
|---------|--------|
| `list-item.scss` | FR-009 déjà satisfait (cercle emoji avec `--color-primary-light` et `border-radius: round`) |
| `dashboard.ts` | Aucune logique métier à changer |
| `currency-pill-selector.ts` | Aucun changement requis |
| Tout fichier backend | Feature purement frontend |

## Design Decisions

### D1 — Gradient Hero Card

**Dark mode** : `linear-gradient(135deg, var(--amber-900) 0%, var(--indigo-900) 100%)`
**Light mode** : `linear-gradient(135deg, var(--amber-50) 0%, var(--indigo-50) 100%)`

Les teintes extrêmes (900/50) garantissent un gradient subtil qui ne nuit pas à la lisibilité. L'angle 135deg est la convention iOS pour les cards hero.

### D2 — Glassmorphism (dark mode uniquement)

```
background: rgba(31, 41, 55, 0.6)  // gray-800 à 60% opacité
backdrop-filter: blur(20px)
border: 1px solid rgba(255, 255, 255, 0.08)
```

Fallback via `@supports` : fond opaque `var(--surface-default)`. En light mode : fond opaque stylé (pas de glassmorphism).

### D3 — Badges variation (HTML + SCSS)

Ajout de `<span class="variation-badge variation-badge--positive/negative/neutral">` autour des textes de variation existants. Utilise les tokens feedback déjà existants (`--bg-success`, `--bg-error`, `--text-success`, `--text-error`).

### D4 — Barres de budget

Hauteur 7px → 10px. `border-radius: var(--radius-round)` déjà en place. Animation d'apparition via keyframe sur la width au mount. Seuils de couleur inchangés (80% warning, 100% danger = déjà implémenté).

### D5 — Page gradient

Pseudo-élément `::before` sur `:host` avec `position: fixed`, gradient radial amber subtil en haut de page. `pointer-events: none` pour ne pas interférer avec le contenu.

### D6 — prefers-reduced-motion

Le mécanisme existant dans `_tokens.scss` (lignes 133-138) met `--duration-*` à 0ms automatiquement. Toutes les nouvelles transitions DOIVENT utiliser ces tokens. Aucun code supplémentaire requis.

## Complexity Tracking

> Aucune violation de constitution — section vide.
