// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/settings/application/language_notifier.dart';

// Checks every ARB catalogue against `app_en.arb`, the reference (KKS-439,
// `docs/i18n.md`, « Adding a language »). ICU validity is left to
// `flutter gen-l10n`.
const _arbDir = 'lib/src/localization';
const _referenceLanguage = 'en';
final _arbFileName = RegExp(r'^app_([a-zA-Z_]+)\.arb$');

/// Loads every `app_xx.arb` file, keyed by language code.
Map<String, Map<String, dynamic>> _loadCatalogues() {
  final catalogues = <String, Map<String, dynamic>>{};
  for (final entity in Directory(_arbDir).listSync()) {
    final name = entity.uri.pathSegments.last;
    final match = _arbFileName.firstMatch(name);
    if (entity is File && match != null) {
      catalogues[match.group(1)!] =
          jsonDecode(entity.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  return catalogues;
}

/// Message keys, without metadata (`@key`, `@@locale`).
Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

/// Keys of [arb] unknown to [reference].
Set<String> _unknownKeys(
  Map<String, dynamic> reference,
  Map<String, dynamic> arb,
) => _messageKeys(arb).difference(_messageKeys(reference));

/// Keys of [reference] missing from [arb].
Set<String> _missingKeys(
  Map<String, dynamic> reference,
  Map<String, dynamic> arb,
) => _messageKeys(reference).difference(_messageKeys(arb));

/// Keys whose message uses other placeholders than the reference message.
Set<String> _placeholderMismatches(
  Map<String, dynamic> reference,
  Map<String, dynamic> arb,
) {
  final mismatches = <String>{};
  for (final key in _messageKeys(arb).intersection(_messageKeys(reference))) {
    final expected = _placeholdersOf(reference[key] as String);
    final actual = _placeholdersOf(arb[key] as String);
    if (expected.length != actual.length || !expected.containsAll(actual)) {
      mismatches.add(key);
    }
  }
  return mismatches;
}

/// Whether `@@locale`, when present, matches the [language] of the file name.
bool _localeMatchesFileName(String language, Map<String, dynamic> arb) =>
    !arb.containsKey('@@locale') || arb['@@locale'] == language;

/// Disagreements between the enabled languages, their native names and the
/// ARB files present.
List<String> _languageListProblems(
  List<String> supported,
  Map<String, String> nativeNames,
  Set<String> arbLanguages,
) => [
  for (final language in supported)
    if (!nativeNames.containsKey(language)) 'no native name: $language',
  for (final language in nativeNames.keys)
    if (!supported.contains(language)) 'not supported: $language',
  for (final language in supported)
    if (!arbLanguages.contains(language)) 'no ARB file: $language',
];

/// Argument names used by an ICU [message], including inside the cases of
/// `plural`, `select` and `selectordinal`. Covers the syntax of the ARB
/// files: no apostrophe escaping (`use-escaping` is off).
Set<String> _placeholdersOf(String message) {
  final names = <String>{};
  final end = _scanMessage(message, 0, names, nested: false);
  if (end != message.length) {
    throw FormatException('Unbalanced "}"', message, end);
  }
  return names;
}

int _scanMessage(
  String message,
  int start,
  Set<String> names, {
  required bool nested,
}) {
  var index = start;
  while (index < message.length) {
    final char = message[index];
    if (char == '{') {
      index = _scanArgument(message, index + 1, names);
    } else if (char == '}') {
      if (nested) {
        return index;
      }
      throw FormatException('Unbalanced "}"', message, index);
    } else {
      index++;
    }
  }
  if (nested) {
    throw FormatException('Unclosed case', message, index);
  }
  return index;
}

/// Scans an argument from just after its `{`, returns the index after its
/// closing `}`.
int _scanArgument(String message, int start, Set<String> names) {
  var index = _skipUntil(message, start, ',}');
  names.add(message.substring(start, index).trim());
  if (message[index] == '}') {
    return index + 1;
  }
  final typeStart = index + 1;
  index = _skipUntil(message, typeStart, ',}');
  final type = message.substring(typeStart, index).trim();
  if (message[index] == '}') {
    return index + 1;
  }
  if (!const {'plural', 'select', 'selectordinal'}.contains(type)) {
    // Style of a `number` or `date` argument: no nested placeholder.
    return _skipUntil(message, index + 1, '}') + 1;
  }
  index++;
  while (true) {
    index = _skipUntil(message, index, '{}');
    if (message[index] == '}') {
      return index + 1;
    }
    index = _scanMessage(message, index + 1, names, nested: true) + 1;
  }
}

int _skipUntil(String message, int start, String stops) {
  var index = start;
  while (index < message.length && !stops.contains(message[index])) {
    index++;
  }
  if (index == message.length) {
    throw FormatException('Unclosed argument', message, start);
  }
  return index;
}

void main() {
  final catalogues = _loadCatalogues();
  final reference = catalogues[_referenceLanguage]!;

  group('ARB catalogues', () {
    test('should_find_the_reference_and_a_translation', () {
      // Garde-fou : sans fichier, les tests ci-dessous seraient vides.
      expect(catalogues.keys, containsAll(supportedLanguages));
      expect(_messageKeys(reference), isNotEmpty);
    });

    for (final MapEntry(key: language, value: arb) in catalogues.entries) {
      test('should_have_no_unknown_key_when_language_is_$language', () {
        expect(_unknownKeys(reference, arb), isEmpty);
      });

      if (supportedLanguages.contains(language)) {
        test('should_have_every_key_when_language_is_enabled_$language', () {
          expect(_missingKeys(reference, arb), isEmpty);
        });
      }

      test(
        'should_use_the_english_placeholders_when_language_is_$language',
        () {
          expect(_placeholderMismatches(reference, arb), isEmpty);
        },
      );

      test('should_match_file_name_when_locale_is_declared_in_$language', () {
        expect(_localeMatchesFileName(language, arb), isTrue);
      });
    }

    test('should_agree_when_comparing_enabled_languages_and_arb_files', () {
      expect(
        _languageListProblems(
          supportedLanguages,
          languageNativeNames,
          catalogues.keys.toSet(),
        ),
        isEmpty,
      );
    });
  });

  group('catalogue rules on faulty catalogues', () {
    const english = <String, dynamic>{
      '@@locale': 'en',
      'greeting': 'Hello {name}',
      '@greeting': {'placeholders': <String, dynamic>{}},
      'count': '{count, plural, one {{count} item} other {{count} items}}',
    };

    test('should_report_key_when_translation_has_unknown_key', () {
      const translation = {'greeting': 'Hola {name}', 'farewell': 'Adiós'};
      expect(_unknownKeys(english, translation), {'farewell'});
    });

    test('should_report_key_when_enabled_translation_misses_a_key', () {
      const translation = {'greeting': 'Hola {name}'};
      expect(_missingKeys(english, translation), {'count'});
    });

    test('should_ignore_metadata_when_comparing_keys', () {
      const translation = {
        '@@locale': 'es',
        'greeting': 'Hola {name}',
        'count': '{count, plural, other {{count} cosas}}',
      };
      expect(_unknownKeys(english, translation), isEmpty);
      expect(_missingKeys(english, translation), isEmpty);
    });

    test('should_report_key_when_placeholder_is_renamed', () {
      const translation = {'greeting': 'Hola {nombre}'};
      expect(_placeholderMismatches(english, translation), {'greeting'});
    });

    test('should_report_key_when_placeholder_is_dropped_from_plural', () {
      const translation = {
        'count': '{count, plural, one {un objeto} other {{total} objetos}}',
      };
      expect(_placeholderMismatches(english, translation), {'count'});
    });

    test('should_report_nothing_when_placeholders_match', () {
      const translation = {
        'greeting': '¡Hola {name}!',
        'count': '{count, plural, one {un objeto} other {{count} objetos}}',
      };
      expect(_placeholderMismatches(english, translation), isEmpty);
    });

    test('should_report_mismatch_when_locale_differs_from_file_name', () {
      expect(_localeMatchesFileName('es', const {'@@locale': 'pt'}), isFalse);
      expect(_localeMatchesFileName('es', const {'@@locale': 'es'}), isTrue);
      expect(_localeMatchesFileName('es', const {'greeting': 'Hola'}), isTrue);
    });

    test('should_report_problem_when_language_lists_disagree', () {
      expect(_languageListProblems(['en', 'es'], {'en': 'English'}, {'en'}), [
        'no native name: es',
        'no ARB file: es',
      ]);
      expect(
        _languageListProblems(['en'], {'en': 'English', 'es': 'Español'}, {
          'en',
          'es',
        }),
        ['not supported: es'],
      );
    });
  });

  group('placeholder extraction', () {
    test('should_return_names_when_message_has_simple_arguments', () {
      expect(_placeholdersOf('{a} and {b}'), {'a', 'b'});
    });

    test('should_return_empty_when_message_has_no_argument', () {
      expect(_placeholdersOf(''), isEmpty);
      expect(_placeholdersOf('Plain text'), isEmpty);
    });

    test('should_ignore_case_text_when_message_has_select', () {
      expect(_placeholdersOf('{hasName, select, yes {Hi {name}} other {Hi}}'), {
        'hasName',
        'name',
      });
    });

    test('should_follow_nested_cases_when_message_nests_plural', () {
      expect(
        _placeholdersOf(
          '{g, select, a {{n, plural, =0 {none} other {{n} by {who}}}} '
          'other {x}}',
        ),
        {'g', 'n', 'who'},
      );
    });

    test('should_skip_style_when_argument_has_a_format', () {
      expect(_placeholdersOf('{amount, number, currency} {d, date}'), {
        'amount',
        'd',
      });
    });

    test('should_throw_when_message_is_unbalanced', () {
      expect(() => _placeholdersOf('{name'), throwsFormatException);
      expect(() => _placeholdersOf('name}'), throwsFormatException);
      expect(
        () => _placeholdersOf('{n, plural, other {x}'),
        throwsFormatException,
      );
      expect(
        () => _placeholdersOf('{n, plural, other {x'),
        throwsFormatException,
      );
    });
  });
}
