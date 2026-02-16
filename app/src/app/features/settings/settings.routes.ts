import { Routes } from '@angular/router';
import { Settings } from './settings';

export const SETTINGS_ROUTES: Routes = [
  { path: '', component: Settings },
  {
    path: 'accounts',
    loadComponent: () =>
      import('./components/accounts/accounts').then((m) => m.Accounts),
  },
];
