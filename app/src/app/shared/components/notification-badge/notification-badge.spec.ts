import { TestBed } from '@angular/core/testing';
import { signal, computed } from '@angular/core';

import { NotificationBadge } from './notification-badge';
import { NotificationService } from '../../../core/services/notification';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

describe('NotificationBadge', () => {
  let notificationServiceMock: {
    hasUnread: ReturnType<typeof computed>;
    unreadCount: ReturnType<typeof signal>;
  };

  beforeEach(() => {
    const unreadCount = signal(3);
    notificationServiceMock = {
      unreadCount,
      hasUnread: computed(() => unreadCount() > 0),
    };

    TestBed.configureTestingModule({
      imports: [NotificationBadge],
      providers: [
        ...provideTranslocoTesting(),
        { provide: NotificationService, useValue: notificationServiceMock },
      ],
    });
  });

  it('should_create_the_component', () => {
    const fixture = TestBed.createComponent(NotificationBadge);
    fixture.detectChanges();

    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_render_french_aria_label', () => {
    const fixture = TestBed.createComponent(NotificationBadge);
    fixture.detectChanges();

    const button: HTMLButtonElement = fixture.nativeElement.querySelector('.notification-badge');

    expect(button.getAttribute('aria-label')).toBe('Notifications');
  });

  it('should_emit_clicked_when_button_clicked', () => {
    const fixture = TestBed.createComponent(NotificationBadge);
    fixture.detectChanges();

    const emitSpy = vi.fn();
    fixture.componentInstance.clicked.subscribe(emitSpy);

    const button: HTMLButtonElement = fixture.nativeElement.querySelector('.notification-badge');
    button.click();

    expect(emitSpy).toHaveBeenCalled();
  });
});
