import { DOCUMENT, Injectable, Injector, effect, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { Router } from '@angular/router';
import { SwUpdate } from '@angular/service-worker';
import { filter, scan } from 'rxjs';

import { isTaskFlowRoute } from '../../shared/utils/task-flow-route.utils';

/** Au-dela de ce delai apres le lancement ou le retour au premier plan, l'usage a pu commencer. */
export const UPDATE_APPLY_WINDOW_MS = 3000;

/**
 * Toute surface modale ouverte : `modal`, `confirm-dialog` (`alertdialog`), `select-picker`
 * (feuille mobile), `snooze-dialog` et les dialogues de `settings/account` portent l'un de ces
 * roles ; `notification-panel`, un `<aside>`, porte `data-modal-surface`. Toutes ne sont dans le
 * DOM qu'ouvertes. Une nouvelle surface modale doit porter l'un de ces marqueurs, sans quoi une
 * mise a jour pourrait recharger la page sous elle.
 */
const MODAL_SURFACE_SELECTOR = '[role="dialog"], [role="alertdialog"], [data-modal-surface]';

/**
 * Politique de mise a jour de la PWA (KKS-446).
 *
 * Recherche a DEUX moments : au lancement, et au passage de la page a l'etat visible. Une version
 * trouvee est appliquee par activation PUIS rechargement, seulement si la recherche aboutit dans
 * la fenetre `UPDATE_APPLY_WINDOW_MS` ; sinon elle est retenue pour le retour au premier plan
 * suivant. Une activation en place, sans rechargement, est deconseillee par Angular pour une
 * application a chargement differe : les fichiers differes changent de nom.
 *
 * Une version n'est jamais appliquee sur un parcours de tache (`isTaskFlowRoute`) ni sous une
 * surface modale ouverte : le rechargement y perdrait la saisie. Elle reste retenue.
 * `VERSION_READY` recu pendant l'usage est retenu, jamais applique sur-le-champ.
 *
 * Aucune interface n'est ajoutee : ni bandeau, ni bouton.
 */
@Injectable({ providedIn: 'root' })
export class AppUpdateService {
  private readonly swUpdate = inject(SwUpdate);
  private readonly document = inject(DOCUMENT);
  private readonly router = inject(Router);
  private readonly injector = inject(Injector);

  private started = false;
  private applying = false;

  /** Version trouvee par une recherche, en attente d'un moment propice. */
  private retained = false;
  /** Nombre de `VERSION_READY` deja traites par une application. */
  private consumedReadyEvents = 0;
  private readyEvents: () => number = () => 0;

  start(): void {
    // Aucun abonnement, aucun appel quand le service worker est inactif (developpement, tests,
    // build hors production) : `SwUpdate` ne doit pas etre approche.
    if (this.started || !this.swUpdate.isEnabled) {
      return;
    }
    this.started = true;

    // Compteur d'evenements plutot qu'un booleen : un `VERSION_READY` recu apres une application
    // echouee doit rester detectable.
    this.readyEvents = toSignal(
      this.swUpdate.versionUpdates.pipe(
        filter((event) => event.type === 'VERSION_READY'),
        scan((count) => count + 1, 0),
      ),
      { initialValue: 0, injector: this.injector },
    );

    // `unrecoverable` recharge a tout moment : l'etat est irrattrapable, attendre ne l'ameliore pas.
    const unrecoverable = toSignal(this.swUpdate.unrecoverable, { injector: this.injector });
    effect(
      () => {
        if (unrecoverable()) {
          this.reload();
        }
      },
      { injector: this.injector },
    );

    this.checkAndApply();

    this.document.addEventListener('visibilitychange', () => {
      if (this.document.visibilityState === 'visible') {
        this.checkAndApply();
      }
    });
  }

  /**
   * « Reessayer » de l'ecran d'incompatibilite : cherche et active une version plus recente quand
   * le service worker est actif, puis recharge dans tous les cas. Un simple rechargement relirait
   * la version en cache, celle-la meme qui est incompatible. Un echec (hors ligne, rien a activer)
   * est absorbe : le rechargement reste le geste attendu.
   */
  async refreshAndReload(): Promise<void> {
    if (this.swUpdate.isEnabled) {
      const found = await this.swUpdate.checkForUpdate().catch(() => false);
      if (found || this.hasPendingVersion()) {
        await this.swUpdate.activateUpdate().catch(() => false);
      }
    }
    this.reload();
  }

  private async checkAndApply(): Promise<void> {
    if (this.hasPendingVersion()) {
      await this.apply();
      return;
    }

    // Fenetre d'application : une recherche qui aboutit APRES ce delai arrive alors que l'usage a
    // pu commencer. La version est alors seulement retenue.
    const startedAt = Date.now();
    // Demarrage hors ligne : le rejet est absorbe, aucune erreur non geree.
    const found = await this.swUpdate.checkForUpdate().catch(() => null);
    if (found === null || (!found && !this.hasPendingVersion())) {
      return;
    }
    if (Date.now() - startedAt <= UPDATE_APPLY_WINDOW_MS) {
      await this.apply();
    } else {
      this.retained = true;
    }
  }

  /**
   * Active la version prete PUIS recharge. Une activation qui echoue ou ne trouve rien a activer
   * ne recharge pas : sans ce garde-fou, une version trouvee mais inactivable ferait recharger la
   * page a chaque retour au premier plan.
   */
  private async apply(): Promise<void> {
    if (this.applying) {
      return;
    }
    if (!this.canApplyNow()) {
      this.retained = true;
      return;
    }

    this.applying = true;
    this.retained = false;
    this.consumedReadyEvents = this.readyEvents();
    // Activation impossible (hors ligne) : le rejet est absorbe, la page courante reste utilisable.
    const activated = await this.swUpdate.activateUpdate().catch(() => false);
    this.applying = false;
    if (activated) {
      this.reload();
    }
  }

  private hasPendingVersion(): boolean {
    return this.retained || this.readyEvents() > this.consumedReadyEvents;
  }

  private canApplyNow(): boolean {
    return (
      !isTaskFlowRoute(this.router.url) &&
      this.document.querySelector(MODAL_SURFACE_SELECTOR) === null
    );
  }

  private reload(): void {
    this.document.defaultView?.location.reload();
  }
}
