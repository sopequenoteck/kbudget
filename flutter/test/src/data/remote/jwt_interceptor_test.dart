import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/api_error.dart';
import 'package:k_budget/src/data/remote/jwt_interceptor.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<FlutterSecureStorage>(),
])
import 'jwt_interceptor_test.mocks.dart';

DioException _errorWithResponse({
  required int statusCode,
  Object? data,
}) {
  final requestOptions = RequestOptions(path: '/some/endpoint');
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
  );
}

/// `handler.next(err)` complète le `Completer` interne avec une erreur.
/// Dio le consomme normalement en le renvoyant à l'appelant, mais ici rien ne
/// l'attend : sans ce drain, le test le remonte comme une exception non
/// gérée.
Future<void> _drain(ErrorInterceptorHandler handler) async {
  try {
    // ignore: invalid_use_of_protected_member
    await handler.future;
  } catch (_) {
    // Erreur attendue : onError l'a volontairement rejetée (handler.next).
  }
}

/// Faux adaptateur HTTP : répond via [respond] et enregistre ce qu'il reçoit.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int statusCode, String body) => ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late MockFlutterSecureStorage mockStorage;
  late Dio dio;
  late bool passwordResetRequiredCalled;
  late bool authFailureCalled;
  late int refreshCalls;
  late JwtInterceptor interceptor;
  late _FakeAdapter adapter;
  late ResponseBody Function(RequestOptions options) respond;
  late Future<String> Function() refreshSession;
  String? storedToken;
  var storageReadFails = false;

  List<Object?> authorizations() =>
      adapter.requests.map((r) => r.headers['Authorization']).toList();

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    storedToken = 'old-token';
    storageReadFails = false;
    when(mockStorage.read(key: 'access_token')).thenAnswer((_) async {
      if (storageReadFails) throw Exception('Storage error');
      return storedToken;
    });
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    respond = (_) => _json(200, '{"ok":true}');
    adapter = _FakeAdapter((options) => respond(options));
    dio.httpClientAdapter = adapter;
    passwordResetRequiredCalled = false;
    authFailureCalled = false;
    refreshCalls = 0;
    refreshSession = () async {
      refreshCalls++;
      return 'new-token';
    };
    interceptor = JwtInterceptor(
      dio: dio,
      secureStorage: mockStorage,
      refreshSession: () => refreshSession(),
      onAuthFailure: () {
        authFailureCalled = true;
      },
      onPasswordResetRequired: () {
        passwordResetRequiredCalled = true;
      },
    );
  });

  group('JwtInterceptor.onError — 403 PASSWORD_RESET_REQUIRED', () {
    test(
        'should_callOnPasswordResetRequired_when_403HasPasswordResetRequiredCode',
        () async {
      final err = _errorWithResponse(
        statusCode: 403,
        data: {'error': 'PASSWORD_RESET_REQUIRED'},
      );
      final handler = ErrorInterceptorHandler();

      interceptor.onError(err, handler);
      await _drain(handler);

      expect(passwordResetRequiredCalled, isTrue);
      expect(handler.isCompleted, isTrue);
    });

    test('should_notCallOnPasswordResetRequired_when_403IsAccessDenied',
        () async {
      final err = _errorWithResponse(
        statusCode: 403,
        data: {'error': 'ACCESS_DENIED'},
      );
      final handler = ErrorInterceptorHandler();

      interceptor.onError(err, handler);
      await _drain(handler);

      expect(passwordResetRequiredCalled, isFalse);
      expect(handler.isCompleted, isTrue);
    });

    test('should_notCallOnPasswordResetRequired_when_403HasNoErrorBody',
        () async {
      final err = _errorWithResponse(statusCode: 403, data: null);
      final handler = ErrorInterceptorHandler();

      interceptor.onError(err, handler);
      await _drain(handler);

      expect(passwordResetRequiredCalled, isFalse);
      expect(handler.isCompleted, isTrue);
    });

    test('should_notCallOnPasswordResetRequired_when_statusIsNot403',
        () async {
      final err = _errorWithResponse(
        statusCode: 500,
        data: {'error': 'PASSWORD_RESET_REQUIRED'},
      );
      final handler = ErrorInterceptorHandler();

      interceptor.onError(err, handler);
      await _drain(handler);

      expect(passwordResetRequiredCalled, isFalse);
    });
  });

  group('JwtInterceptor.onError — 401', () {
    setUp(() {
      dio.interceptors.add(interceptor);
    });

    test('should_replayWithRenewedToken_when_requestReturns401', () async {
      respond = (options) =>
          options.headers['Authorization'] == 'Bearer old-token'
              ? _json(401, '{"error":"TOKEN_EXPIRED"}')
              : _json(200, '{"ok":true}');

      final response = await dio.get<Map<String, dynamic>>('/some/endpoint');

      expect(response.statusCode, 200);
      expect(response.data, {'ok': true});
      expect(refreshCalls, 1);
      expect(authorizations(), ['Bearer old-token', 'Bearer new-token']);
      expect(authFailureCalled, isFalse);
    });

    test('should_forwardReplayError_when_replayFailsAfterRefresh', () async {
      respond = (options) =>
          options.headers['Authorization'] == 'Bearer old-token'
              ? _json(401, '{"error":"TOKEN_EXPIRED"}')
              : _json(401, '{"error":"PASSWORD_INCORRECT"}');

      await expectLater(
        dio.get<Map<String, dynamic>>('/some/endpoint'),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 401)
              .having((e) => apiErrorCode(e), 'code', 'PASSWORD_INCORRECT'),
        ),
      );

      expect(refreshCalls, 1);
      expect(adapter.requests, hasLength(2));
      expect(authFailureCalled, isFalse);
    });

    test('should_callOnAuthFailure_when_sessionCannotBeRenewed', () async {
      respond = (_) => _json(401, '{"error":"TOKEN_EXPIRED"}');
      refreshSession = () async => throw Exception('Refresh token rejected');

      await expectLater(
        dio.get<Map<String, dynamic>>('/some/endpoint'),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 401)
              .having((e) => apiErrorCode(e), 'code', 'TOKEN_EXPIRED'),
        ),
      );

      expect(authFailureCalled, isTrue);
      expect(adapter.requests, hasLength(1));
    });

    test('should_completeRequest_when_onAuthFailureThrows', () async {
      respond = (_) => _json(401, '{"error":"TOKEN_EXPIRED"}');
      refreshSession = () async => throw Exception('Refresh token rejected');
      final uncaught = <Object>[];

      await runZonedGuarded(
        () async {
          final failingDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
            ..httpClientAdapter = adapter;
          failingDio.interceptors.add(
            JwtInterceptor(
              dio: failingDio,
              secureStorage: mockStorage,
              refreshSession: () => refreshSession(),
              onAuthFailure: () => throw StateError('Provider disposed'),
            ),
          );

          await expectLater(
            failingDio.get<Map<String, dynamic>>('/some/endpoint'),
            throwsA(
              isA<DioException>()
                  .having((e) => e.response?.statusCode, 'status', 401),
            ),
          );
          await pumpEventQueue();
        },
        (error, _) => uncaught.add(error),
      );

      expect(uncaught, [isA<StateError>()]);
    });

    test('should_replayWithStoredToken_when_sessionAlreadyRenewed', () async {
      respond = (options) {
        if (options.headers['Authorization'] == 'Bearer old-token') {
          // Another call renews the session while this request is in flight.
          storedToken = 'renewed-token';
          return _json(401, '{"error":"TOKEN_EXPIRED"}');
        }
        return _json(200, '{"ok":true}');
      };

      final response = await dio.get<Map<String, dynamic>>('/some/endpoint');

      expect(response.statusCode, 200);
      expect(refreshCalls, 0);
      expect(authorizations(), ['Bearer old-token', 'Bearer renewed-token']);
      expect(authFailureCalled, isFalse);
    });

    test('should_renewSession_when_noTokenStored', () async {
      storedToken = null;
      respond = (options) => options.headers['Authorization'] == null
          ? _json(401, '{"error":"UNAUTHENTICATED"}')
          : _json(200, '{"ok":true}');

      final response = await dio.get<Map<String, dynamic>>('/some/endpoint');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(authorizations(), [null, 'Bearer new-token']);
    });

    test('should_callOnAuthFailure_when_storageReadFails', () async {
      respond = (_) {
        storageReadFails = true;
        return _json(401, '{"error":"TOKEN_EXPIRED"}');
      };

      await expectLater(
        dio.get<Map<String, dynamic>>('/some/endpoint'),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 401),
        ),
      );

      expect(authFailureCalled, isTrue);
      expect(refreshCalls, 0);
      expect(adapter.requests, hasLength(1));
    });
  });
}
