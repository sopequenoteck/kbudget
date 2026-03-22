# Data Model: Bouton flottant (+) avec Speed Dial

**Feature**: 006-fab-speed-dial | **Date**: 2026-02-09

> Cette feature est purement frontend. Pas d'entités backend ni de persistance.
> Ce document décrit les interfaces TypeScript et les contrats des composants Angular.

## Types & Interfaces

### ModalType (type union)

```typescript
type ModalType = 'transaction' | 'subscription' | 'debt';
```

Représente les 3 actions disponibles dans le speed dial. Utilisé comme valeur émise par le Fab et comme état dans le Shell.

### SpeedDialItem (interface)

```typescript
interface SpeedDialItem {
  readonly type: ModalType;
  readonly label: string;
  readonly icon: string; // Contenu textuel pour l'icône (emoji v1)
}
```

Configuration d'un item du speed dial. Défini en constante dans le composant Fab :

```typescript
const SPEED_DIAL_ACTIONS: readonly SpeedDialItem[] = [
  { type: 'transaction', label: 'Transaction', icon: '💰' },
  { type: 'subscription', label: 'Abonnement', icon: '🔄' },
  { type: 'debt', label: 'Dette', icon: '🤝' },
] as const;
```

## Composants — Contrats (Inputs/Outputs)

### Fab (app-fab)

| Propriété | Type | Direction | Description |
|-----------|------|-----------|-------------|
| `isOpen` | `InputSignal<boolean>` | input | État ouvert/fermé du speed dial |
| `isHidden` | `InputSignal<boolean>` | input | Masquer le FAB (quand modal visible) |
| `toggle` | `OutputEmitterRef<void>` | output | Émis au clic sur le bouton FAB |
| `actionSelected` | `OutputEmitterRef<ModalType>` | output | Émis quand un item est sélectionné |

### Modal (app-modal)

| Propriété | Type | Direction | Description |
|-----------|------|-----------|-------------|
| `isOpen` | `InputSignal<boolean>` | input | Contrôle l'affichage du modal |
| `title` | `InputSignal<string>` | input | Titre affiché dans le header |
| `closed` | `OutputEmitterRef<void>` | output | Émis à la fermeture (×, overlay, Echap) |

Body : `<ng-content>` pour le contenu projeté.

## State du Shell (signals ajoutés)

| Signal | Type | Valeur initiale | Description |
|--------|------|-----------------|-------------|
| `speedDialOpen` | `WritableSignal<boolean>` | `false` | Menu speed dial ouvert/fermé |
| `activeModal` | `WritableSignal<ModalType \| null>` | `null` | Type d'action sélectionnée (null = fermé) |
| `modalOpen` | `Signal<boolean>` | computed: `activeModal() !== null` | Modal ouvert/fermé |
| `modalTitle` | `Signal<string>` | computed depuis `activeModal` | Titre du modal selon le type |

### Mapping activeModal → titre

| `activeModal` | `modalTitle` |
|---------------|-------------|
| `'transaction'` | `'Nouvelle transaction'` |
| `'subscription'` | `'Nouvel abonnement'` |
| `'debt'` | `'Nouvelle dette'` |
| `null` | `''` |

## Flux d'état

```
[Initial]
  speedDialOpen=false, activeModal=null
  → FAB visible (+)

[Clic FAB]
  speedDialOpen=true
  → FAB animé (×), overlay visible, items apparaissent

[Clic item "Transaction"]
  speedDialOpen=false, activeModal='transaction'
  → Speed dial fermé, FAB masqué, modal "Nouvelle transaction" affiché

[Fermeture modal]
  activeModal=null
  → Modal fermé, FAB visible (+)

[Clic overlay/Echap pendant speed dial]
  speedDialOpen=false
  → Speed dial fermé, FAB visible (+)

[Navigation (route change)]
  speedDialOpen=false, activeModal=null
  → Tout fermé, FAB visible (+)
```

## Design Tokens (ajouts)

### Primitives (`_primitives.scss`)

```scss
$z-fab: 250;
```

### Tokens (`_tokens.scss`)

```scss
--z-fab: #{p.$z-fab};
```

Insertion : entre `--z-sticky` (200) et `--z-overlay` (300).
