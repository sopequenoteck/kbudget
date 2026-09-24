import fr from '../../../../public/i18n/fr.json';
import en from '../../../../public/i18n/en.json';

/**
 * Verifie les catalogues livres par KKS-373 contre la convention de
 * `docs/i18n.md` (FR-015, SC-004, SC-013, US6 scenario 3-4) : trois segments,
 * domaine et contexte pris dans les listes fermees du document, element en
 * anglais lowerCamelCase, et parite stricte des deux ensembles de cles.
 *
 * Les listes ci-dessous sont une copie des tableaux « Domains » et
 * « Contexts » de `docs/i18n.md` — les etendre y est un changement de
 * document, pas un changement de test.
 */
const DOMAINS = [
  'accounts',
  'transactions',
  'recurring',
  'subscriptions',
  'debts',
  'budgets',
  'categories',
  'imports',
  'exchangeRates',
  'notifications',
  'users',
  'auth',
  'settings',
  'onboarding',
  'compatibility',
  'common',
  'errors',
  'dashboard',
] as const;

const GENERAL_CONTEXTS = [
  'page',
  'form',
  'list',
  'detail',
  'dialog',
  'empty',
  'filter',
  'action',
  'feedback',
  'summary',
  'value',
] as const;

const COMMON_ONLY_CONTEXTS = ['nav', 'validation'] as const;
const ERRORS_ONLY_CONTEXTS = ['api', 'client'] as const;

const LOWER_CAMEL_CASE = /^[a-z][a-zA-Z0-9]*$/;

function flattenKeys(node: unknown, prefix = ''): string[] {
  if (typeof node !== 'object' || node === null) {
    return [prefix];
  }
  return Object.entries(node as Record<string, unknown>).flatMap(([segment, value]) =>
    flattenKeys(value, prefix ? `${prefix}.${segment}` : segment),
  );
}

function isValidKey(key: string): boolean {
  const segments = key.split('.');
  if (segments.length !== 3) {
    return false;
  }
  const [domain, context, element] = segments;
  if (!(DOMAINS as readonly string[]).includes(domain)) {
    return false;
  }
  if (!LOWER_CAMEL_CASE.test(element)) {
    return false;
  }
  if (domain === 'errors') {
    return (ERRORS_ONLY_CONTEXTS as readonly string[]).includes(context);
  }
  if ((COMMON_ONLY_CONTEXTS as readonly string[]).includes(context)) {
    return domain === 'common';
  }
  return (GENERAL_CONTEXTS as readonly string[]).includes(context);
}

const frenchKeys = flattenKeys(fr).sort();
const englishKeys = flattenKeys(en).sort();

describe('catalogues i18n', () => {
  it('should_expose_the_same_key_set_in_french_and_english', () => {
    // Assert — SC-004 : parite stricte, dans les deux sens.
    expect(frenchKeys).toEqual(englishKeys);
  });

  it.each(frenchKeys)('should_have_three_conventional_segments_when_key_is_%s', (key) => {
    // Assert — SC-013 : domaine et contexte dans les listes fermees,
    // element en lowerCamelCase.
    expect(isValidKey(key)).toBe(true);
  });

  it('should_not_be_empty', () => {
    // Garde-fou contre un catalogue vide qui rendrait les tests ci-dessus
    // vacuously true.
    expect(frenchKeys.length).toBeGreaterThan(0);
  });
});
