import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';

import { PreferenceService } from './preference';
import { ApiService } from './api';
import { type Feature, type UserPreference } from '../models/preference.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

const mockPreference: UserPreference = {
  enabledFeatures: ['SUBSCRIPTIONS', 'DEBTS'],
  navOrder: ['SUBSCRIPTIONS', 'DEBTS'],
};

describe('PreferenceService', () => {
  let service: PreferenceService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
    put: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      put: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [
        PreferenceService,
        { provide: ApiService, useValue: apiService },
        ...provideTranslocoTesting(),
      ],
    });

    service = TestBed.inject(PreferenceService);
  });

  describe('loadPreferences()', () => {
    it('should_load_preferences_when_called', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(mockPreference));

      // Act
      await service.loadPreferences();

      // Assert
      expect(apiService.get).toHaveBeenCalledWith('/users/me/preferences');
      expect(service.enabledFeatures()).toEqual(['SUBSCRIPTIONS', 'DEBTS']);
      expect(service.navOrder()).toEqual(['SUBSCRIPTIONS', 'DEBTS']);
      expect(service.error()).toBeNull();
    });

    it('should_set_error_when_api_fails', async () => {
      // Arrange
      apiService.get.mockReturnValue(throwError(() => new Error('fail')));

      // Act
      await service.loadPreferences();

      // Assert
      expect(service.error()).toBe('Impossible de charger les préférences');
    });
  });

  describe('toggleFeature()', () => {
    it('should_toggle_feature_on_when_disabled', () => {
      // Arrange — initial state: SUBSCRIPTIONS only
      apiService.get.mockReturnValue(
        of({ ...mockPreference, enabledFeatures: ['SUBSCRIPTIONS'], navOrder: ['SUBSCRIPTIONS'] }),
      );
      service.enabledFeatures.set(['SUBSCRIPTIONS']);
      service.navOrder.set(['SUBSCRIPTIONS']);
      apiService.put.mockReturnValue(of(mockPreference));

      // Act
      service.toggleFeature('DEBTS');

      // Assert
      expect(service.enabledFeatures()).toContain('DEBTS');
      expect(service.navOrder()).toContain('DEBTS');
      expect(apiService.put).toHaveBeenCalledWith('/users/me/preferences', {
        enabledFeatures: ['SUBSCRIPTIONS', 'DEBTS'],
      });
    });

    it('should_toggle_feature_off_when_enabled', () => {
      // Arrange — initial state: all features enabled
      service.enabledFeatures.set(['SUBSCRIPTIONS', 'DEBTS']);
      service.navOrder.set(['SUBSCRIPTIONS', 'DEBTS']);
      apiService.put.mockReturnValue(of(mockPreference));

      // Act
      service.toggleFeature('DEBTS');

      // Assert
      expect(service.enabledFeatures()).not.toContain('DEBTS');
      expect(service.navOrder()).not.toContain('DEBTS');
      expect(apiService.put).toHaveBeenCalledWith('/users/me/preferences', {
        enabledFeatures: ['SUBSCRIPTIONS'],
      });
    });

    it('should_set_french_error_message_when_save_fails', async () => {
      // Arrange
      service.enabledFeatures.set(['SUBSCRIPTIONS']);
      service.navOrder.set(['SUBSCRIPTIONS']);
      apiService.put.mockReturnValue(throwError(() => new Error('fail')));

      // Act
      service.toggleFeature('DEBTS');
      await Promise.resolve();

      // Assert
      expect(service.error()).toBe('Impossible de sauvegarder les préférences');
    });
  });

  describe('isEnabled()', () => {
    it('should_return_true_when_feature_enabled', () => {
      // Arrange
      service.enabledFeatures.set(['SUBSCRIPTIONS']);

      // Act & Assert
      expect(service.isEnabled('SUBSCRIPTIONS')).toBe(true);
    });

    it('should_return_false_when_feature_disabled', () => {
      // Arrange
      service.enabledFeatures.set(['SUBSCRIPTIONS']);

      // Act & Assert
      expect(service.isEnabled('DEBTS')).toBe(false);
    });
  });

  describe('reorderNavigation()', () => {
    it('should_reorder_navigation', () => {
      // Arrange
      const initialFeatures: Feature[] = ['SUBSCRIPTIONS', 'DEBTS'];
      service.enabledFeatures.set(initialFeatures);
      service.navOrder.set(['SUBSCRIPTIONS', 'DEBTS']);
      const newOrder: Feature[] = ['DEBTS', 'SUBSCRIPTIONS'];
      apiService.put.mockReturnValue(of(mockPreference));

      // Act
      service.reorderNavigation(newOrder);

      // Assert
      expect(service.navOrder()).toEqual(['DEBTS', 'SUBSCRIPTIONS']);
      expect(apiService.put).toHaveBeenCalledWith('/users/me/preferences', {
        enabledFeatures: initialFeatures,
        navOrder: newOrder,
      });
    });

    it('should_set_french_error_message_when_save_fails', async () => {
      // Arrange
      service.enabledFeatures.set(['SUBSCRIPTIONS']);
      service.navOrder.set(['SUBSCRIPTIONS']);
      apiService.put.mockReturnValue(throwError(() => new Error('fail')));

      // Act
      service.reorderNavigation(['SUBSCRIPTIONS']);
      await Promise.resolve();

      // Assert
      expect(service.error()).toBe("Impossible de sauvegarder l'ordre de navigation");
    });
  });

  describe('update()', () => {
    it('should_set_french_error_message_when_save_fails', async () => {
      // Arrange
      apiService.put.mockReturnValue(throwError(() => new Error('fail')));

      // Act
      service.updateTimezone('Europe/London');
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Assert
      expect(service.error()).toBe('Impossible de sauvegarder les préférences');
    });

    it('should_reload_rates_when_primary_currency_changes', async () => {
      // Arrange
      service.setCurrencies(['EUR']);
      apiService.put.mockReturnValue(of({ ...mockPreference, currencies: ['XOF'] }));
      apiService.get.mockReturnValue(of([]));

      // Act
      service.update({ currencies: ['XOF'] });
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Assert — declenche bien un rechargement des taux, la seule branche
      // observable : `ExchangeRateService.loadRates()` avale ses propres
      // erreurs (try/catch interne), si bien que le `.catch()` de ce site
      // d'appel — et la cle `settings.feedback.exchangeRatesStale` qu'il
      // traduit — ne sont jamais atteints en pratique (bug preexistant,
      // hors perimetre de KKS-374).
      expect(apiService.get).toHaveBeenCalledWith('/exchange-rates');
    });
  });
});
