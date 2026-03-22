# Quickstart: 074-angular-budget-categories

## Prérequis

1. Backend en cours d'exécution avec profil dev (KKS-073 mergé)
2. Node.js installé
3. Branche `074-angular-budget-categories` checkoutée

## Installation

```bash
cd app
npm install ng2-charts chart.js
```

## Démarrage

```bash
cd app && ng serve
# → http://localhost:4200
```

## Vérification

1. Activer la feature BUDGETS dans Settings > Fonctionnalités
2. Naviguer vers /budgets
3. Créer un budget via le bouton (+) ou "Nouveau budget"
4. Vérifier la section Budgets sur le dashboard

## Fichiers clés à créer

| Fichier | Rôle |
|---------|------|
| `core/models/budget.model.ts` | Interfaces TypeScript |
| `core/services/budget.ts` | Service HTTP signal-based |
| `features/budgets/budgets.routes.ts` | Routes lazy-loaded |
| `features/budgets/budget-list/budget-list.ts` | Écran principal |
| `features/budgets/budget-detail/budget-detail.ts` | Vue détaillée Doughnut |
| `features/budgets/components/budget-form/budget-form.ts` | Formulaire modale |
| `features/dashboard/components/budget-summary/budget-summary.ts` | Section dashboard |

## Fichiers à modifier

| Fichier | Modification |
|---------|-------------|
| `core/models/preference.model.ts` | Ajouter `'BUDGETS'` au type Feature + FEATURES array |
| `core/services/modal.service.ts` | Ajouter `'budget'` au ModalType |
| `shared/components/shell/shell.ts` | Ajouter case 'budget' + handler |
| `app.routes.ts` | Ajouter route /budgets avec featureGuard |
| `features/dashboard/dashboard.ts` | Intégrer `BudgetSummary` component |

## Tests

```bash
cd app && ng test
```
