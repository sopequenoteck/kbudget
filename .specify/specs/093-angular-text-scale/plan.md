# Implementation Plan: Angular Text Scale

**Branch**: `093-angular-text-scale` | **Date**: 2026-03-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/093-angular-text-scale/spec.md`

## Summary

Ajouter un contrôle de taille de texte (Petit/Normal/Grand) dans l'écran Apparence Angular, identique à Flutter. Un `TextScaleService` (même pattern que `ThemeService`) persiste le choix dans `localStorage` et applique un facteur CSS sur `<html>`. L'écran Apparence est enrichi d'une section sélecteur + aperçu.

## Technical Context

**Language/Version**: TypeScript 5.9, SCSS
**Primary Dependencies**: Angular 21 (Signals, OnPush, standalone)
**Storage**: localStorage (clé `budget_text_scale`)
**Testing**: Vitest — tests existants doivent passer
**Target Platform**: PWA mobile-first
**Project Type**: Web application (frontend Angular)
**Performance Goals**: Changement de scale < 100ms, pas de reflow visible
**Constraints**: Pas de modification de chaque composant individuellement
**Scale/Scope**: 1 service + 1 composant modifié

## Constitution Check

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Aucun changement backend |
| II. Sécurité | N/A | Pas de données sensibles |
| III. Simplicité/YAGNI | PASS | 1 service simple, pattern existant réutilisé |
| IV. Mobile-First | PASS | Accessible depuis Paramètres mobile |
| V. Testabilité | PASS | Service testable, signal observable |
| VI. Observabilité | N/A | Pas de logique métier |
| VII. Self-Hosted | N/A | Pas de dépendance externe |

**GATE RESULT**: PASS

## Project Structure

### Documentation

```text
specs/093-angular-text-scale/
├── plan.md
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code

```text
app/src/app/
├── core/services/
│   └── text-scale.ts              # NOUVEAU — TextScaleService (signal + localStorage + effect)
├── features/settings/components/appearance/
│   ├── appearance.ts              # MODIFIÉ — inject TextScaleService, exposer signals
│   ├── appearance.html            # MODIFIÉ — section "Taille du texte" + aperçu
│   └── appearance.scss            # MODIFIÉ — styles section taille + preview
```

### Fichiers modifiés (inventaire)

| Fichier | Changement | FR couvertes |
|---------|-----------|--------------|
| `core/services/text-scale.ts` | NOUVEAU — Service signal-based, localStorage, effect sur `document.documentElement.style.fontSize` | FR-001 à FR-004, FR-007 |
| `appearance.ts` | Inject TextScaleService, exposer currentTextScale signal | FR-001, FR-006 |
| `appearance.html` | Section "Taille du texte" (segmented control) + aperçu | FR-001, FR-005, FR-006 |
| `appearance.scss` | Styles section taille + preview card | FR-005, FR-006 |

### Fichiers NON modifiés

- Aucun autre composant — le scale s'applique via CSS `font-size` sur `:root`
- Aucun fichier backend
- Aucun fichier Flutter

## Design Decisions

### D1 — TextScaleService (pattern ThemeService)

```typescript
type TextScale = 'small' | 'medium' | 'large';

const SCALE_FACTORS: Record<TextScale, number> = {
  small: 0.85,
  medium: 1.0,
  large: 1.3,
};
```

Service `@Injectable({ providedIn: 'root' })` avec :
- Signal `currentTextScale` (défaut: `'medium'`)
- Méthode `setTextScale(scale: TextScale)` qui met à jour le signal + localStorage
- `effect()` dans le constructeur qui applique `document.documentElement.style.fontSize = factor * 100 + '%'` (ex: `85%`, `100%`, `130%`)
- `restoreTextScale()` privée appelée au constructeur

### D2 — Application CSS

Le facteur est appliqué via `document.documentElement.style.fontSize`. Comme tous les tokens de typographie utilisent `rem`, changer le `font-size` du `<html>` scale automatiquement tous les textes. Les icônes (qui utilisent `px` ou `size="24"`) ne sont pas affectées — conforme à FR-008.

### D3 — Segmented control réutilisé

La section utilise le même pattern `.segmented-control` que le sélecteur de thème (3 boutons avec classe `--active`). Pas de nouveau composant.

### D4 — Aperçu texte

Un `<div class="text-preview">` sous le sélecteur affiche "Voici un aperçu de la taille du texte choisie." avec un `font-size` calculé inline basé sur le facteur sélectionné.

## Complexity Tracking

> Aucune violation — section vide.
