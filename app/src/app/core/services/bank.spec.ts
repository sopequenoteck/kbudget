import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of, throwError } from 'rxjs';

import { BankService } from './bank';
import { ApiService } from './api';
import { type BankResponse } from '../models/bank.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const MOCK_BANKS: BankResponse[] = [
  { code: 'SG', name: 'Société Générale', country: 'FR', brandColor: '#e2001a', logoUrl: '/api/bank-logos/sg.svg' },
  { code: 'BNP', name: 'BNP Paribas', country: 'FR', brandColor: '#009d57', logoUrl: '/api/bank-logos/bnp.svg' },
  { code: 'OTHER', name: 'Autre', country: null, brandColor: null, logoUrl: null },
];

describe('BankService', () => {
  let service: BankService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
    };

    TestBed.configureTestingModule({
      providers: [BankService, { provide: ApiService, useValue: apiService }],
    });

    service = TestBed.inject(BankService);
  });

  describe('loadBanks()', () => {
    it('should_load_banks_from_api', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_BANKS));

      // Act
      await service.loadBanks();

      // Assert
      expect(apiService.get).toHaveBeenCalledWith('/banks');
      expect(service.banks()).toEqual(MOCK_BANKS);
      expect(service.banks()).toHaveLength(3);
      expect(service.error()).toBeNull();
    });

    it('should_cache_banks_after_first_load', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_BANKS));

      // Act — call loadBanks() twice
      await service.loadBanks();
      await service.loadBanks();

      // Assert — only ONE GET /banks request issued
      expect(apiService.get).toHaveBeenCalledTimes(1);
      expect(apiService.get).toHaveBeenCalledWith('/banks');
    });

    it('should_handle_api_error_gracefully', async () => {
      // Arrange
      apiService.get.mockReturnValue(throwError(() => new Error('Network error')));

      // Act
      await service.loadBanks();

      // Assert
      expect(service.banks()).toEqual([]);
      expect(service.error()).toBe('Impossible de charger les banques');
    });
  });

  describe('getBankByCode()', () => {
    it('should_return_bank_when_code_exists', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_BANKS));
      await service.loadBanks();

      // Act
      const result = service.getBankByCode('SG');

      // Assert
      expect(result).toEqual({
        code: 'SG',
        name: 'Société Générale',
        country: 'FR',
        brandColor: '#e2001a',
        logoUrl: '/api/bank-logos/sg.svg',
      });
    });

    it('should_return_undefined_when_code_not_found', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_BANKS));
      await service.loadBanks();

      // Act
      const result = service.getBankByCode('UNKNOWN');

      // Assert
      expect(result).toBeUndefined();
    });

    it('should_return_undefined_when_banks_not_loaded', () => {
      // Act — no loadBanks() call
      const result = service.getBankByCode('SG');

      // Assert
      expect(result).toBeUndefined();
    });
  });

  describe('getBankLogoUrl()', () => {
    it('should_return_logo_url_when_bank_has_logo', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_BANKS));
      await service.loadBanks();

      // Act
      const result = service.getBankLogoUrl('BNP');

      // Assert
      expect(result).toBe('/api/bank-logos/bnp.svg');
    });

    it('should_return_null_when_bank_logo_is_null', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_BANKS));
      await service.loadBanks();

      // Act
      const result = service.getBankLogoUrl('OTHER');

      // Assert
      expect(result).toBeNull();
    });

    it('should_return_null_when_bank_not_found', async () => {
      // Arrange
      apiService.get.mockReturnValue(of(MOCK_BANKS));
      await service.loadBanks();

      // Act
      const result = service.getBankLogoUrl('UNKNOWN');

      // Assert
      expect(result).toBeNull();
    });
  });
});
