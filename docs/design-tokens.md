# Design Tokens Reference

**Source de verite unique** pour tous les design tokens partages entre Angular (SCSS) et Flutter (Dart).

> Les implementations Angular et Flutter doivent correspondre **exactement** aux valeurs de ce document.

---

## 1. Colors

### Primitive Palettes

#### Gray (neutral)

| Token | Hex |
|-------|-----|
| gray-50 | `#f9fafb` |
| gray-100 | `#f3f4f6` |
| gray-200 | `#e5e7eb` |
| gray-300 | `#d1d5db` |
| gray-400 | `#9ca3af` |
| gray-500 | `#6b7280` |
| gray-600 | `#4b5563` |
| gray-700 | `#374151` |
| gray-800 | `#1f2937` |
| gray-900 | `#111827` |

#### Amber (primary)

| Token | Hex |
|-------|-----|
| amber-50 | `#fffbeb` |
| amber-100 | `#fef3c7` |
| amber-200 | `#fde68a` |
| amber-300 | `#fcd34d` |
| amber-400 | `#fbbf24` |
| amber-500 | `#f59e0b` |
| amber-600 | `#d97706` |
| amber-700 | `#b45309` |
| amber-800 | `#92400e` |
| amber-900 | `#78350f` |

#### Indigo (secondary)

| Token | Hex |
|-------|-----|
| indigo-50 | `#eef2ff` |
| indigo-100 | `#e0e7ff` |
| indigo-200 | `#c7d2fe` |
| indigo-300 | `#a5b4fc` |
| indigo-400 | `#818cf8` |
| indigo-500 | `#6366f1` |
| indigo-600 | `#4f46e5` |
| indigo-700 | `#4338ca` |
| indigo-800 | `#3730a3` |
| indigo-900 | `#312e81` |

#### Feedback Primitives

| Token | Hex | Source |
|-------|-----|--------|
| green-400 | `#4ade80` | success dark |
| green-500 | `#22c55e` | success light |
| green-600 | `#16a34a` | text-success |
| green-100 | `#dcfce7` | bg-success |
| red-400 | `#f87171` | error dark |
| red-500 | `#ef4444` | error light |
| red-600 | `#dc2626` | text-error |
| red-100 | `#fee2e2` | bg-error |
| yellow-400 | `#facc15` | warning dark |
| yellow-500 | `#eab308` | warning light |
| yellow-700 | `#ca8a04` | text-warning |
| yellow-100 | `#fef9c3` | bg-warning |
| blue-400 | `#60a5fa` | info dark |
| blue-500 | `#3b82f6` | info light |
| blue-600 | `#2563eb` | text-info |
| blue-100 | `#dbeafe` | bg-info |

#### Business Color Primitives

| Token | Hex | Usage |
|-------|-----|-------|
| violet-400 | `#a78bfa` | subscription dark |
| violet-500 | `#8b5cf6` | subscription light |
| violet-100 | `#f5f3ff` | subscription background |

---

### Semantic Color Tokens

#### Light Theme

| Token | Value | Primitive |
|-------|-------|-----------|
| **Primary** | | |
| color-primary | `#f59e0b` | amber-500 |
| color-primary-hover | `#d97706` | amber-600 |
| color-primary-light | `#fef3c7` | amber-100 |
| color-primary-contrast | `#ffffff` | white |
| **Secondary** | | |
| color-secondary | `#4f46e5` | indigo-600 |
| color-secondary-hover | `#4338ca` | indigo-700 |
| color-secondary-light | `#e0e7ff` | indigo-100 |
| color-secondary-contrast | `#ffffff` | white |
| **Backgrounds** | | |
| bg-primary | `#f9fafb` | gray-50 |
| bg-secondary | `#ffffff` | white |
| bg-tertiary | `#f3f4f6` | gray-100 |
| bg-success | `#dcfce7` | green-100 |
| bg-error | `#fee2e2` | red-100 |
| bg-warning | `#fef9c3` | yellow-100 |
| bg-info | `#dbeafe` | blue-100 |
| **Text** | | |
| text-primary | `#111827` | gray-900 |
| text-secondary | `#4b5563` | gray-600 |
| text-tertiary | `#9ca3af` | gray-400 |
| text-inverse | `#ffffff` | white |
| text-success | `#16a34a` | green-600 |
| text-error | `#dc2626` | red-600 |
| text-warning | `#ca8a04` | yellow-700 |
| text-info | `#2563eb` | blue-600 |
| **Borders** | | |
| border-default | `#e5e7eb` | gray-200 |
| border-strong | `#d1d5db` | gray-300 |
| **Surfaces** | | |
| surface-default | `#ffffff` | white |
| surface-raised | `#ffffff` | white |
| surface-overlay | `rgba(17,24,39, 0.5)` | gray-900 / 50% |
| **Interactive** | | |
| hover-bg | `#f3f4f6` | gray-100 |
| focus-ring | `rgba(245,158,11, 0.5)` | amber-500 / 50% |
| **Feedback raw** | | |
| color-success-raw | `#22c55e` | green-500 |
| color-error-raw | `#ef4444` | red-500 |
| color-warning-raw | `#eab308` | yellow-500 |
| color-info-raw | `#3b82f6` | blue-500 |
| **Business** | | |
| color-income | `#16a34a` | green-600 |
| color-expense | `#dc2626` | red-600 |
| color-debt-owe | `#dc2626` | red-600 |
| color-debt-owed | `#16a34a` | green-600 |
| color-subscription | `#8b5cf6` | violet-500 |

#### Dark Theme

| Token | Value | Primitive |
|-------|-------|-----------|
| **Primary** | | |
| color-primary | `#fbbf24` | amber-400 |
| color-primary-hover | `#fcd34d` | amber-300 |
| color-primary-light | `#78350f` | amber-900 |
| color-primary-contrast | `#111827` | gray-900 |
| **Secondary** | | |
| color-secondary | `#818cf8` | indigo-400 |
| color-secondary-hover | `#a5b4fc` | indigo-300 |
| color-secondary-light | `#312e81` | indigo-900 |
| color-secondary-contrast | `#111827` | gray-900 |
| **Backgrounds** | | |
| bg-primary | `#111827` | gray-900 |
| bg-secondary | `#1f2937` | gray-800 |
| bg-tertiary | `#374151` | gray-700 |
| bg-success | `rgba(34,197,94, 0.15)` | green-500 / 15% |
| bg-error | `rgba(239,68,68, 0.15)` | red-500 / 15% |
| bg-warning | `rgba(234,179,8, 0.15)` | yellow-500 / 15% |
| bg-info | `rgba(59,130,246, 0.15)` | blue-500 / 15% |
| **Text** | | |
| text-primary | `#f9fafb` | gray-50 |
| text-secondary | `#9ca3af` | gray-400 |
| text-tertiary | `#6b7280` | gray-500 |
| text-inverse | `#111827` | gray-900 |
| text-success | `#4ade80` | green-400 |
| text-error | `#f87171` | red-400 |
| text-warning | `#facc15` | yellow-400 |
| text-info | `#60a5fa` | blue-400 |
| **Borders** | | |
| border-default | `#374151` | gray-700 |
| border-strong | `#4b5563` | gray-600 |
| **Surfaces** | | |
| surface-default | `#1f2937` | gray-800 |
| surface-raised | `#374151` | gray-700 |
| surface-overlay | `rgba(0,0,0, 0.6)` | black / 60% |
| **Interactive** | | |
| hover-bg | `#374151` | gray-700 |
| focus-ring | `rgba(251,191,36, 0.5)` | amber-400 / 50% |
| **Feedback raw** | | |
| color-success-raw | `#22c55e` | green-500 |
| color-error-raw | `#ef4444` | red-500 |
| color-warning-raw | `#eab308` | yellow-500 |
| color-info-raw | `#3b82f6` | blue-500 |
| **Business** | | |
| color-income | `#4ade80` | green-400 |
| color-expense | `#f87171` | red-400 |
| color-debt-owe | `#f87171` | red-400 |
| color-debt-owed | `#4ade80` | green-400 |
| color-subscription | `#a78bfa` | violet-400 |

---

## 2. Spacing

Echelle lineaire base 4px.

| Token | Value |
|-------|-------|
| space-0 | 0 |
| space-1 | 4px / 0.25rem |
| space-2 | 8px / 0.5rem |
| space-3 | 12px / 0.75rem |
| space-4 | 16px / 1rem |
| space-5 | 20px / 1.25rem |
| space-6 | 24px / 1.5rem |
| space-7 | 28px / 1.75rem |
| space-8 | 32px / 2rem |
| space-9 | 36px / 2.25rem |
| space-10 | 40px / 2.5rem |
| space-11 | 44px / 2.75rem |
| space-12 | 48px / 3rem |

---

## 3. Typography

| Token | Value |
|-------|-------|
| **Families** | |
| font-family | `'Inter', system-ui, -apple-system, sans-serif` |
| font-mono | `ui-monospace, 'Cascadia Code', 'Fira Code', monospace` |
| **Sizes** | |
| font-size-xs | 12px / 0.75rem |
| font-size-sm | 14px / 0.875rem |
| font-size-base | 16px / 1rem |
| font-size-lg | 18px / 1.125rem |
| font-size-xl | 20px / 1.25rem |
| font-size-2xl | 24px / 1.5rem |
| font-size-3xl | 30px / 1.875rem |
| **Weights** | |
| font-weight-normal | 400 |
| font-weight-medium | 500 |
| font-weight-semibold | 600 |
| font-weight-bold | 700 |
| **Line Heights** | |
| line-height-tight | 1.25 |
| line-height-normal | 1.5 |
| line-height-relaxed | 1.75 |

---

## 4. Border Radius

| Token | Value |
|-------|-------|
| radius-sm | 4px / 0.25rem |
| radius-md | 8px / 0.5rem |
| radius-lg | 12px / 0.75rem |
| radius-xl | 16px / 1rem |
| radius-xxl | 24px / 1.5rem |
| radius-round | 999px |

---

## 5. Shadows

Reference values (CSS format). Flutter utilise une approximation single-shadow.

| Token | CSS Value | Flutter Approximation |
|-------|-----------|----------------------|
| shadow-sm | `0 1px 2px 0 rgb(0 0 0 / 0.05)` | `BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0D000000))` |
| shadow-md | `0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)` | `BoxShadow(offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1, color: Color(0x1A000000))` |
| shadow-lg | `0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)` | `BoxShadow(offset: Offset(0, 10), blurRadius: 15, spreadRadius: -3, color: Color(0x1A000000))` |
| shadow-colored | `0 8px 24px -4px [color] / 0.4` (light) / `0.35` (dark) | `BoxShadow(offset: Offset(0, 8), blurRadius: 24, spreadRadius: -4, color: color.withAlpha(102))` light / `color.withAlpha(89)` dark |

---

## 6. Animations

| Token | Value |
|-------|-------|
| duration-fast | 120ms |
| duration-normal | 200ms |
| duration-slow | 400ms |
| easing-default | `cubic-bezier(0.4, 0, 0.2, 1)` |
| easing-in | `cubic-bezier(0.4, 0, 1, 1)` |
| easing-out | `cubic-bezier(0, 0, 0.2, 1)` |

**Reduced motion** : toutes les durations → 0ms.
- Angular : `@media (prefers-reduced-motion: reduce)` (automatique CSS)
- Flutter : `AppDurations.resolve(duration, context)` verifie `MediaQuery.of(context).disableAnimations`

---

## 7. Platform-Specific (non partages)

| Token | Platform | Value | Note |
|-------|----------|-------|------|
| z-dropdown | Angular | 100 | Flutter gere via elevation |
| z-sticky | Angular | 200 | |
| z-fab | Angular | 250 | |
| z-overlay | Angular | 300 | |
| z-modal | Angular | 400 | |
| z-toast | Angular | 500 | |
| sidebar-width | Angular | 240px | Layout specifique PWA |
| header-height | Angular | 56px | Layout specifique PWA |
| bottom-nav-height | Angular | 64px | Hauteur barre navigation mobile |

---

## Migration Guide

Tokens renommes ou modifies par rapport aux versions precedentes.

### Valeurs modifiees

| Token | Ancien | Nouveau | Plateforme |
|-------|--------|---------|------------|
| color-subscription (light) | `#2563eb` (blue-600) | `#8b5cf6` (violet-500) | Angular |
| color-subscription (dark) | `#60a5fa` (blue-400) | `#a78bfa` (violet-400) | Angular |
| success | `#10B981` (emerald-500) | `#22c55e` (green-500) | Flutter |
| warning | `#F59E0B` (amber-500) | `#eab308` (yellow-500) | Flutter |
| income (light) | `#10B981` (emerald-500) | `#16a34a` (green-600) | Flutter |
| expense (light) | `#EF4444` (red-500) | `#dc2626` (red-600) | Flutter |
| debt-owe (light) | `#F59E0B` (amber-500) | `#dc2626` (red-600) | Flutter |
| debt-owed (light) | `#3B82F6` (blue-500) | `#16a34a` (green-600) | Flutter |
| income (dark) | `#34D399` (emerald-400) | `#4ade80` (green-400) | Flutter |
| debt-owe (dark) | `#FBBF24` (amber-400) | `#f87171` (red-400) | Flutter |
| debt-owed (dark) | `#60A5FA` (blue-400) | `#4ade80` (green-400) | Flutter |
| ColorScheme.error (dark) | `#ef4444` (red-500) | `#f87171` (red-400) | Flutter |

### Tokens renommes

| Ancien | Nouveau | Plateforme |
|--------|---------|------------|
| easeInOut | easeDefault | Flutter (alias conserve pour compatibilite) |

### Tokens ajoutes

| Token | Plateforme | Description |
|-------|------------|-------------|
| Indigo 50-900 | Les deux | Palette secondaire complete |
| color-secondary, -hover, -light, -contrast | Les deux | Tokens semantiques secondaires |
| space-9, space-11 | Angular | Completent l'echelle 4px |
| radius-xxl | Angular | 24px |
| violet-400, violet-500 | Les deux | Primitives subscription |
| line-height-tight, -normal, -relaxed | Flutter | Hauteurs de ligne |
| fontMono | Flutter | Police monospace |
| AppDurations.resolve() | Flutter | Support reduced-motion |
| secondaryColor | Flutter | Theme extension property |
| warningLight, successLight, errorLight, infoLight | Flutter | Feedback backgrounds |
| textSuccess, textError, textWarning, textInfo | Flutter | Feedback text colors |

---

## File Mapping

| Reference Token | Angular (SCSS) | Flutter (Dart) |
|-----------------|---------------|----------------|
| `amber-500` | `$amber-500` / `--amber-500` | `AppColors.amber500` |
| `indigo-600` | `$indigo-600` / `--indigo-600` | `AppColors.indigo600` |
| `color-primary` | `--color-primary` (theme) | `ColorScheme.primary` |
| `color-secondary` | `--color-secondary` (theme) | `ColorScheme.secondary` |
| `space-4` | `$space-4` / `--space-4` | `AppSpacing.space4` |
| `font-size-base` | `$font-size-base` / `--font-size-base` | `AppTypography.sizeMd` |
| `radius-md` | `$radius-md` / `--radius-md` | `AppRadius.md` |
| `shadow-sm` | `$shadow-sm` / `--shadow-sm` | `AppShadows.sm` |
| `duration-fast` | `$duration-fast` / `--duration-fast` | `AppDurations.fast` |
| `color-income` | `--color-income` (theme) | `AppThemeExtension.incomeColor` |
| `color-subscription` | `--color-subscription` (theme) | `AppThemeExtension.subscriptionColor` |

---

## 8. Icons

### Package

| Platform | Package | Version |
|----------|---------|---------|
| Angular | `@ng-icons/core` + `@ng-icons/phosphor-icons` | v33.1.0 |
| Flutter | `phosphor_flutter` | v2.1.0 |

### Styles

| Style | Usage | Flutter | Angular import |
|-------|-------|---------|----------------|
| Regular | Navigation inactive, inline, decoratif | `PhosphorIconsRegular.*` | `@ng-icons/phosphor-icons/regular` |
| Fill | Navigation active, etats selectionnes | `PhosphorIconsFill.*` | `@ng-icons/phosphor-icons/fill` |
| Bold | Actions (FAB, boutons, close, delete) | `PhosphorIconsBold.*` | `@ng-icons/phosphor-icons/bold` |

### Tailles

| Contexte | Taille | Exemples |
|----------|--------|----------|
| Navigation (bottom nav, sidebar) | 24px | Home, Transactions, Settings |
| Actions (FAB, boutons primaires) | 24px | Add, Delete, Refresh, Close |
| Inline (listes, formulaires, prefix) | 20px | Email, Lock, Calendar, Chevron |
| Decoratif (badges, indicators) | 16px | Check mark on color picker |

### Usage Angular

```typescript
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorHouse } from '@ng-icons/phosphor-icons/regular';
import { phosphorHouseFill } from '@ng-icons/phosphor-icons/fill';
import { phosphorPlusBold } from '@ng-icons/phosphor-icons/bold';

@Component({
  imports: [NgIcon],
  providers: [provideIcons({ phosphorHouse, phosphorHouseFill, phosphorPlusBold })],
  template: `<ng-icon name="phosphorHouse" size="24"></ng-icon>`,
})
```

### Usage Flutter

```dart
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Regular (inline, navigation inactive)
PhosphorIcon(PhosphorIconsRegular.house, size: 24.0)

// Fill (navigation active)
PhosphorIcon(PhosphorIconsFill.house, size: 24.0)

// Bold (actions)
PhosphorIcon(PhosphorIconsBold.plus, size: 24.0)
```

### Dark mode

Les icones Phosphor heritent de `currentColor` par defaut :
- **Angular** : `<ng-icon>` utilise `color: inherit` — les tokens CSS s'appliquent automatiquement
- **Flutter** : `PhosphorIcon` (extends `Icon`) utilise `IconThemeData.color` du theme

---

## 8. Dashboard visual tokens

Tokens specifiques au dashboard Angular (definis dans `_dark.scss` et `_light.scss`). Non utilises par Flutter.

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `--hero-gradient` | `linear-gradient(135deg, amber-900, indigo-900)` | `linear-gradient(135deg, amber-50, indigo-50)` | Fond hero card patrimoine |
| `--glass-bg` | `rgba(31, 41, 55, 0.6)` | `var(--surface-raised)` | Fond glassmorphism cards |
| `--glass-border` | `rgba(255, 255, 255, 0.08)` | `var(--border-default)` | Bordure glassmorphism |
| `--glass-blur` | `20px` | `0px` | Blur backdrop-filter |
| `--page-gradient-color` | `rgba(251, 191, 36, 0.08)` | `rgba(245, 158, 11, 0.05)` | Gradient radial fond page |
| `--font-size-hero` | `2.25rem` | `2.25rem` | Font-size montant patrimoine |
| `--shadow-hero-text` | `0 2px 8px rgba(0, 0, 0, 0.3)` | `none` | Text-shadow montant patrimoine |

> **Note** : Le glassmorphism (`backdrop-filter: blur()`) est applique uniquement en dark mode. En light mode, les cards utilisent un fond opaque via les tokens fallback.
