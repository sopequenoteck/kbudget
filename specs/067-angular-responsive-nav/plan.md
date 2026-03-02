# Implementation Plan: Navigation responsive Angular (bottom nav mobile)

**Branch**: `067-angular-responsive-nav` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/067-angular-responsive-nav/spec.md`
**Linear**: KKS-153

## Summary

Remplacer la sidebar mobile (hamburger + drawer) par une barre de navigation inferieure (bottom nav) sur les ecrans < 768px, en conservant la sidebar sur desktop. La bottom nav affiche les memes onglets dynamiques (features activees + navOrder) que la sidebar. Approche CSS-only (media queries), composant standalone dedie, zero modification backend.

## Technical Context

**Language/Version**: TypeScript 5.9, Angular 21
**Primary Dependencies**: Angular Router, Angular Signals, Angular CDK (deja present)
**Storage**: N/A (pas de persistance, reutilise PreferenceService existant)
**Testing**: Vitest (Angular test runner du projet)
**Target Platform**: PWA mobile-first (Chrome, Safari, Firefox)
**Project Type**: Web application (frontend Angular uniquement)
**Performance Goals**: Transition responsive instantanee (CSS media queries, pas de JS)
**Constraints**: Breakpoint 768px (existant), design tokens CSS obligatoires
**Scale/Scope**: 1 nouveau composant, 4 fichiers modifies, 1 token CSS ajoute

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Pas de modification backend |
| II. Securite par defaut | N/A | Pas de changement auth/securite |
| III. Simplicite & YAGNI | PASS | 1 composant dedie, CSS media queries, pas de sur-ingenierie |
| IV. Mobile-First UX | PASS | Navigation 1-tap au lieu de 2 (hamburger+lien), standard mobile |
| V. Testabilite | PASS | Composant standalone testable isolement |
| VI. Observabilite | N/A | Pas de logging a ajouter (UI pure) |
| VII. Self-Hosted Ready | N/A | Pas d'infra impactee |

**Post-design re-check**: Meme resultat. Aucune violation.

## Project Structure

### Documentation (this feature)

```text
specs/067-angular-responsive-nav/
├── plan.md              # This file
├── research.md          # Decisions techniques (7 decisions)
├── data-model.md        # Pas de nouveau modele
├── quickstart.md        # Guide demarrage rapide
└── tasks.md             # (genere par /speckit.tasks)
```

### Source Code (repository root)

```text
app/src/
├── app/shared/components/
│   ├── bottom-nav/
│   │   ├── bottom-nav.ts          # CREER — composant standalone
│   │   └── bottom-nav.scss        # CREER — styles bottom nav
│   ├── shell/
│   │   ├── shell.ts               # MODIFIER — import BottomNav, passer inputs
│   │   ├── shell.html             # MODIFIER — ajouter <bottom-nav>, supprimer hamburger mobile
│   │   └── shell.scss             # MODIFIER — masquer sidebar mobile, padding bottom nav
│   └── fab/
│       └── fab.scss               # MODIFIER — repositionner FAB au-dessus de bottom nav
└── styles/tokens/
    └── _tokens.scss               # MODIFIER — ajouter --bottom-nav-height
```

**Structure Decision**: Frontend uniquement. Nouveau composant dans `shared/components/` (meme pattern que `fab/`). Aucun backend modifie.

## Design technique

### 1. Composant BottomNav

**Fichier**: `app/src/app/shared/components/bottom-nav/bottom-nav.ts`

- Standalone, `ChangeDetectionStrategy.OnPush`
- **Inputs**:
  - `items = input.required<{label: string; route: string; icon: string}[]>()` — liste des onglets (compatible avec le computed `navItems` existant dans shell.ts)
  - `activeRoute = input<string>('')` — route courante pour highlighting
- **Template**: `<nav>` avec `@for` sur les items, chaque item est un `<a routerLink>`
- **Style**: Barre fixe en bas, `display: flex`, items repartis uniformement (`flex: 1`)
- **Active state**: Classe `.active` via comparaison `activeRoute().startsWith(item.route)`

### 2. Modifications Shell

**shell.html**:
- Ajouter `<bottom-nav [items]="navItems()" [activeRoute]="currentRoute()" />` apres le contenu principal
- La bottom nav est masquee par CSS sur desktop (pas de `@if` Angular, pure CSS)
- Le bouton hamburger reste dans le HTML mais masque sur mobile par CSS (inversion de la logique actuelle)

**shell.ts**:
- Import `BottomNav` dans le composant
- Ajouter `currentRoute` comme computed derive du signal `navigationEnd` (cree via `toSignal` sur `router.events`) : `computed(() => navigationEnd() instanceof NavigationEnd ? navigationEnd().urlAfterRedirects : router.url)`. NB : `router.url` n'est pas reactif, donc `computed(() => this.router.url)` ne fonctionnerait pas — le `navigationEnd` toSignal est le declencheur reactif.
- Les `navItems` existants sont reutilises tels quels (meme computed signal, retourne `{label, route, icon}[]`)

**shell.scss** — Changements responsive:
- Mobile (< 768px):
  - `.shell-sidebar`: `display: none` (plus de sidebar du tout, plus de backdrop)
  - `.shell-hamburger`: `display: none` (plus de bouton hamburger)
  - `.shell-content`: `padding-bottom: calc(var(--bottom-nav-height) + var(--space-6) + 56px + var(--space-4))` (bottom nav + FAB)
  - `bottom-nav`: `display: flex` (visible)
- Desktop (>= 768px):
  - `bottom-nav`: `display: none` (masquee)
  - Sidebar inchangee (toujours visible)

### 3. FAB repositionnement

**fab.scss**:
- Mobile: `.fab-button { bottom: calc(var(--bottom-nav-height) + var(--space-4)); }`
- Desktop: inchange (`bottom: var(--space-6)`)
- Le speed dial menu s'ajuste automatiquement (positionne relativement au FAB)

### 4. Design tokens

**_tokens.scss**:
- Ajouter `--bottom-nav-height: 56px;` dans `:root`

### 5. Styles bottom-nav

**bottom-nav.scss**:
```
- Position fixed, bottom 0, left 0, right 0
- Height: var(--bottom-nav-height)
- Background: var(--surface-default)
- Border-top: 1px solid var(--border-default)
- Z-index: var(--z-sticky)
- Ne PAS definir `display` sur `:host` — le controle flex/none est gere par shell.scss via media queries
- Items repartis (flex: 1 sur chaque item)
- Item: flex column, align center, gap var(--space-1)
- Icone: font-size 1.25rem
- Label: font-size var(--text-xs), overflow hidden, text-overflow ellipsis, white-space nowrap, max-width 100%
- Active: couleur var(--color-primary), font-weight var(--font-semibold)
- Inactive: couleur var(--text-secondary)
- Safe area: padding-bottom env(safe-area-inset-bottom) pour iPhone notch
```

### 6. Nettoyage code mobile sidebar

Le code existant pour la sidebar mobile dans le shell (sidebarOpen signal, toggleSidebar(), backdrop click handler) pourra etre supprime car la sidebar n'est plus affichee sur mobile. Cependant, pour minimiser le risque de regression, on conserve le signal `sidebarOpen` et la logique associee mais le CSS `display: none` les rend inoperants sur mobile.

### 7. Edge case : chargement des preferences

Le computed `navItems` existant demarre avec les 2 onglets fixes (`Accueil`, `Transactions`) puis ajoute les onglets optionnels une fois `navOrder` et `enabledFeatures` charges. Tant que le `PreferenceService` n'a pas repondu, `navOrder()` et `enabledFeatures()` retournent des tableaux vides, donc seuls les 2 onglets fixes sont affiches. Ce comportement satisfait l'edge case "preferences pas encore chargees" de la spec sans code supplementaire.

## Complexity Tracking

> Aucune violation de constitution. Pas de complexite additionnelle.

Pas d'entrees necessaires.
