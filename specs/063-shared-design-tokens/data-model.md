# Data Model: Shared Design Tokens

**Feature**: 063-shared-design-tokens | **Date**: 2026-03-01

## Overview

Pas de persistance base de donnees. Les "entites" sont des fichiers de configuration statiques (SCSS + Dart) synchronises via un document de reference Markdown.

## Token Taxonomy

### Layer 1: Primitive Tokens (raw values)

Valeurs brutes sans semantique. Nommage par teinte + shade.

```
[teinte][shade] → valeur
amber500      → #f59e0b
indigo600     → #4f46e5
gray200       → #e5e7eb
space4        → 16px
```

### Layer 2: Semantic Tokens (theme-aware)

Valeurs qui changent selon le theme (light/dark). Reference une primitive.

```
[role]-[variant] → primitive
color-primary           → amber-500 (light) / amber-400 (dark)
color-secondary         → indigo-600 (light) / indigo-400 (dark)
bg-primary              → gray-50 (light) / gray-900 (dark)
text-primary            → gray-900 (light) / gray-50 (dark)
```

### Layer 3: Component Tokens (out of scope)

Valeurs specifiques a un composant. Hors scope de cette feature.

```
button-bg       → color-primary
card-border     → border-default
```

---

## Token Categories

### 1. Colors

#### Primitive Palettes

| Palette | Shades | Count |
|---------|--------|-------|
| Amber (primary) | 50-900 | 10 |
| Indigo (secondary) | 50-900 | 10 |
| Gray (neutral) | 50-900 | 10 |
| Green (feedback) | 400, 500, 600, 100 | 4 |
| Red (feedback) | 400, 500, 600, 100 | 4 |
| Yellow (feedback) | 400, 500, 700, 100 | 4 |
| Blue (feedback) | 400, 500, 600, 100 | 4 |
| Violet (subscription) | 400, 500 | 2 |
| **Total primitives couleur** | | **~48** |

#### Semantic Color Tokens (per theme)

| Category | Tokens | Count |
|----------|--------|-------|
| Primary | color-primary, -hover, -light, -contrast | 4 |
| Secondary | color-secondary, -hover, -light, -contrast | 4 |
| Backgrounds | bg-primary, -secondary, -tertiary, -success, -error, -warning, -info | 7 |
| Text | text-primary, -secondary, -tertiary, -inverse, -success, -error, -warning, -info | 8 |
| Borders | border-default, -strong | 2 |
| Surfaces | surface-default, -raised, -overlay | 3 |
| Interactive | hover-bg, focus-ring | 2 |
| Business | color-income, -expense, -debt-owe, -debt-owed, -subscription | 5 |
| Feedback raw | color-success-raw, -error-raw, -warning-raw, -info-raw | 4 |
| **Total semantiques (x2 themes)** | | **39 x 2** |

### 2. Spacing

Scale lineaire base 4px. Nommage numerique (0-12).

| Token | Value |
|-------|-------|
| space-0 | 0 |
| space-1 | 4px |
| space-2 | 8px |
| space-3 | 12px |
| space-4 | 16px |
| space-5 | 20px |
| space-6 | 24px |
| space-7 | 28px |
| space-8 | 32px |
| space-9 | 36px |
| space-10 | 40px |
| space-11 | 44px |
| space-12 | 48px |

### 3. Typography

| Token | Value |
|-------|-------|
| **Family** | |
| font-family | 'Inter', system-ui, -apple-system, sans-serif |
| font-mono | ui-monospace, 'Cascadia Code', 'Fira Code', monospace |
| **Sizes** | |
| font-size-xs | 12px |
| font-size-sm | 14px |
| font-size-base | 16px |
| font-size-lg | 18px |
| font-size-xl | 20px |
| font-size-2xl | 24px |
| font-size-3xl | 30px |
| **Weights** | |
| font-weight-normal | 400 |
| font-weight-medium | 500 |
| font-weight-semibold | 600 |
| font-weight-bold | 700 |
| **Line Heights** | |
| line-height-tight | 1.25 |
| line-height-normal | 1.5 |
| line-height-relaxed | 1.75 |

### 4. Border Radius

| Token | Value |
|-------|-------|
| radius-sm | 4px |
| radius-md | 8px |
| radius-lg | 12px |
| radius-xl | 16px |
| radius-xxl | 24px |
| radius-round | 999px |

### 5. Shadows

Reference values (CSS format). Flutter approximation dans research.md R4.

| Token | Value |
|-------|-------|
| shadow-sm | `0 1px 2px 0 rgb(0 0 0 / 0.05)` |
| shadow-md | `0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)` |
| shadow-lg | `0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)` |
| shadow-colored | `0 8px 24px -4px [color] / 0.4` (light) / `0.35` (dark) |

### 6. Animations

| Token | Value |
|-------|-------|
| duration-fast | 120ms |
| duration-normal | 200ms |
| duration-slow | 400ms |
| easing-default | cubic-bezier(0.4, 0, 0.2, 1) |
| easing-in | cubic-bezier(0.4, 0, 1, 1) |
| easing-out | cubic-bezier(0, 0, 0.2, 1) |

Reduced-motion : toutes les durations → 0ms.

### 7. Platform-Specific (non partages)

| Token | Platform | Value | Note |
|-------|----------|-------|------|
| z-dropdown | Angular | 100 | Pas d'equivalent Flutter |
| z-sticky | Angular | 200 | Pas d'equivalent Flutter |
| z-fab | Angular | 250 | Flutter gere via elevation |
| z-overlay | Angular | 300 | |
| z-modal | Angular | 400 | |
| z-toast | Angular | 500 | |
| sidebar-width | Angular | 240px | Layout specifique PWA |
| header-height | Angular | 56px | Layout specifique PWA |

---

## File Mapping

| Reference Token | Angular (SCSS) | Flutter (Dart) |
|-----------------|---------------|----------------|
| `amber-500` | `$amber-500` / `--amber-500` | `AppColors.amber500` |
| `color-primary` | `--color-primary` (theme file) | `ColorScheme.primary` |
| `color-secondary` | `--color-secondary` (theme file) | `ColorScheme.secondary` |
| `space-4` | `$space-4` / `--space-4` | `AppSpacing.space4` |
| `font-size-base` | `$font-size-base` / `--font-size-base` | `AppTypography.sizeMd` |
| `radius-md` | `$radius-md` / `--radius-md` | `AppRadius.md` |
| `shadow-sm` | `$shadow-sm` / `--shadow-sm` | `AppShadows.sm` |
| `duration-fast` | `$duration-fast` / `--duration-fast` | `AppDurations.fast` |
| `color-income` | `--color-income` (theme file) | `AppThemeExtension.incomeColor` |
