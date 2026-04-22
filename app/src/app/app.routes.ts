import { Routes } from '@angular/router';

import { authGuard } from './core/guards/auth.guard';
import { featureGuard } from './core/guards/feature.guard';
import { notPasswordResetGuard } from './core/guards/not-password-reset.guard';
import { passwordResetGuard } from './core/guards/password-reset.guard';
import { Shell } from './shared/components/shell/shell';

export const routes: Routes = [
  {
    path: 'auth',
    loadChildren: () => import('./features/auth/auth.routes').then((m) => m.AUTH_ROUTES),
  },
  {
    path: 'first-login-reset',
    canActivate: [authGuard, notPasswordResetGuard],
    loadComponent: () =>
      import('./features/auth/first-login-reset/first-login-reset.component').then(
        (m) => m.FirstLoginResetComponent,
      ),
  },
  {
    path: '',
    component: Shell,
    canActivate: [authGuard, passwordResetGuard],
    children: [
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full',
      },
      {
        path: 'dashboard',
        data: { animation: 'Dashboard' },
        loadChildren: () =>
          import('./features/dashboard/dashboard.routes').then((m) => m.DASHBOARD_ROUTES),
      },
      {
        path: 'transactions',
        data: { animation: 'Transactions' },
        loadChildren: () =>
          import('./features/transactions/transactions.routes').then((m) => m.TRANSACTIONS_ROUTES),
      },
      {
        path: 'subscriptions',
        canActivate: [featureGuard],
        data: { feature: 'SUBSCRIPTIONS', animation: 'Subscriptions' },
        loadChildren: () =>
          import('./features/subscriptions/subscriptions.routes').then(
            (m) => m.SUBSCRIPTIONS_ROUTES,
          ),
      },
      {
        path: 'debts',
        canActivate: [featureGuard],
        data: { feature: 'DEBTS', animation: 'Debts' },
        loadChildren: () => import('./features/debts/debts.routes').then((m) => m.DEBTS_ROUTES),
      },
      {
        path: 'budgets',
        canActivate: [featureGuard],
        data: { feature: 'BUDGETS', animation: 'Budgets' },
        loadChildren: () =>
          import('./features/budgets/budgets.routes').then((m) => m.BUDGETS_ROUTES),
      },
      {
        path: 'settings',
        data: { animation: 'Settings' },
        loadChildren: () =>
          import('./features/settings/settings.routes').then((m) => m.SETTINGS_ROUTES),
      },
    ],
  },
  {
    path: 'dev/design-lab',
    loadChildren: () => import('./features/dev/dev.routes').then((m) => m.DEV_ROUTES),
  },
  {
    path: '**',
    redirectTo: 'dashboard',
  },
];
