import {
  getCurrencySymbol,
  formatCurrencyAmount,
  insertSortedByNom,
  formatUpcomingDays,
  formatMonthYearLabel,
} from './locale-format.utils';

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

describe('formatUpcomingDays', () => {
  it('should_return_aujourdhui_when_diff_is_zero', () => {
    expect(formatUpcomingDays(0, new Date('2026-01-01'), 'fr-FR')).toBe("aujourd'hui");
  });

  it('should_return_demain_when_diff_is_one', () => {
    expect(formatUpcomingDays(1, new Date('2026-01-01'), 'fr-FR')).toBe('demain');
  });

  it('should_return_days_count_when_diff_is_between_two_and_thirty', () => {
    expect(formatUpcomingDays(15, new Date('2026-01-01'), 'fr-FR')).toBe('dans 15 j.');
  });

  it('should_return_short_date_when_diff_is_above_thirty', () => {
    const result = formatUpcomingDays(45, new Date('2026-03-15'), 'fr-FR');
    expect(result).not.toContain('dans');
    expect(result).not.toBe("aujourd'hui");
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
