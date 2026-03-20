import { Injectable, inject, signal, computed, isDevMode, DestroyRef } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { ApiService } from './api';
import { type NotificationModel, type NotificationPage } from '../models/notification.model';

@Injectable({
  providedIn: 'root',
})
export class NotificationService {
  private readonly apiService = inject(ApiService);
  private readonly destroyRef = inject(DestroyRef);

  readonly notifications = signal<NotificationModel[]>([]);
  readonly unreadCount = signal(0);
  readonly isLoading = signal(false);
  readonly hasMore = signal(true);
  readonly currentPage = signal(0);
  readonly hasUnread = computed(() => this.unreadCount() > 0);

  private pollingInterval: ReturnType<typeof setInterval> | null = null;

  constructor() {
    this.destroyRef.onDestroy(() => this.stopPolling());
  }

  async loadNotifications(): Promise<void> {
    this.isLoading.set(true);
    try {
      const page = await firstValueFrom(
        this.apiService.get<NotificationPage>('/notifications?page=0&size=20'),
      );
      this.notifications.set(page.content);
      this.currentPage.set(0);
      this.hasMore.set(page.number < page.totalPages - 1);
    } catch (e) {
      if (isDevMode()) console.error('Failed to load notifications:', e);
    } finally {
      this.isLoading.set(false);
    }
  }

  async loadMore(): Promise<void> {
    if (!this.hasMore() || this.isLoading()) return;
    const nextPage = this.currentPage() + 1;
    this.isLoading.set(true);
    try {
      const page = await firstValueFrom(
        this.apiService.get<NotificationPage>(`/notifications?page=${nextPage}&size=20`),
      );
      this.notifications.update((current) => [...current, ...page.content]);
      this.currentPage.set(page.number);
      this.hasMore.set(page.number < page.totalPages - 1);
    } catch (e) {
      if (isDevMode()) console.error('Failed to load more notifications:', e);
    } finally {
      this.isLoading.set(false);
    }
  }

  async loadUnreadCount(): Promise<void> {
    try {
      const result = await firstValueFrom(
        this.apiService.get<{ count: number }>('/notifications/unread-count'),
      );
      this.unreadCount.set(result.count);
    } catch (e) {
      if (isDevMode()) console.error('Failed to load unread count:', e);
    }
  }

  async markAsRead(id: string): Promise<void> {
    const notification = this.notifications().find((n) => n.id === id);
    if (!notification || notification.read) return;
    const previousNotifications = this.notifications();
    const previousUnreadCount = this.unreadCount();
    this.notifications.update((list) =>
      list.map((n) => (n.id === id ? { ...n, read: true, readAt: new Date().toISOString() } : n)),
    );
    this.unreadCount.update((c) => Math.max(0, c - 1));
    try {
      await firstValueFrom(this.apiService.put<NotificationModel>(`/notifications/${id}/read`, {}));
    } catch (e) {
      this.notifications.set(previousNotifications);
      this.unreadCount.set(previousUnreadCount);
      if (isDevMode()) console.error('Failed to mark as read:', e);
    }
  }

  async markAllAsRead(): Promise<void> {
    const previousNotifications = this.notifications();
    const previousUnreadCount = this.unreadCount();
    this.notifications.update((list) =>
      list.map((n) => ({ ...n, read: true, readAt: new Date().toISOString() })),
    );
    this.unreadCount.set(0);
    try {
      await firstValueFrom(this.apiService.put<void>('/notifications/read-all', {}));
    } catch (e) {
      this.notifications.set(previousNotifications);
      this.unreadCount.set(previousUnreadCount);
      if (isDevMode()) console.error('Failed to mark all as read:', e);
    }
  }

  async deleteNotification(id: string): Promise<void> {
    const previousNotifications = this.notifications();
    const previousUnreadCount = this.unreadCount();
    const removed = this.notifications().find((n) => n.id === id);
    this.notifications.update((list) => list.filter((n) => n.id !== id));
    if (removed && !removed.read) {
      this.unreadCount.update((c) => Math.max(0, c - 1));
    }
    try {
      await firstValueFrom(this.apiService.delete<void>(`/notifications/${id}`));
    } catch (e) {
      this.notifications.set(previousNotifications);
      this.unreadCount.set(previousUnreadCount);
      if (isDevMode()) console.error('Failed to delete notification:', e);
    }
  }

  async deleteAll(): Promise<void> {
    const previousNotifications = this.notifications();
    const previousUnreadCount = this.unreadCount();
    this.notifications.set([]);
    this.unreadCount.set(0);
    try {
      await firstValueFrom(this.apiService.delete<void>('/notifications'));
    } catch (e) {
      this.notifications.set(previousNotifications);
      this.unreadCount.set(previousUnreadCount);
      if (isDevMode()) console.error('Failed to delete all notifications:', e);
    }
  }

  addNotification(notification: NotificationModel): void {
    if (this.notifications().some((n) => n.id === notification.id)) return;
    this.notifications.update((list) => [notification, ...list]);
    if (!notification.read) {
      this.unreadCount.update((c) => c + 1);
    }
  }

  startPolling(): void {
    this.stopPolling();
    this.loadUnreadCount();
    this.pollingInterval = setInterval(() => this.loadUnreadCount(), 30000);
  }

  stopPolling(): void {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
      this.pollingInterval = null;
    }
  }
}
