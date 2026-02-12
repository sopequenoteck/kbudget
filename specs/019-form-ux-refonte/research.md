# Research: Refonte UX formulaire Transaction

**Date**: 2026-02-12
**Branch**: `019-form-ux-refonte`

## Contexte

Feature purement UI — pas d'inconnues techniques majeures. Tous les composants et patterns necessaires existent deja dans le codebase.

## Decisions

### 1. Projection du toggle dans le header modal

- **Decision**: Utiliser `<ng-content select="[modal-header-actions]" />` dans le template Modal pour permettre au composant parent (Shell) de projeter du contenu dans le header.
- **Rationale**: Angular content projection via selecteur d'attribut est le pattern standard pour les slots nommes. Pas besoin de portal CDK ni de ViewContainerRef — le contenu est projete statiquement.
- **Alternatives considerees**:
  - Portal CDK (`@angular/cdk/portal`) : trop complexe pour un slot statique, violation YAGNI.
  - Input template (`TemplateRef`) : necessiterait `ngTemplateOutlet`, plus verbeux sans avantage.

### 2. Gestion de l'etat du type de transaction

- **Decision**: Le signal `transactionType` vit dans Shell (composant orchestrateur). TransactionForm le recoit via `input()` et ne gere plus le type en interne.
- **Rationale**: Le toggle est visuellement dans le header du modal (hors du formulaire). Le state doit vivre la ou le toggle est rendu. Shell est deja l'orchestrateur des modals.
- **Alternatives considerees**:
  - Signal dans un service partage : over-engineering pour une communication parent-enfant directe.
  - Laisser le type dans le FormGroup et synchroniser bidirectionnellement : complexite inutile, risque de desynchronisation.

### 3. Layout grille CSS

- **Decision**: CSS Grid via `display: grid` + `grid-template-columns` dans des classes `.form-row`. Breakpoint `@media (max-width: 400px)` pour empiler en colonne.
- **Rationale**: CSS Grid est nativement supporte par tous les navigateurs cibles. Plus expressif que flexbox pour des layouts 2D avec proportions specifiques (7fr 3fr).
- **Alternatives considerees**:
  - Flexbox : moins expressif pour les proportions 70/30, necessite `flex-basis` et `min-width`.
  - Framework CSS grid (Tailwind, etc.) : non utilise dans le projet, violation convention.

### 4. Suppression sans confirmation

- **Decision**: Clic direct sur "Supprimer" sans dialog de confirmation.
- **Rationale**: Application single-user, pas de risque de suppression accidentelle par un tiers. Reduit le nombre d'interactions. Coherent avec l'objectif "saisie en 2-3 interactions".
- **Alternatives considerees**:
  - Toast undo (supprimer + annuler pendant 5s) : plus elegant mais necessite un service de notification non existant. Differe a une feature future.
  - Confirmation inline (etat actuel) : ajoute une interaction, contraire a l'objectif UX.
