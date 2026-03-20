import { Routes } from '@angular/router';
import { Transactions } from './transactions';

export const TRANSACTIONS_ROUTES: Routes = [
  { path: '', component: Transactions },
  {
    path: 'recurring',
    loadComponent: () =>
      import('./components/recurring-list/recurring-list').then((m) => m.RecurringList),
  },
];
