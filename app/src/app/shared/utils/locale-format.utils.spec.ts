import {
  getCurrencySymbol,
  formatCurrencyAmount,
  insertSortedByNom,
  formatMonthYearLabel,
  formatFullDateLabel,
  formatSignedPercent,
  formatDayMonthLabel,
} from './locale-format.utils';

// Intl insère une espace insécable (U+00A0 ou U+202F selon l'ICU) avant le
// signe "%" en fr-FR : on la normalise en espace classique pour comparer à
// une chaîne littérale sans dépendre de la version d'ICU.
function normalizeSpaces(value: string): string {
  return value.replace(/[\u00A0\u202F]/g, ' ');
}

describe('getCurrencySymbol', () => {
  it('should_return_euro_symbol_when_currency_is_eur_and_locale_is_fr', () => {
    expect(getCurrencySymbol('EUR', 'fr-FR')).toBe('€');
  });

  it('should_return_dollar_symbol_when_currency_is_usd_and_locale_is_en', () => {
    expect(getCurrencySymbol('USD', 'en-US')).toBe('$');
  });

  it('should_return_xof_symbol_without_decimals_when_currency_is_xof', () => {
    expect(getCurrencySymbol('XOF', 'fr-FR')).not.toContain(',');
  });
});

describe('formatCurrencyAmount', () => {
  it('should_format_amount_with_euro_symbol_when_locale_is_fr', () => {
    expect(formatCurrencyAmount(12.5, 'EUR', 'fr-FR')).toContain('12,50');
  });

  it('should_format_amount_without_decimals_when_currency_is_xof', () => {
    const result = formatCurrencyAmount(1000, 'XOF', 'fr-FR');
    expect(result).not.toContain(',');
    expect(result).not.toContain('.');
  });
});

describe('insertSortedByNom', () => {
  it('should_insert_item_in_alphabetical_order_when_locale_is_fr', () => {
    const items = [{ nom: 'Alimentation' }, { nom: 'Transport' }];
    const result = insertSortedByNom(items, { nom: 'Loisirs' }, 'fr-FR');
    expect(result.map((i) => i.nom)).toEqual(['Alimentation', 'Loisirs', 'Transport']);
  });

  it('should_not_mutate_original_array_when_inserting', () => {
    const items = [{ nom: 'Alimentation' }];
    insertSortedByNom(items, { nom: 'Loisirs' }, 'fr-FR');
    expect(items.length).toBe(1);
  });

  it('should_sort_accented_names_correctly_when_locale_is_fr', () => {
    const items = [{ nom: 'Économie' }, { nom: 'Autre' }];
    const result = insertSortedByNom(items, { nom: 'Épargne' }, 'fr-FR');
    expect(result.map((i) => i.nom)).toEqual(['Autre', 'Économie', 'Épargne']);
  });
});

describe('formatMonthYearLabel', () => {
  it('should_format_month_and_year_when_locale_is_fr', () => {
    expect(formatMonthYearLabel(new Date(2026, 2, 15), 'fr-FR')).toBe('mars 2026');
  });

  it('should_format_month_and_year_when_locale_is_en', () => {
    const result = formatMonthYearLabel(new Date(2026, 2, 15), 'en-US');
    expect(result).toContain('2026');
    expect(result.toLowerCase()).toContain('march');
  });
});

describe('formatFullDateLabel', () => {
  it('should_format_day_month_and_year_when_locale_is_fr', () => {
    expect(formatFullDateLabel('2026-10-01', 'fr-FR')).toBe('1 octobre 2026');
  });

  it('should_format_day_month_and_year_when_locale_is_en', () => {
    const result = formatFullDateLabel('2026-10-01', 'en-GB');
    expect(result).toContain('2026');
    expect(result.toLowerCase()).toContain('october');
  });

  it('should_not_shift_the_date_by_a_day_when_timezone_is_negative', () => {
    // La date ISO est ancrée à minuit local (KKS-397) : un fuseau UTC-N ne
    // doit jamais faire reculer le jour affiché.
    expect(formatFullDateLabel('2026-01-01', 'fr-FR')).toBe('1 janvier 2026');
  });
});

describe('formatSignedPercent', () => {
  it.each([
    [64.4, 'fr-FR', '+64,4 %'],
    [64.4, 'en-GB', '+64.4%'],
    [-64.4, 'en-GB', '-64.4%'],
    [0, 'fr-FR', '+0,0 %'],
    [64.49, 'en-GB', '+64.5%'],
  ])(
    'should_format_signed_percent_when_value_is_%s_and_locale_is_%s',
    (percent, locale, expected) => {
      expect(normalizeSpaces(formatSignedPercent(percent, locale))).toBe(expected);
    },
  );

  it('should_use_comma_as_decimal_separator_when_locale_is_fr', () => {
    expect(formatSignedPercent(64.4, 'fr-FR')).toContain(',');
  });

  it('should_not_contain_any_space_when_locale_is_en', () => {
    expect(formatSignedPercent(64.4, 'en-GB')).not.toMatch(/\s/);
  });
});

describe('formatDayMonthLabel', () => {
  it.each([
    ['2026-09-27', 'fr-FR', '27 septembre'],
    ['2026-09-27', 'en-GB', '27 September'],
    ['2026-01-01', 'fr-FR', '1 janvier'],
  ])(
    'should_format_day_and_month_of_local_date_when_value_is_%s_and_locale_is_%s',
    (isoDate, locale, expected) => {
      expect(formatDayMonthLabel(isoDate, locale)).toBe(expected);
    },
  );
});
