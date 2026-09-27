import { ChangeDetectionStrategy, Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';

import { NotificationTextPipe } from './notification-text.pipe';
import { PreferenceService } from '../../core/services/preference';
import { type NotificationModel } from '../../core/models/notification.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

function makeNotification(overrides: Partial<NotificationModel> = {}): NotificationModel {
  return {
    id: 'notif-1',
    type: 'SUBSCRIPTION_DUE',
    title: 'Titre brut',
    message: 'Message brut',
    entityType: null,
    entityId: null,
    read: false,
    readAt: null,
    createdAt: '2026-09-27T00:00:00.000Z',
    ...overrides,
  };
}

@Component({
  standalone: true,
  imports: [NotificationTextPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <span class="title">{{ (notification | notificationText).title }}</span>
    <span class="message">{{ (notification | notificationText).message }}</span>
  `,
})
class NotificationTextHost {
  notification: NotificationModel = makeNotification();
}

describe('NotificationTextPipe', () => {
  it('should_return_raw_title_and_message_when_params_is_absent', () => {
    TestBed.configureTestingModule({ providers: [provideTranslocoTesting()] });
    const fixture = TestBed.createComponent(NotificationTextHost);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.title').textContent).toBe('Titre brut');
    expect(fixture.nativeElement.querySelector('.message').textContent).toBe('Message brut');
  });

  it('should_build_french_text_when_params_are_present', () => {
    TestBed.configureTestingModule({ providers: [provideTranslocoTesting()] });
    const fixture = TestBed.createComponent(NotificationTextHost);
    fixture.componentInstance.notification = makeNotification({
      type: 'SUBSCRIPTION_DUE',
      params: { name: 'Netflix' },
    });
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.title').textContent).toBe('Abonnement Netflix');
    expect(fixture.nativeElement.querySelector('.message').textContent).toBe('Netflix — échéance demain');
  });

  it('should_build_english_text_when_language_switches_to_en_without_recreating_fixture', async () => {
    TestBed.configureTestingModule({ providers: [provideTranslocoTesting()] });
    const fixture = TestBed.createComponent(NotificationTextHost);
    fixture.componentInstance.notification = makeNotification({
      type: 'DEBT_DUE',
      params: { person: 'Alice' },
    });
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.title').textContent).toBe('Dette Alice');

    const preferenceService = TestBed.inject(PreferenceService);
    preferenceService.language.set('en');
    fixture.detectChanges();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.title').textContent).toBe('Debt with Alice');
    expect(fixture.nativeElement.querySelector('.message').textContent).toBe(
      'Debt with Alice is due tomorrow',
    );
  });

  it('should_translate_the_system_category_name_when_language_switches_to_en', async () => {
    TestBed.configureTestingModule({ providers: [provideTranslocoTesting()] });
    const fixture = TestBed.createComponent(NotificationTextHost);
    fixture.componentInstance.notification = makeNotification({
      type: 'BUDGET_THRESHOLD',
      params: { category: 'Abonnement', categorySystemKey: 'SUBSCRIPTION', percentage: '85' },
    });
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.title').textContent).toBe('Budget Abonnement : 85 %');

    const preferenceService = TestBed.inject(PreferenceService);
    preferenceService.language.set('en');
    fixture.detectChanges();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.title').textContent).toBe('Budget Subscription: 85%');
  });
});
