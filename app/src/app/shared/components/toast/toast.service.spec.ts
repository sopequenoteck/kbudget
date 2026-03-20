import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';

import { ToastService } from './toast.service';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

describe('ToastService', () => {
  let service: ToastService;

  beforeEach(() => {
    vi.useFakeTimers();

    TestBed.configureTestingModule({
      providers: [ToastService],
    });

    service = TestBed.inject(ToastService);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('should_add_success_toast_when_success_called', () => {
    service.success('Opération réussie');

    const toasts = service.toasts();
    expect(toasts).toHaveLength(1);
    expect(toasts[0].type).toBe('success');
    expect(toasts[0].message).toBe('Opération réussie');
    expect(toasts[0].id).toBeGreaterThan(0);
  });

  it('should_add_error_toast_when_error_called', () => {
    service.error('Une erreur est survenue');

    const toasts = service.toasts();
    expect(toasts).toHaveLength(1);
    expect(toasts[0].type).toBe('error');
    expect(toasts[0].message).toBe('Une erreur est survenue');
  });

  it('should_add_info_toast_when_info_called', () => {
    service.info('Information importante');

    const toasts = service.toasts();
    expect(toasts).toHaveLength(1);
    expect(toasts[0].type).toBe('info');
    expect(toasts[0].message).toBe('Information importante');
  });

  it('should_auto_dismiss_after_4s', () => {
    service.success('Toast temporaire');

    expect(service.toasts()).toHaveLength(1);

    vi.advanceTimersByTime(4000);

    expect(service.toasts()).toHaveLength(0);
  });

  it('should_not_dismiss_before_4s', () => {
    service.success('Toast temporaire');

    vi.advanceTimersByTime(3999);

    expect(service.toasts()).toHaveLength(1);
  });

  it('should_remove_toast_when_dismiss_called', () => {
    service.success('Toast 1');
    service.error('Toast 2');

    expect(service.toasts()).toHaveLength(2);

    const id = service.toasts()[0].id;
    service.dismiss(id);

    expect(service.toasts()).toHaveLength(1);
    expect(service.toasts()[0].type).toBe('error');
  });

  it('should_not_remove_other_toasts_when_dismiss_called_with_specific_id', () => {
    service.success('Toast 1');
    service.info('Toast 2');
    service.error('Toast 3');

    const idToRemove = service.toasts()[1].id;
    service.dismiss(idToRemove);

    expect(service.toasts()).toHaveLength(2);
    expect(service.toasts().find((t) => t.id === idToRemove)).toBeUndefined();
  });

  it('should_assign_unique_ids_to_successive_toasts', () => {
    service.success('Toast 1');
    service.success('Toast 2');
    service.success('Toast 3');

    const ids = service.toasts().map((t) => t.id);
    const uniqueIds = new Set(ids);
    expect(uniqueIds.size).toBe(3);
  });
});
