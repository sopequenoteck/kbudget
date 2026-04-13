import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of, throwError } from 'rxjs';

import { PreferenceService } from './preference';
import { ApiService } from './api';
import { type Feature, type UserPreference } from '../models/preference.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

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
      providers: [PreferenceService, { provide: ApiService, useValue: apiService }],
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
  });
});
