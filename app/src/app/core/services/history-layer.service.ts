import {
  DOCUMENT,
  DestroyRef,
  Injectable,
  Signal,
  WritableSignal,
  computed,
  effect,
  inject,
  signal,
  untracked,
} from '@angular/core';
import { Router } from '@angular/router';

/** Marque l'etat d'historique pose par une couche (jamais d'URL, jamais de route). */
const LAYER_STATE_KEY = 'kbudgetHistoryLayer';

interface Layer {
  readonly onBack: () => void;
  readonly isBlocked: (() => boolean) | undefined;
  /** Vrai tant que la couche possede une entree d'historique sous le geste de retour. */
  bound: boolean;
}

/**
 * Couches d'historique (KKS-447) : le geste de retour (Android, bouton precedent) ferme la surface
 * ouverte au lieu de quitter la page.
 *
 * Chaque surface ouverte (feuille, dialogue, panneau, section depliee) enregistre une couche :
 * une entree `pushState` sans changement d'URL. UN SEUL ecouteur `popstate` ferme la couche du
 * dessus ; les autres restent ouvertes.
 *
 * Fermer une surface autrement (voile, Echap, bouton, validation) libere sa couche : l'entree est
 * retiree par `history.go(-n)` (une seule fois pour un lot de liberations), et le `popstate` qui en
 * resulte est ignore.
 *
 * Une navigation de route ne doit JAMAIS etre annulee par ce retrait : si la navigation est en
 * cours, ou si l'entree du dessus n'est plus la notre (le routeur a pousse ou remplace la sienne),
 * les entrees sont abandonnees sans retour en arriere. Residu : une entree morte reste sous
 * l'historique, un retour « a vide » (meme URL, rien de visible) est alors possible. Meme residu
 * apres un rechargement de la page avec une surface ouverte.
 */
@Injectable({ providedIn: 'root' })
export class HistoryLayerService {
  private readonly win = inject(DOCUMENT).defaultView;
  private readonly router = inject(Router);

  private readonly layers = new Map<number, Layer>();
  private nextId = 1;
  /** Entrees d'historique posees par le service et encore sous le geste de retour. */
  private entries = 0;
  /** `popstate` provoques par nos propres `history.go`, a ne pas traiter comme un retour. */
  private ignoredPops = 0;
  private reconcilePending = false;

  private readonly onPopState = (): void => {
    if (this.ignoredPops > 0) {
      this.ignoredPops -= 1;
      return;
    }
    if (this.entries === 0) return;
    this.entries -= 1;
    const top = this.topBoundLayer();
    if (!top) return;
    const [id, layer] = top;
    if (layer.isBlocked?.()) {
      // La surface refuse de se fermer (ex. envoi en cours) : l'entree est reposee.
      this.pushEntry();
      return;
    }
    this.layers.delete(id);
    layer.onBack();
  };

  constructor() {
    this.win?.addEventListener('popstate', this.onPopState);
    inject(DestroyRef).onDestroy(() => this.win?.removeEventListener('popstate', this.onPopState));
  }

  /**
   * Enregistre une couche et pose une entree d'historique. `onBack` ferme la surface ;
   * `isBlocked` la protege tant qu'elle ne peut pas se fermer (le retour est alors absorbe).
   * Renvoie l'identifiant opaque de la couche, a passer a `release`.
   */
  push(onBack: () => void, isBlocked?: () => boolean): number {
    const id = this.nextId++;
    this.layers.set(id, { onBack, isBlocked, bound: this.pushEntry() });
    return id;
  }

  /** La surface s'est fermee d'elle-meme : retire sa couche et son entree d'historique. */
  release(handle: number): void {
    if (!this.layers.delete(handle)) return;
    if (this.reconcilePending) return;
    this.reconcilePending = true;
    queueMicrotask(() => this.reconcile());
  }

  /** Faux apres un retour qui a ferme la couche, ou apres sa liberation. */
  isActive(handle: number | null): boolean {
    return handle !== null && this.layers.has(handle);
  }

  private pushEntry(): boolean {
    if (!this.win) return false;
    this.win.history.pushState({ [LAYER_STATE_KEY]: true }, '');
    this.entries += 1;
    return true;
  }

  private topBoundLayer(): [number, Layer] | null {
    let top: [number, Layer] | null = null;
    for (const entry of this.layers) {
      if (entry[1].bound) top = entry;
    }
    return top;
  }

  private boundCount(): number {
    let count = 0;
    for (const layer of this.layers.values()) {
      if (layer.bound) count += 1;
    }
    return count;
  }

  /** Aligne les entrees posees sur les couches encore ouvertes (en un seul `history.go`). */
  private reconcile(): void {
    this.reconcilePending = false;
    const excess = this.entries - this.boundCount();
    if (excess <= 0) return;
    if (!this.canTraverse()) {
      this.abandon();
      return;
    }
    this.entries -= excess;
    this.ignoredPops += 1;
    this.win?.history.go(-excess);
  }

  /** Reculer n'est sur que si l'entree courante est la notre et qu'aucune navigation n'est en cours. */
  private canTraverse(): boolean {
    const state = this.win?.history.state as Record<string, unknown> | null | undefined;
    return state?.[LAYER_STATE_KEY] === true && this.router.currentNavigation() === null;
  }

  /** Les entrees restent dans l'historique, le service n'en reclame plus aucune. */
  private abandon(): void {
    this.entries = 0;
    for (const layer of this.layers.values()) {
      layer.bound = false;
    }
  }
}

/**
 * Lie une surface a une couche d'historique : la couche existe tant que `isOpen` est vrai (a defaut,
 * tant que le proprietaire existe). A appeler dans un contexte d'injection (constructeur).
 */
export function bindHistoryLayer(
  onBack: () => void,
  isOpen?: Signal<boolean>,
  isBlocked?: () => boolean,
): void {
  const service = inject(HistoryLayerService);
  const open = isOpen ?? signal(true);
  let handle: number | null = null;

  const releaseHandle = (): void => {
    if (handle !== null) service.release(handle);
    handle = null;
  };

  effect(() => {
    const shouldBeOpen = open();
    untracked(() => {
      if (!shouldBeOpen) {
        releaseHandle();
      } else if (!service.isActive(handle)) {
        handle = service.push(onBack, isBlocked);
      }
    });
  });
  inject(DestroyRef).onDestroy(releaseHandle);
}

/** Section depliee d'une feuille : le retour la replie (saisie intacte) avant de fermer la feuille. */
export function bindExpandedSectionLayer<T>(section: WritableSignal<T | null>): void {
  bindHistoryLayer(
    () => section.set(null),
    computed(() => section() !== null),
  );
}
