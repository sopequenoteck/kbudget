import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { PreferenceService } from '../services/preference';
import { type Feature } from '../models/preference.model';

export const featureGuard: CanActivateFn = (route) => {
  const preferenceService = inject(PreferenceService);
  const router = inject(Router);

  const feature = route.data['feature'] as Feature | undefined;
  if (!feature) {
    return true;
  }

  // Race condition: if preferences not yet loaded, allow navigation
  // The shell effect will handle redirect once data is loaded
  if (!preferenceService.isLoaded()) {
    return true;
  }

  if (preferenceService.isEnabled(feature)) {
    return true;
  }

  return router.createUrlTree(['/dashboard']);
};
