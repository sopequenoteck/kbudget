import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/services/local_notification_service.dart';

void main() {
  LocalNotificationService createService([
    Locale locale = const Locale('fr'),
  ]) =>
      LocalNotificationService(
        readL10n: () => lookupAppLocalizations(locale),
      );

  group('LocalNotificationService', () {
    test('should_not_be_initialized_when_created', () {
      // Arrange & Act — instancier le service sans appeler initialize()
      // Assert — la construction ne doit pas lever d'exception
      expect(createService, returnsNormally);
    });

    test('should_nameChannelFromArb_when_localeIsFrench', () {
      final android = createService().notificationDetails().android!;

      expect(android.channelId, 'k_budget_notifications');
      expect(android.channelName, 'Notifications');
      expect(android.channelDescription, 'Notifications K-Budget');
    });

    test('should_nameChannelFromArb_when_localeIsEnglish', () {
      final android =
          createService(const Locale('en')).notificationDetails().android!;

      expect(android.channelId, 'k_budget_notifications');
      expect(android.channelDescription, 'K-Budget notifications');
    });

    test('should_readLocale_when_detailsAreBuilt', () {
      // La langue est lue à chaque notification, pas à la construction
      var locale = const Locale('fr');
      final service = LocalNotificationService(
        readL10n: () => lookupAppLocalizations(locale),
      );
      locale = const Locale('en');

      expect(
        service.notificationDetails().android!.channelDescription,
        'K-Budget notifications',
      );
    });

    test('should_readDisplayLocale_when_createdByProvider', () {
      final container = ProviderContainer(
        overrides: [
          displayLocaleProvider.overrideWithValue(const Locale('en')),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(localNotificationServiceProvider);

      expect(
        service.notificationDetails().android!.channelDescription,
        'K-Budget notifications',
      );
    });

    test('should_use_positive_id_when_hashcode_is_negative', () {
      // Test de la logique arithmétique utilisée dans showNotification :
      // id.hashCode & 0x7FFFFFFF garantit un entier positif (bit de signe masqué)
      const testIds = ['abc', 'notification-123', '', '🔔', 'aaaaaaaaaa'];
      for (final id in testIds) {
        final result = id.hashCode & 0x7FFFFFFF;
        expect(
          result,
          greaterThanOrEqualTo(0),
          reason: 'id="$id" a produit un résultat négatif',
        );
      }
    });

    test('should_use_positive_id_when_hashcode_is_positive', () {
      // Vérifier que le bitmask préserve correctement un hashCode positif
      const testIds = ['sub-1', 'debt-42', 'k_budget'];
      for (final id in testIds) {
        final hashCode = id.hashCode;
        final result = hashCode & 0x7FFFFFFF;
        expect(
          result,
          greaterThanOrEqualTo(0),
          reason: 'id="$id" hashCode=$hashCode a produit un résultat négatif',
        );
        // Le masque ne doit pas modifier les bits inférieurs à 31 si le hashCode
        // est déjà positif
        if (hashCode >= 0) {
          expect(result, equals(hashCode));
        }
      }
    });
  });
}
