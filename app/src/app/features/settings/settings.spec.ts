import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { signal } from '@angular/core';
import { of, throwError } from 'rxjs';
import { CdkDragDrop } from '@angular/cdk/drag-drop';

import { Settings } from './settings';
import { AuthService } from '../../core/services/auth';
import { AvatarService } from '../../core/services/avatar.service';
import { UserService } from '../../core/services/user';
import { ThemeService } from '../../core/services/theme';
import { TextScaleService } from '../../core/services/text-scale';
import { PreferenceService } from '../../core/services/preference';
import { SubscriptionService } from '../../core/services/subscription';
import { DebtService } from '../../core/services/debt';
import { HealthService } from '../../core/services/health';
import { UserInfo } from '../../core/models/user.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

describe('Settings', () => {
  let authServiceMock: { currentUser: ReturnType<typeof signal<UserInfo | null>>; isAdmin: ReturnType<typeof signal<boolean>> };
  let preferenceServiceMock: {
    enabledNotificationTypes: ReturnType<typeof signal<string[]>>;
    timezone: ReturnType<typeof signal<string>>;
    navOrder: ReturnType<typeof signal<string[]>>;
    enabledFeatures: ReturnType<typeof signal<string[]>>;
    isEnabled: ReturnType<typeof vi.fn>;
    toggleFeature: ReturnType<typeof vi.fn>;
    updateNotificationTypes: ReturnType<typeof vi.fn>;
    updateTimezone: ReturnType<typeof vi.fn>;
    reorderNavigation: ReturnType<typeof vi.fn>;
  };
  let subscriptionServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let debtServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let healthServiceMock: { getServerInfo: ReturnType<typeof vi.fn>; checkHealth: ReturnType<typeof vi.fn> };
  let themeServiceMock: { currentTheme: ReturnType<typeof signal<string>>; setTheme: ReturnType<typeof vi.fn> };
  let textScaleServiceMock: {
    currentTextScale: ReturnType<typeof signal<string>>;
    scaleFactor: ReturnType<typeof signal<number>>;
    setTextScale: ReturnType<typeof vi.fn>;
  };

  const user: UserInfo = { name: 'Ada Lovelace', email: 'ada@exemple.com', mustResetCredentials: false };

  const setup = () => {
    authServiceMock = {
      currentUser: signal<UserInfo | null>(user),
      isAdmin: signal(false),
    };
    preferenceServiceMock = {
      enabledNotificationTypes: signal<string[]>(['SUBSCRIPTION_DUE']),
      timezone: signal('Europe/Paris'),
      navOrder: signal(['SUBSCRIPTIONS', 'DEBTS']),
      enabledFeatures: signal(['SUBSCRIPTIONS', 'DEBTS']),
      isEnabled: vi.fn().mockReturnValue(true),
      toggleFeature: vi.fn(),
      updateNotificationTypes: vi.fn(),
      updateTimezone: vi.fn(),
      reorderNavigation: vi.fn(),
    };
    subscriptionServiceMock = { getAll: vi.fn().mockReturnValue(of([])) };
    debtServiceMock = { getAll: vi.fn().mockReturnValue(of([])) };
    healthServiceMock = {
      getServerInfo: vi.fn().mockReturnValue({ apiUrl: 'http://localhost/api', environment: 'development' }),
      checkHealth: vi.fn().mockReturnValue(
        of({ status: 'online' as const, responseTimeMs: 42, error: null, checkedAt: new Date() }),
      ),
    };
    themeServiceMock = { currentTheme: signal('dark'), setTheme: vi.fn() };
    textScaleServiceMock = {
      currentTextScale: signal('medium'),
      scaleFactor: signal(1),
      setTextScale: vi.fn(),
    };

    TestBed.configureTestingModule({
      imports: [Settings],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        { provide: AuthService, useValue: authServiceMock },
        { provide: AvatarService, useValue: { avatarUrl: signal<string | null>(null) } },
        { provide: UserService, useValue: { getProfile: vi.fn().mockReturnValue(of(user)) } },
        { provide: ThemeService, useValue: themeServiceMock },
        { provide: TextScaleService, useValue: textScaleServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
        { provide: SubscriptionService, useValue: subscriptionServiceMock },
        { provide: DebtService, useValue: debtServiceMock },
        { provide: HealthService, useValue: healthServiceMock },
      ],
    });

    return TestBed.createComponent(Settings);
  };

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('ngOnInit()', () => {
    it('should_set_the_health_result_returned_by_the_health_service', async () => {
      const fixture = setup();
      fixture.detectChanges();
      await fixture.whenStable();

      expect(fixture.componentInstance.healthResult().status).toBe('online');
    });

    it('should_report_an_unknown_error_when_the_health_check_rejects', async () => {
      const fixture = setup();
      healthServiceMock.checkHealth.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();
      await fixture.whenStable();

      expect(fixture.componentInstance.healthResult().status).toBe('offline');
      expect(fixture.componentInstance.healthResult().error).toBe('Erreur inconnue');
    });
  });

  describe('getInitials()', () => {
    it('should_uppercase_and_limit_to_two_letters', () => {
      const fixture = setup();
      fixture.detectChanges();

      expect(fixture.componentInstance.getInitials('grace brewster hopper')).toBe('GB');
    });
  });

  describe('theme and text scale', () => {
    it('should_delegate_setTheme_to_the_theme_service', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.setTheme('light');

      expect(themeServiceMock.setTheme).toHaveBeenCalledWith('light');
    });

    it('should_delegate_setTextScale_to_the_text_scale_service', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.setTextScale('large');

      expect(textScaleServiceMock.setTextScale).toHaveBeenCalledWith('large');
    });
  });

  describe('notification types', () => {
    it('should_report_a_type_as_enabled_when_it_is_in_the_preference_list', () => {
      const fixture = setup();
      fixture.detectChanges();

      expect(fixture.componentInstance.isTypeEnabled('SUBSCRIPTION_DUE')).toBe(true);
      expect(fixture.componentInstance.isTypeEnabled('DEBT_DUE')).toBe(false);
    });

    it('should_add_a_type_when_toggled_on', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.toggleType('DEBT_DUE');

      expect(preferenceServiceMock.updateNotificationTypes).toHaveBeenCalledWith([
        'SUBSCRIPTION_DUE',
        'DEBT_DUE',
      ]);
    });

    it('should_remove_a_type_when_toggled_off', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.toggleType('SUBSCRIPTION_DUE');

      expect(preferenceServiceMock.updateNotificationTypes).toHaveBeenCalledWith([]);
    });

    it('should_expose_labelKey_and_descriptionKey_for_every_notification_type', () => {
      const fixture = setup();
      fixture.detectChanges();

      expect(fixture.componentInstance.notificationTypes).toEqual([
        {
          type: 'SUBSCRIPTION_DUE',
          labelKey: 'settings.list.subscriptionReminders',
          descriptionKey: 'settings.list.subscriptionRemindersHint',
          icon: 'phosphorCalendarCheck',
        },
        {
          type: 'DEBT_DUE',
          labelKey: 'settings.list.debtReminders',
          descriptionKey: 'settings.list.debtRemindersHint',
          icon: 'phosphorHandCoins',
        },
      ]);
    });
  });

  describe('onTimezoneChange()', () => {
    it('should_update_the_timezone_from_the_select_value', () => {
      const fixture = setup();
      fixture.detectChanges();
      const select = document.createElement('select');
      const option = document.createElement('option');
      option.value = 'Europe/London';
      select.appendChild(option);
      select.value = 'Europe/London';
      const event = { target: select } as unknown as Event;

      fixture.componentInstance.onTimezoneChange(event);

      expect(preferenceServiceMock.updateTimezone).toHaveBeenCalledWith('Europe/London');
    });
  });

  describe('toggleFeature()', () => {
    it('should_toggle_directly_when_enabling_a_feature', async () => {
      const fixture = setup();
      preferenceServiceMock.isEnabled.mockReturnValue(false);
      fixture.detectChanges();

      await fixture.componentInstance.toggleFeature('SUBSCRIPTIONS');

      expect(preferenceServiceMock.toggleFeature).toHaveBeenCalledWith('SUBSCRIPTIONS');
      expect(fixture.componentInstance.confirmDisableFeature()).toBeNull();
    });

    it('should_toggle_directly_when_disabling_a_feature_with_no_data', async () => {
      const fixture = setup();
      preferenceServiceMock.isEnabled.mockReturnValue(true);
      subscriptionServiceMock.getAll.mockReturnValue(of([]));
      fixture.detectChanges();

      await fixture.componentInstance.toggleFeature('SUBSCRIPTIONS');

      expect(preferenceServiceMock.toggleFeature).toHaveBeenCalledWith('SUBSCRIPTIONS');
    });

    it('should_ask_for_confirmation_when_disabling_a_feature_with_data', async () => {
      const fixture = setup();
      preferenceServiceMock.isEnabled.mockReturnValue(true);
      subscriptionServiceMock.getAll.mockReturnValue(of([{ id: 1 }]));
      fixture.detectChanges();

      await fixture.componentInstance.toggleFeature('SUBSCRIPTIONS');

      expect(preferenceServiceMock.toggleFeature).not.toHaveBeenCalled();
      expect(fixture.componentInstance.confirmDisableFeature()).toBe('SUBSCRIPTIONS');
    });

    it('should_ask_for_confirmation_when_disabling_debts_with_data', async () => {
      const fixture = setup();
      preferenceServiceMock.isEnabled.mockReturnValue(true);
      debtServiceMock.getAll.mockReturnValue(of([{ id: 1 }]));
      fixture.detectChanges();

      await fixture.componentInstance.toggleFeature('DEBTS');

      expect(preferenceServiceMock.toggleFeature).not.toHaveBeenCalled();
      expect(fixture.componentInstance.confirmDisableFeature()).toBe('DEBTS');
    });

    it('should_toggle_directly_for_a_feature_without_a_data_check', async () => {
      const fixture = setup();
      preferenceServiceMock.isEnabled.mockReturnValue(true);
      fixture.detectChanges();

      await fixture.componentInstance.toggleFeature('BUDGETS');

      expect(preferenceServiceMock.toggleFeature).toHaveBeenCalledWith('BUDGETS');
    });

    it('should_toggle_directly_when_the_data_check_fails', async () => {
      const fixture = setup();
      preferenceServiceMock.isEnabled.mockReturnValue(true);
      subscriptionServiceMock.getAll.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();

      await fixture.componentInstance.toggleFeature('SUBSCRIPTIONS');

      expect(preferenceServiceMock.toggleFeature).toHaveBeenCalledWith('SUBSCRIPTIONS');
    });
  });

  describe('confirmDisable() / cancelDisable()', () => {
    it('should_toggle_the_feature_and_clear_the_confirmation_state', () => {
      const fixture = setup();
      fixture.detectChanges();
      fixture.componentInstance.confirmDisableFeature.set('SUBSCRIPTIONS');

      fixture.componentInstance.confirmDisable();

      expect(preferenceServiceMock.toggleFeature).toHaveBeenCalledWith('SUBSCRIPTIONS');
      expect(fixture.componentInstance.confirmDisableFeature()).toBeNull();
    });

    it('should_do_nothing_when_there_is_no_feature_pending', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.confirmDisable();

      expect(preferenceServiceMock.toggleFeature).not.toHaveBeenCalled();
    });

    it('should_clear_the_confirmation_state_on_cancel', () => {
      const fixture = setup();
      fixture.detectChanges();
      fixture.componentInstance.confirmDisableFeature.set('DEBTS');

      fixture.componentInstance.cancelDisable();

      expect(fixture.componentInstance.confirmDisableFeature()).toBeNull();
    });
  });

  describe('onDrop()', () => {
    it('should_reorder_the_enabled_navigation_items', () => {
      const fixture = setup();
      fixture.detectChanges();

      const event = { previousIndex: 0, currentIndex: 1 } as CdkDragDrop<unknown>;
      fixture.componentInstance.onDrop(event);

      expect(preferenceServiceMock.reorderNavigation).toHaveBeenCalledWith(['DEBTS', 'SUBSCRIPTIONS']);
    });
  });

  describe('enabledNavItems() / disabledNavItems()', () => {
    it('should_expose_only_the_enabled_features_matching_nav_order', () => {
      const fixture = setup();
      fixture.detectChanges();

      const values = fixture.componentInstance.enabledNavItems().map((item) => item.value);
      expect(values).toEqual(['SUBSCRIPTIONS', 'DEBTS']);
    });

    it('should_expose_the_features_not_enabled_as_disabled_items', () => {
      const fixture = setup();
      preferenceServiceMock.enabledFeatures.set(['SUBSCRIPTIONS']);
      fixture.detectChanges();

      const values = fixture.componentInstance.disabledNavItems().map((item) => item.value);
      expect(values).toEqual(['DEBTS', 'BUDGETS']);
    });
  });
});
