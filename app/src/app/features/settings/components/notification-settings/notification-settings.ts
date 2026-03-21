import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowLeft,
  phosphorWarning,
  phosphorCalendarCheck,
  phosphorHandCoins,
} from '@ng-icons/phosphor-icons/regular';

import { PreferenceService } from '../../../../core/services/preference';
import { type NotificationType } from '../../../../core/models/notification.model';

interface NotificationTypeConfig {
  type: NotificationType;
  label: string;
  description: string;
  icon: string;
}

const NOTIFICATION_TYPES: NotificationTypeConfig[] = [
  {
    type: 'SUBSCRIPTION_DUE',
    label: 'Rappels abonnements',
    description: "Notification la veille d'une échéance d'abonnement",
    icon: 'phosphorCalendarCheck',
  },
  {
    type: 'DEBT_DUE',
    label: 'Rappels dettes',
    description: "Notification la veille d'une échéance de dette",
    icon: 'phosphorHandCoins',
  },
];

@Component({
  selector: 'app-notification-settings',
  standalone: true,
  imports: [RouterLink, NgIcon],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorWarning,
      phosphorCalendarCheck,
      phosphorHandCoins,
    }),
  ],
  template: `
    <div class="settings-page">
      <a class="section-back" routerLink="/settings">
        <ng-icon name="phosphorArrowLeft" size="20" /> Réglages
      </a>
      <h1>Notifications</h1>

      <section class="settings-section">
        <h2>Types de notifications</h2>
        @for (config of notificationTypes; track config.type) {
          <div class="setting-row">
            <div class="setting-info">
              <ng-icon [name]="config.icon" size="20" />
              <div>
                <div class="setting-label">{{ config.label }}</div>
                <div class="setting-description">{{ config.description }}</div>
              </div>
            </div>
            <label class="toggle">
              <input
                type="checkbox"
                [checked]="isTypeEnabled(config.type)"
                (change)="toggleType(config.type)"
              />
              <span class="toggle-slider"></span>
            </label>
          </div>
        }
      </section>

      <section class="settings-section">
        <h2>Fuseau horaire</h2>
        <div class="setting-row">
          <div class="setting-info">
            <div>
              <div class="setting-label">Fuseau horaire</div>
              <div class="setting-description">Pour le calcul des rappels J-1</div>
            </div>
          </div>
          <select
            class="timezone-select"
            [value]="timezone()"
            (change)="onTimezoneChange($event)"
          >
            @for (tz of timezones; track tz) {
              <option [value]="tz">{{ tz }}</option>
            }
          </select>
        </div>
      </section>
    </div>
  `,
  styles: [`
    .settings-page {
      max-width: 640px;
      margin: 0 auto;
      padding: var(--space-4, 16px);
    }
    .section-back {
      display: inline-flex;
      align-items: center;
      gap: var(--space-2, 8px);
      color: var(--text-secondary);
      text-decoration: none;
      font-size: var(--font-sm, 14px);
      margin-bottom: var(--space-4, 16px);
    }
    h1 {
      font-size: var(--font-xl, 24px);
      font-weight: 600;
      margin: 0 0 var(--space-6, 24px);
    }
    .settings-section {
      margin-bottom: var(--space-6, 24px);
    }
    .settings-section h2 {
      font-size: var(--font-sm, 14px);
      font-weight: 600;
      color: var(--text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin: 0 0 var(--space-3, 12px);
    }
    .setting-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: var(--space-3, 12px) 0;
      border-bottom: 1px solid var(--border-primary, #e5e7eb);
    }
    .setting-info {
      display: flex;
      align-items: center;
      gap: var(--space-3, 12px);
    }
    .setting-label {
      font-size: var(--font-sm, 14px);
      font-weight: 500;
    }
    .setting-description {
      font-size: var(--font-xs, 12px);
      color: var(--text-secondary);
      margin-top: 2px;
    }
    .toggle {
      position: relative;
      display: inline-block;
      width: 44px;
      height: 24px;
      flex-shrink: 0;
    }
    .toggle input {
      opacity: 0;
      width: 0;
      height: 0;
    }
    .toggle-slider {
      position: absolute;
      cursor: pointer;
      inset: 0;
      background-color: var(--bg-tertiary, #d1d5db);
      border-radius: 12px;
      transition: background-color 0.2s;
    }
    .toggle-slider::before {
      content: '';
      position: absolute;
      height: 18px;
      width: 18px;
      left: 3px;
      bottom: 3px;
      background-color: white;
      border-radius: 50%;
      transition: transform 0.2s;
    }
    .toggle input:checked + .toggle-slider {
      background-color: var(--color-primary, #f59e0b);
    }
    .toggle input:checked + .toggle-slider::before {
      transform: translateX(20px);
    }
    .timezone-select {
      padding: var(--space-2, 8px) var(--space-3, 12px);
      border: 1px solid var(--border-primary, #e5e7eb);
      border-radius: var(--radius-md, 8px);
      background: var(--bg-primary, #fff);
      color: var(--text-primary);
      font-size: var(--font-sm, 14px);
    }
  `],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationSettings {
  private readonly preferenceService = inject(PreferenceService);

  readonly notificationTypes = NOTIFICATION_TYPES;
  readonly enabledTypes = this.preferenceService.enabledNotificationTypes;
  readonly timezone = this.preferenceService.timezone;
  readonly timezones = [
    'Europe/Paris', 'Europe/London', 'Europe/Berlin', 'Europe/Madrid',
    'Europe/Rome', 'Europe/Brussels', 'Africa/Casablanca', 'Africa/Lome', 'Africa/Tunis',
    'Africa/Lagos', 'Africa/Abidjan', 'America/New_York', 'America/Chicago',
    'America/Los_Angeles', 'Asia/Tokyo', 'Asia/Shanghai',
  ];

  isTypeEnabled(type: NotificationType): boolean {
    return this.enabledTypes().includes(type);
  }

  toggleType(type: NotificationType): void {
    const current = this.enabledTypes();
    const updated = current.includes(type)
      ? current.filter((t) => t !== type)
      : [...current, type];
    this.preferenceService.updateNotificationTypes(updated);
  }

  onTimezoneChange(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    this.preferenceService.updateTimezone(value);
  }
}
