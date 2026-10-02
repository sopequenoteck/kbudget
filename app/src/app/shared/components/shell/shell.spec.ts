import { TestBed } from '@angular/core/testing';
import { signal, computed } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideNoopAnimations } from '@angular/platform-browser/animations';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';

import { Shell } from './shell';
import { AuthService } from '../../../core/services/auth';
import { AvatarService } from '../../../core/services/avatar.service';
import { PreferenceService } from '../../../core/services/preference';
import { NotificationService } from '../../../core/services/notification';
import { StompService } from '../../../core/services/stomp';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

describe('Shell', () => {
  let authServiceMock: {
    currentUser: ReturnType<typeof signal>;
    isAuthenticated: ReturnType<typeof computed>;
    logout: ReturnType<typeof vi.fn>;
  };
  let avatarServiceMock: {
    avatarUrl: ReturnType<typeof signal>;
    loadAvatarBlob: ReturnType<typeof vi.fn>;
  };
  let preferenceServiceMock: {
    navOrder: ReturnType<typeof signal>;
    enabledFeatures: ReturnType<typeof signal>;
    language: ReturnType<typeof signal>;
    loaded: ReturnType<typeof signal>;
    isLoaded: ReturnType<typeof vi.fn>;
    loadPreferences: ReturnType<typeof vi.fn>;
  };
  let notificationServiceMock: {
    notifications: ReturnType<typeof signal>;
    unreadCount: ReturnType<typeof signal>;
    isLoading: ReturnType<typeof signal>;
    hasUnread: ReturnType<typeof computed>;
    loadUnreadCount: ReturnType<typeof vi.fn>;
    loadNotifications: ReturnType<typeof vi.fn>;
  };
  let stompServiceMock: { connect: ReturnType<typeof vi.fn>; disconnect: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    const currentUserSignal = signal<{ name: string; email: string } | null>(null);
    authServiceMock = {
      currentUser: currentUserSignal,
      isAuthenticated: computed(() => currentUserSignal() !== null),
      logout: vi.fn(),
    };

    avatarServiceMock = {
      avatarUrl: signal(null),
      loadAvatarBlob: vi.fn(),
    };

    preferenceServiceMock = {
      navOrder: signal([]),
      enabledFeatures: signal([]),
      language: signal(null),
      loaded: signal(false),
      isLoaded: vi.fn().mockReturnValue(false),
      loadPreferences: vi.fn(),
    };

    const unreadCountSignal = signal(0);
    notificationServiceMock = {
      notifications: signal([]),
      unreadCount: unreadCountSignal,
      isLoading: signal(false),
      hasUnread: computed(() => unreadCountSignal() > 0),
      loadUnreadCount: vi.fn(),
      loadNotifications: vi.fn(),
    };

    stompServiceMock = {
      connect: vi.fn(),
      disconnect: vi.fn(),
    };

    TestBed.configureTestingModule({
      imports: [Shell],
      providers: [
        ...provideTranslocoTesting(),
        provideRouter([]),
        provideNoopAnimations(),
        // Les enfants du shell (formulaires, FAB) injectent des services HTTP
        // reels : sans backend de test, jsdom emet de vraies requetes (CI).
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: AuthService, useValue: authServiceMock },
        { provide: AvatarService, useValue: avatarServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
        { provide: NotificationService, useValue: notificationServiceMock },
        { provide: StompService, useValue: stompServiceMock },
      ],
    });
  });

  it('should_create_the_component', () => {
    const fixture = TestBed.createComponent(Shell);
    fixture.detectChanges();

    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_expose_label_keys_for_fixed_nav_items', () => {
    const fixture = TestBed.createComponent(Shell);
    fixture.detectChanges();

    const items = fixture.componentInstance.navItems();

    expect(items[0]).toMatchObject({ labelKey: 'common.nav.home', route: '/dashboard' });
    expect(items[1]).toMatchObject({ labelKey: 'common.nav.transactions', route: '/transactions' });
  });

  it('should_expose_label_keys_for_optional_nav_items_from_enabled_features', () => {
    preferenceServiceMock.navOrder.set(['SUBSCRIPTIONS', 'DEBTS']);
    preferenceServiceMock.enabledFeatures.set(['SUBSCRIPTIONS', 'DEBTS']);

    const fixture = TestBed.createComponent(Shell);
    fixture.detectChanges();

    const items = fixture.componentInstance.navItems();

    expect(items[2]).toMatchObject({ labelKey: 'common.nav.subscriptions', route: '/subscriptions' });
    expect(items[3]).toMatchObject({ labelKey: 'common.nav.debts', route: '/debts' });
  });

  it('should_render_french_fixed_nav_labels_in_the_dom', () => {
    const fixture = TestBed.createComponent(Shell);
    fixture.detectChanges();

    const labels = Array.from(
      fixture.nativeElement.querySelectorAll('.shell-sidebar a') as NodeListOf<HTMLElement>,
    ).map((el) => el.textContent?.trim());

    expect(labels).toEqual(['Accueil', 'Transactions']);
  });

  it('should_render_french_user_menu_aria_label', () => {
    const fixture = TestBed.createComponent(Shell);
    fixture.detectChanges();

    const trigger: HTMLButtonElement = fixture.nativeElement.querySelector('.shell-user-trigger');

    expect(trigger.getAttribute('aria-label')).toBe('Menu utilisateur');
  });

  it('should_render_french_settings_and_logout_labels_when_dropdown_open', () => {
    const fixture = TestBed.createComponent(Shell);
    fixture.detectChanges();

    fixture.componentInstance.toggleDropdown();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;

    expect(text).toContain('Paramètres');
    expect(text).toContain('Déconnexion');
  });
});
