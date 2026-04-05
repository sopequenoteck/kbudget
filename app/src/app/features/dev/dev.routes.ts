import { Routes } from '@angular/router';

export const DEV_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./design-lab').then((m) => m.DesignLab),
  },
];
