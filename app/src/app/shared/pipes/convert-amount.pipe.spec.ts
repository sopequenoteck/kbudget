import { TestBed } from '@angular/core/testing';

import { ConvertAmountPipe } from './convert-amount.pipe';
import { ConversionService } from '../../core/services/conversion';
import { LanguageService } from '../../core/services/language';

describe('ConvertAmountPipe', () => {
  let conversionServiceMock: { convert: ReturnType<typeof vi.fn> };
  let languageServiceMock: { displayLocale: ReturnType<typeof vi.fn> };
  let pipe: ConvertAmountPipe;

  beforeEach(() => {
    conversionServiceMock = {
      convert: vi.fn(),
    };
    languageServiceMock = {
      displayLocale: vi.fn().mockReturnValue('fr-FR'),
    };

    TestBed.configureTestingModule({
      providers: [
        { provide: ConversionService, useValue: conversionServiceMock },
        { provide: LanguageService, useValue: languageServiceMock },
      ],
    });

    pipe = TestBed.runInInjectionContext(() => new ConvertAmountPipe());
  });

  it('should_return_empty_string_when_from_currency_is_missing', () => {
    expect(pipe.transform(10, '', 'EUR')).toBe('');
  });

  it('should_return_empty_string_when_from_and_to_currencies_are_equal', () => {
    expect(pipe.transform(10, 'EUR', 'EUR')).toBe('');
  });

  it('should_return_empty_string_when_conversion_is_not_available', () => {
    conversionServiceMock.convert.mockReturnValue(null);
    expect(pipe.transform(10, 'USD', 'EUR')).toBe('');
  });

  it('should_format_converted_amount_with_known_symbol_when_currency_is_xof', () => {
    conversionServiceMock.convert.mockReturnValue(6550);
    const result = pipe.transform(10, 'EUR', 'XOF');
    expect(result).toContain('CFA');
    expect(result).not.toContain(',');
  });

  it('should_format_converted_amount_with_two_decimals_when_currency_is_not_xof', () => {
    conversionServiceMock.convert.mockReturnValue(11.5);
    const result = pipe.transform(10, 'USD', 'EUR');
    expect(result).toContain('€');
    expect(result).toContain('11,50');
  });

  it('should_fallback_to_currency_code_when_symbol_is_unknown', () => {
    conversionServiceMock.convert.mockReturnValue(10);
    const result = pipe.transform(10, 'EUR', 'JPY');
    expect(result).toContain('JPY');
  });

  it('should_use_locale_from_language_service_when_formatting', () => {
    conversionServiceMock.convert.mockReturnValue(11.5);
    pipe.transform(10, 'USD', 'EUR');
    expect(languageServiceMock.displayLocale).toHaveBeenCalled();
  });
});
