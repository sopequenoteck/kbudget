import { Routes } from '@angular/router';

import { authGuard } from './core/guards/auth.guard';
import { featureGuard } from './core/guards/feature.guard';
import { Shell } from './shared/components/shell/shell';

export const routes: Routes = [
  {
    path: 'auth',
    loadChildren: () => import('./features/auth/auth.routes').then((m) => m.AUTH_ROUTES),
  },
  {
    path: '',
    component: Shell,
    canActivate: [authGuard],
    children: [
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full',
      },
      {
        path: 'dashboard',
        loadChildren: () =>
          import('./features/dashboard/dashboard.routes').then((m) => m.DASHBOARD_ROUTES),
      },
      {
        path: 'transactions',
        loadChildren: () =>
          import('./features/transactions/transactions.routes').then((m) => m.TRANSACTIONS_ROUTES),
      },
      {
        path: 'subscriptions',
        canActivate: [featureGuard],
        data: { feature: 'SUBSCRIPTIONS' },
        loadChildren: () =>
          import('./features/subscriptions/subscriptions.routes').then(
            (m) => m.SUBSCRIPTIONS_ROUTES,
          ),
      },
      {
        path: 'debts',
        canActivate: [featureGuard],
        data: { feature: 'DEBTS' },
        loadChildren: () => import('./features/debts/debts.routes').then((m) => m.DEBTS_ROUTES),
      },
      {
        path: 'shop',
        canActivate: [featureGuard],
        data: { feature: 'SHOP' },
        loadChildren: () => import('./features/shop/shop.routes').then((m) => m.SHOP_ROUTES),
      },
      {
        path: 'budgets',
        canActivate: [featureGuard],
        data: { feature: 'BUDGETS' },
        loadChildren: () =>
          import('./features/budgets/budgets.routes').then((m) => m.BUDGETS_ROUTES),
      },
      {
        path: 'settings',
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
