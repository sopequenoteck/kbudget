# Implementation Plan: Redesign page Dettes

**Branch**: `022-debt-page-redesign` | **Date**: 2026-02-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/022-debt-page-redesign/spec.md`

## Summary

Refonte visuelle et UX de la page Dettes : remplacement de la liste plate par un groupement par sens (On me doit / Je dois) avec sections colorées, suppression du filtre par sens (devenu redondant), KPI calculés sur les dettes en cours uniquement, badge "Remboursé" inline, et enrichissement des items (catégorie + date relative). Changement purement frontend sur 3 fichiers existants (`debts.ts`, `debts.html`, `debts.scss`).

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: Angular (Signals, standalone, OnPush), SCSS design tokens, `ListItem`, `AmountPipe`, `RelativeDatePipe`
**Storage**: N/A (données via `DebtService` existant, API REST backend inchangée)
**Testing**: Vitest 4.x via `npx vitest run` (config: `app/vitest.config.ts`)
**Target Platform**: PWA mobile-first (Chrome, Safari mobile)
**Project Type**: web (frontend uniquement pour cette feature)
**Performance Goals**: N/A (dataset personnel, single-user)
**Constraints**: Mobile-first, minimum 320px width, tokens CSS uniquement (jamais de valeurs hardcodées)
**Scale/Scope**: 1 page, 3 fichiers modifiés (`debts.ts`, `debts.html`, `debts.scss`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Pas de changement backend |
| II. Sécurité par défaut | N/A | Pas de changement de sécurité |
| III. Simplicité & YAGNI | PASS | Réutilise `ListItem` existant, pas de nouveau composant, pas d'abstraction |
| IV. Mobile-First UX | PASS | Design responsive 320px+, groupement visuel réduit les interactions |
| V. Testabilité | PASS | Logique dans computed signals testables unitairement |
| VI. Observabilité | N/A | Frontend uniquement, isDevMode() existant conservé |
| VII. Self-Hosted Ready | N/A | Pas de dépendance externe |

**Verdict** : Tous les gates passent. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/022-debt-page-redesign/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output (minimal — pas d'inconnus)
├── data-model.md        # Phase 1 output (structure computed signals)
├── quickstart.md        # Phase 1 output (validation manuelle)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/app/features/debts/
├── debts.ts        # Component class — signals, computed, logique de filtrage/groupement
├── debts.html      # Template — KPI cards, filtre statut, sections groupées
└── debts.scss      # Styles — sections avec accent latéral, badge inline, opacité
```

**Structure Decision** : Modification in-place de 3 fichiers existants dans `app/src/app/features/debts/`. Aucun nouveau fichier source créé. Le composant `ListItem` (`app/src/app/shared/components/list-item/`) est réutilisé tel quel sans modification.

## Complexity Tracking

> Aucune violation de la constitution. Tableau non applicable.

## Design — Changements détaillés

### 1. Component class (`debts.ts`)

**Suppressions :**
- Signal `sensFilter` et type `SensFilter`
- Méthode `setSensFilter()`
- Filtrage par sens dans `filteredDebts`

**Modifications :**

```
loadData() :
  - AVANT : charge les dettes filtrées par statut via API (rembourse param)
  - APRÈS : charge TOUTES les dettes (pas de param rembourse),
            le filtrage statut se fait côté client dans les computed signals
```

**Nouveaux computed signals :**

| Signal | Source | Description |
|--------|--------|-------------|
| `activeDebts` | `debts().filter(d => !d.rembourse)` | Dettes en cours uniquement (pour KPI) |
| `filteredDebts` | `debts()` filtré par `statusFilter` | Dettes après filtre statut (pour liste) |
| `totalJeDois` | `activeDebts` → EMPRUNT → sum | KPI total emprunts en cours |
| `totalOnMeDoit` | `activeDebts` → PRET → sum | KPI total prêts en cours |
| `netBalance` | `totalOnMeDoit - totalJeDois` | KPI solde net |
| `debtsOnMeDoit` | `filteredDebts` → PRET → sort date desc | Section "On me doit" |
| `debtsJeDois` | `filteredDebts` → EMPRUNT → sort date desc | Section "Je dois" |
| `sectionTotalOnMeDoit` | `debtsOnMeDoit` → sum | Total header section prêts |
| `sectionTotalJeDois` | `debtsJeDois` → sum | Total header section emprunts |
| `hasDebts` | `debts().length > 0` | Afficher KPI ou état vide |

**Changement de chargement :**

```
loadData() :
  - Appel API : this.debtService.getAll() (sans param → toutes les dettes)
  - Plus besoin de recharger à chaque changement de statusFilter
  - Le effect() ne track plus statusFilter() — le filtrage est client-side
```

**Méthode `getSubtitle(debt)` ajoutée :**
- Si `debt.category` → retourne `debt.category.nom`
- Sinon → retourne `"Emprunt"` ou `"Prêt"` selon `debt.sens`

### 2. Template (`debts.html`)

**Structure cible :**

```
@if (hasDebts()) { KPI cards (3) }
Filtre statut (segmented control unique)
@if (loading) { spinner }
@else if (error) { error + retry }
@else if (no filtered debts) { empty state }
@else {
  @if (debtsOnMeDoit().length > 0) {
    Section "On me doit" avec header + total + accent vert
    Liste items avec ListItem
  }
  @if (debtsJeDois().length > 0) {
    Section "Je dois" avec header + total + accent rouge
    Liste items avec ListItem
  }
}
```

**Changements template par rapport à l'existant :**

| Élément | Avant | Après |
|---------|-------|-------|
| KPI `totalJeDois` / `totalOnMeDoit` | Basé sur `filteredDebts` (filtré par sens) | Basé sur `activeDebts` (en cours uniquement) |
| Filtre sens | 2e segmented control | Supprimé |
| Liste | `<ul>` plate avec `filteredDebts` | 2 `<section>` avec header + `<ul>` par sens |
| Section header | N/A | `<div class="section-header">` avec titre + total coloré |
| Badge "Remboursé" | `<span>` absolute dans `<li>` | Inclus dans `subtitle` de `ListItem` via concaténation |
| Subtitle ListItem | `debt.date \| relativeDate` | `getSubtitle(debt)` (catégorie ou type) |
| Right subtitle | Non utilisé | `debt.date \| relativeDate` |
| Item opacité | Aucune | Classe CSS `.debt-item--rembourse` sur `<li>` si `debt.rembourse` |

**Badge inline — approche retenue :**
Le badge "Remboursé" est géré par deux mécanismes combinés :
- **Opacité** : classe CSS `.debt-item--rembourse` sur le `<li>` wrapper → `opacity: 0.5`
- **Texte** : concaténation dans le `subtitle` input de `ListItem` via `getSubtitle()` (ex: `"Personnel · Remboursé"`)

Pas de modification du composant partagé `ListItem` — tout est dans le composant debts.

### 3. Styles (`debts.scss`)

**Suppressions :**
- `.sens-filter` et `&__btn` (entièrement supprimé)
- `.badge-rembourse` (remplacé par approche inline)

**Modifications :**
- `.debt-list` → déplacé à l'intérieur de `.debt-section` (section wrapper)

**Ajouts :**

```scss
// Section groupée (On me doit / Je dois)
.debt-section {
  display: flex;
  flex-direction: column;
  border-radius: var(--radius-xl);
  background-color: var(--surface-default);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  border-left: 3px solid transparent; // accent latéral

  &--owed {
    border-left-color: var(--color-debt-owed); // vert
  }

  &--owe {
    border-left-color: var(--color-debt-owe); // rouge
  }
}

// Header de section
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-3) var(--space-4);
  // titre: font-size-sm, font-weight-semibold, text-secondary
  // total: font-size-sm, font-weight-bold, coloré selon sens
}

// Item remboursé
.debt-item--rembourse {
  opacity: 0.5;
}
```

### 4. Flux de données

```
API: GET /api/debts (toutes les dettes)
  ↓
debts signal (toutes les dettes)
  ├── activeDebts (rembourse === false) → KPI (totalJeDois, totalOnMeDoit, netBalance)
  └── filteredDebts (filtre statusFilter côté client)
       ├── debtsOnMeDoit (sens === PRET, tri date desc) + sectionTotalOnMeDoit
       └── debtsJeDois (sens === EMPRUNT, tri date desc) + sectionTotalJeDois
```

### 5. Risques et mitigations

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Charger toutes les dettes au lieu de filtrer côté API | Faible — app single-user, dataset petit | Acceptable pour cette échelle |
| Badge inline via concaténation subtitle | Le texte "Remboursé" n'est pas stylisable séparément | Opacité sur l'item entier compense — le badge est informatif |
| Perte du rechargement API par changement de filtre | Aucun — les données sont identiques | Le filtrage client-side est instantané |
