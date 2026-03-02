import { Routes } from '@angular/router';

export const SHOP_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./shop-list/shop-list').then((m) => m.ShopList),
  },
  {
    path: ':id',
    loadComponent: () => import('./shop-detail/shop-detail').then((m) => m.ShopDetail),
  },
];
