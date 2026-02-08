import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AuthService } from '../services/auth';

export const authGuard: CanActivateFn = (_route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  const url = state.url;
  const isInternalUrl = url.startsWith('/') && !url.startsWith('//') && !url.startsWith('/\\');
  const isNotAbsolute = !url.match(/^https?:/i);

  if (isInternalUrl && isNotAbsolute) {
    return router.createUrlTree(['/auth'], { queryParams: { returnUrl: url } });
  }

  return router.createUrlTree(['/auth']);
};
