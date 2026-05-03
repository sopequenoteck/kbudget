import { normalize } from './string.utils';

describe('normalize', () => {
  it('should_lowercase_string', () => {
    expect(normalize('Hello')).toBe('hello');
  });

  it('should_remove_accents_from_lowercase', () => {
    expect(normalize('café')).toBe('cafe');
  });

  it('should_remove_accents_from_uppercase', () => {
    expect(normalize('ÉCONOMIE')).toBe('economie');
  });

  it('should_handle_mixed_case_with_accents', () => {
    expect(normalize('Café')).toBe('cafe');
  });

  it('should_return_empty_string_when_input_is_empty', () => {
    expect(normalize('')).toBe('');
  });

  it('should_be_idempotent_when_called_twice', () => {
    const result = normalize('Éléphant');
    expect(normalize(result)).toBe(result);
  });

  it('should_handle_multiple_diacritics', () => {
    expect(normalize('crème brûlée')).toBe('creme brulee');
  });

  it('should_normalize_uppercase_accented_string', () => {
    expect(normalize('Île-de-France')).toBe('ile-de-france');
  });
});
