import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/compatibility_service.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';

/// Adapter Dio minimal : la reponse de `/meta` est scriptee par test.
///
/// Preferé a un mock genere — il n'y a qu'une requete a simuler, et l'adapter
/// permet de distinguer explicitement un 404 (serveur ancien) d'une erreur de
/// connexion (hors ligne), qui est la distinction que ces tests protegent.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({this.statusCode, this.body, this.throwConnectionError = false});

  final int? statusCode;
  final Map<String, dynamic>? body;
  final bool throwConnectionError;

  String? capturedPath;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream,
      Future<void>? cancelFuture) async {
    capturedPath = options.uri.toString();
    if (throwConnectionError) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'network down',
      );
    }
    return ResponseBody.fromString(
      body == null ? '' : _encode(body!),
      statusCode!,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  static String _encode(Map<String, dynamic> map) {
    final entries = map.entries.map((e) {
      final v = e.value;
      if (v is String) return '"${e.key}":"$v"';
      if (v is List) return '"${e.key}":[${v.map((x) => '"$x"').join(',')}]';
      return '"${e.key}":$v';
    });
    return '{${entries.join(',')}}';
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_StubAdapter adapter) => Dio()..httpClientAdapter = adapter;

const _validBody = {
  'serverVersion': '9.9.9',
  'apiVersion': 'v1',
  'minClientVersion': '0.0.1',
  'capabilities': ['SUBSCRIPTIONS', 'DEBTS', 'BUDGETS'],
};

void main() {
  group('CompatibilityService', () {
    test('should_callMetaWithoutVersionPrefix_when_checking', () async {
      final adapter = _StubAdapter(statusCode: 200, body: _validBody);
      await CompatibilityService(_dioWith(adapter))
          .check(baseUrl: 'https://host/api', clientVersion: '6.0.0');

      // Le prefixe de version est ce que le client vient decouvrir : le
      // supposer connu viderait l'endpoint de son role.
      expect(adapter.capturedPath, 'https://host/api/meta');
    });

    test('should_stripTrailingSlash_when_baseUrlEndsWithOne', () async {
      final adapter = _StubAdapter(statusCode: 200, body: _validBody);
      await CompatibilityService(_dioWith(adapter))
          .check(baseUrl: 'https://host/api/', clientVersion: '6.0.0');

      expect(adapter.capturedPath, 'https://host/api/meta');
    });

    test('should_returnOk_when_bothVersionsSatisfy', () async {
      final status = await CompatibilityService(
        _dioWith(_StubAdapter(statusCode: 200, body: _validBody)),
      ).check(baseUrl: 'https://host/api', clientVersion: '6.0.0');

      expect(status, isA<CompatibilityOk>());
    });

    test('should_returnServerTooOld_when_metaReturns404', () async {
      final status = await CompatibilityService(
        _dioWith(_StubAdapter(statusCode: 404, body: null)),
      ).check(baseUrl: 'https://host/api', clientVersion: '6.0.0');

      expect(status, isA<CompatibilityServerTooOld>());
      expect((status as CompatibilityServerTooOld).serverVersion, isNull);
    });

    test('should_returnOffline_and_notServerTooOld_when_connectionFails', () async {
      // Distinction critique : un serveur injoignable n'est pas un serveur
      // incompatible. Les confondre afficherait « mettez votre serveur a jour »
      // a un utilisateur simplement hors ligne.
      final status = await CompatibilityService(
        _dioWith(_StubAdapter(throwConnectionError: true)),
      ).check(baseUrl: 'https://host/api', clientVersion: '6.0.0');

      expect(status, isA<CompatibilityOffline>());
    });

    test('should_returnOffline_when_serverReturns500', () async {
      final status = await CompatibilityService(
        _dioWith(_StubAdapter(statusCode: 500, body: null)),
      ).check(baseUrl: 'https://host/api', clientVersion: '6.0.0');

      expect(status, isA<CompatibilityOffline>());
    });

    test('should_returnServerTooOld_when_serverVersionBelowMinimum', () async {
      final status = await CompatibilityService(
        _dioWith(_StubAdapter(
          statusCode: 200,
          body: {..._validBody, 'serverVersion': '1.0.0'},
        )),
      ).check(baseUrl: 'https://host/api', clientVersion: '6.0.0');

      expect(status, isA<CompatibilityServerTooOld>());
      expect((status as CompatibilityServerTooOld).serverVersion, '1.0.0');
      expect(status.requiredVersion, kMinServerVersion);
    });

    test('should_returnClientTooOld_when_clientBelowMinClientVersion', () async {
      final status = await CompatibilityService(
        _dioWith(_StubAdapter(
          statusCode: 200,
          body: {..._validBody, 'minClientVersion': '999.0.0'},
        )),
      ).check(baseUrl: 'https://host/api', clientVersion: '6.0.0');

      expect(status, isA<CompatibilityClientTooOld>());
      expect((status as CompatibilityClientTooOld).requiredVersion, '999.0.0');
    });

    test('should_prioritiseClientTooOld_when_bothAreOutOfRange', () async {
      // Demander a l'utilisateur de mettre a jour son app est actionnable ; lui
      // demander de mettre a jour un serveur qui exige deja plus recent que lui
      // ne l'est pas.
      final status = await CompatibilityService(
        _dioWith(_StubAdapter(
          statusCode: 200,
          body: {..._validBody, 'serverVersion': '1.0.0', 'minClientVersion': '999.0.0'},
        )),
      ).check(baseUrl: 'https://host/api', clientVersion: '6.0.0');

      expect(status, isA<CompatibilityClientTooOld>());
    });

    test('should_ignoreBuildNumber_when_clientVersionCarriesOne', () async {
      // PackageInfo.version n'inclut pas le build number, mais un appelant
      // pourrait passer la valeur brute de pubspec.
      final status = await CompatibilityService(
        _dioWith(_StubAdapter(
          statusCode: 200,
          body: {..._validBody, 'minClientVersion': '6.0.0'},
        )),
      ).check(baseUrl: 'https://host/api', clientVersion: '6.0.0+1');

      expect(status, isA<CompatibilityOk>());
    });
  });
}
