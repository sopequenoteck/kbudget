# Implementation Plan: Bottom Nav Revamp

**Branch**: `092-bottom-nav-revamp` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/092-bottom-nav-revamp/spec.md`

## Summary

Refonte visuelle du bottom nav Angular : pill indicator sur l'onglet actif, glassmorphism (dark mode), police réduite pour 6+ items. Réutilise les tokens glassmorphism de la feature 091. Changements localisés dans 2 fichiers (bottom-nav.scss, bottom-nav.ts) + tokens thème.

## Technical Context

**Language/Version**: TypeScript 5.9, SCSS
**Primary Dependencies**: Angular 21 (standalone, OnPush, Signals), Phosphor Icons
**Storage**: N/A
**Testing**: Vitest — 5 tests existants doivent passer
**Target Platform**: Mobile-first PWA (< 768px)
**Project Type**: Web application (frontend Angular uniquement)
**Performance Goals**: Aucun impact de rendu supplémentaire
**Constraints**: `prefers-reduced-motion` respecté, fallback `backdrop-filter`
**Scale/Scope**: 2-3 fichiers modifiés

## Constitution Check

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Aucun changement backend |
| II. Sécurité | N/A | Aucun changement auth/données |
| III. Simplicité/YAGNI | PASS | SCSS uniquement, pas de nouvelle abstraction |
| IV. Mobile-First | PASS | Bottom nav est mobile-only (< 768px) |
| V. Testabilité | PASS | Tests existants suffisants |
| VI. Observabilité | N/A | Pas de logique métier |
| VII. Self-Hosted | N/A | Pas de dépendance externe |

**GATE RESULT**: PASS

## Project Structure

### Documentation (this feature)

```text
specs/092-bottom-nav-revamp/
├── plan.md
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
app/src/
├── app/shared/components/bottom-nav/
│   ├── bottom-nav.ts          # Template + TS (pill indicator, classe count)
│   └── bottom-nav.scss        # Styles (glassmorphism, pill, police réduite)
└── styles/themes/
    ├── _dark.scss              # Token --nav-glass-* (si distinct de 091)
    └── _light.scss             # Variantes light
```

**Structure Decision**: Les tokens glassmorphism `--glass-bg`, `--glass-border`, `--glass-blur` de la feature 091 sont réutilisés. Aucun nouveau token à créer — la barre utilise les mêmes valeurs que les summary cards. Seul ajout potentiel : `--nav-border-top` pour la bordure supérieure en light mode.

### Fichiers modifiés (inventaire exhaustif)

| Fichier | Changement | FR couvertes |
|---------|-----------|--------------|
| `bottom-nav.scss` | Glassmorphism, pill indicator, shadow remplacée, police réduite | FR-001 à FR-011 |
| `bottom-nav.ts` | Classe CSS conditionnelle pour le pill, host binding pour item count | FR-001, FR-002, FR-007 |
| `_dark.scss` | Token `--nav-border-top` (optionnel, si bordure spécifique dark) | FR-006 |
| `_light.scss` | Token `--nav-border-top` pour bordure subtile en light mode | FR-005 |

### Fichiers NON modifiés

| Fichier | Raison |
|---------|--------|
| `shell.ts` / `shell.html` / `shell.scss` | Le shell passe déjà `navItems()` au bottom nav — aucun changement nécessaire |
| `dashboard.*` | Pas de lien avec le bottom nav |
| Tout fichier backend | Feature purement frontend |

## Design Decisions

### D1 — Pill Indicator

Un pseudo-élément `::before` sur `.nav-item.active` crée le pill derrière l'icône. Dimensions : `width: 56px`, `height: 32px`, `border-radius: var(--radius-round)`, `background: var(--color-primary-light)`. Positionné en absolute derrière l'icône via `z-index: -1`.

### D2 — Glassmorphism (dark mode uniquement)

Réutilise les tokens de 091 (`--glass-bg`, `--glass-border`, `--glass-blur`). Le fond `var(--surface-default)` est remplacé par `var(--glass-bg)`. En light mode, le blur est à 0px et le bg est opaque (via les tokens existants). Shadow hardcodée remplacée par `border-top: 1px solid var(--glass-border)`.

### D3 — Police réduite pour 6+ items

Le composant expose le nombre d'items via un `[attr.data-item-count]` sur le host. Le CSS cible `[data-item-count="6"] .nav-item__label` avec `font-size: 10px`. Pas de logique TypeScript complexe, juste un binding d'attribut.

### D4 — prefers-reduced-motion

Les transitions pill (apparition/disparition) utilisent `--duration-normal` qui passe à 0ms automatiquement via `_tokens.scss`. Pas de code supplémentaire.

## Complexity Tracking

> Aucune violation — section vide.
