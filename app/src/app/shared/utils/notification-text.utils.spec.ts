import { describe, it, expect, vi } from 'vitest';
import { TranslocoService } from '@jsverse/transloco';

import { buildNotificationText } from './notification-text.utils';
import { formatCurrencyAmount } from './locale-format.utils';
import { type NotificationModel, type NotificationType } from '../../core/models/notification.model';

function translocoStub(): TranslocoService {
  return {
    translate: vi.fn((key: string, params?: Record<string, string>) => {
      const paramsSuffix = params && Object.keys(params).length > 0 ? `:${JSON.stringify(params)}` : '';
      return `translated:${key}${paramsSuffix}`;
    }),
  } as unknown as TranslocoService;
}

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

describe('buildNotificationText', () => {
  it('should_return_raw_title_and_message_when_params_is_undefined', () => {
    const transloco = translocoStub();
    const notification = makeNotification({ params: undefined });

    const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(result).toEqual({ title: 'Titre brut', message: 'Message brut' });
    expect(transloco.translate).not.toHaveBeenCalled();
  });

  it('should_return_raw_title_and_message_when_params_is_null', () => {
    const transloco = translocoStub();
    const notification = makeNotification({ params: null });

    const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(result).toEqual({ title: 'Titre brut', message: 'Message brut' });
  });

  it('should_return_raw_title_and_message_when_type_is_unknown_to_this_client', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'SOMETHING_NEW' as NotificationType,
      params: { name: 'Netflix' },
    });

    const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(result).toEqual({ title: 'Titre brut', message: 'Message brut' });
  });

  it('should_build_subscription_due_text_when_name_is_present', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'SUBSCRIPTION_DUE',
      params: { name: 'Netflix' },
    });

    const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.subscriptionDueTitle',
      { name: 'Netflix' },
      'fr',
    );
    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.subscriptionDueMessage',
      { name: 'Netflix' },
      'fr',
    );
    expect(result.title).toContain('notifications.list.subscriptionDueTitle');
  });

  it('should_return_raw_title_and_message_when_subscription_due_name_is_missing', () => {
    const transloco = translocoStub();
    const notification = makeNotification({ type: 'SUBSCRIPTION_DUE', params: {} });

    const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(result).toEqual({ title: 'Titre brut', message: 'Message brut' });
    expect(transloco.translate).not.toHaveBeenCalled();
  });

  it('should_build_debt_due_text_when_person_is_present', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'DEBT_DUE',
      params: { person: 'Alice' },
    });

    buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.debtDueTitle',
      { person: 'Alice' },
      'fr',
    );
  });

  it('should_return_raw_title_and_message_when_debt_due_person_is_missing', () => {
    const transloco = translocoStub();
    const notification = makeNotification({ type: 'DEBT_DUE', params: {} });

    const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(result).toEqual({ title: 'Titre brut', message: 'Message brut' });
  });

  it('should_format_amount_with_currency_when_debt_reminder_has_all_params', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'DEBT_REMINDER',
      params: { person: 'Bob', amount: '120.50', currency: 'EUR' },
    });

    buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.debtReminderTitle',
      { person: 'Bob', amount: formatCurrencyAmount(120.5, 'EUR', 'fr-FR') },
      'fr',
    );
  });

  it.each([
    ['person', { amount: '120.50', currency: 'EUR' }],
    ['amount', { person: 'Bob', currency: 'EUR' }],
    ['currency', { person: 'Bob', amount: '120.50' }],
  ])('should_return_raw_title_and_message_when_debt_reminder_is_missing_%s', (_paramName, params) => {
    const transloco = translocoStub();
    const notification = makeNotification({ type: 'DEBT_REMINDER', params });

    const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(result).toEqual({ title: 'Titre brut', message: 'Message brut' });
  });

  it.each<[NotificationType, string]>([
    ['BUDGET_THRESHOLD', 'notifications.list.budgetThresholdTitle'],
    ['BUDGET_EXCEEDED', 'notifications.list.budgetExceededTitle'],
  ])('should_translate_system_category_and_pass_percentage_when_type_is_%s', (type, titleKey) => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type,
      params: { category: 'Abonnement', categorySystemKey: 'SUBSCRIPTION', percentage: '85' },
    });

    buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(transloco.translate).toHaveBeenCalledWith(
      'categories.value.subscription',
      {},
      'fr',
    );
    expect(transloco.translate).toHaveBeenCalledWith(
      titleKey,
      { category: 'translated:categories.value.subscription', percentage: '85' },
      'fr',
    );
  });

  it('should_use_the_raw_category_name_when_category_system_key_is_absent', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'BUDGET_THRESHOLD',
      params: { category: 'Loisirs', percentage: '50' },
    });

    buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.budgetThresholdTitle',
      { category: 'Loisirs', percentage: '50' },
      'fr',
    );
  });

  it.each(['category', 'percentage'])(
    'should_return_raw_title_and_message_when_budget_threshold_is_missing_%s',
    (missingParam) => {
      const transloco = translocoStub();
      const params: Record<string, string> = { category: 'Loisirs', percentage: '50' };
      delete params[missingParam];
      const notification = makeNotification({ type: 'BUDGET_THRESHOLD', params });

      const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

      expect(result).toEqual({ title: 'Titre brut', message: 'Message brut' });
    },
  );

  it('should_format_amount_and_due_date_when_recurring_transaction_has_currency', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'RECURRING_TRANSACTION_DUE',
      params: { label: 'Loyer', amount: '850', currency: 'EUR', dueDate: '2026-10-01' },
    });

    buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.recurringTransactionDueTitle',
      { label: 'Loyer', amount: formatCurrencyAmount(850, 'EUR', 'fr-FR'), dueDate: '1 octobre 2026' },
      'fr',
    );
  });

  it('should_use_the_raw_amount_when_recurring_transaction_currency_is_missing', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'RECURRING_TRANSACTION_DUE',
      params: { label: 'Loyer', amount: '850', dueDate: '2026-10-01' },
    });

    buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.recurringTransactionDueTitle',
      { label: 'Loyer', amount: '850', dueDate: '1 octobre 2026' },
      'fr',
    );
  });

  it.each(['label', 'amount', 'dueDate'])(
    'should_return_raw_title_and_message_when_recurring_transaction_is_missing_%s',
    (missingParam) => {
      const transloco = translocoStub();
      const params: Record<string, string> = {
        label: 'Loyer',
        amount: '850',
        currency: 'EUR',
        dueDate: '2026-10-01',
      };
      delete params[missingParam];
      const notification = makeNotification({ type: 'RECURRING_TRANSACTION_DUE', params });

      const result = buildNotificationText(notification, transloco, 'fr', 'fr-FR');

      expect(result).toEqual({ title: 'Titre brut', message: 'Message brut' });
    },
  );

  it('should_return_raw_amount_when_amount_is_not_a_valid_number', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'DEBT_REMINDER',
      params: { person: 'Bob', amount: 'not-a-number', currency: 'EUR' },
    });

    buildNotificationText(notification, transloco, 'fr', 'fr-FR');

    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.debtReminderTitle',
      { person: 'Bob', amount: 'not-a-number' },
      'fr',
    );
  });

  it('should_translate_into_english_when_lang_is_en', () => {
    const transloco = translocoStub();
    const notification = makeNotification({
      type: 'SUBSCRIPTION_DUE',
      params: { name: 'Netflix' },
    });

    buildNotificationText(notification, transloco, 'en', 'en-GB');

    expect(transloco.translate).toHaveBeenCalledWith(
      'notifications.list.subscriptionDueTitle',
      { name: 'Netflix' },
      'en',
    );
  });
});
