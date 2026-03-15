import { Injectable, computed, inject, isDevMode, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { ApiService } from './api';
import { type NotificationType } from '../models/notification.model';
import {
  type Feature,
  type UserPreference,
  type UserPreferenceRequest,
} from '../models/preference.model';

@Injectable({
  providedIn: 'root',
})
export class PreferenceService {
  private readonly apiService = inject(ApiService);

  readonly enabledFeatures = signal<Feature[]>([]);
  readonly navOrder = signal<Feature[]>([]);
  readonly currencies = signal<string[]>(['EUR']);
  readonly primaryCurrency = computed(() => this.currencies()[0] ?? 'EUR');
  readonly enabledNotificationTypes = signal<NotificationType[]>(['SUBSCRIPTION_DUE', 'DEBT_DUE']);
  readonly timezone = signal<string>('Europe/Paris');
  readonly textScale = signal<string>('MEDIUM');
  readonly error = signal<string | null>(null);

  async loadPreferences(): Promise<void> {
    try {
      const prefs = await firstValueFrom(
        this.apiService.get<UserPreference>('/users/me/preferences'),
      );
      this.enabledFeatures.set(prefs.enabledFeatures);
      this.navOrder.set(prefs.navOrder);
      this.currencies.set(prefs.currencies ?? ['EUR']);
      this.enabledNotificationTypes.set(prefs.enabledNotificationTypes ?? ['SUBSCRIPTION_DUE', 'DEBT_DUE']);
      this.timezone.set(prefs.timezone ?? 'Europe/Paris');
      this.textScale.set(prefs.textScale ?? 'MEDIUM');
      this.error.set(null);
    } catch (e) {
      if (isDevMode()) console.error('Failed to load preferences:', e);
      this.error.set('Impossible de charger les préférences');
    }
  }

  toggleFeature(feature: Feature): void {
    const current = this.enabledFeatures();
    const enabled = current.includes(feature);
    const updated = enabled ? current.filter((f) => f !== feature) : [...current, feature];

    // Optimistic update
    this.enabledFeatures.set(updated);

    // Also update navOrder: remove if disabling, add at end if enabling
    if (enabled) {
      this.navOrder.update((order) => order.filter((f) => f !== feature));
    } else {
      this.navOrder.update((order) => [...order, feature]);
    }

    // Fire-and-forget PUT with enabledFeatures only (no navOrder — let backend auto-manage)
    const request: UserPreferenceRequest = { enabledFeatures: updated };
    firstValueFrom(this.apiService.put<UserPreference>('/users/me/preferences', request)).catch(
      (e) => {
        if (isDevMode()) console.error('Failed to update preferences:', e);
        this.error.set('Impossible de sauvegarder les préférences');
      },
    );
  }

  isEnabled(feature: Feature): boolean {
    return this.enabledFeatures().includes(feature);
  }

  isLoaded(): boolean {
    return this.enabledFeatures().length > 0;
  }

  update(request: Partial<UserPreferenceRequest>): void {
    const merged: UserPreferenceRequest = {
      enabledFeatures: this.enabledFeatures(),
      navOrder: this.navOrder(),
      currencies: this.currencies(),
      enabledNotificationTypes: this.enabledNotificationTypes(),
      timezone: this.timezone(),
      textScale: this.textScale(),
      ...request,
    };
    firstValueFrom(this.apiService.put<UserPreference>('/users/me/preferences', merged)).catch(
      (e) => {
        if (isDevMode()) console.error('Failed to update preferences:', e);
        this.error.set('Impossible de sauvegarder les préférences');
      },
    );
  }

  setCurrencies(currencies: string[]): void {
    this.currencies.set(currencies);
  }

  updateNotificationTypes(types: NotificationType[]): void {
    this.enabledNotificationTypes.set(types);
    this.update({ enabledNotificationTypes: types });
  }

  updateTimezone(tz: string): void {
    this.timezone.set(tz);
    this.update({ timezone: tz });
  }

  updateTextScale(scale: string): void {
    this.textScale.set(scale);
    this.update({ textScale: scale });
  }

  reorderNavigation(newNavOrder: Feature[]): void {
    // Optimistic update
    this.navOrder.set(newNavOrder);

    // PUT with both enabledFeatures and navOrder (per design decision D5)
    const request: UserPreferenceRequest = {
      enabledFeatures: this.enabledFeatures(),
      navOrder: newNavOrder,
    };
    firstValueFrom(this.apiService.put<UserPreference>('/users/me/preferences', request)).catch(
      (e) => {
        if (isDevMode()) console.error('Failed to reorder navigation:', e);
        this.error.set("Impossible de sauvegarder l'ordre de navigation");
      },
    );
  }
}
