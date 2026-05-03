import { Routes } from '@angular/router';
import { Auth } from './auth';

export const AUTH_ROUTES: Routes = [
  { path: '', component: Auth },
  {
    path: 'accept-invite/:token',
    loadComponent: () =>
      import('./pages/accept-invite/accept-invite').then((m) => m.AcceptInvite),
  },
];
