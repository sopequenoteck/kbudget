import { Injectable, computed, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { TranslocoService } from '@jsverse/transloco';

import { ApiService } from './api';
import { ExchangeRateService } from './exchange-rate';
import { type NotificationType } from '../models/notification.model';
import {
  type Feature,
  type UserPreference,
  type UserPreferenceRequest,
} from '../models/preference.model';
import { DevLogger } from './dev-logger';

@Injectable({
  providedIn: 'root',
})
export class PreferenceService {
  private readonly apiService = inject(ApiService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly logger = inject(DevLogger);
  private readonly transloco = inject(TranslocoService);

  readonly enabledFeatures = signal<Feature[]>([]);
  readonly navOrder = signal<Feature[]>([]);
  readonly currencies = signal<string[]>(['EUR']);
  readonly primaryCurrency = computed(() => this.currencies()[0] ?? 'EUR');
  readonly enabledNotificationTypes = signal<NotificationType[]>(['SUBSCRIPTION_DUE', 'DEBT_DUE']);
  readonly timezone = signal<string>('Europe/Paris');
  readonly textScale = signal<string>('MEDIUM');
  /**
   * Langue choisie par l'utilisateur, `null` tant qu'il n'a rien choisi
   * (KKS-373). Source de {@link LanguageService}. Aucune ecriture client
   * dans ce lot : pas de `update...` correspondant a `updateTextScale`.
   */
  readonly language = signal<string | null>(null);
  readonly error = signal<string | null>(null);
  /**
   * Passe a `true` apres un chargement reussi (KKS-380). Distinct
   * d'{@link isLoaded}, qui reste fonde sur `enabledFeatures().length` pour
   * ses consommateurs actuels (`feature.guard`) — faux pour un compte sans
   * fonctionnalite activee, alors que {@link loaded} l'est. Consomme par
   * `LanguageService` : tant qu'il vaut `false`, une preference de langue
   * nulle ne signifie pas encore « le serveur confirme l'absence de choix ».
   */
  readonly loaded = signal(false);

  async loadPreferences(): Promise<void> {
    try {
      const prefs = await firstValueFrom(
        this.apiService.get<UserPreference>('/users/me/preferences'),
      );
      this.enabledFeatures.set(prefs.enabledFeatures);
      this.navOrder.set(prefs.navOrder);
      this.currencies.set(prefs.currencies ?? ['EUR']);
      this.enabledNotificationTypes.set(
        prefs.enabledNotificationTypes ?? ['SUBSCRIPTION_DUE', 'DEBT_DUE'],
      );
      this.timezone.set(prefs.timezone ?? 'Europe/Paris');
      this.textScale.set(prefs.textScale ?? 'MEDIUM');
      this.language.set(prefs.language ?? null);
      this.error.set(null);
      this.loaded.set(true);
    } catch (e) {
      this.logger.error('Failed to load preferences:', e);
      this.error.set(this.transloco.translate('settings.feedback.loadError'));
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
        this.logger.error('Failed to update preferences:', e);
        this.error.set(this.transloco.translate('settings.feedback.saveError'));
      },
    );
  }

  isEnabled(feature: Feature): boolean {
    return this.enabledFeatures().includes(feature);
  }

  isLoaded(): boolean {
    return this.enabledFeatures().length > 0;
  }

  /**
   * Corps complet d'un `PUT /users/me/preferences` (remplacement integral) :
   * l'etat courant de chaque champ, `language` omis s'il vaut `null` (KKS-380 —
   * jamais envoye a `null`, la remise a `null` passe par
   * `DELETE .../preferences/language`), puis les `overrides` demandes.
   */
  private buildPreferenceRequest(
    overrides: Partial<UserPreferenceRequest> = {},
  ): UserPreferenceRequest {
    const language = this.language();
    return {
      enabledFeatures: this.enabledFeatures(),
      navOrder: this.navOrder(),
      currencies: this.currencies(),
      enabledNotificationTypes: this.enabledNotificationTypes(),
      timezone: this.timezone(),
      textScale: this.textScale(),
      ...(language ? { language } : {}),
      ...overrides,
    };
  }

  update(request: Partial<UserPreferenceRequest>): void {
    const oldPrimary = this.currencies()[0];
    const merged = this.buildPreferenceRequest(request);
    firstValueFrom(this.apiService.put<UserPreference>('/users/me/preferences', merged))
      .then(() => {
        const newPrimary = merged.currencies?.[0];
        if (newPrimary && newPrimary !== oldPrimary) {
          this.exchangeRateService.loadRates().catch(() => {
            this.error.set(this.transloco.translate('settings.feedback.exchangeRatesStale'));
          });
        }
      })
      .catch((e) => {
        this.logger.error('Failed to update preferences:', e);
        this.error.set(this.transloco.translate('settings.feedback.saveError'));
      });
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

  /**
   * Choisit une langue explicite (KKS-380). Optimiste, sans revert
   * automatique dans {@link update} (aucun des autres champs n'en a besoin) :
   * ici le revert est manuel, la langue affichee devant rester correcte meme
   * hors ligne.
   */
  setLanguage(language: string): void {
    const previous = this.language();
    if (previous === language) {
      return;
    }
    this.language.set(language);
    firstValueFrom(
      this.apiService.put<UserPreference>(
        '/users/me/preferences',
        this.buildPreferenceRequest({ language }),
      ),
    ).catch((e) => {
      this.logger.error('Failed to update language preference:', e);
      this.language.set(previous);
      this.error.set(this.transloco.translate('settings.feedback.saveError'));
    });
  }

  /** Revient au choix « Automatique » (KKS-380) : `DELETE`, pas un `PUT`
   * avec `language: null` — la preference n'accepte que `'en' | 'fr'`. */
  clearLanguage(): void {
    const previous = this.language();
    if (previous === null) {
      return;
    }
    this.language.set(null);
    firstValueFrom(this.apiService.delete<void>('/users/me/preferences/language')).catch((e) => {
      this.logger.error('Failed to reset language preference:', e);
      this.language.set(previous);
      this.error.set(this.transloco.translate('settings.feedback.saveError'));
    });
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
        this.logger.error('Failed to reorder navigation:', e);
        this.error.set(this.transloco.translate('settings.feedback.navOrderSaveError'));
      },
    );
  }
}
