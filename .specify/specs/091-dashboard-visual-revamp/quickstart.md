# Quickstart: Dashboard Visual Revamp

**Branch**: `091-dashboard-visual-revamp`

## Prérequis

- Node.js 18+
- Angular CLI (`ng`)

## Lancer le dev server

```bash
cd app && ng serve
```

Ouvrir `http://localhost:4200/dashboard` en dark mode (thème par défaut).

## Fichiers principaux à modifier

| Fichier | Type de changement |
|---------|-------------------|
| `app/src/app/features/dashboard/dashboard.scss` | SCSS — hero gradient, glassmorphism, transactions gap, page gradient, micro-interactions |
| `app/src/app/features/dashboard/dashboard.html` | HTML — badges variation (classes CSS), structure mineure |
| `app/src/app/features/dashboard/components/budget-summary/budget-summary.ts` | Inline styles — hauteur barres, animation apparition |
| `app/src/styles/themes/_dark.scss` | Tokens — nouveaux tokens glassmorphism dark |
| `app/src/styles/themes/_light.scss` | Tokens — variantes light mode (hero gradient, opaque cards) |

## Vérification rapide

1. Dashboard dark mode : hero card avec gradient visible ?
2. Cards Revenus/Dépenses : effet glassmorphism (flou visible) ?
3. Barres budget : coins arrondis, hauteur 10px, animation ?
4. Variations : badges colorés au lieu de texte inline ?
5. Transactions : gaps entre items, pas de border-bottom ?
6. Tap sur cards : effet scale(0.97) au touch ?
7. `prefers-reduced-motion` : aucune animation ?

## Tests existants

```bash
cd app && ng test
```

Aucun nouveau test requis — vérifier que les tests existants passent sans modification.
