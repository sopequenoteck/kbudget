import { Routes } from '@angular/router';

export const BUDGETS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./components/budget-list/budget-list').then((m) => m.BudgetList),
  },
  {
    path: 'details',
    loadComponent: () => import('./components/budget-detail/budget-detail').then((m) => m.BudgetDetail),
  },
];
