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
    path: 'features',
    loadComponent: () => import('./components/features/features').then((m) => m.Features),
  },
  {
    path: 'appearance',
    loadComponent: () => import('./components/appearance/appearance').then((m) => m.Appearance),
  },
  {
    path: 'profile',
    loadComponent: () => import('./components/profile/profile').then((m) => m.Profile),
  },
  {
    path: 'about',
    loadComponent: () => import('./components/about/about').then((m) => m.About),
  },
  {
    path: 'budget',
    loadComponent: () => import('./components/placeholder/placeholder').then((m) => m.Placeholder),
    data: { title: 'Budget', icon: 'phosphorChartBar' },
  },
  {
    path: 'notifications',
    loadComponent: () => import('./components/placeholder/placeholder').then((m) => m.Placeholder),
    data: { title: 'Notifications', icon: 'phosphorBell' },
  },
  {
    path: 'data',
    loadComponent: () =>
      import('./components/data-settings/data-settings').then((m) => m.DataSettings),
  },
];
