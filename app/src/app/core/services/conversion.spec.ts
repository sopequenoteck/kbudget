import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';

import { ConversionService } from './conversion';
import { ExchangeRateService } from './exchange-rate';
import { PreferenceService } from './preference';
import { ExchangeRate } from '../models/exchange-rate.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockRate = (base: string, target: string, rate: number): ExchangeRate => ({
  id: `${base}_${target}`,
  baseCurrency: base,
  targetCurrency: target,
  rate,
  updatedAt: '2026-01-01T00:00:00Z',
});

describe('ConversionService', () => {
  let service: ConversionService;
  let exchangeRateService: { rates: ReturnType<typeof vi.fn> };
  let preferenceService: { primaryCurrency: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    exchangeRateService = { rates: vi.fn().mockReturnValue([]) };
    preferenceService = { primaryCurrency: vi.fn().mockReturnValue('EUR') };

    TestBed.configureTestingModule({
      providers: [
        ConversionService,
        { provide: ExchangeRateService, useValue: exchangeRateService },
        { provide: PreferenceService, useValue: preferenceService },
      ],
    });

    service = TestBed.inject(ConversionService);
  });

  test('should_convertAmount_when_rateAvailable', () => {
    // Arrange
    exchangeRateService.rates.mockReturnValue([mockRate('EUR', 'XOF', 655.957)]);

    // Act
    const result = service.convert(10, 'EUR', 'XOF');

    // Assert
    expect(result).toBe(6560); // 10 * 655.957 = 6559.57 → arrondi XOF = 6560
  });

  test('should_returnNull_when_noRate', () => {
    // Arrange
    exchangeRateService.rates.mockReturnValue([]);

    // Act
    const result = service.convert(100, 'EUR', 'USD');

    // Assert
    expect(result).toBeNull();
  });

  test('should_indicateCanConvert_when_rateExists', () => {
    // Arrange — taux direct disponible
    exchangeRateService.rates.mockReturnValue([mockRate('EUR', 'USD', 1.08)]);

    // Act & Assert
    expect(service.canConvert('EUR', 'USD')).toBe(true);
  });

  test('should_handleSameCurrency_when_converting', () => {
    // Arrange — aucun taux nécessaire quand devises identiques
    exchangeRateService.rates.mockReturnValue([]);

    // Act
    const result = service.convert(42, 'EUR', 'EUR');

    // Assert
    expect(result).toBe(42);
    expect(service.canConvert('EUR', 'EUR')).toBe(true);
  });
});
