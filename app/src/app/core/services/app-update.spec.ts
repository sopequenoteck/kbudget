import { DOCUMENT } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { SwUpdate } from '@angular/service-worker';
import { Subject } from 'rxjs';

import { AppUpdateService, UPDATE_APPLY_WINDOW_MS } from './app-update';

/**
 * Document factice : ecouteurs et `reload` observables, `querySelector` delegue a un vrai DOM
 * (jsdom) pour que le selecteur de surface modale soit lui aussi evalue pour de bon.
 */
interface FakeDocument {
  visibilityState: string;
  surfaces: Document;
  addEventListener: (type: string, listener: () => void) => void;
  querySelector: (selector: string) => Element | null;
  defaultView: { location: { reload: () => void } };
  fire: (type: string) => void;
}

function fakeDocument(reload: () => void): FakeDocument {
  const listeners = new Map<string, (() => void)[]>();
  const surfaces = document.implementation.createHTMLDocument('surfaces');
  return {
    visibilityState: 'visible',
    surfaces,
    addEventListener: (type, listener) => {
      listeners.set(type, [...(listeners.get(type) ?? []), listener]);
    },
    querySelector: (selector) => surfaces.querySelector(selector),
    defaultView: { location: { reload } },
    fire: (type) => {
      for (const listener of listeners.get(type) ?? []) {
        listener();
      }
    },
  };
}

/** Promesse resolue a la main : maitrise l'instant ou une recherche ou une activation aboutit. */
function deferred<T>(): { promise: Promise<T>; resolve: (value: T) => void } {
  let resolve: (value: T) => void = () => undefined;
  const promise = new Promise<T>((r) => {
    resolve = r;
  });
  return { promise, resolve };
}

describe('AppUpdateService', () => {
  let reload: ReturnType<typeof vi.fn<() => void>>;
  let fakeDoc: FakeDocument;
  let router: { url: string };
  let versionUpdates: Subject<{ type: string }>;
  let unrecoverable: Subject<unknown>;
  let checkForUpdate: ReturnType<typeof vi.fn<() => Promise<boolean>>>;
  let activateUpdate: ReturnType<typeof vi.fn<() => Promise<boolean>>>;

  // Laisse s'ecouler les promesses en chaine (recherche, activation, rechargement).
  const flush = async (): Promise<void> => {
    for (let i = 0; i < 6; i++) {
      await Promise.resolve();
    }
  };

  const setup = (isEnabled: boolean): AppUpdateService => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      providers: [
        { provide: DOCUMENT, useValue: fakeDoc },
        { provide: Router, useValue: router },
        {
          provide: SwUpdate,
          useValue: { isEnabled, versionUpdates, unrecoverable, checkForUpdate, activateUpdate },
        },
      ],
    });
    return TestBed.inject(AppUpdateService);
  };

  /** Premiere recherche en suspens, avec une horloge que le test fait avancer. */
  const slowSearch = () => {
    let now = 1_000_000;
    vi.spyOn(Date, 'now').mockImplementation(() => now);
    const search = deferred<boolean>();
    checkForUpdate.mockReturnValueOnce(search.promise);
    return {
      resolve: search.resolve,
      elapse: (ms: number) => {
        now += ms;
      },
    };
  };

  const returnToForeground = async (): Promise<void> => {
    fakeDoc.visibilityState = 'visible';
    fakeDoc.fire('visibilitychange');
    await flush();
  };

  beforeEach(() => {
    reload = vi.fn<() => void>();
    fakeDoc = fakeDocument(reload);
    router = { url: '/dashboard' };
    versionUpdates = new Subject();
    unrecoverable = new Subject();
    checkForUpdate = vi.fn<() => Promise<boolean>>().mockResolvedValue(false);
    activateUpdate = vi.fn<() => Promise<boolean>>().mockResolvedValue(true);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    TestBed.resetTestingModule();
  });

  describe('start', () => {
    it('should_do_nothing_when_service_worker_is_disabled', () => {
      const service = setup(false);

      expect(() => service.start()).not.toThrow();

      expect(checkForUpdate).not.toHaveBeenCalled();
      expect(activateUpdate).not.toHaveBeenCalled();
      expect(versionUpdates.observed).toBe(false);
      expect(unrecoverable.observed).toBe(false);
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_check_for_update_when_started', async () => {
      setup(true).start();
      await flush();

      expect(checkForUpdate).toHaveBeenCalledTimes(1);
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_register_listeners_only_once_when_started_twice', async () => {
      const service = setup(true);
      service.start();
      service.start();
      await flush();

      expect(checkForUpdate).toHaveBeenCalledTimes(1);
    });

    it('should_check_for_update_when_page_becomes_visible', async () => {
      setup(true).start();
      await flush();

      await returnToForeground();

      expect(checkForUpdate).toHaveBeenCalledTimes(2);
    });

    it('should_not_check_for_update_when_page_becomes_hidden', async () => {
      setup(true).start();
      await flush();

      fakeDoc.visibilityState = 'hidden';
      fakeDoc.fire('visibilitychange');
      await flush();

      expect(checkForUpdate).toHaveBeenCalledTimes(1);
    });
  });

  describe('application dans la fenetre', () => {
    it('should_activate_then_reload_when_update_is_found_within_window', async () => {
      checkForUpdate.mockResolvedValue(true);

      setup(true).start();
      await flush();

      expect(activateUpdate).toHaveBeenCalledTimes(1);
      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_apply_when_update_is_found_exactly_at_the_end_of_the_window', async () => {
      const search = slowSearch();

      setup(true).start();
      search.elapse(UPDATE_APPLY_WINDOW_MS);
      search.resolve(true);
      await flush();

      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_retain_update_when_found_after_window_then_apply_on_next_return', async () => {
      const search = slowSearch();

      setup(true).start();
      search.elapse(UPDATE_APPLY_WINDOW_MS + 1);
      search.resolve(true);
      await flush();
      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).not.toHaveBeenCalled();

      await returnToForeground();

      expect(activateUpdate).toHaveBeenCalledTimes(1);
      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_not_reload_when_activation_returns_false', async () => {
      checkForUpdate.mockResolvedValue(true);
      activateUpdate.mockResolvedValue(false);

      setup(true).start();
      await flush();

      expect(activateUpdate).toHaveBeenCalledTimes(1);
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_not_reload_and_not_throw_when_activation_rejects', async () => {
      checkForUpdate.mockResolvedValue(true);
      activateUpdate.mockRejectedValue(new Error('offline'));

      setup(true).start();
      await flush();

      expect(reload).not.toHaveBeenCalled();
    });

    it('should_not_activate_twice_when_returns_to_foreground_during_activation', async () => {
      checkForUpdate.mockResolvedValue(true);
      const activation = deferred<boolean>();
      activateUpdate.mockReturnValue(activation.promise);

      setup(true).start();
      await flush();
      await returnToForeground();
      activation.resolve(true);
      await flush();

      expect(activateUpdate).toHaveBeenCalledTimes(1);
      expect(reload).toHaveBeenCalledTimes(1);
    });
  });

  describe('VERSION_READY', () => {
    it('should_never_reload_when_version_ready_is_received_during_use', async () => {
      setup(true).start();
      await flush();

      versionUpdates.next({ type: 'VERSION_READY' });
      await flush();

      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_apply_retained_version_without_new_search_when_returning_to_foreground', async () => {
      setup(true).start();
      await flush();
      versionUpdates.next({ type: 'VERSION_READY' });

      await returnToForeground();

      expect(checkForUpdate).toHaveBeenCalledTimes(1);
      expect(activateUpdate).toHaveBeenCalledTimes(1);
      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_ignore_other_version_events_when_deciding_to_apply', async () => {
      setup(true).start();
      await flush();
      versionUpdates.next({ type: 'VERSION_DETECTED' });
      versionUpdates.next({ type: 'VERSION_INSTALLATION_FAILED' });

      await returnToForeground();

      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_not_reapply_a_version_already_applied_when_returning_again', async () => {
      activateUpdate.mockResolvedValue(false);
      setup(true).start();
      await flush();
      versionUpdates.next({ type: 'VERSION_READY' });
      await returnToForeground();
      expect(activateUpdate).toHaveBeenCalledTimes(1);

      await returnToForeground();

      expect(activateUpdate).toHaveBeenCalledTimes(1);
    });
  });

  describe('exceptions : parcours de tache et surface modale', () => {
    it.each([
      '/settings',
      '/settings/account',
      '/transactions/import',
      '/transactions/import/review/d1',
    ])('should_retain_update_when_current_route_is_task_flow_%s', async (url) => {
      router.url = url;
      checkForUpdate.mockResolvedValue(true);

      setup(true).start();
      await flush();

      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_apply_retained_update_when_leaving_the_task_flow_and_returning_to_foreground', async () => {
      router.url = '/transactions/import';
      checkForUpdate.mockResolvedValue(true);
      setup(true).start();
      await flush();

      router.url = '/transactions';
      await returnToForeground();

      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_apply_when_route_only_resembles_a_task_flow', async () => {
      router.url = '/transactions/recurring';
      checkForUpdate.mockResolvedValue(true);

      setup(true).start();
      await flush();

      expect(reload).toHaveBeenCalledTimes(1);
    });

    it.each([
      { name: 'dialog', html: '<div role="dialog"></div>' },
      { name: 'alertdialog', html: '<div role="alertdialog"></div>' },
      {
        name: 'nested dialog',
        html: '<div><section><aside role="dialog" aria-modal="true"></aside></section></div>',
      },
      { name: 'marked', html: '<aside data-modal-surface></aside>' },
    ])('should_retain_update_when_a_$name_surface_is_open', async ({ html }) => {
      fakeDoc.surfaces.body.innerHTML = html;
      checkForUpdate.mockResolvedValue(true);

      setup(true).start();
      await flush();

      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_retain_a_version_ready_event_when_a_surface_is_open_on_return', async () => {
      setup(true).start();
      await flush();
      versionUpdates.next({ type: 'VERSION_READY' });
      fakeDoc.surfaces.body.innerHTML = '<div role="dialog"></div>';

      await returnToForeground();

      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_apply_on_next_return_when_the_surface_has_been_closed', async () => {
      fakeDoc.surfaces.body.innerHTML = '<div role="dialog"></div>';
      checkForUpdate.mockResolvedValue(true);
      setup(true).start();
      await flush();

      fakeDoc.surfaces.body.innerHTML = '';
      await returnToForeground();

      expect(reload).toHaveBeenCalledTimes(1);
    });

    it.each([
      { name: 'a menu', html: '<div role="menu"></div>' },
      { name: 'a listbox', html: '<div role="listbox"></div>' },
      { name: 'a plain aside', html: '<aside></aside>' },
    ])('should_apply_when_only_$name_is_present', async ({ html }) => {
      fakeDoc.surfaces.body.innerHTML = html;
      checkForUpdate.mockResolvedValue(true);

      setup(true).start();
      await flush();

      expect(reload).toHaveBeenCalledTimes(1);
    });
  });

  describe('unrecoverable', () => {
    it('should_reload_immediately_when_unrecoverable_even_on_a_task_flow_with_a_dialog_open', async () => {
      router.url = '/settings';
      fakeDoc.surfaces.body.innerHTML = '<div role="dialog"></div>';
      setup(true).start();
      await flush();

      unrecoverable.next({ type: 'UNRECOVERABLE_STATE', reason: 'x' });
      TestBed.tick();

      expect(reload).toHaveBeenCalledTimes(1);
      expect(activateUpdate).not.toHaveBeenCalled();
    });
  });

  describe('hors ligne', () => {
    it('should_absorb_the_rejection_when_check_for_update_fails_at_startup', async () => {
      checkForUpdate.mockRejectedValue(new Error('offline'));

      // Un rejet non gere ferait echouer la suite : vitest rapporte toute `unhandledRejection`.
      setup(true).start();
      await flush();
      await new Promise((resolve) => setTimeout(resolve, 0));

      expect(checkForUpdate).toHaveBeenCalledTimes(1);
      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).not.toHaveBeenCalled();
    });

    it('should_keep_checking_on_next_return_when_a_previous_check_failed', async () => {
      checkForUpdate.mockRejectedValueOnce(new Error('offline')).mockResolvedValue(true);

      setup(true).start();
      await flush();
      await returnToForeground();

      expect(reload).toHaveBeenCalledTimes(1);
    });
  });

  describe('refreshAndReload', () => {
    it('should_only_reload_when_service_worker_is_disabled', async () => {
      await setup(false).refreshAndReload();

      expect(checkForUpdate).not.toHaveBeenCalled();
      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_check_activate_then_reload_when_a_new_version_is_found', async () => {
      checkForUpdate.mockResolvedValue(true);
      const order: string[] = [];
      activateUpdate.mockImplementation(async () => {
        order.push('activate');
        return true;
      });
      reload.mockImplementation(() => order.push('reload'));

      await setup(true).refreshAndReload();

      expect(order).toEqual(['activate', 'reload']);
    });

    it('should_reload_without_activation_when_no_new_version_is_found', async () => {
      await setup(true).refreshAndReload();

      expect(checkForUpdate).toHaveBeenCalledTimes(1);
      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_activate_a_retained_version_even_when_search_finds_nothing_new', async () => {
      const service = setup(true);
      service.start();
      await flush();
      versionUpdates.next({ type: 'VERSION_READY' });

      await service.refreshAndReload();

      expect(activateUpdate).toHaveBeenCalledTimes(1);
      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_reload_anyway_when_check_for_update_rejects', async () => {
      checkForUpdate.mockRejectedValue(new Error('offline'));

      await expect(setup(true).refreshAndReload()).resolves.toBeUndefined();

      expect(activateUpdate).not.toHaveBeenCalled();
      expect(reload).toHaveBeenCalledTimes(1);
    });

    it('should_reload_anyway_when_activation_rejects', async () => {
      checkForUpdate.mockResolvedValue(true);
      activateUpdate.mockRejectedValue(new Error('boom'));

      await setup(true).refreshAndReload();

      expect(reload).toHaveBeenCalledTimes(1);
    });
  });
});
