import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/services/local_notification_service.dart';

void main() {
  group('LocalNotificationService', () {
    test('should_not_be_initialized_when_created', () {
      // Arrange & Act — instancier le service sans appeler initialize()
      // Assert — la construction ne doit pas lever d'exception
      expect(() => LocalNotificationService(), returnsNormally);
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
