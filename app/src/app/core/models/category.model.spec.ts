import { describe, it, expect } from 'vitest';

import { systemCategoryNameKey } from './category.model';

describe('systemCategoryNameKey', () => {
  it.each([
    ['SUBSCRIPTION', 'categories.value.subscription'],
    ['DEBT', 'categories.value.debt'],
    ['TRANSFER', 'categories.value.transfer'],
    ['ADJUSTMENT', 'categories.value.adjustment'],
  ])('should_return_the_translation_key_when_system_key_is_%s', (systemKey, expectedKey) => {
    expect(systemCategoryNameKey(systemKey)).toBe(expectedKey);
  });

  it('should_return_null_when_system_key_is_null', () => {
    expect(systemCategoryNameKey(null)).toBeNull();
  });

  it('should_return_null_when_system_key_is_undefined', () => {
    expect(systemCategoryNameKey(undefined)).toBeNull();
  });

  it('should_return_null_when_system_key_is_empty', () => {
    expect(systemCategoryNameKey('')).toBeNull();
  });

  it('should_return_null_when_system_key_is_unknown_to_this_client', () => {
    // Un serveur plus recent peut envoyer une valeur d'enum que ce client ne connait pas.
    expect(systemCategoryNameKey('SOMETHING_NEW')).toBeNull();
  });
});
