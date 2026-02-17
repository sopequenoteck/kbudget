# Implementation Plan: Refonte page Settings (8 sections)

**Branch**: `028-settings-redesign` | **Date**: 2026-02-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/028-settings-redesign/spec.md`
**Linear**: [KKS-83](https://linear.app/kksdev/issue/KKS-83/refonte-page-settings-8-sections)

## Summary

Restructurer la page Settings existante (actuellement : lien vers comptes + gestion catégories inline) en un hub de navigation avec 8 sections distinctes accessibles par routes enfant. Créer un `ThemeService` pour la bascule light/dark/auto avec persistance localStorage. Extraire la gestion des catégories dans un composant dédié. Aucun travail backend requis.

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21
**Primary Dependencies**: Angular Router, Angular Signals, SCSS design tokens (existants)
**Storage**: localStorage (thème), AuthService.currentUser() signal (profil)
**Testing**: Karma + Jasmine (Angular CLI default)
**Target Platform**: PWA mobile-first (tous navigateurs modernes)
**Project Type**: Web application (frontend uniquement pour cette feature)
**Performance Goals**: <100ms bascule de thème (SC-002), <1s chargement page Settings (SC-005)
**Constraints**: Pas de rechargement page (SPA), deep linking sur toutes les sections
**Scale/Scope**: 8 sections, ~10 fichiers créés/modifiés, 0 endpoints API

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature frontend-only. Aucun nouvel endpoint API. Les données profil proviennent de `AuthService.currentUser()` (signal existant alimenté au login). |
| II. Sécurité par défaut | ✅ | Données profil issues de la session JWT authentifiée. Pas de données sensibles exposées. Page protégée par `authGuard` existant. |
| III. Simplicité & YAGNI | ✅ | Un composant par section. Pas d'abstraction prématurée. Les sections placeholder sont de simples templates statiques. `ThemeService` minimal (3 états, localStorage). |
| IV. Mobile-First UX | ✅ | Layout colonne unique sur toutes les tailles d'écran. Navigation en 2 interactions max (hub → section). |
| V. Testabilité | ✅ | Chaque section testable indépendamment via sa route. ThemeService testable unitairement. |
| VI. Observabilité | N/A | Aucune action backend. Pas de logging côté frontend (hors isDevMode déjà en place). |
| VII. Self-Hosted Ready | ✅ | Aucune dépendance externe ajoutée. Thème stocké en localStorage. |

**Résultat GATE** : ✅ PASS — aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/028-settings-redesign/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A - frontend-only)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/
├── core/
│   └── services/
│       └── theme.ts                    # NOUVEAU — ThemeService
├── features/
│   └── settings/
│       ├── settings.routes.ts          # MODIFIÉ — hub + 8 routes enfant
│       ├── settings.ts                 # REMPLACÉ — devient le hub (grille 8 cartes)
│       ├── settings.html               # REMPLACÉ — template hub
│       ├── settings.scss               # REMPLACÉ — styles hub
│       └── components/
│           ├── accounts/               # EXISTANT — inchangé (déjà en composant séparé)
│           │   ├── accounts.ts
│           │   ├── accounts.html
│           │   └── accounts.scss
│           ├── categories/             # NOUVEAU — extrait de l'ancien settings.ts
│           │   ├── categories.ts
│           │   ├── categories.html
│           │   └── categories.scss
│           ├── appearance/             # NOUVEAU — segmented control thème
│           │   ├── appearance.ts
│           │   ├── appearance.html
│           │   └── appearance.scss
│           ├── profile/                # NOUVEAU — lecture seule nom/email
│           │   ├── profile.ts
│           │   ├── profile.html
│           │   └── profile.scss
│           ├── about/                  # NOUVEAU — nom app, version, auteur
│           │   ├── about.ts
│           │   ├── about.html
│           │   └── about.scss
│           └── placeholder/            # NOUVEAU — réutilisable pour Budget, Notifications, Données
│               ├── placeholder.ts
│               ├── placeholder.html
│               └── placeholder.scss
└── src/
    └── index.html                      # MODIFIÉ — class thème sur <html>

app/src/styles/
└── _base.scss                          # POTENTIELLEMENT MODIFIÉ — media query prefers-color-scheme
```

**Structure Decision** : Les 8 sections sont des composants Angular standalone sous `settings/components/`. Le composant placeholder est partagé entre Budget, Notifications et Données via `ActivatedRoute.snapshot.data` (titre et icône passés dans la config de route). Le hub Settings (`settings.ts`) devient un composant léger avec la grille des 8 cartes.

## Complexity Tracking

> Aucune violation de constitution détectée. Pas de justification requise.
