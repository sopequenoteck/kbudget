import { Routes } from '@angular/router';
import { Settings } from './settings';

export const SETTINGS_ROUTES: Routes = [
  { path: '', component: Settings },
  {
    path: 'accounts',
    loadComponent: () => import('./components/accounts/accounts').then((m) => m.Accounts),
  },
  {
    path: 'categories',
    loadComponent: () => import('./components/categories/categories').then((m) => m.Categories),
  },
  {
    path: 'import',
    loadComponent: () =>
      import('./components/import-settings/import-settings').then((m) => m.ImportSettings),
  },
  {
    path: 'import/review/:draftId',
    loadComponent: () =>
      import('./components/import-review/import-review').then((m) => m.ImportReview),
  },
  {
    path: 'import/mapping',
    loadComponent: () =>
      import('./components/csv-mapping/csv-mapping').then((m) => m.CsvMapping),
  },
  {
    path: 'users',
    loadComponent: () => import('./pages/users/users').then((m) => m.Users),
  },
];
