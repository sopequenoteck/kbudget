import { TestBed } from '@angular/core/testing';
import { Router, type ActivatedRouteSnapshot, type RouterStateSnapshot } from '@angular/router';
import { signal } from '@angular/core';

import { compatibilityGuard } from './compatibility.guard';
import { CompatibilityService } from '../services/compatibility';
import { type CompatibilityStatus } from '../models/meta.model';

const route = {} as ActivatedRouteSnapshot;
const state = {} as RouterStateSnapshot;

function runGuard(status: CompatibilityStatus | null, checkResult?: CompatibilityStatus) {
  const compatibility = {
    status: signal<CompatibilityStatus | null>(status),
    check: vi.fn().mockResolvedValue(checkResult ?? status),
  };
  const router = { createUrlTree: vi.fn().mockReturnValue('URL_TREE') };

  TestBed.configureTestingModule({
    providers: [
      { provide: CompatibilityService, useValue: compatibility },
      { provide: Router, useValue: router },
    ],
  });

  const result = TestBed.runInInjectionContext(() => compatibilityGuard(route, state));
  return { result, compatibility, router };
}

describe('compatibilityGuard', () => {
  afterEach(() => {
    TestBed.resetTestingModule();
  });

  it('should_allow_when_compatible', async () => {
    const { result } = runGuard({
      kind: 'compatible',
      meta: {
        serverVersion: '9.9.9',
        apiVersion: 'v1',
        minClientVersion: '0.0.1',
        capabilities: [],
      },
    });

    await expect(result).resolves.toBe(true);
  });

  it('should_allow_when_offline', async () => {
    // Hors ligne n'est pas une incompatibilite : le cache prend le relais
    // (constitution, principe IV).
    const { result } = runGuard({ kind: 'offline' });

    await expect(result).resolves.toBe(true);
  });

  it('should_redirect_when_server_too_old', async () => {
    const { result, router } = runGuard({
      kind: 'serverTooOld',
      serverVersion: '1.0.0',
      requiredVersion: '6.1.0',
    });

    await expect(result).resolves.toBe('URL_TREE');
    expect(router.createUrlTree).toHaveBeenCalledWith(['/incompatible']);
  });

  it('should_redirect_when_client_too_old', async () => {
    const { result, router } = runGuard({
      kind: 'clientTooOld',
      clientVersion: '1.0.0',
      requiredVersion: '9.0.0',
    });

    await expect(result).resolves.toBe('URL_TREE');
    expect(router.createUrlTree).toHaveBeenCalledWith(['/incompatible']);
  });

  it('should_check_once_when_status_is_not_yet_known', async () => {
    const { result, compatibility } = runGuard(null, { kind: 'offline' });

    await result;
    expect(compatibility.check).toHaveBeenCalledOnce();
  });

  it('should_not_recheck_when_status_already_known', async () => {
    // Rejouer l'appel a chaque navigation ajouterait une latence sur chaque
    // transition pour une information qui ne change pas sans rechargement.
    const { result, compatibility } = runGuard({ kind: 'offline' });

    await result;
    expect(compatibility.check).not.toHaveBeenCalled();
  });
});
