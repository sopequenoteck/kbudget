import { Routes } from '@angular/router';
import { Settings } from './settings';

export const SETTINGS_ROUTES: Routes = [
  { path: '', component: Settings },
  {
    path: 'account',
    loadComponent: () =>
      import('./account/mon-compte.component').then((m) => m.MonCompteComponent),
  },
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
    // Ancienne revue (avant KKS-386) : les liens et favoris existants suivent.
    path: 'import/review/:draftId',
    redirectTo: '/transactions/import/review/:draftId',
  },
  {
    path: 'import/mapping',
    loadComponent: () =>
      import('./components/csv-mapping/csv-mapping').then((m) => m.CsvMapping),
  },
  {
    path: 'import/history-cleanup',
    loadComponent: () =>
      import('../imports/history-cleanup/history-cleanup').then((m) => m.HistoryCleanup),
  },
  {
    path: 'users',
    loadComponent: () => import('./pages/users/users').then((m) => m.Users),
  },
];
