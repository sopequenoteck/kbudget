# Implementation Plan: Angular Emoji Picker

**Branch**: `097-angular-emoji-picker` | **Date**: 2026-03-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/097-angular-emoji-picker/spec.md`

## Summary

Remplacer le composant `EmojiInput` Angular (actuellement un `<input type="text">` brut) par un vrai picker d'emojis utilisant `emoji-mart` (web component). Le picker s'ouvre dans un popover CDK Overlay avec grille par catégories, recherche en français, section récents, et thème dark/light automatique. L'API publique du composant (`value` / `valueChange`) reste inchangée — migration transparente pour les formulaires catégorie et compte.

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21
**Primary Dependencies**: `emoji-mart` + `@emoji-mart/data` (nouveau), `@angular/cdk/overlay` (existant)
**Storage**: localStorage (emojis récents, géré par emoji-mart)
**Testing**: Vitest (Angular test runner du projet)
**Target Platform**: Web (PWA mobile-first)
**Project Type**: Web application (frontend Angular uniquement)
**Performance Goals**: Picker ouvert en < 200ms, sélection en 2 interactions
**Constraints**: Aucune requête réseau (emojis embarqués dans le bundle)
**Scale/Scope**: 1 composant modifié, 2 formulaires consommateurs

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Commentaire |
|----------|--------|-------------|
| I. API-First | N/A | Pas de changement backend |
| II. Sécurité par défaut | PASS | Pas de données sensibles, pas d'endpoint |
| III. Simplicité & YAGNI | PASS | Remplacement 1:1 d'un composant, pas de nouvelle abstraction |
| IV. Mobile-First UX | PASS | Picker améliore l'UX de saisie (2 interactions vs saisie manuelle) |
| V. Testabilité | PASS | Tests unitaires prévus pour le composant |
| VI. Observabilité | N/A | Composant UI pur, pas de logging nécessaire |
| VII. Self-Hosted Ready | PASS | Aucune dépendance SaaS, emojis embarqués |

**Post-design re-check**: Tous les gates passent. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/097-angular-emoji-picker/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/shared/components/emoji-input/
├── emoji-input.ts       # Composant refactorisé (trigger box + CDK overlay + emoji-mart)
├── emoji-input.html     # Template (trigger box + overlay avec <em-emoji-picker>)
├── emoji-input.scss     # Styles (trigger box + surcharge thème picker)
└── emoji-input.spec.ts  # Tests unitaires (nouveau)
```

**Structure Decision**: Feature contenue dans un seul composant Angular existant (`emoji-input/`). Pas de nouveau fichier hors du dossier du composant. Pas de contracts/ (aucun endpoint modifié).

## Complexity Tracking

Aucune violation de constitution — tableau non applicable.
