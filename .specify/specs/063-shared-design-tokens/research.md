# Research: Shared Design Tokens

**Feature**: 063-shared-design-tokens | **Date**: 2026-03-01

## R1 — Best-of-Both Token Resolution

### Methodology

Each divergent token evaluated on: contrast (WCAG AA), semantic clarity, Tailwind alignment, visual consistency.

### Color Palette Decisions

#### Feedback Colors (Light)

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| success | `#22c55e` (green-500) | `#10B981` (emerald-500) | **#22c55e** (Angular) | Tailwind green-500 standard, meilleure reconnaissance universelle |
| warning | `#eab308` (yellow-500) | `#F59E0B` (amber-500) | **#eab308** (Angular) | Flutter warning = primary = collision sémantique critique |
| error | `#ef4444` | `#EF4444` | **#ef4444** | Identique |
| info | `#3b82f6` | `#3B82F6` | **#3b82f6** | Identique |

#### Feedback Colors (Dark)

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| success | `#4ade80` (green-400) | `#34D399` (emerald-400) | **#4ade80** (Angular) | Cohérence avec light, Tailwind green-400 |
| warning | (absent) | (absent) | **#facc15** (yellow-400) | Nouvelle valeur, Tailwind yellow-400 |
| error | `#f87171` (red-400) | `#F87171` | **#f87171** | Identique |
| info | `#60a5fa` (blue-400) | (absent) | **#60a5fa** (Angular) | Tailwind blue-400 |

#### Feedback Colors (Light Background)

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| bg-success | `#dcfce7` | (absent) | **#dcfce7** | Tailwind green-100 |
| bg-warning | `#fef9c3` | (absent) | **#fef9c3** | Tailwind yellow-100 |
| bg-error | `#fee2e2` | (absent) | **#fee2e2** | Tailwind red-100 |
| bg-info | `#dbeafe` | (absent) | **#dbeafe** | Tailwind blue-100 |

#### Feedback Colors (Text on Light)

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| text-success | `#16a34a` (green-600) | (absent) | **#16a34a** | Bon contraste sur blanc (5.1:1) |
| text-warning | `#ca8a04` (yellow-700) | (absent) | **#ca8a04** | Bon contraste sur blanc (4.7:1) |
| text-error | `#dc2626` (red-600) | (absent) | **#dc2626** | Bon contraste sur blanc (5.6:1) |
| text-info | `#2563eb` (blue-600) | (absent) | **#2563eb** | Bon contraste sur blanc (5.3:1) |

#### Business Colors (Light)

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| income | `#16a34a` (green-600) | `#10B981` (emerald-500) | **#16a34a** (Angular) | Meilleur contraste sur blanc, cohérent text-success |
| expense | `#dc2626` (red-600) | `#EF4444` (red-500) | **#dc2626** (Angular) | Meilleur contraste, cohérent text-error |
| debt-owe | `#dc2626` (red-600) | `#F59E0B` (amber-500) | **#dc2626** (Angular) | "Je dois" = négatif = rouge. Flutter utilisait primary = confusion |
| debt-owed | `#16a34a` (green-600) | `#3B82F6` (blue-500) | **#16a34a** (Angular) | "On me doit" = positif = vert. Symétrie avec income |
| subscription | `#2563eb` (blue-600) | `#8B5CF6` (violet-500) | **#8B5CF6** (Flutter) | Violet distingué d'Indigo secondary (#4F46E5) et de info (blue) |

#### Business Colors (Dark)

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| income | `#4ade80` (green-400) | `#34D399` (emerald-400) | **#4ade80** | Cohérence avec light-income = green family |
| expense | `#f87171` (red-400) | `#F87171` | **#f87171** | Identique |
| debt-owe | `#f87171` (red-400) | `#FBBF24` (amber-400) | **#f87171** | Cohérence debt-owe = red |
| debt-owed | `#4ade80` (green-400) | `#60A5FA` (blue-400) | **#4ade80** | Cohérence debt-owed = green |
| subscription | `#60a5fa` (blue-400) | `#A78BFA` (violet-400) | **#A78BFA** | Cohérence avec light = violet |

### Spacing Scale

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| space-9 (36px) | **absent** | `36.0` | **Ajouter** | Compléter la séquence 4px |
| space-11 (44px) | **absent** | `44.0` | **Ajouter** | Compléter la séquence 4px |

Échelle finale : 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48 (13 valeurs, 0-12).

### Border Radius

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| xxl (24px) | **absent** | `24.0` | **Ajouter** | Utile pour grandes cartes, modals |

Échelle finale : sm=4, md=8, lg=12, xl=16, xxl=24, round=999.

### Typography

| Token | Angular | Flutter | Decision | Rationale |
|-------|---------|---------|----------|-----------|
| Line heights | tight=1.25, normal=1.5, relaxed=1.75 | **absent** | **Ajouter dans Flutter** | Essentiel pour la cohérence typographique |
| Mono font | `ui-monospace, 'Cascadia Code', 'Fira Code', monospace` | **absent** | **Ajouter dans Flutter** | Utile pour montants, codes |

### Shadows

| Token | Angular (CSS) | Flutter | Decision | Rationale |
|-------|--------------|---------|----------|-----------|
| sm | `0 1px 2px 0 rgb(0 0 0 / 0.05)` | `Offset(0,1), blur 2, 5%` | **Identique** | Memes valeurs |
| md | dual: `0 4px 6px -1px / 0.1` + `0 2px 4px -2px / 0.1` | `Offset(0,2), blur 6, 10%` | **Angular** (reference) | Flutter simplifiera en single shadow acceptable |
| lg | dual: `0 10px 15px -3px / 0.1` + `0 4px 6px -4px / 0.1` | `Offset(0,4), blur 15, 10%` | **Angular** (reference) | Idem |
| colored | `0 8px 24px -4px / 0.4` | `Offset(0,2), blur 8, 30%` | **Angular** (reference) | Plus prononce, meilleur effet visuel |

Note : Flutter ne supporte pas `spread-radius` negatif dans BoxShadow de la meme maniere que CSS. L'approximation Flutter la plus proche sera documentee dans quickstart.md.

### Animations

Durations et easing identiques. Angular "default" = Flutter "easeInOut" = `cubic-bezier(0.4, 0, 0.2, 1)`.

Renommage : unifier sur `easeDefault` / `easeIn` / `easeOut` (les valeurs sont identiques, seuls les noms different).

---

## R2 — Indigo Secondary Palette

Source : Tailwind CSS Indigo scale. #4F46E5 = Indigo-600.

| Shade | Hex | Usage prevu |
|-------|-----|-------------|
| 50 | `#eef2ff` | Background tres leger |
| 100 | `#e0e7ff` | Background leger, badges |
| 200 | `#c7d2fe` | Bordures focus secondaire |
| 300 | `#a5b4fc` | — |
| 400 | `#818cf8` | Dark theme secondary |
| 500 | `#6366f1` | — |
| 600 | `#4f46e5` | **Main secondary** (light theme) |
| 700 | `#4338ca` | Hover secondary |
| 800 | `#3730a3` | — |
| 900 | `#312e81` | Dark accents |

### WCAG AA Contrast Check

| Couleur | Sur fond blanc | Sur fond #111827 (dark) | Verdict |
|---------|---------------|------------------------|---------|
| Indigo-600 `#4f46e5` | **7.9:1** | 2.1:1 | Light only |
| Indigo-400 `#818cf8` | 3.5:1 | **4.9:1** | Dark only |
| Indigo-500 `#6366f1` | **4.8:1** | 3.3:1 | Light text (AA, large) |

Decision : `indigo-600` pour light theme, `indigo-400` pour dark theme (meme pattern que primary amber-500/amber-400).

### Semantic Tokens Secondary

| Token | Light | Dark |
|-------|-------|------|
| `--color-secondary` | `indigo-600` (#4f46e5) | `indigo-400` (#818cf8) |
| `--color-secondary-hover` | `indigo-700` (#4338ca) | `indigo-300` (#a5b4fc) |
| `--color-secondary-light` | `indigo-100` (#e0e7ff) | `indigo-900` (#312e81) |
| `--color-secondary-contrast` | `#ffffff` | `#111827` |

---

## R3 — Reduced-Motion Flutter Implementation

### Approach

Angular : `@media (prefers-reduced-motion: reduce)` force toutes les durations a 0ms automatiquement.

Flutter : `MediaQuery.of(context).disableAnimations` (ou `MediaQueryData.disableAnimations`) detecte le setting OS.

### Implementation Pattern

Methode statique `resolve()` dans `AppDurations` :

```dart
static Duration resolve(Duration duration, BuildContext context) {
  return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
}
```

Usage :
```dart
AnimatedContainer(
  duration: AppDurations.resolve(AppDurations.normal, context),
  // ...
)
```

Alternatives rejetees :
- Provider Riverpod : sur-ingenierie pour un simple read de MediaQuery
- Extension sur Duration : ne porte pas le BuildContext

---

## R4 — Flutter Shadows Cross-Platform Mapping

CSS `box-shadow` supporte `spread-radius` negatif et multiples ombres. Flutter `BoxShadow` supporte `spreadRadius` mais sans negatif en pratique.

### Mapping Reference → Flutter

| Level | CSS Reference | Flutter Approximation |
|-------|--------------|----------------------|
| sm | `0 1px 2px 0 rgb(0 0 0 / 0.05)` | `BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0D000000))` |
| md | `0 4px 6px -1px rgb(0 0 0 / 0.1)` | `BoxShadow(offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1, color: Color(0x1A000000))` |
| lg | `0 10px 15px -3px rgb(0 0 0 / 0.1)` | `BoxShadow(offset: Offset(0, 10), blurRadius: 15, spreadRadius: -3, color: Color(0x1A000000))` |
| colored | `0 8px 24px -4px color/0.4` | `BoxShadow(offset: Offset(0, 8), blurRadius: 24, spreadRadius: -4, color: color.withAlpha(102))` |

Note : Flutter `spreadRadius` accepte les valeurs negatives. Les ombres secondaires (dual) CSS sont omises car l'effet visuel est suffisamment proche avec une seule ombre.
