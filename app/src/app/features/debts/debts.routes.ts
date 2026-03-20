import { Routes } from '@angular/router';
import { Debts } from './debts';

export const DEBTS_ROUTES: Routes = [
  { path: '', component: Debts },
  {
    path: ':id',
    loadComponent: () =>
      import('./components/debt-detail/debt-detail').then((m) => m.DebtDetail),
  },
];
