import { describe, it, expect, vi } from 'vitest';
import { TranslocoService } from '@jsverse/transloco';

import { categoryDisplayName } from './category-name.utils';

function translocoStub(): TranslocoService {
  return {
    translate: vi.fn((key: string) => `translated:${key}`),
  } as unknown as TranslocoService;
}

describe('categoryDisplayName', () => {
  it('should_translate_the_key_when_system_key_is_known', () => {
    const transloco = translocoStub();

    const result = categoryDisplayName('Abonnement-legacy', 'SUBSCRIPTION', transloco, 'fr');

    expect(result).toBe('translated:categories.value.subscription');
    expect(transloco.translate).toHaveBeenCalledWith('categories.value.subscription', {}, 'fr');
  });

  it('should_return_the_raw_name_when_system_key_is_null', () => {
    const transloco = translocoStub();

    expect(categoryDisplayName('Courses', null, transloco, 'fr')).toBe('Courses');
    expect(transloco.translate).not.toHaveBeenCalled();
  });

  it('should_return_the_raw_name_when_system_key_is_undefined', () => {
    const transloco = translocoStub();

    expect(categoryDisplayName('Courses', undefined, transloco, 'fr')).toBe('Courses');
  });

  it('should_return_the_raw_name_when_system_key_is_unknown_to_this_client', () => {
    const transloco = translocoStub();

    expect(categoryDisplayName('Nouvelle', 'SOMETHING_NEW', transloco, 'fr')).toBe('Nouvelle');
  });
});
