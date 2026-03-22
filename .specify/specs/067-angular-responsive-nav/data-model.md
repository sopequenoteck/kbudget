# Data Model: 067-angular-responsive-nav

**Date**: 2026-03-01

## Entites impactees

Aucune nouvelle entite. Aucune modification de modele de donnees.

Cette feature est un changement purement presentationnel (CSS + composant Angular). Elle reutilise les structures existantes :

### Structures reutilisees (pas de modification)

| Structure | Fichier | Utilisation |
|-----------|---------|-------------|
| `Feature` (type) | `preference.model.ts` | Typage des features optionnelles |
| `FeatureMetadata` (interface) | `preference.model.ts` | Metadata navigation (label, icon, route) |
| `FEATURES` (const) | `preference.model.ts` | Liste des features avec metadata |
| `UserPreference` (interface) | `preference.model.ts` | Preferences utilisateur (enabledFeatures, navOrder) |

### Nouveau type (interface composant)

```typescript
// Input du composant BottomNav — reutilise le meme format que navItems du shell
interface NavItem {
  label: string;
  route: string;
  icon: string;
}
```

Ce type existe deja implicitement dans le shell (structure du `computed navItems`). Le composant `BottomNav` l'utilisera tel quel via `input<NavItem[]>()`.

## Flux de donnees

```
PreferenceService.enabledFeatures() + .navOrder()
       ↓
Shell.navItems (computed signal)
       ↓
  ┌────┴────┐
  │         │
Sidebar   BottomNav
(desktop)  (mobile)
```

Les deux composants de navigation (sidebar et bottom nav) consomment la meme source de donnees (`navItems`). Pas de duplication de logique.
