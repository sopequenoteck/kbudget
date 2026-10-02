import { Routes } from '@angular/router';

/** Parcours d'import, monte sous `/transactions/import` (KKS-386). */
export const IMPORTS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./import-start/import-start').then((m) => m.ImportStart),
  },
  {
    path: 'review/:draftId',
    loadComponent: () => import('./import-review/import-review').then((m) => m.ImportReview),
  },
];
