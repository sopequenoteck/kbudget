import 'package:dio/dio.dart';

/// Exception metier typee pour les erreurs reseau.
///
/// Encapsule les erreurs de connectivite (pas de reseau, timeout)
/// pour un traitement uniforme au niveau des notifiers.
class NetworkException implements Exception {
  const NetworkException({
    required this.message,
    this.originalError,
  });

  final String message;
  final DioException? originalError;

  @override
  String toString() => 'NetworkException: $message';
}

/// Dio interceptor that catches network-related errors and wraps them
/// in a typed [NetworkException].
///
/// Catches [DioExceptionType.connectionError], [DioExceptionType.connectionTimeout],
/// and [DioExceptionType.receiveTimeout] errors.
class ConnectivityInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionError:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(
              message: 'Impossible de se connecter au serveur. '
                  'Verifiez votre connexion internet.',
              originalError: err,
            ),
            type: err.type,
          ),
        );
      case DioExceptionType.connectionTimeout:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(
              message: 'Le serveur ne repond pas. '
                  'La connexion a expire.',
              originalError: err,
            ),
            type: err.type,
          ),
        );
      case DioExceptionType.receiveTimeout:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(
              message: 'Le serveur met trop de temps a repondre. '
                  'Veuillez reessayer.',
              originalError: err,
            ),
            type: err.type,
          ),
        );
      default:
        return handler.next(err);
    }
  }
}
