import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/services/stomp_service.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  group('StompService', () {
    test('should_create_stream_when_instantiated', () {
      // Arrange & Act
      final service = StompService();

      // Assert
      expect(service.notifications, isA<Stream<NotificationModel>>());
      expect(service.notifications, isNotNull);

      service.dispose();
    });

    test('should_dispose_cleanly_when_dispose_called', () async {
      // Arrange
      final service = StompService();
      var doneCalled = false;
      final completer = Completer<void>();

      service.notifications.listen(
        (_) {},
        onDone: () {
          doneCalled = true;
          completer.complete();
        },
      );

      // Act
      service.dispose();

      // Assert — onDone doit être appelé lorsque le stream est fermé
      await completer.future.timeout(const Duration(seconds: 1));
      expect(doneCalled, isTrue);
    });

    test('should_not_be_observing_when_created', () {
      // Arrange & Act — créer sans connecter
      final service = StompService();

      // Assert — dispose() sans connect() préalable ne doit pas crasher
      // (car _observing == false, removeObserver n'est pas appelé)
      expect(() => service.dispose(), returnsNormally);
    });

    test('should_handle_double_dispose_gracefully', () {
      // Arrange
      final service = StompService();

      // Act
      service.dispose();

      // Assert — second dispose ne doit pas lever d'exception
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
