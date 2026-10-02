import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/services/local_notification_service.dart';
import 'package:k_budget/src/services/stomp_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

// Remplace l'affichage système : enregistre ce qui lui est transmis
class _FakeLocalNotificationService extends LocalNotificationService {
  _FakeLocalNotificationService()
      : super(readL10n: () => lookupAppLocalizations(const Locale('fr')));

  final List<(String, String, String)> shown = [];

  @override
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    shown.add((id, title, body));
  }
}

StompService _createService({
  Locale Function()? readLocale,
  LocalNotificationService? localNotificationService,
}) {
  final locale = readLocale ?? () => const Locale('fr');
  return StompService(
    readL10n: () => lookupAppLocalizations(locale()),
    readIntlLocale: () => locale().languageCode == 'en' ? 'en_GB' : 'fr_FR',
    localNotificationService: localNotificationService,
  );
}

StompFrame _notificationFrame() => StompFrame(
      command: 'MESSAGE',
      body: jsonEncode({
        'id': 'n-1',
        'type': 'SUBSCRIPTION_DUE',
        'title': 'Subscription Netflix',
        'message': 'Netflix is due tomorrow',
        'entityType': 'SUBSCRIPTION',
        'entityId': 'sub-1',
        'read': false,
        'createdAt': '2026-09-30T08:00:00Z',
        'params': {'name': 'Netflix'},
      }),
    );

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  group('StompService', () {
    test('should_create_stream_when_instantiated', () {
      // Arrange & Act
      final service = _createService();

      // Assert
      expect(service.notifications, isA<Stream<NotificationModel>>());
      expect(service.notifications, isNotNull);

      service.dispose();
    });

    test('should_dispose_cleanly_when_dispose_called', () async {
      // Arrange
      final service = _createService();
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
      final service = _createService();

      // Assert — dispose() sans connect() préalable ne doit pas crasher
      // (car _observing == false, removeObserver n'est pas appelé)
      expect(() => service.dispose(), returnsNormally);
    });

    test('should_handle_double_dispose_gracefully', () {
      // Arrange
      final service = _createService();

      // Act
      service.dispose();

      // Assert — second dispose ne doit pas lever d'exception
      expect(() => service.dispose(), returnsNormally);
    });
  });

  test('should_readDisplayLocale_when_createdByProvider', () {
    final container = ProviderContainer(
      overrides: [
        displayLocaleProvider.overrideWithValue(const Locale('en')),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(stompServiceProvider);

    expect(service.readIntlLocale(), 'en_GB');
    expect(service.readL10n().notificationsPageChannelDescription,
        'K-Budget notifications');
  });

  group('StompService.handleNotificationFrame', () {
    late _FakeLocalNotificationService fakeLocal;

    setUp(() {
      fakeLocal = _FakeLocalNotificationService();
    });

    test('should_publishNotification_when_frameHasBody', () async {
      final service = _createService(localNotificationService: fakeLocal);
      final received = service.notifications.first;

      service.handleNotificationFrame(_notificationFrame());

      final notification = await received;
      expect(notification.id, 'n-1');
      expect(notification.params, {'name': 'Netflix'});
      service.dispose();
    });

    test('should_showTranslatedText_when_appIsInBackground', () {
      final service = _createService(localNotificationService: fakeLocal)
        ..didChangeAppLifecycleState(AppLifecycleState.paused);

      service.handleNotificationFrame(_notificationFrame());

      expect(fakeLocal.shown, [
        ('n-1', 'Abonnement Netflix', 'Netflix — échéance demain'),
      ]);
      service.dispose();
    });

    test('should_readLocale_when_notificationArrives', () {
      var locale = const Locale('fr');
      final service = _createService(
        readLocale: () => locale,
        localNotificationService: fakeLocal,
      )..didChangeAppLifecycleState(AppLifecycleState.paused);
      locale = const Locale('en');

      service.handleNotificationFrame(_notificationFrame());

      expect(fakeLocal.shown, [
        ('n-1', 'Subscription Netflix', 'Netflix is due tomorrow'),
      ]);
      service.dispose();
    });

    test('should_notShowSystemNotification_when_appIsInForeground', () {
      final service = _createService(localNotificationService: fakeLocal);

      service.handleNotificationFrame(_notificationFrame());

      expect(fakeLocal.shown, isEmpty);
      service.dispose();
    });

    test('should_ignoreFrame_when_bodyIsNull', () async {
      final service = _createService(localNotificationService: fakeLocal)
        ..didChangeAppLifecycleState(AppLifecycleState.paused);
      var published = false;
      final subscription = service.notifications.listen((_) {
        published = true;
      });

      service.handleNotificationFrame(StompFrame(command: 'MESSAGE'));
      await Future<void>.delayed(Duration.zero);

      expect(published, isFalse);
      expect(fakeLocal.shown, isEmpty);
      await subscription.cancel();
      service.dispose();
    });
  });
}
