import { describe, it, expect } from 'vitest';
import { RelativeDatePipe } from './relative-date.pipe';

describe('RelativeDatePipe', () => {
  const pipe = new RelativeDatePipe();

  /** Retourne la date ISO (YYYY-MM-DD) de `n` jours avant aujourd'hui */
  function daysAgo(n: number): string {
    const d = new Date();
    d.setDate(d.getDate() - n);
    return d.toISOString().split('T')[0];
  }

  it('should_return_aujourdhui_when_today', () => {
    expect(pipe.transform(daysAgo(0))).toBe("Aujourd'hui");
  });

  it('should_return_hier_when_yesterday', () => {
    expect(pipe.transform(daysAgo(1))).toBe('Hier');
  });

  it('should_return_demain_when_tomorrow', () => {
    expect(pipe.transform(daysAgo(-1))).toBe('Demain');
  });

  it('should_return_il_y_a_X_jours_when_2_to_7_days', () => {
    expect(pipe.transform(daysAgo(3))).toBe('il y a 3 jours');
  });

  it('should_return_il_y_a_7_jours_when_exactly_7_days', () => {
    expect(pipe.transform(daysAgo(7))).toBe('il y a 7 jours');
  });

  it('should_return_il_y_a_1_semaine_when_8_days', () => {
    expect(pipe.transform(daysAgo(8))).toBe('il y a 1 semaine');
  });

  it('should_return_il_y_a_X_semaines_when_14_to_30_days', () => {
    expect(pipe.transform(daysAgo(14))).toBe('il y a 2 semaines');
  });

  it('should_return_long_date_when_over_30_days', () => {
    const result = pipe.transform(daysAgo(45));
    // Le format long fr-FR contient un nom de mois en toutes lettres
    expect(result).toMatch(/^\d{1,2}.+\d{4}$/);
    expect(result).not.toBe('');
  });

  it('should_return_long_date_when_future_beyond_tomorrow', () => {
    const result = pipe.transform(daysAgo(-5));
    // Date future au-delà de demain → format long fr-FR
    expect(result).toMatch(/^\d{1,2}.+\d{4}$/);
    expect(result).not.toBe('');
  });

  it('should_return_empty_string_when_null', () => {
    expect(pipe.transform(null)).toBe('');
  });

  it('should_return_empty_string_when_undefined', () => {
    expect(pipe.transform(undefined)).toBe('');
  });

  it('should_return_empty_string_when_invalid_date', () => {
    expect(pipe.transform('abc')).toBe('');
  });

  it('should_return_empty_string_when_empty_string', () => {
    expect(pipe.transform('')).toBe('');
  });
});
