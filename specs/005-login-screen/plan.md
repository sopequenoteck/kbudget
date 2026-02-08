# Implementation Plan: Écran de login et fondations UI

**Branch**: `005-login-screen` | **Date**: 2026-02-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-login-screen/spec.md`

## Summary

Implémenter l'écran de connexion de l'application Budget, accompagné des fondations UI : styles globaux pour formulaires et boutons, composant réutilisable `FormField`, et layout shell avec sidebar responsive (overlay sur mobile, fixe sur desktop). Feature purement frontend — aucune modification backend.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/forms` (ReactiveFormsModule), `@angular/router` (Router, RouterOutlet, RouterLink, RouterLinkActive), `AuthService` (existant), `ApiService` (existant)
**Storage**: localStorage via AuthService (existant, pas de modification)
**Testing**: Vitest 4.x via `npx vitest run` (tests existants à préserver)
**Target Platform**: PWA mobile-first (navigateur web, 375px minimum)
**Project Type**: Web application (frontend Angular uniquement pour cette feature)
**Performance Goals**: Connexion en < 2 secondes, pas de scroll horizontal sur 375px
**Constraints**: Tokens CSS uniquement (`var(--token)`), standalone + OnPush, `inject()`, signals-first
**Scale/Scope**: 1 utilisateur (single-user), 4 sections de navigation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Commentaire |
|----------|--------|-------------|
| I. API-First | N/A | Feature purement frontend, les endpoints `/auth/login` et `/auth/register` existent déjà |
| II. Sécurité par défaut | PASS | AuthService + guard + intercepteur JWT déjà en place. Le login utilise l'infrastructure existante |
| III. Simplicité & YAGNI | PASS | FormField est le seul composant shared, justifié par réutilisation immédiate. Pas de ThemeService, pas d'icônes, pas d'inscription |
| IV. Mobile-First UX | PASS | Design mobile-first, sidebar responsive (drawer mobile / fixe desktop), bas de l'écran libre pour futur FAB (+) |
| V. Testabilité | PASS | Tests existants préservés. Les composants sont testables via Vitest |
| VI. Observabilité | N/A | Feature frontend, pas de logging serveur |
| VII. Self-Hosted Ready | PASS | Aucune dépendance externe ajoutée |

**Gate result**: PASS — aucune violation.

**Post-design re-check**: PASS — la sidebar responsive respecte le principe IV (mobile-first + espace libre pour FAB). Le signal `sidebarOpen` respecte le pattern signals-first du projet.

## Project Structure

### Documentation (this feature)

```text
specs/005-login-screen/
├── plan.md              # This file
├── spec.md              # Feature specification (with clarifications)
├── research.md          # Phase 0 output (5 decisions)
├── quickstart.md        # Phase 1 output
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
app/src/
├── styles/
│   ├── _index.scss              # MODIFIER — ajouter @use 'forms' et @use 'buttons'
│   ├── _forms.scss              # CRÉER — styles globaux inputs/textarea/select
│   └── _buttons.scss            # CRÉER — styles globaux boutons (.btn-primary, .btn-outline, .btn-block)
├── app/
│   ├── app.routes.ts            # MODIFIER — layout route Shell avec children
│   ├── shared/
│   │   └── components/
│   │       ├── form-field/      # CRÉER — composant réutilisable label + ng-content + erreur
│   │       │   ├── form-field.ts
│   │       │   ├── form-field.html
│   │       │   └── form-field.scss
│   │       └── shell/           # CRÉER — layout shell (header + sidebar responsive + content)
│   │           ├── shell.ts
│   │           ├── shell.html
│   │           └── shell.scss
│   └── features/
│       └── auth/
│           ├── auth.ts          # MODIFIER — logique formulaire ReactiveForm + signals
│           ├── auth.html        # MODIFIER — template login
│           └── auth.scss        # MODIFIER — styles login mobile-first
```

**Structure Decision**: Application web Angular existante. Ajout de fichiers dans `styles/` (globaux) et `shared/components/` (réutilisables). Modification des fichiers existants dans `features/auth/` et `app.routes.ts`.

## Complexity Tracking

> Aucune violation de la constitution. Pas de tracking nécessaire.
