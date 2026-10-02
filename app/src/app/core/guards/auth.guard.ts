import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AuthService } from '../services/auth';
import { isInternalReturnUrl } from '../../shared/utils/return-url.utils';

export const authGuard: CanActivateFn = (_route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  const url = state.url;

  if (isInternalReturnUrl(url)) {
    return router.createUrlTree(['/auth'], { queryParams: { returnUrl: url } });
  }

  return router.createUrlTree(['/auth']);
};
