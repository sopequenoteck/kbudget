# Implementation Plan: Composant ListItem réutilisable

**Branch**: `008-list-item` | **Date**: 2026-02-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-list-item/spec.md`

## Summary

Créer un composant Angular standalone `ListItem` dans `shared/components/` pour afficher uniformément les éléments de listes (transactions, abonnements, dettes). Le composant est purement présentationnel, utilise les signals Angular 21 pour ses inputs/outputs, et s'appuie exclusivement sur les design tokens existants du projet.

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/core` (Component, ChangeDetectionStrategy, input, output)
**Storage**: N/A (composant présentationnel sans état)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: PWA mobile-first (320px minimum)
**Project Type**: Web application (monorepo `app/`)
**Performance Goals**: Rendu instantané dans des listes de dizaines d'éléments (OnPush)
**Constraints**: Uniquement les design tokens CSS existants, pas de dépendance externe
**Scale/Scope**: 1 composant, 3 fichiers (.ts, .html, .scss), 1 fichier de tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Composant purement frontend, pas d'endpoint API |
| II. Sécurité par défaut | N/A | Pas de données sensibles, pas d'auth |
| III. Simplicité & YAGNI | PASS | Composant simple sans abstraction, inputs directs, pas de logique métier |
| IV. Mobile-First UX | PASS | Responsive 320px min, touch-friendly, a11y clavier |
| V. Testabilité | PASS | Composant isolé testable unitairement, inputs/outputs simples |
| VI. Observabilité | N/A | Composant UI sans side effects à logger |
| VII. Self-Hosted Ready | N/A | Pas de dépendance SaaS |

**Gate result**: PASS — Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/008-list-item/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── spec.md              # Feature specification
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/shared/components/
└── list-item/
    ├── list-item.ts          # Composant standalone OnPush
    ├── list-item.html         # Template avec layout flexbox
    └── list-item.scss         # Styles design tokens uniquement

app/src/app/shared/components/
└── list-item/
    └── list-item.spec.ts      # Tests unitaires Vitest
```

**Structure Decision**: Le composant suit exactement le pattern des composants shared existants (`form-field/`, `fab/`, `modal/`). Structure flat : `.ts` + `.html` + `.scss` dans un dossier nommé `list-item/`.

## Complexity Tracking

> Aucune violation de constitution — tableau non requis.

## Phase 0: Research

### Recherche effectuée

Aucun NEEDS CLARIFICATION identifié dans le Technical Context. La recherche porte sur les patterns existants du projet.

#### R-001: Pattern de composant shared existant

**Decision**: Suivre le pattern identique à `FormField`, `Fab`, `Modal`
**Rationale**: Cohérence avec le codebase existant. Tous les composants shared utilisent :
- `input()` / `input.required()` pour les entrées
- `output()` pour les sorties
- `ChangeDetectionStrategy.OnPush`
- `standalone: true`
- SCSS avec `var(--token)` uniquement
**Alternatives considered**: Aucune — le pattern est établi et uniforme.

#### R-002: Gestion de la classe CSS sur la valeur

**Decision**: Input optionnel `valueClass` de type `string` avec valeur par défaut `''`
**Rationale**: Le parent applique une classe utilitaire existante (`.amount-income`, `.amount-expense`) ou une classe custom. Le composant ne connaît pas la sémantique métier.
**Alternatives considered**:
- Enum interne (`income | expense | debt-owe | debt-owed`) → Rejeté : couple le composant à la logique métier, viole YAGNI
- `ngClass` object → Rejeté : surcharge inutile pour un cas simple

#### R-003: Layout flexbox pour le list item

**Decision**: Flexbox horizontal avec 3 zones : icône (fixe) | contenu (flex: 1, min-width: 0) | valeur (fixe, shrink: 0)
**Rationale**:
- `min-width: 0` sur le contenu permet le `text-overflow: ellipsis` sur le titre
- `flex-shrink: 0` sur la valeur garantit qu'elle reste entièrement visible
- Pattern standard pour les list items responsive
**Alternatives considered**:
- CSS Grid → Rejeté : flexbox suffit pour un layout 1D, plus simple

#### R-004: Accessibilité clavier et interaction

**Decision**: Élément racine = `<div>` avec `role="button"`, `tabindex="0"`, handler `(click)` + `(keydown.enter)` + `(keydown.space)`
**Rationale**: Le composant est interactif (émet un événement au clic). Le `role="button"` + `tabindex="0"` rend l'élément focusable et navigable au clavier. Enter et Space déclenchent l'action conformément aux guidelines ARIA.
**Alternatives considered**:
- `<button>` natif → Rejeté : le reset de styles d'un `<button>` est lourd et le layout interne complexe se prête mieux à un `<div>` avec rôle explicite
- `<a>` → Rejeté : pas de navigation URL, c'est une action

#### R-005: Design tokens à utiliser

**Decision**: Mapping des tokens existants vers les zones du composant :

| Zone | Token(s) |
|------|----------|
| Padding horizontal | `var(--space-4)` (16px) |
| Padding vertical | `var(--space-3)` (12px) |
| Gap icône ↔ contenu | `var(--space-3)` (12px) |
| Titre (font) | `var(--font-size-base)`, `var(--font-weight-medium)`, `var(--text-primary)` |
| Sous-titre (font) | `var(--font-size-sm)`, `var(--font-weight-normal)`, `var(--text-secondary)` |
| Valeur (font) | `var(--font-size-base)`, `var(--font-weight-semibold)`, `var(--text-primary)` |
| Sous-titre droit (font) | `var(--font-size-sm)`, `var(--text-secondary)` |
| Icône (font) | `var(--font-size-lg)` |
| Bordure séparatrice | `1px solid var(--border-default)` |
| Hover | `var(--hover-bg)` |
| Focus | `outline: 2px solid var(--color-primary)` |
| Transitions | `var(--duration-fast)`, `var(--easing-default)` |

**Rationale**: Tous les tokens existent dans `_tokens.scss`. Les tailles et espacements correspondent au rythme 4px du design system.

## Phase 1: Design

### Component API

```typescript
// list-item.ts
@Component({
  selector: 'app-list-item',
  standalone: true,
  templateUrl: './list-item.html',
  styleUrl: './list-item.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ListItem {
  // === Inputs ===
  readonly icon = input.required<string>();           // FR-001: Icône texte/emoji (obligatoire)
  readonly title = input.required<string>();           // FR-002: Titre principal (obligatoire)
  readonly value = input.required<string>();           // FR-003: Valeur affichée à droite (obligatoire)
  readonly subtitle = input<string>('');               // FR-004: Sous-titre sous le titre (optionnel)
  readonly rightSubtitle = input<string>('');          // FR-005: Sous-titre sous la valeur (optionnel)
  readonly valueClass = input<string>('');             // FR-006: Classe CSS sur la valeur (optionnel)

  // === Outputs ===
  readonly pressed = output<void>();                   // FR-007: Signal void au clic

  // === Methods ===
  onPress(): void {
    this.pressed.emit();
  }

  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      this.pressed.emit();
    }
  }
}
```

### Template Structure

```html
<!-- list-item.html -->
<div
  class="list-item"
  role="button"
  tabindex="0"
  (click)="onPress()"
  (keydown)="onKeydown($event)"
>
  <span class="list-item__icon">{{ icon() }}</span>

  <div class="list-item__content">
    <span class="list-item__title">{{ title() }}</span>
    @if (subtitle()) {
      <span class="list-item__subtitle">{{ subtitle() }}</span>
    }
  </div>

  <div class="list-item__right">
    <span class="list-item__value" [class]="valueClass()">{{ value() }}</span>
    @if (rightSubtitle()) {
      <span class="list-item__right-subtitle">{{ rightSubtitle() }}</span>
    }
  </div>
</div>
```

### SCSS Structure

```scss
// list-item.scss
:host {
  display: block;
}

.list-item {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border-bottom: 1px solid var(--border-default);
  cursor: pointer;
  transition: background var(--duration-fast) var(--easing-default);
  user-select: none;

  &:hover {
    background: var(--hover-bg);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: -2px;
  }

  &:active {
    background: var(--hover-bg);
  }

  &__icon {
    font-size: var(--font-size-lg);
    flex-shrink: 0;
    width: var(--space-8);
    text-align: center;
    line-height: 1;
  }

  &__content {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
  }

  &__title {
    font-size: var(--font-size-base);
    font-weight: var(--font-weight-medium);
    color: var(--text-primary);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  &__subtitle {
    font-size: var(--font-size-sm);
    color: var(--text-secondary);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  &__right {
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: var(--space-1);
  }

  &__value {
    font-size: var(--font-size-base);
    font-weight: var(--font-weight-semibold);
    color: var(--text-primary);
    white-space: nowrap;
  }

  &__right-subtitle {
    font-size: var(--font-size-sm);
    color: var(--text-secondary);
    white-space: nowrap;
  }
}
```

### Mapping FR → Design

| FR | Implémentation |
|----|----------------|
| FR-001 | `input.required<string>()` icon, affiché dans `.list-item__icon` |
| FR-002 | `input.required<string>()` title, dans `.list-item__title` avec ellipsis |
| FR-003 | `input.required<string>()` value, dans `.list-item__value` aligné droite |
| FR-004 | `input<string>('')` subtitle, rendu conditionnel `@if` |
| FR-005 | `input<string>('')` rightSubtitle, rendu conditionnel `@if` |
| FR-006 | `input<string>('')` valueClass, binding `[class]` sur la valeur |
| FR-007 | `output<void>()` pressed, émis sur click + Enter + Space |
| FR-008 | CSS `:hover` → `var(--hover-bg)`, `:focus-visible` → outline primary |
| FR-009 | Flexbox + `min-width: 0` + `flex-shrink: 0` → responsive 320px+ |
| FR-010 | `text-overflow: ellipsis` + `overflow: hidden` + `white-space: nowrap` |
| FR-011 | `border-bottom: 1px solid var(--border-default)` |
| FR-012 | Tous les styles utilisent exclusivement `var(--token)` |

### Test Strategy

Tests unitaires Vitest couvrant :

| Test | FR | Type |
|------|-----|------|
| should render icon, title, and value | FR-001, FR-002, FR-003 | Nominal |
| should render subtitle when provided | FR-004 | Nominal |
| should not render subtitle when empty | FR-004 | Edge |
| should render right subtitle when provided | FR-005 | Nominal |
| should not render right subtitle when empty | FR-005 | Edge |
| should apply valueClass to value element | FR-006 | Nominal |
| should not apply class when valueClass empty | FR-006 | Edge |
| should emit pressed on click | FR-007 | Nominal |
| should emit pressed on Enter key | FR-007 | A11y |
| should emit pressed on Space key | FR-007 | A11y |
| should have role="button" and tabindex="0" | FR-008 | A11y |
| should truncate long title with ellipsis | FR-010 | Edge |

### Usage Examples (Quickstart)

#### Transaction

```html
<app-list-item
  icon="🛒"
  title="Courses Carrefour"
  subtitle="Alimentation · 15 jan."
  value="-42,50 €"
  valueClass="amount-expense"
  (pressed)="onTransactionClick(transaction)"
/>
```

#### Abonnement

```html
<app-list-item
  icon="🎵"
  title="Spotify Premium"
  subtitle="Mensuel · Depuis mars 2024"
  value="-10,99 €"
  rightSubtitle="Prochain : 1 fév."
  valueClass="amount-expense"
  (pressed)="onSubscriptionClick(sub)"
/>
```

#### Dette (on me doit)

```html
<app-list-item
  icon="👤"
  title="Pierre Martin"
  subtitle="Remboursement restaurant"
  value="+25,00 €"
  rightSubtitle="Depuis le 10 jan."
  valueClass="amount-income"
  (pressed)="onDebtClick(debt)"
/>
```

## Constitution Re-Check (Post-Design)

| Principe | Statut | Notes |
|----------|--------|-------|
| III. Simplicité & YAGNI | PASS | 6 inputs, 1 output, 0 logique métier, 0 dépendance externe |
| IV. Mobile-First UX | PASS | Layout flexbox responsive, touch target suffisant, a11y clavier |
| V. Testabilité | PASS | 12 tests unitaires prévus, composant isolé sans dépendances |

**Final gate**: PASS
