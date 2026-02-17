# Implementation Plan: SelectPicker generique

**Branch**: `029-select-picker` | **Date**: 2026-02-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/029-select-picker/spec.md`

## Summary

Mutualiser les 3 patterns de selection existants (select natif, category-picker custom, account-picker chips) en un composant generique `SelectPicker` implementant `ControlValueAccessor`. Le composant fournit un dropdown custom cross-browser coherent avec recherche optionnelle, navigation clavier, accessibilite ARIA et bottom-sheet sur mobile. Le `CategoryPicker` existant est refactore en thin wrapper autour du `SelectPicker` pour conserver la creation inline. L'`AccountPicker` et les `<select>` natifs sont remplaces par le `SelectPicker` configure pour les comptes.

## Technical Context

**Language/Version**: TypeScript 5.9.2, Angular 21.1.0
**Primary Dependencies**: @angular/core, @angular/forms (ControlValueAccessor), @angular/cdk (CdkTrapFocus pour le bottom-sheet)
**Storage**: N/A (composant frontend pur, pas de persistance)
**Testing**: Vitest 4.0.18 + @analogjs/vitest-angular 2.2.3, vi.fn() pour mocks, TestBed
**Target Platform**: PWA Angular, Chrome/Safari/Firefox, mobile-first (breakpoint 768px)
**Project Type**: web (frontend uniquement)
**Performance Goals**: Scroll fluide avec 50+ items, filtre reactif sans lag perceptible
**Constraints**: Pas de select natif, uniquement des CSS custom properties (var(--token)), OnPush change detection, signals-first
**Scale/Scope**: 1 composant generique + 1 wrapper categorie, migration de 3 formulaires (transfer-form, transaction-form, subscription-form), suppression de account-picker. Le debt-form n'est pas modifie (utilise CategoryPicker via formControlName, impacte indirectement par le refactoring du wrapper). Le shell n'est pas modifie (layout qui rend les formulaires, aucun picker propre).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature purement frontend, aucun endpoint modifie |
| II. Securite par defaut | N/A | Pas de donnees sensibles, pas de route API |
| III. Simplicite & YAGNI | PASS | 1 composant generique + 1 wrapper, pas de multi-select, pas de virtualisation |
| IV. Mobile-First UX | PASS | Bottom-sheet sur mobile (<768px), dropdown sur desktop |
| V. Testabilite | PASS | Tests unitaires SelectPicker + tests regression formulaires existants |
| VI. Observabilite | N/A | Composant frontend, pas de logging serveur |
| VII. Self-Hosted Ready | N/A | Pas de dependance externe ajoutee, @angular/cdk deja installe |

**Gate result**: PASS — aucune violation.

**Post-Phase 1 re-check**: PASS — la conception (interface SelectPickerItem, bottom-sheet via media queries, wrapper CategoryPicker) reste alignee avec Simplicite & YAGNI (pas de ng-template, pas de CDK Overlay), Mobile-First UX (bottom-sheet 768px) et Testabilite (tests unitaires + regression).

## Project Structure

### Documentation (this feature)

```text
specs/029-select-picker/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (component API & interfaces)
├── quickstart.md        # Phase 1 output (usage examples)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/shared/components/
├── select-picker/                    # NOUVEAU - composant generique
│   ├── select-picker.ts             # Component + ControlValueAccessor
│   ├── select-picker.html           # Template (dropdown + bottom-sheet)
│   ├── select-picker.scss           # Styles (tokens CSS, responsive)
│   ├── select-picker.spec.ts        # Tests unitaires
│   └── select-picker.model.ts       # Interface SelectPickerItem
│
├── category-picker/                  # REFACTORE - thin wrapper
│   ├── category-picker.ts           # Wrapper autour de SelectPicker + creation inline
│   ├── category-picker.html         # Template simplifie (SelectPicker + modal)
│   ├── category-picker.scss         # Styles specifiques (minimal)
│   └── category-picker.spec.ts      # Tests regression
│
├── account-picker/                   # SUPPRIME apres migration
│   └── (fichiers supprimes)
│
└── transfer-form/                    # MODIFIE - remplacement des <select> natifs
    ├── transfer-form.ts             # Mise a jour imports
    ├── transfer-form.html           # Remplacement <select> → <app-select-picker>
    └── transfer-form.spec.ts        # Tests regression

app/src/app/features/
├── transactions/components/transaction-form/
│   ├── transaction-form.ts           # MODIFIE - remplacement AccountPicker
│   └── transaction-form.html         # MODIFIE - <app-select-picker> pour comptes
│
├── subscriptions/components/subscription-form/
│   ├── subscription-form.ts          # MODIFIE - remplacement AccountPicker
│   └── subscription-form.html        # MODIFIE - <app-select-picker> pour comptes
│
└── debts/components/debt-form/        # NON MODIFIE (utilise deja CategoryPicker via formControlName)
```

**Structure Decision**: Feature purement frontend. Le composant generique est place dans `shared/components/` car il est reutilise par tous les formulaires. Aucun changement backend.
