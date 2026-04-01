import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCalendarCheck,
  phosphorCaretLeft,
  phosphorGlobe,
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
      phosphorCalendarCheck,
      phosphorCaretLeft,
      phosphorGlobe,
      phosphorHandCoins,
    }),
  ],
  templateUrl: './notification-settings.html',
  styleUrl: './notification-settings.scss',
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
