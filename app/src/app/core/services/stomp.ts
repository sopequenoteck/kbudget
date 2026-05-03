import { Injectable, inject, DestroyRef } from '@angular/core';
import { Client } from '@stomp/stompjs';
import { NotificationService } from './notification';
import { AuthService } from './auth';
import { ExchangeRateService } from './exchange-rate';
import { type NotificationModel } from '../models/notification.model';
import { DevLogger } from './dev-logger';

@Injectable({
  providedIn: 'root',
})
export class StompService {
  private readonly notificationService = inject(NotificationService);
  private readonly authService = inject(AuthService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly destroyRef = inject(DestroyRef);
  private readonly logger = inject(DevLogger);

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
        this.logger.error('STOMP connected');
        this.notificationService.stopPolling();

        this.client!.subscribe('/user/queue/notifications', (message) => {
          const notification: NotificationModel = JSON.parse(message.body);
          this.notificationService.addNotification(notification);
        });

        this.client!.subscribe('/user/queue/exchange-rates', (message) => {
          const event = JSON.parse(message.body);
          if (event?.type === 'EXCHANGE_RATES_UPDATED') {
            this.exchangeRateService.loadRates();
          }
        });
      },
      onDisconnect: () => {
        this.logger.error('STOMP disconnected');
      },
      onStompError: (frame) => {
        this.logger.error('STOMP error:', frame.headers['message']);
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
