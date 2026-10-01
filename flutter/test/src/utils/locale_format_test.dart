import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/utils/locale_format.dart';

void main() {
  group('intlLocaleFor', () {
    for (final (locale, expected) in [
      (const Locale('fr'), 'fr_FR'),
      (const Locale('en'), 'en_GB'),
    ]) {
      test('should_return${expected}_when_languageCodeIs${locale.languageCode}', () {
        expect(intlLocaleFor(locale), expected);
      });
    }

    test('should_defaultToEnGb_when_languageCodeIsUnknown', () {
      expect(intlLocaleFor(const Locale('es')), 'en_GB');
    });
  });

  group('formatRate', () {
    for (final (rate, locale, expected) in [
      (655.957, 'fr_FR', '655,957'),
      (1.1, 'fr_FR', '1,1'),
      (1.1, 'en_GB', '1.1'),
      (2.0, 'fr_FR', '2'),
      (0.0015244, 'fr_FR', '0,001524'),
      (1234.5, 'fr_FR', '1\u202f234,5'),
      (1234.5, 'en_GB', '1,234.5'),
    ]) {
      test('should_format${rate}_when_localeIs$locale', () {
        expect(formatRate(rate, locale), expected);
      });
    }
  });
}
