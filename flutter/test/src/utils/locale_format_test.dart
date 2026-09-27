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

    test('should_defaultToFrFr_when_languageCodeIsUnknown', () {
      expect(intlLocaleFor(const Locale('es')), 'fr_FR');
    });
  });
}
