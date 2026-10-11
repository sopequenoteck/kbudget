import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/data/remote/connectivity_interceptor.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/data/remote/jwt_interceptor.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/auth/data/auth_repository_impl.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRemoteDataSource>(),
])
import 'repository_providers_test.mocks.dart';

/// Faux adaptateur HTTP : 401 tant que la requête porte l'ancien jeton.
class _TokenGateAdapter implements HttpClientAdapter {
  _TokenGateAdapter({required this.acceptedToken});

  final String acceptedToken;
  final authorizations = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final authorization = options.headers['Authorization'];
    authorizations.add(authorization);
    final accepted = authorization == 'Bearer $acceptedToken';
    return ResponseBody.fromString(
      accepted ? '{"ok":true}' : '{"error":"TOKEN_EXPIRED"}',
      accepted ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Génère un JWT factice expiré depuis une heure (non signé).
String _expiredJwt() {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final exp = DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch ~/
      1000;
  final payload = base64Url.encode(utf8.encode('{"sub":"a@b.fr","exp":$exp}'));
  return '$header.$payload.fake-signature';
}

void main() {
  late MockAppConfigRepository configRepo;
  late MockAuthRemoteDataSource dataSource;

  setUp(() {
    configRepo = MockAppConfigRepository();
    dataSource = MockAuthRemoteDataSource();
    // Nothing listens there: a request that escapes the fake adapter fails
    // fast instead of reaching a real server.
    when(configRepo.getServerUrl())
        .thenAnswer((_) async => 'http://127.0.0.1:1/api');
    FlutterSecureStorage.setMockInitialValues({});
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(configRepo),
        // Real repository, default storage: the token it writes is the one
        // the interceptor reads.
        authRepositoryProvider
            .overrideWith((ref) async => AuthRepositoryImpl(dataSource)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('authenticatedDioProvider', () {
    test(
        'should_keepPublicClientFreeOfInterceptors_when_authenticatedClientBuilt',
        () async {
      final container = buildContainer();

      final authenticated =
          await container.read(authenticatedDioProvider.future);
      final publicClient = await container.read(apiClientProvider.future);

      expect(authenticated, isNot(same(publicClient)));
      expect(authenticated.options.baseUrl, publicClient.options.baseUrl);
      expect(
        authenticated.interceptors.whereType<JwtInterceptor>(),
        isNotEmpty,
      );
      expect(
        publicClient.interceptors.whereType<JwtInterceptor>(),
        isEmpty,
      );
      expect(
        publicClient.interceptors.whereType<ConnectivityInterceptor>(),
        isEmpty,
      );
    });

    test('should_refreshOnce_when_startupCheckAndRejectedRequestRace',
        () async {
      final expiredToken = _expiredJwt();
      FlutterSecureStorage.setMockInitialValues({
        'access_token': expiredToken,
        'refresh_token': 'old-refresh',
      });
      final gate = Completer<AuthResponse>();
      when(dataSource.refresh(any)).thenAnswer((_) => gate.future);
      final container = buildContainer();
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));
      final dio = await container.read(authenticatedDioProvider.future);
      final adapter = _TokenGateAdapter(acceptedToken: 'new-access');
      dio.httpClientAdapter = adapter;

      final request = dio.get<Map<String, dynamic>>('/some/endpoint');
      final check = container.read(authNotifierProvider.notifier).checkAuth();
      // Both paths are now waiting on the same refresh.
      await pumpEventQueue();
      verify(dataSource.refresh('old-refresh')).called(1);
      // The request was rejected and has not been replayed yet.
      expect(adapter.authorizations, ['Bearer $expiredToken']);
      gate.complete(
        const AuthResponse(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          email: 'a@b.fr',
          name: 'A',
        ),
      );
      final response = await request;
      await check;

      verifyNever(dataSource.refresh('new-refresh'));
      expect(response.statusCode, 200);
      expect(
        adapter.authorizations,
        ['Bearer $expiredToken', 'Bearer new-access'],
      );
      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
      expect(states.whereType<AuthUnauthenticated>(), isEmpty);
    });
  });
}
