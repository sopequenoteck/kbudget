import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';

import { ExchangeRateService } from './exchange-rate';
import { ApiService } from './api';
import { type ExchangeRate } from '../models/exchange-rate.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

const MOCK_RATES: ExchangeRate[] = [
  { baseCurrency: 'EUR', targetCurrency: 'XOF', rate: 655.957 },
];

describe('ExchangeRateService', () => {
  let service: ExchangeRateService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
    put: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [
        ExchangeRateService,
        { provide: ApiService, useValue: apiService },
        ...provideTranslocoTesting(),
      ],
    });

    service = TestBed.inject(ExchangeRateService);
  });

  describe('loadRates()', () => {
    it('should_load_rates_when_api_succeeds', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_RATES));

      // Act
      await service.loadRates();

      // Assert
      expect(service.rates()).toEqual(MOCK_RATES);
      expect(service.error()).toBeNull();
      expect(service.loading()).toBe(false);
    });

    it('should_set_french_error_message_when_api_fails', async () => {
      // Arrange
      apiService.get.mockReturnValue(throwError(() => new Error('Network error')));

      // Act
      await service.loadRates();

      // Assert
      expect(service.rates()).toEqual([]);
      expect(service.error()).toBe('Impossible de charger les taux de change');
      expect(service.loading()).toBe(false);
    });
  });

  describe('upsert()', () => {
    it('should_put_rate_to_api', async () => {
      // Arrange
      const created: ExchangeRate = { baseCurrency: 'EUR', targetCurrency: 'XOF', rate: 655.957 };
      apiService.put.mockReturnValue(of(created));

      // Act
      const result = await service.upsert('EUR', 'XOF', 655.957).toPromise();

      // Assert
      expect(apiService.put).toHaveBeenCalledWith('/exchange-rates', {
        baseCurrency: 'EUR',
        targetCurrency: 'XOF',
        rate: 655.957,
      });
      expect(result).toEqual(created);
    });
  });

  describe('delete()', () => {
    it('should_delete_rate_from_api', async () => {
      // Arrange
      apiService.delete.mockReturnValue(of(undefined));

      // Act
      await service.delete('EUR', 'XOF').toPromise();

      // Assert
      expect(apiService.delete).toHaveBeenCalledWith('/exchange-rates/EUR/XOF');
    });
  });
});
