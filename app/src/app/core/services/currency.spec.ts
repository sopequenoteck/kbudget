import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { of } from 'rxjs';

import { CurrencyService } from './currency';
import { ApiService } from './api';
import { PreferenceService } from './preference';
import { type CurrencyInfo } from '../models/currency.model';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

const MOCK_CURRENCIES: CurrencyInfo[] = [
  { code: 'EUR', symbol: '€', name: 'Euro', decimalPlaces: 2 },
  { code: 'USD', symbol: '$', name: 'Dollar américain', decimalPlaces: 2 },
  { code: 'XYZ', symbol: 'Z', name: 'Zorkmid', decimalPlaces: 2 },
];

describe('CurrencyService', () => {
  let service: CurrencyService;
  let preferenceService: PreferenceService;
  let apiService: { get: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    apiService = { get: vi.fn() };

    TestBed.configureTestingModule({
      providers: [
        CurrencyService,
        { provide: ApiService, useValue: apiService },
        ...provideTranslocoTesting(),
      ],
    });

    service = TestBed.inject(CurrencyService);
    preferenceService = TestBed.inject(PreferenceService);
  });

  describe('getAll()', () => {
    it('should_populate_currencies_when_api_succeeds', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_CURRENCIES));

      // Act
      await service.getAll().toPromise();

      // Assert
      expect(service.currencies()).toEqual(MOCK_CURRENCIES);
    });
  });

  describe('loadIfEmpty()', () => {
    it('should_call_the_api_when_no_currency_is_loaded', () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_CURRENCIES));

      // Act
      service.loadIfEmpty();

      // Assert
      expect(apiService.get).toHaveBeenCalledWith('/currencies');
    });

    it('should_do_nothing_when_currencies_are_already_loaded', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_CURRENCIES));
      await service.getAll().toPromise();
      apiService.get.mockClear();

      // Act
      service.loadIfEmpty();

      // Assert
      expect(apiService.get).not.toHaveBeenCalled();
    });
  });

  describe('currencyItems', () => {
    it('should_translate_the_name_of_a_supported_currency_in_french', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_CURRENCIES));
      await service.getAll().toPromise();

      // Act
      const items = service.currencyItems();

      // Assert — KKS-393 : la traduction remplace le nom francais brut de
      // l'API pour un code de la liste fermee des devises supportees.
      expect(items).toEqual([
        { id: 'EUR', label: 'EUR - €', secondaryText: 'Euro', icon: null, color: null },
        { id: 'USD', label: 'USD - $', secondaryText: 'Dollar US', icon: null, color: null },
        { id: 'XYZ', label: 'XYZ - Z', secondaryText: 'Zorkmid', icon: null, color: null },
      ]);
    });

    it('should_fall_back_to_the_api_provided_name_for_a_currency_outside_the_closed_list', async () => {
      // Arrange — XYZ n'est pas dans SUPPORTED_CURRENCIES.
      apiService.get.mockReturnValue(of([MOCK_CURRENCIES[2]]));
      await service.getAll().toPromise();

      // Act
      const items = service.currencyItems();

      // Assert
      expect(items).toEqual([
        { id: 'XYZ', label: 'XYZ - Z', secondaryText: 'Zorkmid', icon: null, color: null },
      ]);
    });

    it('should_translate_the_name_in_english_when_the_active_language_changes', async () => {
      // Arrange
      apiService.get.mockReturnValue(of([MOCK_CURRENCIES[1]]));
      await service.getAll().toPromise();
      expect(service.currencyItems()[0].secondaryText).toBe('Dollar US');

      // Act — la reevaluation suit `activeLanguage()`, lu avant de traduire.
      // `activeLanguage` ne bascule qu'apres chargement du catalogue
      // (KKS-380) : il faut laisser la promesse de `LanguageService` se
      // resoudre avant de lire `currencyItems()`.
      TestBed.inject(TranslocoService).load('en').subscribe();
      preferenceService.language.set('en');
      TestBed.tick();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Assert
      expect(service.currencyItems()[0].secondaryText).toBe('US Dollar');
    });
  });
});
