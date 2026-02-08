import { Routes } from '@angular/router';

import { authGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'dashboard',
    pathMatch: 'full',
  },
  {
    path: 'auth',
    loadChildren: () => import('./features/auth/auth.routes').then((m) => m.AUTH_ROUTES),
  },
  {
    path: 'dashboard',
    canActivate: [authGuard],
    loadChildren: () =>
      import('./features/dashboard/dashboard.routes').then((m) => m.DASHBOARD_ROUTES),
  },
  {
    path: 'transactions',
    canActivate: [authGuard],
    loadChildren: () =>
      import('./features/transactions/transactions.routes').then((m) => m.TRANSACTIONS_ROUTES),
  },
  {
    path: 'subscriptions',
    canActivate: [authGuard],
    loadChildren: () =>
      import('./features/subscriptions/subscriptions.routes').then((m) => m.SUBSCRIPTIONS_ROUTES),
  },
  {
    path: 'debts',
    canActivate: [authGuard],
    loadChildren: () => import('./features/debts/debts.routes').then((m) => m.DEBTS_ROUTES),
  },
  {
    path: '**',
    canActivate: [authGuard],
    redirectTo: 'dashboard',
  },
];
