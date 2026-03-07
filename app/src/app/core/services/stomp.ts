import { Injectable, inject, isDevMode, DestroyRef } from '@angular/core';
import { Client } from '@stomp/stompjs';
import { NotificationService } from './notification';
import { AuthService } from './auth';
import { type NotificationModel } from '../models/notification.model';

@Injectable({
  providedIn: 'root',
})
export class StompService {
  private readonly notificationService = inject(NotificationService);
  private readonly authService = inject(AuthService);
  private readonly destroyRef = inject(DestroyRef);

  private client: Client | null = null;

  constructor() {
    this.destroyRef.onDestroy(() => this.disconnect());
  }

  connect(): void {
    if (this.client?.active) return;

    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
    const brokerURL = `${protocol}//${location.host}/api/ws`;

    this.client = new Client({
      brokerURL,
      reconnectDelay: 5000,
      heartbeatIncoming: 10000,
      heartbeatOutgoing: 10000,
      beforeConnect: () => {
        const token = this.authService.getToken();
        if (token) {
          this.client!.connectHeaders = { Authorization: `Bearer ${token}` };
        } else {
          this.disconnect();
        }
      },
      onConnect: () => {
        if (isDevMode()) console.log('STOMP connected');
        this.notificationService.stopPolling();

        this.client!.subscribe('/user/queue/notifications', (message) => {
          const notification: NotificationModel = JSON.parse(message.body);
          this.notificationService.addNotification(notification);
        });
      },
      onDisconnect: () => {
        if (isDevMode()) console.log('STOMP disconnected');
      },
      onStompError: (frame) => {
        if (isDevMode()) console.error('STOMP error:', frame.headers['message']);
      },
      onWebSocketClose: () => {
        this.notificationService.startPolling();
      },
    });

    this.client.activate();
  }

  disconnect(): void {
    this.notificationService.stopPolling();
    if (this.client?.active) {
      this.client.deactivate();
    }
    this.client = null;
  }
}
