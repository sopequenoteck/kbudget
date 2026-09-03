import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/jwt_interceptor.dart';
import 'package:mockito/annotations.dart';

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

void main() {
  late MockFlutterSecureStorage mockStorage;
  late Dio dio;
  late bool passwordResetRequiredCalled;
  late JwtInterceptor interceptor;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    passwordResetRequiredCalled = false;
    interceptor = JwtInterceptor(
      dio: dio,
      secureStorage: mockStorage,
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
}
