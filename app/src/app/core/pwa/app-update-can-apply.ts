import { Provider, inject } from '@angular/core';
import { Router } from '@angular/router';

import { isTaskFlowRoute } from '../../shared/utils/task-flow-route.utils';
import { APP_UPDATE_CAN_APPLY } from './app-update';

/**
 * Critere propre a K·Budget pour `AppUpdateService` (copie k-design, KKS-619) : une version n'est
 * jamais appliquee sur un parcours de tache (`isTaskFlowRoute`), ou un rechargement perdrait la
 * saisie. Le service controle lui-meme les surfaces modales. La route est lue a chaque
 * application, jamais une fois pour toutes.
 */
export function provideAppUpdateCanApply(): Provider {
  return {
    provide: APP_UPDATE_CAN_APPLY,
    useFactory: () => {
      const router = inject(Router);
      return () => !isTaskFlowRoute(router.url);
    },
  };
}
