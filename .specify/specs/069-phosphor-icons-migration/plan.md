# Implementation Plan: Migration Phosphor Icons

**Branch**: `069-phosphor-icons-migration` | **Date**: 2026-03-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/069-phosphor-icons-migration/spec.md`

## Summary

Migration de toutes les icones systeme vers Phosphor Icons sur les deux plateformes (Angular et Flutter). Cote Angular, les emojis Unicode utilises comme icones systeme sont remplaces par des icones Phosphor via `@ng-icons/core` + `@ng-icons/phosphor-icons`. Cote Flutter, les `Icons.*` (Material) sont remplaces par `PhosphorIcons*` via `phosphor_flutter`.

## Technical Context

**Language/Version**: TypeScript 5.9 (Angular), Dart >= 3.6 (Flutter)
**Primary Dependencies**: `@ng-icons/core` + `@ng-icons/phosphor-icons` v33.1.0 (Angular), `phosphor_flutter` v2.1.0 (Flutter)
**Storage**: N/A (aucun changement de modele de donnees)
**Testing**: Vitest (Angular), flutter_test (Flutter) — verification visuelle manuelle
**Target Platform**: Web (Angular PWA) + Mobile (Flutter iOS/Android)
**Project Type**: Web application + Mobile app (monorepo)
**Performance Goals**: Aucune degradation de performance — tree-shaking Angular pour minimiser le bundle
**Constraints**: Aucune regression visuelle, emojis utilisateur (categories, comptes) non impactes
**Scale/Scope**: ~20 emojis systeme (Angular) + ~60 Material Icons (Flutter) a migrer

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Aucun changement backend |
| II. Securite par defaut | PASS | Aucun impact securite |
| III. Simplicite & YAGNI | PASS | Remplacement 1:1, pas d'abstraction ajoutee |
| IV. Mobile-First UX | PASS | Convention de tailles (24/20/16px) et styles (regular/fill/bold) ameliorent la lisibilite mobile |
| V. Testabilite | PASS | Verification visuelle + grep automatise pour valider la migration complete |
| VI. Observabilite | N/A | Aucun impact logging |
| VII. Self-Hosted Ready | PASS | Aucune dependance cloud ajoutee — packages npm/pub embarques |

**GATE RESULT: PASS** — Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/069-phosphor-icons-migration/
├── spec.md              # Specification
├── plan.md              # This file
├── research.md          # Phase 0 — packages, inventaire, decisions
├── data-model.md        # Phase 1 — N/A (aucun changement data)
├── icon-mapping.md      # Inventaire complet des icones (FR-006)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/                              # Angular PWA
├── package.json                  # + @ng-icons/core, @ng-icons/phosphor-icons
└── src/app/
    ├── shared/components/
    │   ├── shell/                # Navigation emojis → Phosphor
    │   ├── fab/                  # FAB action emojis → Phosphor
    │   └── bottom-nav/           # Bottom nav emojis → Phosphor
    ├── features/
    │   ├── settings/             # Settings section emojis → Phosphor
    │   └── shop/                 # Shop icons
    └── core/models/
        └── preference.model.ts   # Feature icon definitions

flutter/                          # Mobile app
├── pubspec.yaml                  # + phosphor_flutter: ^2.1.0
└── lib/src/
    ├── common_widgets/           # Shared widgets (app_modal, select_picker, etc.)
    ├── features/
    │   ├── auth/                 # Login/Register icons
    │   ├── dashboard/            # Dashboard, mini cards
    │   ├── transactions/         # Transaction list/form
    │   ├── subscriptions/        # Subscription list/form
    │   ├── debts/                # Debt list/form
    │   ├── shop/                 # Product list/form/detail
    │   ├── settings/             # All settings screens
    │   └── onboarding/           # Onboarding icons
    ├── routing/
    │   └── app_router.dart       # Bottom nav icon definitions
    └── domain/enums/
        └── feature.dart          # Feature icon definitions
```

**Structure Decision**: Pas de changement de structure. Modifications in-place dans les fichiers existants des deux projets.

## Design Decisions

### D1: Strategie Angular — NgIcon component

Chaque composant Angular qui utilise des emojis systeme devra :
1. Importer `NgIcon` dans `imports`
2. Enregistrer les icones via `provideIcons()` dans `providers`
3. Remplacer les emojis par `<ng-icon name="phosphorXxx" size="24"></ng-icon>`

Convention Angular :
- Regular: `phosphorHouse` (import depuis `@ng-icons/phosphor-icons/regular`)
- Fill: `phosphorHouseFill` (import depuis `@ng-icons/phosphor-icons/fill`)
- Bold: `phosphorPlusBold` (import depuis `@ng-icons/phosphor-icons/bold`)

### D2: Strategie Flutter — PhosphorIcon widget

Remplacement direct `Icon(Icons.xxx)` → `PhosphorIcon(PhosphorIconsRegular.xxx)` :
- Navigation inactive: `PhosphorIconsRegular.xxx` (24px)
- Navigation active: `PhosphorIconsFill.xxx` (24px)
- Actions (FAB, boutons): `PhosphorIconsBold.xxx` (24px)
- Inline/listes: `PhosphorIconsRegular.xxx` (20px)
- Decoratif: `PhosphorIconsRegular.xxx` (16px)

### D3: Convention de tailles (design tokens)

| Contexte | Taille | Style |
|----------|--------|-------|
| Navigation (bottom nav, sidebar) | 24px | regular (inactif) / fill (actif) |
| Actions (FAB, boutons primaires) | 24px | bold |
| Inline (listes, formulaires, prefix) | 20px | regular |
| Decoratif (badges, indicators) | 16px | regular |

### D4: Dark theme

Les icones Phosphor heritent de `currentColor` par defaut sur les deux plateformes :
- **Angular** : `<ng-icon>` utilise `color: inherit` — les tokens CSS `--text-*` s'appliquent automatiquement en light et dark
- **Flutter** : `PhosphorIcon` utilise `IconThemeData.color` du theme — `AppTheme.light` et `AppTheme.dark` definissent deja les couleurs d'icones

Aucune action specifique requise pour le dark theme.

### D5: Migration order

1. **Packages** — Installer les dependances (Angular + Flutter)
2. **Inventaire** — Documenter le mapping complet dans `icon-mapping.md`
3. **Common/Shared** — Migrer les composants partages en priorite (impact maximal)
4. **Flutter** — Migrer ecran par ecran (~60 icones, effort principal)
5. **Angular** — Migrer ecran par ecran (~20 emojis, effort moindre)
6. **Nettoyage** — Supprimer imports inutilises, verifier builds

## Complexity Tracking

> Aucune violation de la constitution detectee — section vide.
