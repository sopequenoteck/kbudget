# Implementation Plan: Créer AmountPipe et RelativeDatePipe

**Branch**: `007-format-pipes` | **Date**: 2026-02-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-format-pipes/spec.md`

## Summary

Créer deux pipes Angular standalone (`AmountPipe` et `RelativeDatePipe`) pour le formatage des montants en euros (conventions fr-FR, signe conditionnel selon le type métier) et des dates relatives (langage naturel pour les dates récentes, format long pour les anciennes). Ces pipes utilitaires purs sont des fondations de la Phase 4 consommées par tous les écrans fonctionnels (KKS-54 à KKS-57).

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/core` (Pipe, PipeTransform), `Intl.NumberFormat`, `Intl.DateTimeFormat`
**Storage**: N/A (pipes purs sans état, sans persistance)
**Testing**: Vitest 4.x via `npx vitest run`, `@analogjs/vite-plugin-angular`, jsdom
**Target Platform**: PWA mobile-first (navigateurs modernes supportant Intl)
**Project Type**: Frontend Angular (monorepo `app/`)
**Performance Goals**: N/A (transformation synchrone pure, pas de goulot d'étranglement)
**Constraints**: Locale fr-FR uniquement, devise EUR uniquement
**Scale/Scope**: 2 pipes, ~50-80 lignes chacun + tests unitaires

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Applicable | Statut | Notes |
|----------|-----------|--------|-------|
| I. API-First | Non | N/A | Feature purement frontend (transformation d'affichage), pas d'endpoint API |
| II. Sécurité par défaut | Non | N/A | Pipes purs sans accès données sensibles |
| III. Simplicité & YAGNI | Oui | PASS | Deux fichiers simples, pas d'abstraction, pas de factory, pas de service wrapper |
| IV. Mobile-First UX | Oui | PASS | Formatage fr-FR adapté à l'affichage mobile (montants lisibles, dates compréhensibles) |
| V. Testabilité | Oui | PASS | Pipes purs = entrée/sortie déterministe, testables unitairement sans TestBed |
| VI. Observabilité | Non | N/A | Pas de logging nécessaire (transformation synchrone pure) |
| VII. Self-Hosted Ready | Non | N/A | Pas de dépendance externe (Intl est natif au navigateur) |

**Résultat GATE** : PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/007-format-pipes/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/shared/pipes/
├── amount.pipe.ts            # AmountPipe (standalone)
└── relative-date.pipe.ts     # RelativeDatePipe (standalone)

app/src/app/shared/pipes/
├── amount.pipe.spec.ts       # Tests unitaires AmountPipe
└── relative-date.pipe.spec.ts # Tests unitaires RelativeDatePipe
```

**Structure Decision** : Les pipes sont placés dans `app/src/app/shared/pipes/` conformément à la structure existante du projet (dossier `pipes/` déjà créé mais vide). Les fichiers de test sont co-localisés avec les fichiers source (pattern standard Angular). Pas de barrel file (YAGNI, convention projet).

## Complexity Tracking

> Aucune violation de constitution — tableau non nécessaire.
