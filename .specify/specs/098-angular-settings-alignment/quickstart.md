# Quickstart: Alignement Settings Angular sur Flutter

## Prerequis

- Node.js installe
- `cd app && npm install`

## Lancer en dev

```bash
cd app && ng serve
```

Ouvrir http://localhost:4200/settings

## Tester

```bash
cd app && npm run test
```

## Fichiers a modifier

| Fichier | Modification |
|---------|-------------|
| `app/src/app/features/settings/settings.ts` | Ajouter groupes, couleurs, reordonnement, nouveaux imports icones |
| `app/src/app/features/settings/settings.html` | Template avec headers de groupe et couleurs d'icones |
| `app/src/app/features/settings/settings.scss` | Styles pour headers de groupe et couleurs d'icones individuelles |
| `app/src/app/features/settings/settings.routes.ts` | Retirer route budget, ajouter route security |
| `app/src/app/features/settings/components/about/about.ts` | Injecter HealthService + services CRUD, signals |
| `app/src/app/features/settings/components/about/about.html` | 3 cards (Application, Mes donnees, Contact) |
| `app/src/app/features/settings/components/about/about.scss` | Refonte styles pour les 3 cards |

## Verification

1. `/settings` — 3 groupes visibles avec headers, couleurs d'icones variees
2. `/settings` — Budget absent, Securite present (placeholder)
3. `/settings/about` — 3 cards, statut serveur, 4 compteurs, contact
4. Dark mode — coherence visuelle
5. Tests passent : `cd app && npm run test`
