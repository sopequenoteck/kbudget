import { ChangeDetectionStrategy, Component, DestroyRef, inject, input, output, computed, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
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
} from '@ng-icons/phosphor-icons/regular';
import { NotificationService } from '../../../core/services/notification';
import { type NotificationModel, type NotificationType } from '../../../core/models/notification.model';

@Component({
  selector: 'app-notification-panel',
  standalone: true,
  imports: [DatePipe, NgIcon],
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
    }),
  ],
  templateUrl: './notification-panel.html',
  styleUrl: './notification-panel.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationPanel {
  private readonly destroyRef = inject(DestroyRef);
  readonly notificationService = inject(NotificationService);
  readonly isOpen = input(false);
  readonly closed = output<void>();
  readonly confirmDeleteAll = signal(false);

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
