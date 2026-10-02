import { TestBed } from '@angular/core/testing';

import { ConvertAmountPipe } from './convert-amount.pipe';
import { ConversionService } from '../../core/services/conversion';
import { LanguageService } from '../../core/services/language';

// Intl insère une espace insécable (U+00A0 ou U+202F selon l'ICU) entre le
// montant et la devise : on la normalise pour comparer à une chaîne
// littérale sans dépendre de la version d'ICU de l'environnement de test.
function normalizeSpaces(value: string): string {
  return value.replace(/[\u00A0\u202F]/g, ' ');
}

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

  it('should_format_converted_amount_without_decimals_when_currency_is_xof', () => {
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

  it('should_format_converted_amount_with_intl_currency_display_when_currency_is_jpy', () => {
    conversionServiceMock.convert.mockReturnValue(10);
    const result = pipe.transform(10, 'EUR', 'JPY');
    expect(result).toContain('JPY');
  });

  it('should_use_locale_from_language_service_when_formatting', () => {
    conversionServiceMock.convert.mockReturnValue(11.5);
    pipe.transform(10, 'USD', 'EUR');
    expect(languageServiceMock.displayLocale).toHaveBeenCalled();
  });

  it('should_place_currency_symbol_before_amount_when_locale_is_en', () => {
    languageServiceMock.displayLocale.mockReturnValue('en-GB');
    conversionServiceMock.convert.mockReturnValue(11.5);
    const result = pipe.transform(10, 'USD', 'EUR');
    expect(result).toBe('~ €11.50');
  });

  it('should_place_currency_symbol_after_amount_when_locale_is_fr', () => {
    languageServiceMock.displayLocale.mockReturnValue('fr-FR');
    conversionServiceMock.convert.mockReturnValue(11.5);
    const result = pipe.transform(10, 'USD', 'EUR');
    expect(result).toContain('11,50');
    expect(result.indexOf('€')).toBeGreaterThan(result.indexOf('11,50'));
  });

  it('should_reformat_with_new_locale_when_display_locale_changes_between_calls', () => {
    conversionServiceMock.convert.mockReturnValue(11.5);
    languageServiceMock.displayLocale.mockReturnValue('fr-FR');
    const resultFr = pipe.transform(10, 'USD', 'EUR');

    languageServiceMock.displayLocale.mockReturnValue('en-GB');
    const resultEn = pipe.transform(10, 'USD', 'EUR');

    expect(normalizeSpaces(resultFr)).toBe('~ 11,50 €');
    expect(normalizeSpaces(resultEn)).toBe('~ €11.50');
  });
});
