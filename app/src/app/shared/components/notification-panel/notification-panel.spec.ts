import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';
import { signal, computed } from '@angular/core';

import { NotificationPanel } from './notification-panel';
import { NotificationService } from '../../../core/services/notification';
import { DebtService } from '../../../core/services/debt';
import { ToastService } from '../toast/toast.service';
import { type NotificationModel } from '../../../core/models/notification.model';
import { Debt, DebtType } from '../../../core/models/debt.model';
import { RecurringTransactionService } from '../../../core/services/recurring-transaction';
import { SubscriptionService } from '../../../core/services/subscription';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const makeNotification = (overrides: Partial<NotificationModel> = {}): NotificationModel => ({
  id: 'notif-1',
  type: 'SUBSCRIPTION_DUE',
  title: 'Abonnement',
  message: 'Votre abonnement arrive à échéance',
  entityType: 'SUBSCRIPTION',
  entityId: 'sub-1',
  read: false,
  readAt: null,
  createdAt: new Date().toISOString(),
  ...overrides,
});

const mockDebt: Debt = {
  id: 'debt-1',
  personne: 'Alice',
  montant: 200,
  montantRestant: 150,
  sens: DebtType.EMPRUNT,
  date: '2026-01-15',
  dueDate: null,
  rembourse: false,
  category: null,
  currency: 'EUR',
  account: null,
  includeInBalance: false,
  reminderDate: null,
  reminderTime: null,
};

describe('NotificationPanel', () => {
  let notificationServiceMock: {
    notifications: ReturnType<typeof signal>;
    unreadCount: ReturnType<typeof signal>;
    isLoading: ReturnType<typeof signal>;
    hasUnread: ReturnType<typeof computed>;
    hasMore: ReturnType<typeof signal>;
    currentPage: ReturnType<typeof signal>;
    markAsRead: ReturnType<typeof vi.fn>;
    markAllAsRead: ReturnType<typeof vi.fn>;
    deleteNotification: ReturnType<typeof vi.fn>;
    deleteAll: ReturnType<typeof vi.fn>;
    loadMore: ReturnType<typeof vi.fn>;
    loadNotifications: ReturnType<typeof vi.fn>;
  };

  let debtServiceMock: {
    getById: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof signal>;
  };

  let toastServiceMock: {
    success: ReturnType<typeof vi.fn>;
    error: ReturnType<typeof vi.fn>;
  };

  let recurringTransactionServiceMock: {
    validate: ReturnType<typeof vi.fn>;
    skip: ReturnType<typeof vi.fn>;
    deactivate: ReturnType<typeof vi.fn>;
  };

  let subscriptionServiceMock: {
    pay: ReturnType<typeof vi.fn>;
  };

  const createNotificationServiceMock = (notifications: NotificationModel[]) => {
    const notificationsSignal = signal(notifications);
    const unreadCountSignal = signal(notifications.filter((n) => !n.read).length);
    return {
      notifications: notificationsSignal,
      unreadCount: unreadCountSignal,
      isLoading: signal(false),
      hasUnread: computed(() => unreadCountSignal() > 0),
      hasMore: signal(false),
      currentPage: signal(0),
      markAsRead: vi.fn(),
      markAllAsRead: vi.fn(),
      deleteNotification: vi.fn(),
      deleteAll: vi.fn(),
      loadMore: vi.fn(),
      loadNotifications: vi.fn(),
    };
  };

  beforeEach(() => {
    notificationServiceMock = createNotificationServiceMock([]);

    debtServiceMock = {
      getById: vi.fn().mockReturnValue(of(mockDebt)),
      refreshTrigger: signal(0),
    };

    toastServiceMock = {
      success: vi.fn(),
      error: vi.fn(),
    };

    recurringTransactionServiceMock = {
      validate: vi.fn().mockReturnValue(of({})),
      skip: vi.fn().mockReturnValue(of({})),
      deactivate: vi.fn().mockReturnValue(of({})),
    };

    subscriptionServiceMock = {
      pay: vi.fn().mockReturnValue(of({})),
    };
  });

  const setupTestBed = () => {
    TestBed.configureTestingModule({
      imports: [NotificationPanel],
      providers: [
        { provide: NotificationService, useValue: notificationServiceMock },
        { provide: DebtService, useValue: debtServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
        { provide: RecurringTransactionService, useValue: recurringTransactionServiceMock },
        { provide: SubscriptionService, useValue: subscriptionServiceMock },
      ],
    });
  };

  it('should_create_the_component', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_show_action_buttons_for_debt_due_notification', () => {
    const debtDueNotification = makeNotification({
      id: 'notif-debt-due',
      type: 'DEBT_DUE',
      title: 'Dette échue',
      message: 'Alice doit vous rembourser',
      entityType: 'DEBT',
      entityId: 'debt-1',
    });
    notificationServiceMock = createNotificationServiceMock([debtDueNotification]);

    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.componentRef.setInput('isOpen', true);
    fixture.detectChanges();

    const actionButtons = fixture.nativeElement.querySelectorAll('.notification-action-btn');
    expect(actionButtons.length).toBeGreaterThanOrEqual(2);

    const buttonTexts = Array.from(actionButtons).map((btn: Element) =>
      (btn as HTMLElement).textContent?.trim(),
    );
    expect(buttonTexts).toContain('Rembourser');
    expect(buttonTexts).toContain('Reporter');
  });

  it('should_show_action_buttons_for_debt_reminder_notification', () => {
    const debtReminderNotification = makeNotification({
      id: 'notif-debt-reminder',
      type: 'DEBT_REMINDER',
      title: 'Rappel dette',
      message: 'Rappel : Bob vous doit de l\'argent',
      entityType: 'DEBT',
      entityId: 'debt-1',
    });
    notificationServiceMock = createNotificationServiceMock([debtReminderNotification]);

    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.componentRef.setInput('isOpen', true);
    fixture.detectChanges();

    const actionButtons = fixture.nativeElement.querySelectorAll('.notification-action-btn');
    expect(actionButtons.length).toBeGreaterThanOrEqual(2);

    const buttonTexts = Array.from(actionButtons).map((btn: Element) =>
      (btn as HTMLElement).textContent?.trim(),
    );
    expect(buttonTexts).toContain('Rembourser');
    expect(buttonTexts).toContain('Reporter');
  });

  it('should_show_pay_button_for_subscription_notification', () => {
    const subscriptionNotification = makeNotification({
      id: 'notif-sub',
      type: 'SUBSCRIPTION_DUE',
      title: 'Abonnement',
      message: 'Netflix arrive à échéance',
      entityType: 'SUBSCRIPTION',
      entityId: 'sub-1',
    });
    notificationServiceMock = createNotificationServiceMock([subscriptionNotification]);

    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.componentRef.setInput('isOpen', true);
    fixture.detectChanges();

    const actionButtons = fixture.nativeElement.querySelectorAll('.notification-action-btn');
    expect(actionButtons.length).toBe(1);
    expect(actionButtons[0].textContent.trim()).toBe('Payer');
  });

  it('should_not_show_action_buttons_for_budget_threshold_notification', () => {
    const budgetNotification = makeNotification({
      id: 'notif-budget',
      type: 'BUDGET_THRESHOLD',
      title: 'Budget',
      message: 'Seuil de budget atteint',
      entityType: null,
      entityId: null,
    });
    notificationServiceMock = createNotificationServiceMock([budgetNotification]);

    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.componentRef.setInput('isOpen', true);
    fixture.detectChanges();

    const actionButtons = fixture.nativeElement.querySelectorAll('.notification-action-btn');
    expect(actionButtons.length).toBe(0);
  });

  it('should_show_empty_state_when_no_notifications', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.componentRef.setInput('isOpen', true);
    fixture.detectChanges();

    const emptyState = fixture.nativeElement.querySelector('.empty-state');
    expect(emptyState).toBeTruthy();
  });

  it('should_not_render_panel_when_closed', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.componentRef.setInput('isOpen', false);
    fixture.detectChanges();

    const panel = fixture.nativeElement.querySelector('.notification-panel');
    expect(panel).toBeNull();
  });

  it('should_emit_closed_when_close_called', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.componentRef.setInput('isOpen', true);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let closedEmitted = false;
    component.closed.subscribe(() => {
      closedEmitted = true;
    });

    component.onClose();

    expect(closedEmitted).toBe(true);
  });

  it('should_load_debt_and_show_repay_dialog_when_repay_action_clicked', async () => {
    const debtDueNotification = makeNotification({
      id: 'notif-debt-due',
      type: 'DEBT_DUE',
      entityId: 'debt-1',
    });

    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const fakeEvent = { stopPropagation: vi.fn() } as unknown as Event;

    await component.onRepayAction(fakeEvent, debtDueNotification);

    expect(debtServiceMock.getById).toHaveBeenCalledWith('debt-1');
    expect(component.showRepayDialog()).toBe(true);
    expect(component.activeDebt()).toEqual(mockDebt);
  });

  it('should_show_error_toast_when_repay_action_fails', async () => {
    const { throwError } = await import('rxjs');

    const debtDueNotification = makeNotification({
      id: 'notif-debt-due',
      type: 'DEBT_DUE',
      entityId: 'debt-1',
    });

    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const fakeEvent = { stopPropagation: vi.fn() } as unknown as Event;

    debtServiceMock.getById.mockReturnValue(throwError(() => new Error('Not found')));

    await component.onRepayAction(fakeEvent, debtDueNotification);

    expect(toastServiceMock.error).toHaveBeenCalledWith('Impossible de charger la dette');
  });

  it('should_return_correct_icon_for_notification_types', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    const component = fixture.componentInstance;

    expect(component.getIconForType('SUBSCRIPTION_DUE')).toBe('phosphorCalendarCheck');
    expect(component.getIconForType('DEBT_DUE')).toBe('phosphorHandCoins');
    expect(component.getIconForType('DEBT_REMINDER')).toBe('phosphorBellRinging');
    expect(component.getIconForType('BUDGET_THRESHOLD')).toBe('phosphorWarning');
    expect(component.getIconForType('BUDGET_EXCEEDED')).toBe('phosphorWarning');
  });

  it('should_show_validate_skip_buttons_for_recurring_notification', () => {
    const recurringNotification = makeNotification({
      id: 'notif-recurring',
      type: 'RECURRING_TRANSACTION_DUE',
      title: 'Transaction récurrente',
      message: 'Loyer à valider',
      entityType: 'RECURRING_TRANSACTION',
      entityId: 'rec-1',
    });
    notificationServiceMock = createNotificationServiceMock([recurringNotification]);

    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    fixture.componentRef.setInput('isOpen', true);
    fixture.detectChanges();

    const actionButtons = fixture.nativeElement.querySelectorAll('.notification-action-btn');
    expect(actionButtons.length).toBeGreaterThanOrEqual(2);

    const buttonTexts = Array.from(actionButtons).map((btn: Element) =>
      (btn as HTMLElement).textContent?.trim(),
    );
    expect(buttonTexts).toContain('Valider');
    expect(buttonTexts).toContain('Passer');
  });

  it('should_return_repeat_icon_for_recurring_notification', () => {
    setupTestBed();
    const fixture = TestBed.createComponent(NotificationPanel);
    const component = fixture.componentInstance;

    expect(component.getIconForType('RECURRING_TRANSACTION_DUE')).toBe('phosphorRepeat');
  });
});
