import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';

void main() {
  group('displayLocaleProvider', () {
    test('should_returnFrench_when_noOverride', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(displayLocaleProvider), const Locale('fr'));
    });

    test('should_useOverride_when_providedInTests', () {
      final container = ProviderContainer(
        overrides: [
          displayLocaleProvider.overrideWithValue(const Locale('en')),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(displayLocaleProvider), const Locale('en'));
    });
  });

  group('intlLocaleProvider', () {
    test('should_returnFrFr_when_displayLocaleIsFrench', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(intlLocaleProvider), 'fr_FR');
    });

    test('should_returnEnGb_when_displayLocaleIsEnglish', () {
      final container = ProviderContainer(
        overrides: [
          displayLocaleProvider.overrideWithValue(const Locale('en')),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(intlLocaleProvider), 'en_GB');
    });
  });
}
