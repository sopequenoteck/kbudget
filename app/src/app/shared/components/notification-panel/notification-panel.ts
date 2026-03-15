import { ChangeDetectionStrategy, Component, DestroyRef, inject, input, output, computed, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { Router } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorBellRinging,
  phosphorChecks,
  phosphorTrash,
  phosphorX,
  phosphorBell,
  phosphorWarning,
  phosphorCalendarCheck,
  phosphorHandCoins,
  phosphorRepeat,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';
import { NotificationService } from '../../../core/services/notification';
import { type NotificationModel, type NotificationType } from '../../../core/models/notification.model';
import { DebtService } from '../../../core/services/debt';
import { RecurringTransactionService } from '../../../core/services/recurring-transaction';
import { SubscriptionService } from '../../../core/services/subscription';
import { ToastService } from '../toast/toast.service';
import { type Debt } from '../../../core/models/debt.model';
import { RepayDialog } from '../../../features/debts/components/repay-dialog/repay-dialog';
import { SnoozeDialog } from '../../../features/debts/components/snooze-dialog/snooze-dialog';

@Component({
  selector: 'app-notification-panel',
  standalone: true,
  imports: [DatePipe, NgIcon, RepayDialog, SnoozeDialog],
  providers: [
    provideIcons({
      phosphorBellRinging,
      phosphorChecks,
      phosphorTrash,
      phosphorX,
      phosphorBell,
      phosphorWarning,
      phosphorCalendarCheck,
      phosphorHandCoins,
      phosphorRepeat,
    }),
  ],
  templateUrl: './notification-panel.html',
  styleUrl: './notification-panel.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationPanel {
  private readonly destroyRef = inject(DestroyRef);
  private readonly debtService = inject(DebtService);
  private readonly recurringTransactionService = inject(RecurringTransactionService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly toastService = inject(ToastService);
  private readonly router = inject(Router);
  readonly notificationService = inject(NotificationService);
  readonly isOpen = input(false);
  readonly closed = output<void>();
  readonly confirmDeleteAll = signal(false);
  readonly activeDebt = signal<Debt | null>(null);
  readonly activeNotification = signal<NotificationModel | null>(null);
  readonly showRepayDialog = signal(false);
  readonly showSnoozeDialog = signal(false);

  readonly groupedNotifications = computed(() => {
    const notifications = this.notificationService.notifications();
    const groups: { label: string; notifications: NotificationModel[] }[] = [];
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const getGroupLabel = (dateStr: string): string => {
      const date = new Date(dateStr);
      if (date.toDateString() === today.toDateString()) return "Aujourd'hui";
      if (date.toDateString() === yesterday.toDateString()) return 'Hier';
      return date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
    };

    for (const notification of notifications) {
      const label = getGroupLabel(notification.createdAt);
      let group = groups.find((g) => g.label === label);
      if (!group) {
        group = { label, notifications: [] };
        groups.push(group);
      }
      group.notifications.push(notification);
    }

    return groups;
  });

  getIconForType(type: NotificationType): string {
    switch (type) {
      case 'SUBSCRIPTION_DUE':
        return 'phosphorCalendarCheck';
      case 'DEBT_DUE':
        return 'phosphorHandCoins';
      case 'DEBT_REMINDER':
        return 'phosphorBellRinging';
      case 'BUDGET_THRESHOLD':
      case 'BUDGET_EXCEEDED':
        return 'phosphorWarning';
      case 'RECURRING_TRANSACTION_DUE':
        return 'phosphorRepeat';
      default:
        return 'phosphorBell';
    }
  }

  onNotificationClick(notification: NotificationModel): void {
    if (!notification.read) {
      this.notificationService.markAsRead(notification.id);
    }
  }

  onDelete(event: Event, id: string): void {
    event.stopPropagation();
    this.notificationService.deleteNotification(id);
  }

  onMarkAllRead(): void {
    this.notificationService.markAllAsRead();
  }

  onDeleteAll(): void {
    this.confirmDeleteAll.set(true);
  }

  cancelDeleteAll(): void {
    this.confirmDeleteAll.set(false);
  }

  executeDeleteAll(): void {
    this.notificationService.deleteAll();
    this.confirmDeleteAll.set(false);
  }

  onClose(): void {
    this.closed.emit();
  }

  async onRepayAction(event: Event, notification: NotificationModel): Promise<void> {
    event.stopPropagation();
    if (!notification.entityId) return;
    try {
      const debt = await firstValueFrom(this.debtService.getById(notification.entityId));
      this.activeDebt.set(debt);
      this.activeNotification.set(notification);
      this.showRepayDialog.set(true);
    } catch {
      this.toastService.error('Impossible de charger la dette');
    }
  }

  async onSnoozeAction(event: Event, notification: NotificationModel): Promise<void> {
    event.stopPropagation();
    if (!notification.entityId) return;
    try {
      const debt = await firstValueFrom(this.debtService.getById(notification.entityId));
      this.activeDebt.set(debt);
      this.activeNotification.set(notification);
      this.showSnoozeDialog.set(true);
    } catch {
      this.toastService.error('Impossible de charger la dette');
    }
  }

  onRepaid(_updatedDebt: Debt, notification: NotificationModel): void {
    this.showRepayDialog.set(false);
    this.activeDebt.set(null);
    this.toastService.success('Remboursement enregistré');
    this.notificationService.markAsRead(notification.id);
  }

  onSnoozed(_updatedDebt: Debt, notification: NotificationModel): void {
    this.showSnoozeDialog.set(false);
    this.activeDebt.set(null);
    this.toastService.success('Rappel reporté');
    this.notificationService.markAsRead(notification.id);
  }

  async onValidateRecurring(notification: NotificationModel): Promise<void> {
    if (!notification.entityId) return;
    try {
      await firstValueFrom(this.recurringTransactionService.validate(notification.entityId));
      this.toastService.success('Transaction créée');
      this.notificationService.markAsRead(notification.id);
    } catch {
      this.toastService.error('Impossible de valider la transaction');
    }
  }

  async onSkipRecurring(notification: NotificationModel): Promise<void> {
    if (!notification.entityId) return;
    try {
      await firstValueFrom(this.recurringTransactionService.skip(notification.entityId));
      this.toastService.success('Occurrence passée');
      this.notificationService.markAsRead(notification.id);
    } catch {
      this.toastService.error('Impossible de passer l\'occurrence');
    }
  }

  async onPaySubscription(notification: NotificationModel): Promise<void> {
    if (!notification.entityId) return;
    try {
      await firstValueFrom(this.subscriptionService.pay(notification.entityId));
      this.toastService.success('Paiement enregistré');
      this.notificationService.markAsRead(notification.id);
    } catch {
      this.toastService.error('Impossible d\'enregistrer le paiement');
    }
  }

  onNotificationTap(notification: NotificationModel): void {
    if (notification.type === 'RECURRING_TRANSACTION_DUE') {
      this.router.navigate(['/transactions/recurring']);
      this.closed.emit();
    } else if (notification.type === 'SUBSCRIPTION_DUE') {
      this.router.navigate(['/subscriptions', notification.entityId]);
      this.closed.emit();
    }
  }

  private scrollDebounceTimer: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    this.destroyRef.onDestroy(() => {
      if (this.scrollDebounceTimer) clearTimeout(this.scrollDebounceTimer);
    });
  }

  onScroll(event: Event): void {
    const el = event.target as HTMLElement;
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 100) {
      if (this.scrollDebounceTimer) clearTimeout(this.scrollDebounceTimer);
      this.scrollDebounceTimer = setTimeout(() => {
        this.notificationService.loadMore();
        this.scrollDebounceTimer = null;
      }, 150);
    }
  }
}
