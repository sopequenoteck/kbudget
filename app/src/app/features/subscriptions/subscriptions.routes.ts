import { Routes } from '@angular/router';
import { Subscriptions } from './subscriptions';

export const SUBSCRIPTIONS_ROUTES: Routes = [
  { path: '', component: Subscriptions },
  {
    path: ':id',
    loadComponent: () =>
      import('./components/subscription-detail/subscription-detail').then(
        (m) => m.SubscriptionDetail,
      ),
  },
];
