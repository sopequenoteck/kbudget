import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { CompatibilityService } from '../services/compatibility';

/**
 * Detourne vers l'ecran d'incompatibilite quand le client et le serveur ne
 * peuvent pas fonctionner ensemble (KKS-314).
 *
 * <p>La verification n'a lieu qu'une fois par session : `status()` est deja
 * renseigne aux navigations suivantes. Rejouer l'appel a chaque route
 * ajouterait une latence sur chaque transition pour une information qui ne
 * change pas tant que la page n'est pas rechargee.
 *
 * <p>Un serveur injoignable laisse passer : hors ligne n'est pas une
 * incompatibilite, et le cache prend le relais (constitution, principe IV).
 */
export const compatibilityGuard: CanActivateFn = async () => {
  const compatibility = inject(CompatibilityService);
  const router = inject(Router);

  const status = compatibility.status() ?? (await compatibility.check());

  if (status.kind === 'compatible' || status.kind === 'offline') {
    return true;
  }

  return router.createUrlTree(['/incompatible']);
};
