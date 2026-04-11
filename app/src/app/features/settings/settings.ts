import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  computed,
  inject,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorSun,
  phosphorMoon,
  phosphorCircleHalf,
  phosphorCalendarCheck,
  phosphorHandCoins,
  phosphorGlobe,
  phosphorHouse,
  phosphorCurrencyDollar,
  phosphorLock,
  phosphorDotsSixVertical,
  phosphorArrowsClockwise,
  phosphorHandshake,
  phosphorStorefront,
  phosphorBank,
  phosphorTag,
  phosphorCamera,
  phosphorSignOut,
  phosphorChartPie,
} from '@ng-icons/phosphor-icons/regular';
import { CdkDragDrop, CdkDropList, CdkDrag, CdkDragHandle, moveItemInArray } from '@angular/cdk/drag-drop';
import { firstValueFrom } from 'rxjs';
import packageJson from '../../../../package.json';

import { AuthService } from '../../core/services/auth';
import { UserService } from '../../core/services/user';
import { ThemeService, type Theme } from '../../core/services/theme';
import { TextScaleService, type TextScale } from '../../core/services/text-scale';
import { PreferenceService } from '../../core/services/preference';
import { SubscriptionService } from '../../core/services/subscription';
import { DebtService } from '../../core/services/debt';
import { HealthService, type HealthCheckResult } from '../../core/services/health';
import { FEATURES, type Feature } from '../../core/models/preference.model';
import { type NotificationType } from '../../core/models/notification.model';

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
  selector: 'app-settings',
  standalone: true,
  imports: [RouterLink, NgIcon, CdkDropList, CdkDrag, CdkDragHandle],
  providers: [
    provideIcons({
      phosphorSun,
      phosphorMoon,
      phosphorCircleHalf,
      phosphorCalendarCheck,
      phosphorHandCoins,
      phosphorGlobe,
      phosphorHouse,
      phosphorCurrencyDollar,
      phosphorLock,
      phosphorDotsSixVertical,
      phosphorArrowsClockwise,
      phosphorHandshake,
      phosphorStorefront,
      phosphorBank,
      phosphorTag,
      phosphorCamera,
      phosphorSignOut,
      phosphorChartPie,
    }),
  ],
  templateUrl: './settings.html',
  styleUrl: './settings.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Settings implements OnInit {
  private readonly authService = inject(AuthService);
  private readonly userService = inject(UserService);
  private readonly themeService = inject(ThemeService);
  readonly textScaleService = inject(TextScaleService);
  readonly preferenceService = inject(PreferenceService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly debtService = inject(DebtService);
  private readonly healthService = inject(HealthService);

  readonly currentUser = this.authService.currentUser;
  readonly currentTheme = this.themeService.currentTheme;
  readonly currentTextScale = this.textScaleService.currentTextScale;
  readonly enabledTypes = this.preferenceService.enabledNotificationTypes;
  readonly timezone = this.preferenceService.timezone;
  readonly features = FEATURES;
  readonly notificationTypes = NOTIFICATION_TYPES;
  readonly version = packageJson.version;
  readonly serverInfo = this.healthService.getServerInfo();

  readonly timezones = [
    'Europe/Paris', 'Europe/London', 'Europe/Berlin', 'Europe/Madrid',
    'Europe/Rome', 'Europe/Brussels', 'Africa/Casablanca', 'Africa/Lome', 'Africa/Tunis',
    'Africa/Lagos', 'Africa/Abidjan', 'America/New_York', 'America/Chicago',
    'America/Los_Angeles', 'Asia/Tokyo', 'Asia/Shanghai',
  ];

  readonly confirmDisableFeature = signal<Feature | null>(null);

  readonly healthResult = signal<HealthCheckResult>({
    status: 'checking',
    responseTimeMs: null,
    error: null,
    checkedAt: null,
  });

  readonly enabledNavItems = computed(() => {
    const navOrder = this.preferenceService.navOrder();
    const enabled = this.preferenceService.enabledFeatures();
    return navOrder
      .filter((f) => enabled.includes(f))
      .map((f) => FEATURES.find((m) => m.value === f)!);
  });

  readonly disabledNavItems = computed(() => {
    const enabled = this.preferenceService.enabledFeatures();
    return FEATURES.filter((f) => !enabled.includes(f.value));
  });

  constructor() {
    firstValueFrom(this.userService.getProfile());
  }

  async ngOnInit(): Promise<void> {
    try {
      const result = await firstValueFrom(this.healthService.checkHealth());
      this.healthResult.set(result);
    } catch {
      this.healthResult.set({
        status: 'offline',
        responseTimeMs: null,
        error: 'Erreur inconnue',
        checkedAt: null,
      });
    }
  }

  getInitials(name: string): string {
    return name
      .split(' ')
      .map((part) => part[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  }

  setTheme(theme: Theme): void {
    this.themeService.setTheme(theme);
  }

  setTextScale(scale: TextScale): void {
    this.textScaleService.setTextScale(scale);
  }

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

  async toggleFeature(feature: Feature): Promise<void> {
    const isCurrentlyEnabled = this.preferenceService.isEnabled(feature);

    if (isCurrentlyEnabled) {
      const hasData = await this.checkFeatureHasData(feature);
      if (hasData) {
        this.confirmDisableFeature.set(feature);
        return;
      }
    }

    this.preferenceService.toggleFeature(feature);
  }

  confirmDisable(): void {
    const feature = this.confirmDisableFeature();
    if (feature) {
      this.preferenceService.toggleFeature(feature);
      this.confirmDisableFeature.set(null);
    }
  }

  cancelDisable(): void {
    this.confirmDisableFeature.set(null);
  }

  onDrop(event: CdkDragDrop<unknown>): void {
    const items = [...this.enabledNavItems()];
    moveItemInArray(items, event.previousIndex, event.currentIndex);
    this.preferenceService.reorderNavigation(items.map((i) => i.value));
  }

  private async checkFeatureHasData(feature: Feature): Promise<boolean> {
    try {
      if (feature === 'SUBSCRIPTIONS') {
        const subs = await firstValueFrom(this.subscriptionService.getAll());
        return subs.length > 0;
      }
      if (feature === 'DEBTS') {
        const debts = await firstValueFrom(this.debtService.getAll());
        return debts.length > 0;
      }
      return false;
    } catch {
      return false;
    }
  }
}
