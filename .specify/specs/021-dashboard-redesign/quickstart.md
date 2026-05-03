# Quickstart: Dashboard Redesign

## Prérequis

- Node.js + npm installés
- Backend Spring Boot en cours d'exécution (`cd api && mvn spring-boot:run`)

## Lancer le dev server

```bash
cd app && ng serve
```

Ouvrir `http://localhost:4200/dashboard`.

## Fichiers modifiés

| Fichier | Changement |
|---------|------------|
| `app/src/app/features/dashboard/dashboard.html` | Restructuration template : zone KPI en haut, listes pures en bas |
| `app/src/app/features/dashboard/dashboard.scss` | Styles mini-cards, KPI zone, séparateur |
| `app/src/app/features/dashboard/dashboard.ts` | Import Router, méthodes navigation mini-cards |
| `app/src/styles/tokens/_primitives.scss` | Ajout couleur subscription (bleu) |
| `app/src/styles/themes/_light.scss` | Ajout `--color-subscription` light |
| `app/src/styles/themes/_dark.scss` | Ajout `--color-subscription` dark |

## Vérification

1. Dashboard affiche 6 KPI en haut (2 rangées)
2. Mini-cards cliquables (navigation vers /subscriptions, /debts)
3. Sections listes sans résumé texte
4. Dettes avec montant positif + label "Emprunt"/"Prêt"
5. Tester en thème clair et sombre
6. Vérifier sur viewport 375px (pas de débordement)
