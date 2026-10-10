import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/data/remote/compatibility_provider.dart';
import 'package:k_budget/src/data/remote/compatibility_service.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../helpers/display_locale.dart';
import '../../../../helpers/mocks.mocks.dart';

class _FakeCompatibilityService implements CompatibilityService {
  _FakeCompatibilityService(this.result);

  CompatibilityStatus result;
  final checkedUrls = <String>[];

  @override
  Future<CompatibilityStatus> check({
    required String baseUrl,
    required String clientVersion,
  }) async {
    checkedUrls.add(baseUrl);
    return result;
  }
}

class _FakeAuthDataSource extends AuthRemoteDataSource {
  _FakeAuthDataSource() : super(Dio());

  Future<void> Function(String refreshToken)? onLogout;
  final revoked = <String>[];

  @override
  Future<void> logout(String refreshToken) async {
    revoked.add(refreshToken);
    await onLogout?.call(refreshToken);
  }
}

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
      (_) async => const AppConfig(),
    );
    container = ProviderContainer(
      overrides: [
        displayLocaleOverride(),
        appConfigRepositoryProvider.overrideWithValue(repo),
      ],
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

  group('changeServerUrl', () {
    const newUrl = 'https://new.example.com/api';
    const okMeta = ServerMeta(
      serverVersion: '6.11.0',
      apiVersion: 'v1',
      minClientVersion: '6.0.0',
      capabilities: [],
    );

    late MockAppConfigRepository configRepo;
    late MockAuthRepository authRepo;
    late _FakeAuthDataSource dataSource;
    late _FakeCompatibilityService compatibility;
    late ProviderContainer changeContainer;
    var apiClientBuilds = 0;

    DataSettingsNotifier changeNotifier() =>
        changeContainer.read(dataSettingsNotifierProvider.notifier);

    DataSettingsState changeState() =>
        changeContainer.read(dataSettingsNotifierProvider);

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      PackageInfo.setMockInitialValues(
        appName: 'k-budget',
        packageName: 'fr.kksdev.budget',
        version: '6.11.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    setUp(() {
      apiClientBuilds = 0;
      configRepo = MockAppConfigRepository();
      authRepo = MockAuthRepository();
      dataSource = _FakeAuthDataSource();
      compatibility = _FakeCompatibilityService(const CompatibilityOk(okMeta));
      when(configRepo.getConfig()).thenAnswer((_) async => const AppConfig());
      when(configRepo.getServerUrl())
          .thenAnswer((_) async => 'https://old.example.com/api');
      when(configRepo.setServerUrl(any)).thenAnswer((_) async {});
      when(authRepo.getRefreshToken()).thenAnswer((_) async => 'refresh-1');
      when(authRepo.clearTokens()).thenAnswer((_) async {});
      changeContainer = ProviderContainer(
        overrides: [
          displayLocaleOverride(),
          appConfigRepositoryProvider.overrideWithValue(configRepo),
          compatibilityServiceProvider.overrideWithValue(compatibility),
          authRepositoryProvider.overrideWith((ref) async => authRepo),
          authRemoteDataSourceProvider.overrideWith((ref) async => dataSource),
          apiClientProvider.overrideWith((ref) async {
            apiClientBuilds++;
            return Dio();
          }),
        ],
      );
      addTearDown(changeContainer.dispose);
    });

    test('should_returnFalseAndKeepEverything_when_serverOffline', () async {
      compatibility.result = const CompatibilityOffline();

      final changed = await changeNotifier().changeServerUrl(newUrl);

      expect(changed, false);
      expect(changeState().isLoading, false);
      expect(
        changeState().error,
        "Serveur injoignable. Vérifiez l'URL et votre connexion.",
      );
      expect(compatibility.checkedUrls, [newUrl]);
      verifyNever(configRepo.setServerUrl(any));
      verifyNever(authRepo.clearTokens());
      expect(dataSource.revoked, isEmpty);
      expect(
        changeContainer.read(authNotifierProvider),
        const AuthState.initial(),
      );
    });

    test('should_returnFalseWithMessage_when_serverIncompatible', () async {
      compatibility.result = const CompatibilityServerTooOld(
        serverVersion: '6.0.0',
        requiredVersion: '6.1.0',
      );

      final changed = await changeNotifier().changeServerUrl(newUrl);

      expect(changed, false);
      expect(changeState().error, isNotNull);
      verifyNever(configRepo.setServerUrl(any));
      verifyNever(authRepo.clearTokens());
    });

    test('should_showLoading_when_changeInProgress', () async {
      final gate = Completer<CompatibilityStatus>();
      final slow = _GatedService(gate.future);
      changeContainer.dispose();
      changeContainer = ProviderContainer(
        overrides: [
          displayLocaleOverride(),
          appConfigRepositoryProvider.overrideWithValue(configRepo),
          compatibilityServiceProvider.overrideWithValue(slow),
          authRepositoryProvider.overrideWith((ref) async => authRepo),
          authRemoteDataSourceProvider.overrideWith((ref) async => dataSource),
        ],
      );
      addTearDown(changeContainer.dispose);

      final notifier = changeNotifier();
      // Let the initial config load settle: it replaces the state.
      await Future<void>.delayed(Duration.zero);
      final pending = notifier.changeServerUrl(newUrl);
      await Future<void>.delayed(Duration.zero);

      expect(changeState().isLoading, true);
      expect(changeState().error, isNull);

      gate.complete(const CompatibilityOk(okMeta));
      expect(await pending, true);
      expect(changeState().isLoading, false);
    });

    test('should_switchServerAndSignOut_when_serverIsCompatible', () async {
      await changeContainer.read(apiClientProvider.future);
      await changeContainer
          .read(compatibilityNotifierProvider.notifier)
          .ensureChecked();
      expect(
        changeContainer.read(compatibilityNotifierProvider),
        isA<CompatibilityOk>(),
      );
      expect(apiClientBuilds, 1);

      final changed = await changeNotifier().changeServerUrl(newUrl);

      expect(changed, true);
      verifyInOrder([
        authRepo.getRefreshToken(),
        authRepo.clearTokens(),
        configRepo.setServerUrl(newUrl),
      ]);
      expect(dataSource.revoked, ['refresh-1']);
      expect(changeContainer.read(compatibilityNotifierProvider), isNull);
      await changeContainer.read(apiClientProvider.future);
      expect(apiClientBuilds, 2);
      expect(changeState().serverUrl, newUrl);
      expect(changeState().error, isNull);
      expect(changeState().isLoading, false);
      expect(
        changeContainer.read(authNotifierProvider),
        const AuthState.unauthenticated(),
      );
    });

    test('should_notRevoke_when_noRefreshToken', () async {
      when(authRepo.getRefreshToken()).thenAnswer((_) async => null);

      final changed = await changeNotifier().changeServerUrl(newUrl);

      expect(changed, true);
      expect(dataSource.revoked, isEmpty);
      verify(authRepo.clearTokens()).called(1);
      verify(configRepo.setServerUrl(newUrl)).called(1);
    });

    test('should_succeed_when_revocationFails', () async {
      dataSource.onLogout = (_) async =>
          throw DioException(requestOptions: RequestOptions());

      final changed = await changeNotifier().changeServerUrl(newUrl);
      await Future<void>.delayed(Duration.zero);

      expect(changed, true);
      expect(dataSource.revoked, ['refresh-1']);
      verify(configRepo.setServerUrl(newUrl)).called(1);
      expect(
        changeContainer.read(authNotifierProvider),
        const AuthState.unauthenticated(),
      );
    });

    test('should_notWaitForRevocation_when_previousServerHangs', () async {
      final hang = Completer<void>();
      dataSource.onLogout = (_) => hang.future;

      final changed = await changeNotifier().changeServerUrl(newUrl);

      expect(changed, true);
      verify(configRepo.setServerUrl(newUrl)).called(1);
      hang.complete();
    });

    test('should_returnFalseAndSignOut_when_saveFails', () async {
      when(configRepo.setServerUrl(any)).thenThrow(Exception('Storage error'));

      final changed = await changeNotifier().changeServerUrl(newUrl);

      expect(changed, false);
      expect(changeState().isLoading, false);
      expect(changeState().error, 'Erreur lors de la sauvegarde');
      verify(authRepo.clearTokens()).called(1);
      expect(
        changeContainer.read(authNotifierProvider),
        const AuthState.unauthenticated(),
      );
    });

    test('should_keepSessionAndReportError_when_tokensCannotBeRead', () async {
      when(authRepo.getRefreshToken()).thenThrow(Exception('Storage error'));

      final changed = await changeNotifier().changeServerUrl(newUrl);

      expect(changed, false);
      expect(changeState().isLoading, false);
      expect(changeState().error, 'Erreur lors de la sauvegarde');
      verifyNever(authRepo.clearTokens());
      verifyNever(configRepo.setServerUrl(any));
      expect(
        changeContainer.read(authNotifierProvider),
        const AuthState.initial(),
      );
    });

    test('should_stopLoadingAndReportError_when_checkFailsUnexpectedly',
        () async {
      final container = ProviderContainer(
        overrides: [
          displayLocaleOverride(),
          appConfigRepositoryProvider.overrideWithValue(configRepo),
          compatibilityServiceProvider.overrideWithValue(_ThrowingService()),
          authRepositoryProvider.overrideWith((ref) async => authRepo),
          authRemoteDataSourceProvider.overrideWith((ref) async => dataSource),
        ],
      );
      addTearDown(container.dispose);
      // Let the initial config load finish: it replaces the whole state.
      container.read(dataSettingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        container
            .read(dataSettingsNotifierProvider.notifier)
            .changeServerUrl(newUrl),
        throwsStateError,
      );

      final state = container.read(dataSettingsNotifierProvider);
      expect(state.isLoading, false);
      expect(state.error, 'Erreur lors de la sauvegarde');
      verifyNever(authRepo.clearTokens());
      verifyNever(configRepo.setServerUrl(any));
    });

    test('should_pointAuthenticatedClientAtNewUrl_when_serverChanged',
        () async {
      var storedUrl = 'https://old.example.com/api';
      when(configRepo.getServerUrl()).thenAnswer((_) async => storedUrl);
      when(configRepo.setServerUrl(any)).thenAnswer((invocation) async {
        storedUrl = invocation.positionalArguments.single as String;
      });
      // apiClientProvider is the real one: the cascade down to the
      // authenticated client is what this test proves.
      final container = ProviderContainer(
        overrides: [
          displayLocaleOverride(),
          appConfigRepositoryProvider.overrideWithValue(configRepo),
          compatibilityServiceProvider.overrideWithValue(compatibility),
          authRepositoryProvider.overrideWith((ref) async => authRepo),
          authRemoteDataSourceProvider.overrideWith((ref) async => dataSource),
        ],
      );
      addTearDown(container.dispose);
      final before = await container.read(authenticatedDioProvider.future);

      final changed = await container
          .read(dataSettingsNotifierProvider.notifier)
          .changeServerUrl(newUrl);

      final after = await container.read(authenticatedDioProvider.future);
      expect(changed, true);
      expect(before.options.baseUrl, 'https://old.example.com/api/v1');
      expect(after.options.baseUrl, 'https://new.example.com/api/v1');
      expect(after, isNot(same(before)));
    });
  });
}

class _ThrowingService implements CompatibilityService {
  @override
  Future<CompatibilityStatus> check({
    required String baseUrl,
    required String clientVersion,
  }) async => throw StateError('Unexpected payload');
}

class _GatedService implements CompatibilityService {
  _GatedService(this.gate);

  final Future<CompatibilityStatus> gate;

  @override
  Future<CompatibilityStatus> check({
    required String baseUrl,
    required String clientVersion,
  }) => gate;
}
