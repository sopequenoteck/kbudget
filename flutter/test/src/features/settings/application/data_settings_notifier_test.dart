import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late ProviderContainer container;
  late HttpServer server;
  var statusCode = 200;

  DataSettingsNotifier notifier() =>
      container.read(dataSettingsNotifierProvider.notifier);

  DataSettingsState state() => container.read(dataSettingsNotifierProvider);

  String serverUrl() => 'http://${server.address.host}:${server.port}/api';

  setUp(() async {
    // Serveur local : repond au health check avec le statut voulu
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response
        ..statusCode = statusCode
        ..close();
    });
    final repo = MockAppConfigRepository();
    when(repo.getConfig()).thenAnswer(
      (_) async => const AppConfig(dataMode: DataMode.local),
    );
    container = ProviderContainer(
      overrides: [appConfigRepositoryProvider.overrideWithValue(repo)],
    );
    state();
  });

  tearDown(() async {
    container.dispose();
    await server.close(force: true);
  });

  group('checkConnectivity', () {
    test('should_returnTrueWithoutError_when_serverAnswers200', () async {
      statusCode = 200;

      final reachable = await notifier().checkConnectivity(serverUrl());

      expect(reachable, true);
      expect(state().error, isNull);
      expect(state().isLoading, false);
    });

    test('should_reportAccessDenied_when_serverAnswers403', () async {
      statusCode = 403;

      final reachable = await notifier().checkConnectivity(serverUrl());

      expect(reachable, false);
      expect(state().error, 'Accès refusé par le serveur');
    });

    test('should_reportEndpointNotFound_when_serverAnswers404', () async {
      statusCode = 404;

      await notifier().checkConnectivity('${serverUrl()}/');

      expect(state().error, "Endpoint introuvable — vérifiez l'URL");
    });

    test('should_reportUnreachable_when_serverAnswers500', () async {
      statusCode = 500;

      await notifier().checkConnectivity(serverUrl());

      expect(state().error, 'Serveur injoignable');
    });

    test('should_reportNetworkError_when_connectionRefused', () async {
      final url = serverUrl();
      await server.close(force: true);

      await notifier().checkConnectivity(url);

      expect(state().error, 'Impossible de contacter le serveur');
    });
  });

  group('validateUrl', () {
    test('should_requireUrl_when_blank', () {
      expect(notifier().validateUrl('  '), "L'URL du serveur est requise");
    });

    test('should_requireHttps_when_otherScheme', () {
      expect(
        notifier().validateUrl('ftp://example.com'),
        "L'URL doit commencer par https://",
      );
    });

    test('should_acceptUrl_when_https', () {
      expect(notifier().validateUrl('https://example.com/api'), isNull);
    });
  });
}
