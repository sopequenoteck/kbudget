import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';

import '../../../../helpers/display_locale.dart';
import 'language_notifier_test.dart';

void main() {
  group('displayLocaleProvider', () {
    test('should_followLanguageNotifier_when_noOverride', () async {
      final container = ProviderContainer(
        overrides: languageOverrides(
          config: FakeLanguageConfig(),
          remote: FakePreferenceDataSource(),
          auth: const AuthState.initial(),
          system: const [Locale('pt', 'BR'), Locale('fr', 'FR')],
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(displayLocaleProvider), const Locale('fr'));
      // Let the stored language load before the container is disposed
      await pumpEventQueue();
    });

    test('should_returnEnglish_when_systemLanguageIsNotSupported', () async {
      final container = ProviderContainer(
        overrides: languageOverrides(
          config: FakeLanguageConfig(),
          remote: FakePreferenceDataSource(),
          auth: const AuthState.initial(),
          system: const [Locale('de')],
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(displayLocaleProvider), const Locale('en'));
      // Let the stored language load before the container is disposed
      await pumpEventQueue();
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
      final container = ProviderContainer(
        overrides: [displayLocaleOverride()],
      );
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
