# Quickstart: 067-angular-responsive-nav

**Date**: 2026-03-01

## Prerequis

- Node.js installe
- Dependances installees (`cd app && npm install`)
- Backend API en cours d'execution (pour les preferences)

## Lancer en dev

```bash
cd app && ng serve
```

Ouvrir `http://localhost:4200` et utiliser les DevTools Chrome pour simuler un ecran mobile (< 768px).

## Tester le responsive

1. Ouvrir DevTools (F12)
2. Activer le mode responsive (Ctrl+Shift+M)
3. Selectionner un device mobile (ex: iPhone 14, Pixel 7)
4. Verifier : bottom nav visible, sidebar masquee, hamburger supprime
5. Basculer en desktop (> 768px) : sidebar visible, bottom nav masquee

## Fichiers cles

| Fichier | Role |
|---------|------|
| `app/src/app/shared/components/bottom-nav/bottom-nav.ts` | Composant bottom nav |
| `app/src/app/shared/components/shell/shell.html` | Integration dans le layout |
| `app/src/app/shared/components/shell/shell.scss` | Responsive CSS |
| `app/src/app/shared/components/fab/fab.scss` | Repositionnement FAB mobile |

## Build

```bash
cd app && ng build
```

## Tests

```bash
cd app && ng test
```
