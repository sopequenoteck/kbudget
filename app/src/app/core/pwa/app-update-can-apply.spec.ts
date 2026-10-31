import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';

import { APP_UPDATE_CAN_APPLY } from './app-update';
import { provideAppUpdateCanApply } from './app-update-can-apply';

describe('provideAppUpdateCanApply', () => {
  let router: { url: string };

  const setup = (): (() => boolean) => {
    TestBed.configureTestingModule({
      providers: [{ provide: Router, useValue: router }, provideAppUpdateCanApply()],
    });
    return TestBed.inject(APP_UPDATE_CAN_APPLY);
  };

  beforeEach(() => {
    router = { url: '/' };
  });

  it.each(['/settings', '/settings/account', '/transactions/import', '/transactions/import/review/d1'])(
    'should_refuse_update_when_route_is_task_flow_%s',
    (url) => {
      router.url = url;

      expect(setup()()).toBe(false);
    },
  );

  it.each(['/', '/transactions', '/budgets', '/dashboard'])(
    'should_allow_update_when_route_is_not_task_flow_%s',
    (url) => {
      router.url = url;

      expect(setup()()).toBe(true);
    },
  );

  it('should_read_current_route_at_each_call', () => {
    const canApply = setup();

    router.url = '/transactions/import';
    expect(canApply()).toBe(false);

    router.url = '/transactions';
    expect(canApply()).toBe(true);
  });
});
