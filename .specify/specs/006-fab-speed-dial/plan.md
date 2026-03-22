# Implementation Plan: Bouton flottant (+) avec Speed Dial

**Branch**: `006-fab-speed-dial` | **Date**: 2026-02-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-fab-speed-dial/spec.md`

## Summary

Implémenter un bouton d'action flottant (FAB) avec menu speed dial dans le Shell Angular, permettant la création rapide de transactions, abonnements et dettes via des modals placeholder. Feature purement frontend (pas de backend), utilisant `@angular/cdk` pour le focus trap et le scroll lock, avec des animations CSS performantes (200ms, 60 FPS).

## Technical Context

**Language/Version**: TypeScript 5.9.2 / Angular 21.1.0
**Primary Dependencies**: `@angular/cdk` (overlay + a11y), `@angular/router` (NavigationEnd)
**Storage**: N/A (feature purement UI, pas de persistance)
**Testing**: Vitest 4.x via `@analogjs/vite-plugin-angular`
**Target Platform**: PWA mobile-first, desktop responsive (>= 768px)
**Project Type**: web (monorepo `app/` frontend)
**Performance Goals**: 60 FPS animations, ouverture modal en 2 interactions max
**Constraints**: `@angular/cdk` à installer (non présent), animations CSS uniquement (pas de JS requestAnimationFrame), design tokens existants
**Scale/Scope**: 2 composants (Fab, Modal), 1 token z-index à ajouter, intégration dans Shell existant

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe | Statut | Justification |
|----------|--------|---------------|
| I. API-First | N/A | Feature purement UI, pas d'endpoint backend |
| II. Sécurité par défaut | PASS | FAB intégré dans Shell (route protégée par authGuard), invisible hors auth |
| III. Simplicité & YAGNI | PASS | 3 composants simples, pas d'abstraction prématurée. Modal réutilisable justifié par les futures features formulaires |
| IV. Mobile-First UX | PASS | FAB = concrétisation directe du principe "saisie en 2-3 interactions". Responsive mobile → desktop |
| V. Testabilité | PASS | Composants standalone testables unitairement. Signals = état facile à inspecter |
| VI. Observabilité | N/A | Feature UI sans logique métier serveur |
| VII. Self-Hosted Ready | N/A | Pas de dépendance SaaS. `@angular/cdk` est une lib Angular officielle |

**Résultat** : PASS (aucune violation)

## Project Structure

### Documentation (this feature)

```text
specs/006-fab-speed-dial/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (component interfaces)
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/src/
├── app/
│   ├── shared/
│   │   └── components/
│   │       ├── fab/
│   │       │   ├── fab.ts           # FAB + Speed Dial (composant unique)
│   │       │   ├── fab.html         # Template
│   │       │   └── fab.scss         # Styles + animations
│   │       └── modal/
│   │           ├── modal.ts         # Modal réutilisable (CDK overlay)
│   │           ├── modal.html       # Template (header + body slot)
│   │           └── modal.scss       # Styles + animations
│   └── ...
└── styles/
    └── tokens/
        ├── _primitives.scss   # + $z-fab: 250
        └── _tokens.scss       # + --z-fab token
```

**Structure Decision** : Le FAB et le speed dial forment un seul composant (`Fab`) car ils sont indissociables et partagent le même état (ouvert/fermé). Le modal est séparé car réutilisable par les futures features formulaires. Les deux sont dans `shared/components/` conformément à la spec.

## Design

### Component Architecture

```
Shell (existant)
├── <header> (existant)
├── <nav sidebar> (existant)
├── <main> <router-outlet /> (existant)
├── <app-fab />                    ← NOUVEAU
│   ├── Bouton FAB (56px, rond)
│   ├── Overlay speed dial
│   └── Items speed dial × 3
└── <app-modal />                  ← NOUVEAU (conditionnel)
    ├── Overlay modal
    ├── Header (titre + bouton ×)
    └── Body (ng-content / placeholder)
```

### State Management (Signals)

```
Shell
├── sidebarOpen: signal<boolean>       (existant)
├── speedDialOpen: signal<boolean>     (NOUVEAU)
├── activeModal: signal<ModalType | null>  (NOUVEAU)
│
├── Fab (inputs/outputs)
│   ├── input: isOpen (lié à speedDialOpen)
│   ├── input: isHidden (computed: activeModal() !== null)
│   ├── output: toggle → Shell.speedDialOpen.update()
│   └── output: actionSelected → Shell ouvre le modal
│
└── Modal (inputs/outputs)
    ├── input: isOpen (computed: activeModal() !== null)
    ├── input: title (computed depuis activeModal)
    └── output: close → Shell.activeModal.set(null)
```

### ModalType

```typescript
type ModalType = 'transaction' | 'subscription' | 'debt';
```

### Z-index Layers

```
--z-sticky:  200  ← Header
--z-fab:     250  ← FAB button (NOUVEAU)
--z-overlay: 300  ← Speed dial overlay + Sidebar backdrop
--z-modal:   400  ← Modal overlay + Modal panel
--z-toast:   500  ← Notifications (futur)
```

### Animations CSS

**FAB icon rotation** :
```
Fermé: rotate(0deg) → Ouvert: rotate(135deg)
Durée: var(--duration-normal) = 200ms
Easing: var(--easing-default)
```

**Speed dial items (staggered)** :
```
Chaque item: opacity 0→1, translateY(8px)→translateY(0)
Délai: item[i] * 50ms (3 items = 0ms, 50ms, 100ms)
Durée totale: ~150ms + 50ms = 200ms
```

**Modal apparition** :
```
Overlay: opacity 0→1, 200ms
Panel: opacity 0→1 + scale(0.95)→scale(1), 200ms
Easing: var(--easing-out)
```

### Router Integration

Le Shell écoute `Router.events` (filtre `NavigationEnd`) pour fermer automatiquement le speed dial et le modal à chaque changement de route. Implémenté via `toSignal()` + `effect()`.

### CDK Integration

**Focus trap (speed dial)** : `cdkTrapFocus` directive sur le conteneur des items speed dial. Navigation clavier personnalisée via `@HostListener` ou `(keydown)` handler pour ArrowUp/ArrowDown/Enter/Escape.

**Scroll lock (modal)** : Approche manuelle légère — `document.body.style.overflow = 'hidden'` à l'ouverture, restauration à la fermeture. Le `BlockScrollStrategy` du CDK Overlay est conçu pour les overlays CDK complets. Comme notre modal est un composant standalone (pas un CDK Overlay), le scroll lock manuel est plus simple et direct.

**Focus trap (modal)** : `cdkTrapFocus` + `cdkTrapFocusAutoCapture` sur le panel modal.

### Accessibility

- FAB : `aria-label="Actions rapides"`, `aria-expanded` lié à l'état ouvert
- Speed dial items : `role="menu"` sur le conteneur, `role="menuitem"` sur chaque item
- Modal : `role="dialog"`, `aria-modal="true"`, `aria-labelledby` lié au titre
- Bouton fermer modal : `aria-label="Fermer"`
- Focus restauré sur le FAB après fermeture du speed dial
- Focus restauré sur le FAB après fermeture du modal
- `prefers-reduced-motion` : déjà géré par les tokens (durées à 0ms)

### Responsive Behavior

**Mobile (< 768px)** :
- FAB : `position: fixed`, `bottom: 16px`, `right: 16px`
- Modal : `width: calc(100% - 32px)`, centré

**Desktop (>= 768px)** :
- FAB : `position: fixed`, `bottom: 16px`, `right: 16px` (le contenu a déjà `margin-left: var(--sidebar-width)`, le FAB est dans la zone de contenu car il est enfant du Shell et positionné en fixed par rapport au viewport — il faut ajuster `right` pour tenir compte de la sidebar ou le positionner relativement à la zone de contenu)
- Approche : `right: 16px` fonctionne car le FAB est visuellement dans la zone libre du viewport. Sur desktop avec sidebar de 240px, le FAB reste à droite du viewport, bien dans la zone de contenu.
- Modal : `max-width: 480px`, centré horizontalement

## Complexity Tracking

> Aucune violation de constitution détectée. Tableau non applicable.

## Build Sequence

1. Installer `@angular/cdk`
2. Ajouter token `--z-fab` dans les design tokens
3. Créer composant `Modal` (shared, réutilisable)
4. Créer composant `Fab` (shared, FAB + speed dial)
5. Intégrer `Fab` et `Modal` dans le Shell
6. Implémenter la fermeture automatique sur navigation
7. Tests unitaires
8. Vérification lint + format
