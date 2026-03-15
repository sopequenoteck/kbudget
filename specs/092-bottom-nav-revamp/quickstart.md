# Quickstart: Bottom Nav Revamp

**Branch**: `092-bottom-nav-revamp`

## Lancer

```bash
cd app && npx ng serve
```

Ouvrir `http://localhost:4200` sur mobile (< 768px) ou en DevTools responsive.

## Vérification rapide

1. Bottom nav dark mode : effet glassmorphism visible (contenu flouté derrière) ?
2. Onglet actif : pill coloré derrière l'icône + icône fill ?
3. Changer d'onglet : transition fluide du pill ?
4. 6 onglets : labels non tronqués, police réduite ?
5. Light mode : fond opaque, bordure supérieure subtile ?
6. `prefers-reduced-motion` : pas de transition ?
7. Desktop (>= 768px) : bottom nav masqué (sidebar active) ?

## Tests

```bash
cd app && npx vitest run
```
