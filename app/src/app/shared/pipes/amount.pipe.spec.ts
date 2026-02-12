import { describe, it, expect } from 'vitest';
import { AmountPipe } from './amount.pipe';

describe('AmountPipe', () => {
  const pipe = new AmountPipe();

  // Helper : normalise les espaces insécables en espaces normaux pour assertions lisibles
  const normalize = (s: string) => s.replace(/[\u00A0\u202F\u2009]/g, ' ');

  it('should_format_with_plus_when_RECETTE', () => {
    const result = normalize(pipe.transform(2100, 'RECETTE'));
    expect(result).toContain('+');
    expect(result).toContain('2');
    expect(result).toContain('100,00');
    expect(result).toContain('€');
  });

  it('should_format_with_minus_when_DEPENSE', () => {
    const result = normalize(pipe.transform(9.99, 'DEPENSE'));
    expect(result).toContain('-');
    expect(result).toContain('9,99');
    expect(result).toContain('€');
  });

  it('should_format_with_plus_when_PRET', () => {
    const result = normalize(pipe.transform(500, 'PRET'));
    expect(result).toContain('+');
    expect(result).toContain('500,00');
    expect(result).toContain('€');
  });

  it('should_format_with_minus_when_EMPRUNT', () => {
    const result = normalize(pipe.transform(150, 'EMPRUNT'));
    expect(result).toContain('-');
    expect(result).toContain('150,00');
    expect(result).toContain('€');
  });

  it('should_format_without_sign_when_no_type', () => {
    const result = normalize(pipe.transform(1500.5));
    expect(result).not.toMatch(/^[+-]/);
    expect(result).toContain('1');
    expect(result).toContain('500,50');
    expect(result).toContain('€');
  });

  it('should_format_zero_without_sign', () => {
    const result = normalize(pipe.transform(0, 'DEPENSE'));
    expect(result).not.toMatch(/[+-]/);
    expect(result).toContain('0,00');
    expect(result).toContain('€');
  });

  it('should_return_empty_string_when_null', () => {
    expect(pipe.transform(null)).toBe('');
  });

  it('should_return_empty_string_when_undefined', () => {
    expect(pipe.transform(undefined)).toBe('');
  });

  it('should_handle_large_amounts', () => {
    const result = normalize(pipe.transform(1000000, 'RECETTE'));
    expect(result).toContain('+');
    expect(result).toContain('1');
    expect(result).toContain('000');
    expect(result).toContain('000,00');
    expect(result).toContain('€');
  });

  it('should_handle_negative_value_without_type', () => {
    const result = normalize(pipe.transform(-50));
    expect(result).toContain('-');
    expect(result).toContain('50,00');
    expect(result).toContain('€');
  });
});
