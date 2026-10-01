import { readFileSync, readdirSync } from 'node:fs';
import { parse, type Token } from '@messageformat/parser';

import { SUPPORTED_LANGUAGES } from '../services/language';

/**
 * Verifie les catalogues livres par KKS-373 contre la convention de
 * `docs/i18n.md` (FR-015, SC-004, SC-013, US6 scenario 3-4) : trois segments,
 * domaine et contexte pris dans les listes fermees du document, element en
 * anglais lowerCamelCase.
 *
 * Depuis KKS-439 (« Adding a language » de `docs/i18n.md`), tout catalogue
 * present dans `public/i18n/` est compare a `en.json`, la reference : aucune
 * cle inconnue, toutes les cles pour une langue activee, memes arguments ICU,
 * ICU valide.
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

// « Never name the widget » (`docs/i18n.md`, Element) : KKS-374 a d'abord
// livre `bankNameLabel`, que rien ne refusait.
const WIDGET_WORD = /Button|Field|Picker|Switch|Label|Badge/;

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
  if (WIDGET_WORD.test(element)) {
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

type Catalogue = Record<string, unknown>;

const I18N_DIR = 'public/i18n';
const REFERENCE_LANGUAGE = 'en';

/** Catalogues presents, decouverts sur le disque et indexes par langue. */
function loadCatalogues(): Record<string, Catalogue> {
  return Object.fromEntries(
    readdirSync(I18N_DIR)
      .filter((file) => file.endsWith('.json'))
      .map((file) => [
        file.slice(0, -'.json'.length),
        JSON.parse(readFileSync(`${I18N_DIR}/${file}`, 'utf8')) as Catalogue,
      ]),
  );
}

/** Messages a plat, indexes par cle complete. */
function flattenMessages(node: unknown, prefix = ''): Record<string, string> {
  if (typeof node !== 'object' || node === null) {
    return { [prefix]: String(node) };
  }
  return Object.assign(
    {},
    ...Object.entries(node as Catalogue).map(([segment, value]) =>
      flattenMessages(value, prefix ? `${prefix}.${segment}` : segment),
    ),
  ) as Record<string, string>;
}

function unknownKeys(reference: Catalogue, catalogue: Catalogue): string[] {
  const referenceKeys = new Set(flattenKeys(reference));
  return flattenKeys(catalogue).filter((key) => !referenceKeys.has(key));
}

function missingKeys(reference: Catalogue, catalogue: Catalogue): string[] {
  return unknownKeys(catalogue, reference);
}

/** Noms des arguments ICU, y compris dans les cas de `plural` / `select`. */
function argumentNames(tokens: Token[], names = new Set<string>()): Set<string> {
  for (const token of tokens) {
    if (token.type === 'content' || token.type === 'octothorpe') {
      continue;
    }
    names.add(token.arg);
    if (token.type === 'function') {
      argumentNames(token.param ?? [], names);
    } else if (token.type !== 'argument') {
      token.cases.forEach((selectCase) => argumentNames(selectCase.tokens, names));
    }
  }
  return names;
}

function sortedArguments(message: string): string[] {
  return [...argumentNames(parse(message))].sort();
}

/** Cles dont le message utilise d'autres arguments que le message anglais. */
function argumentMismatches(reference: Catalogue, catalogue: Catalogue): string[] {
  const referenceMessages = flattenMessages(reference);
  return Object.entries(flattenMessages(catalogue))
    .filter(([key]) => key in referenceMessages)
    .filter(
      ([key, message]) =>
        sortedArguments(message).join() !== sortedArguments(referenceMessages[key]).join(),
    )
    .map(([key]) => key);
}

/** Cles dont le message n'est pas un ICU valide. */
function invalidMessages(catalogue: Catalogue): string[] {
  return Object.entries(flattenMessages(catalogue))
    .filter(([, message]) => {
      try {
        parse(message);
        return false;
      } catch {
        return true;
      }
    })
    .map(([key]) => key);
}

/** Langues de `availableLangs` dans le source d'une configuration Transloco. */
function availableLangsOf(source: string): string[] {
  const match = /availableLangs:\s*\[([^\]]*)\]/.exec(source);
  expect(match, 'availableLangs introuvable').not.toBeNull();
  return [...match![1].matchAll(/'([^']+)'/g)].map(([, language]) => language);
}

const catalogues = loadCatalogues();
const english = catalogues[REFERENCE_LANGUAGE];
const englishKeys = flattenKeys(english).sort();
const languages = Object.keys(catalogues).sort();
const enabledLanguages = languages.filter((language) =>
  (SUPPORTED_LANGUAGES as readonly string[]).includes(language),
);

describe('catalogues i18n', () => {
  it('should_find_every_enabled_language_when_reading_the_catalogue_folder', () => {
    expect(languages).toEqual(expect.arrayContaining([...SUPPORTED_LANGUAGES]));
  });

  it.each(languages)('should_have_no_unknown_key_when_language_is_%s', (language) => {
    expect(unknownKeys(english, catalogues[language])).toEqual([]);
  });

  it.each(enabledLanguages)('should_have_every_key_when_language_is_enabled_%s', (language) => {
    // Assert — SC-004 : parite stricte, dans les deux sens, pour toute langue
    // activee ; le controle fr/en de KKS-373 en est un cas.
    expect(missingKeys(english, catalogues[language])).toEqual([]);
  });

  it.each(languages)('should_use_the_english_arguments_when_language_is_%s', (language) => {
    expect(argumentMismatches(english, catalogues[language])).toEqual([]);
  });

  it.each(languages)('should_hold_valid_icu_messages_when_language_is_%s', (language) => {
    expect(invalidMessages(catalogues[language])).toEqual([]);
  });

  it('should_enable_the_same_languages_in_transloco_and_language_service', () => {
    const appConfig = readFileSync('src/app/app.config.ts', 'utf8');
    expect(availableLangsOf(appConfig)).toEqual([...SUPPORTED_LANGUAGES]);
  });

  it.each(englishKeys)('should_have_three_conventional_segments_when_key_is_%s', (key) => {
    // Assert — SC-013 : domaine et contexte dans les listes fermees,
    // element en lowerCamelCase.
    expect(isValidKey(key)).toBe(true);
  });

  it('should_reject_key_when_element_names_the_widget', () => {
    expect(isValidKey('accounts.form.bankNameLabel')).toBe(false);
  });

  it('should_not_be_empty', () => {
    // Garde-fou contre un catalogue vide qui rendrait les tests ci-dessus
    // vacuously true.
    expect(englishKeys.length).toBeGreaterThan(0);
  });
});

describe('regles de catalogue sur des catalogues fautifs', () => {
  const reference: Catalogue = {
    accounts: {
      list: {
        greeting: 'Hello {name}',
        count: '{count, plural, one {# account} other {# accounts}}',
      },
    },
  };

  it('should_report_key_when_catalogue_has_unknown_key', () => {
    const catalogue = { accounts: { list: { greeting: 'Hola {name}', farewell: 'Adiós' } } };
    expect(unknownKeys(reference, catalogue)).toEqual(['accounts.list.farewell']);
  });

  it('should_report_key_when_enabled_catalogue_misses_a_key', () => {
    const catalogue = { accounts: { list: { greeting: 'Hola {name}' } } };
    expect(missingKeys(reference, catalogue)).toEqual(['accounts.list.count']);
  });

  it('should_report_key_when_argument_is_renamed', () => {
    const catalogue = { accounts: { list: { greeting: 'Hola {nombre}' } } };
    expect(argumentMismatches(reference, catalogue)).toEqual(['accounts.list.greeting']);
  });

  it('should_report_key_when_plural_argument_differs', () => {
    const catalogue = {
      accounts: { list: { count: '{total, plural, one {# cuenta} other {# cuentas}}' } },
    };
    expect(argumentMismatches(reference, catalogue)).toEqual(['accounts.list.count']);
  });

  it('should_report_key_when_argument_is_dropped_from_a_select_case', () => {
    const withSelect: Catalogue = {
      common: { value: { greeting: '{hasName, select, yes {Hi {name}} other {Hi}}' } },
    };
    const catalogue = {
      common: { value: { greeting: '{hasName, select, yes {Hola} other {Hola}}' } },
    };
    expect(argumentMismatches(withSelect, catalogue)).toEqual(['common.value.greeting']);
  });

  it('should_report_nothing_when_arguments_match', () => {
    const catalogue = {
      accounts: {
        list: {
          greeting: '¡Hola {name}!',
          count: '{count, plural, one {# cuenta} other {# cuentas}}',
        },
      },
    };
    expect(argumentMismatches(reference, catalogue)).toEqual([]);
  });

  it('should_follow_function_parameters_when_collecting_arguments', () => {
    expect(sortedArguments('{amount, number} {when, date, short}')).toEqual(['amount', 'when']);
  });

  it('should_report_key_when_message_is_invalid_icu', () => {
    const catalogue = {
      accounts: { list: { greeting: 'Hola {name', count: '{count, plural, other {# cuentas}}' } },
    };
    expect(invalidMessages(catalogue)).toEqual(['accounts.list.greeting']);
  });

  it('should_read_languages_when_config_declares_available_langs', () => {
    expect(availableLangsOf("config: { availableLangs: ['en', 'fr', 'es'], }")).toEqual([
      'en',
      'fr',
      'es',
    ]);
  });

  it('should_detect_disagreement_when_lists_differ', () => {
    expect(availableLangsOf("availableLangs: ['en']")).not.toEqual([...SUPPORTED_LANGUAGES]);
  });
});
