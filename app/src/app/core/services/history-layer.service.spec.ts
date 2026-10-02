import { DOCUMENT } from '@angular/common';
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';

import {
  HistoryLayerService,
  bindExpandedSectionLayer,
  bindHistoryLayer,
} from './history-layer.service';
import { goBack, resetHistory, settleHistory } from '../../../testing/history-testing';

const LAYER_STATE = { kbudgetHistoryLayer: true };

/** Historique remis a zero et routeur sans navigation en cours. */
function configureWithIdleRouter(): void {
  resetHistory();
  TestBed.configureTestingModule({
    providers: [{ provide: Router, useValue: { currentNavigation: () => null } }],
  });
}

describe('HistoryLayerService', () => {
  let service: HistoryLayerService;
  let navigation: ReturnType<typeof signal<unknown>>;

  beforeEach(() => {
    resetHistory();
    navigation = signal<unknown>(null);
    TestBed.configureTestingModule({
      providers: [{ provide: Router, useValue: { currentNavigation: () => navigation() } }],
    });
    service = TestBed.inject(HistoryLayerService);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('push', () => {
    it('should_push_a_history_entry_without_changing_the_url_when_a_layer_is_registered', () => {
      const pushSpy = vi.spyOn(history, 'pushState');

      service.push(vi.fn());

      expect(pushSpy).toHaveBeenCalledTimes(1);
      expect(history.state).toEqual(LAYER_STATE);
      expect(location.pathname).toBe('/');
    });

    it('should_report_the_layer_active_when_registered', () => {
      const handle = service.push(vi.fn());

      expect(service.isActive(handle)).toBe(true);
    });
  });

  describe('popstate', () => {
    it('should_close_the_layer_when_back_is_pressed', async () => {
      const onBack = vi.fn();
      const handle = service.push(onBack);

      await goBack();

      expect(onBack).toHaveBeenCalledTimes(1);
      expect(service.isActive(handle)).toBe(false);
    });

    it('should_close_only_the_top_layer_when_two_layers_are_open', async () => {
      const lower = vi.fn();
      const upper = vi.fn();
      service.push(lower);
      service.push(upper);

      await goBack();

      expect(upper).toHaveBeenCalledTimes(1);
      expect(lower).not.toHaveBeenCalled();
    });

    it('should_close_the_lower_layer_when_back_is_pressed_a_second_time', async () => {
      const lower = vi.fn();
      const upper = vi.fn();
      service.push(lower);
      service.push(upper);

      await goBack();
      await goBack();

      expect(lower).toHaveBeenCalledTimes(1);
      expect(upper).toHaveBeenCalledTimes(1);
    });

    it('should_do_nothing_when_back_is_pressed_without_any_layer', async () => {
      const onBack = vi.fn();
      const handle = service.push(onBack);
      service.release(handle);
      await settleHistory();

      await goBack();

      expect(onBack).not.toHaveBeenCalled();
    });

    it('should_keep_the_layer_and_restore_the_entry_when_the_surface_is_blocked', async () => {
      const onBack = vi.fn();
      const handle = service.push(onBack, () => true);

      await goBack();

      expect(onBack).not.toHaveBeenCalled();
      expect(service.isActive(handle)).toBe(true);
      expect(history.state).toEqual(LAYER_STATE);
    });

    it('should_close_a_blocked_layer_once_it_is_no_longer_blocked', async () => {
      const blocked = signal(true);
      const onBack = vi.fn();
      service.push(onBack, () => blocked());
      await goBack();

      blocked.set(false);
      await goBack();

      expect(onBack).toHaveBeenCalledTimes(1);
    });
  });

  describe('release', () => {
    it('should_remove_the_entry_and_ignore_the_resulting_popstate_when_a_layer_is_released', async () => {
      const lower = vi.fn();
      const upper = vi.fn();
      service.push(lower);
      const upperHandle = service.push(upper);
      const goSpy = vi.spyOn(history, 'go');

      service.release(upperHandle);
      await settleHistory();

      expect(goSpy).toHaveBeenCalledWith(-1);
      expect(lower).not.toHaveBeenCalled();
      expect(upper).not.toHaveBeenCalled();
    });

    it('should_still_close_the_remaining_layer_when_back_is_pressed_after_a_release', async () => {
      const lower = vi.fn();
      service.push(lower);
      const upperHandle = service.push(vi.fn());
      service.release(upperHandle);
      await settleHistory();

      await goBack();

      expect(lower).toHaveBeenCalledTimes(1);
    });

    it('should_go_back_once_for_all_entries_when_several_layers_are_released_together', async () => {
      const first = service.push(vi.fn());
      const second = service.push(vi.fn());
      const goSpy = vi.spyOn(history, 'go');

      service.release(first);
      service.release(second);
      await settleHistory();

      expect(goSpy).toHaveBeenCalledTimes(1);
      expect(goSpy).toHaveBeenCalledWith(-2);
    });

    it('should_report_the_layer_inactive_when_released', () => {
      const handle = service.push(vi.fn());

      service.release(handle);

      expect(service.isActive(handle)).toBe(false);
    });

    it('should_do_nothing_when_a_layer_is_released_twice', async () => {
      const handle = service.push(vi.fn());
      service.release(handle);
      await settleHistory();
      const goSpy = vi.spyOn(history, 'go');

      service.release(handle);
      await settleHistory();

      expect(goSpy).not.toHaveBeenCalled();
    });

    it('should_not_go_back_when_the_layer_was_already_closed_by_a_popstate', async () => {
      const handle = service.push(vi.fn());
      await goBack();
      const goSpy = vi.spyOn(history, 'go');

      service.release(handle);
      await settleHistory();

      expect(goSpy).not.toHaveBeenCalled();
    });
  });

  describe('cas limites', () => {
    it('should_absorb_a_popstate_when_the_only_entry_belongs_to_a_layer_already_released', async () => {
      const onBack = vi.fn();
      const handle = service.push(onBack);
      service.release(handle);

      globalThis.dispatchEvent(new PopStateEvent('popstate'));
      await settleHistory();

      expect(onBack).not.toHaveBeenCalled();
    });

    it('should_report_no_layer_active_when_the_handle_is_null', () => {
      expect(service.isActive(null)).toBe(false);
    });

    it('should_keep_an_abandoned_layer_without_closing_it_when_back_is_pressed_on_a_newer_layer', async () => {
      const abandoned = vi.fn();
      const newer = vi.fn();
      service.push(abandoned);
      const second = service.push(vi.fn());
      history.pushState({ navigationId: 2 }, '', '/dashboard');
      service.release(second);
      await settleHistory();
      service.push(newer);

      await goBack();

      expect(newer).toHaveBeenCalledTimes(1);
      expect(abandoned).not.toHaveBeenCalled();
    });

    it('should_not_traverse_when_an_abandoned_layer_is_released_later', async () => {
      const first = service.push(vi.fn());
      const second = service.push(vi.fn());
      history.pushState({ navigationId: 2 }, '', '/dashboard');
      service.release(second);
      await settleHistory();
      const goSpy = vi.spyOn(history, 'go');

      service.release(first);
      await settleHistory();

      expect(goSpy).not.toHaveBeenCalled();
    });
  });

  describe('route navigation', () => {
    it('should_not_go_back_when_a_navigation_is_in_progress_at_release', async () => {
      const handle = service.push(vi.fn());
      navigation.set({ id: 1 });
      const goSpy = vi.spyOn(history, 'go');

      service.release(handle);
      await settleHistory();

      expect(goSpy).not.toHaveBeenCalled();
    });

    it('should_not_go_back_when_the_router_replaced_the_top_history_entry', async () => {
      const handle = service.push(vi.fn());
      history.pushState({ navigationId: 2 }, '', '/dashboard');
      const goSpy = vi.spyOn(history, 'go');

      service.release(handle);
      await settleHistory();

      expect(goSpy).not.toHaveBeenCalled();
      expect(location.pathname).toBe('/dashboard');
    });

    it('should_not_claim_abandoned_entries_when_a_new_layer_opens_after_a_navigation', async () => {
      const abandoned = service.push(vi.fn());
      history.pushState({ navigationId: 2 }, '', '/dashboard');
      service.release(abandoned);
      await settleHistory();
      const onBack = vi.fn();
      service.push(onBack);

      await goBack();

      expect(onBack).toHaveBeenCalledTimes(1);
      expect(location.pathname).toBe('/dashboard');
    });
  });
});

describe('HistoryLayerService sans fenetre', () => {
  it('should_register_and_release_layers_without_touching_the_history_when_there_is_no_window', async () => {
    TestBed.configureTestingModule({
      providers: [
        { provide: DOCUMENT, useValue: { defaultView: null } },
        { provide: Router, useValue: { currentNavigation: () => null } },
      ],
    });
    const service = TestBed.inject(HistoryLayerService);
    const pushSpy = vi.spyOn(history, 'pushState');
    const goSpy = vi.spyOn(history, 'go');

    const handle = service.push(vi.fn());
    service.release(handle);
    await settleHistory();

    expect(pushSpy).not.toHaveBeenCalled();
    expect(goSpy).not.toHaveBeenCalled();
    vi.restoreAllMocks();
  });
});

@Component({
  selector: 'app-layer-host',
  template: '',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class LayerHost {
  readonly open = signal(false);
  readonly onBack = vi.fn();

  constructor() {
    bindHistoryLayer(this.onBack, this.open);
  }
}

@Component({
  selector: 'app-always-layer-host',
  template: '',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class AlwaysLayerHost {
  readonly onBack = vi.fn();

  constructor() {
    bindHistoryLayer(this.onBack);
  }
}

@Component({
  selector: 'app-section-host',
  template: '',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class SectionHost {
  readonly section = signal<'date' | 'category' | null>(null);

  constructor() {
    bindExpandedSectionLayer(this.section);
  }
}

describe('bindHistoryLayer', () => {
  beforeEach(configureWithIdleRouter);

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should_push_an_entry_when_the_surface_opens', () => {
    const fixture = TestBed.createComponent(LayerHost);
    const pushSpy = vi.spyOn(history, 'pushState');

    fixture.componentInstance.open.set(true);
    fixture.detectChanges();

    expect(pushSpy).toHaveBeenCalledTimes(1);
  });

  it('should_not_push_an_entry_while_the_surface_stays_closed', () => {
    const fixture = TestBed.createComponent(LayerHost);
    const pushSpy = vi.spyOn(history, 'pushState');

    fixture.detectChanges();

    expect(pushSpy).not.toHaveBeenCalled();
  });

  it('should_call_on_back_when_back_is_pressed_while_open', async () => {
    const fixture = TestBed.createComponent(LayerHost);
    fixture.componentInstance.open.set(true);
    fixture.detectChanges();

    await goBack();

    expect(fixture.componentInstance.onBack).toHaveBeenCalledTimes(1);
  });

  it('should_release_the_entry_when_the_surface_closes_by_itself', async () => {
    const fixture = TestBed.createComponent(LayerHost);
    fixture.componentInstance.open.set(true);
    fixture.detectChanges();
    const goSpy = vi.spyOn(history, 'go');

    fixture.componentInstance.open.set(false);
    fixture.detectChanges();
    await settleHistory();

    expect(goSpy).toHaveBeenCalledWith(-1);
    expect(fixture.componentInstance.onBack).not.toHaveBeenCalled();
  });

  it('should_release_the_entry_when_the_owner_is_destroyed_while_open', async () => {
    const fixture = TestBed.createComponent(LayerHost);
    fixture.componentInstance.open.set(true);
    fixture.detectChanges();
    const goSpy = vi.spyOn(history, 'go');

    fixture.destroy();
    await settleHistory();

    expect(goSpy).toHaveBeenCalledWith(-1);
  });

  it('should_push_a_new_entry_when_the_surface_reopens_after_a_back', async () => {
    const fixture = TestBed.createComponent(LayerHost);
    const host = fixture.componentInstance;
    host.open.set(true);
    fixture.detectChanges();
    await goBack();
    host.open.set(false);
    fixture.detectChanges();
    host.open.set(true);
    fixture.detectChanges();

    await goBack();

    expect(host.onBack).toHaveBeenCalledTimes(2);
  });

  it('should_hold_the_layer_as_long_as_the_owner_exists_when_no_open_signal_is_given', async () => {
    const fixture = TestBed.createComponent(AlwaysLayerHost);
    fixture.detectChanges();

    await goBack();

    expect(fixture.componentInstance.onBack).toHaveBeenCalledTimes(1);
  });
});

describe('bindExpandedSectionLayer', () => {
  beforeEach(configureWithIdleRouter);

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should_collapse_the_section_when_back_is_pressed', async () => {
    const fixture = TestBed.createComponent(SectionHost);
    fixture.componentInstance.section.set('date');
    fixture.detectChanges();

    await goBack();

    expect(fixture.componentInstance.section()).toBeNull();
  });

  it('should_keep_a_single_layer_when_switching_directly_between_sections', () => {
    const fixture = TestBed.createComponent(SectionHost);
    const pushSpy = vi.spyOn(history, 'pushState');
    fixture.componentInstance.section.set('date');
    fixture.detectChanges();
    fixture.componentInstance.section.set('category');
    fixture.detectChanges();

    expect(pushSpy).toHaveBeenCalledTimes(1);
  });

  it('should_release_the_entry_when_the_section_is_collapsed_by_the_user', async () => {
    const fixture = TestBed.createComponent(SectionHost);
    fixture.componentInstance.section.set('date');
    fixture.detectChanges();
    const goSpy = vi.spyOn(history, 'go');

    fixture.componentInstance.section.set(null);
    fixture.detectChanges();
    await settleHistory();

    expect(goSpy).toHaveBeenCalledWith(-1);
  });
});
