// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/utils/version_compare.dart';

/// Version de serveur la plus ancienne que ce client sait exploiter (KKS-314).
///
/// Ne bouge qu'a une rupture de contrat cote serveur. `6.1.0` est la version
/// qui
/// introduit `/api/meta` : un serveur anterieur ne sait pas se decrire.
const String kMinServerVersion = '6.1.0';

/// Interroge `/api/meta` et classe le serveur (KKS-314).
///
/// Sans ce mecanisme, une incompatibilite se manifeste par une erreur de
/// deserialisation JSON chez un utilisateur qui n'a aucun moyen de comprendre
/// que son serveur est en cause.
class CompatibilityService {
  /// Le client HTTP fourni doit pointer la racine de l'API, sans segment
  /// de version.
  const CompatibilityService(this._dio);

  final Dio _dio;

  /// [baseUrl] est la RACINE de l'API (`https://.../api`), sans segment de
  /// version : `/meta` n'est pas versionne, et c'est justement lui qui apprend
  /// au client quelle version le serveur sert.
  ///
  /// [clientVersion] provient de `PackageInfo`, donc du build.
  Future<CompatibilityStatus> check({
    required String baseUrl,
    required String clientVersion,
  }) async {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        '$root/meta',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
    } on DioException catch (e) {
      // 404 : le serveur repond mais ignore /meta — il est anterieur
      // a KKS-314, donc trop ancien. Toute autre issue signifie qu'on ne
      // sait pas : hors ligne, jamais incompatible.
      if (e.response?.statusCode == 404) {
        return const CompatibilityServerTooOld(
          requiredVersion: kMinServerVersion,
        );
      }
      return const CompatibilityOffline();
    }

    final data = response.data;
    if (data == null) {
      return const CompatibilityOffline();
    }

    final meta = ServerMeta.fromJson(data);

    // clientTooOld prime : demander a l'utilisateur de mettre a jour son app
    // est
    // actionnable, lui demander de mettre a jour un serveur qui exige deja plus
    // recent que lui ne l'est pas.
    if (isOlderThan(clientVersion, meta.minClientVersion)) {
      return CompatibilityClientTooOld(
        clientVersion: clientVersion,
        requiredVersion: meta.minClientVersion,
      );
    }
    if (isOlderThan(meta.serverVersion, kMinServerVersion)) {
      return CompatibilityServerTooOld(
        serverVersion: meta.serverVersion,
        requiredVersion: kMinServerVersion,
      );
    }
    return CompatibilityOk(meta);
  }
}

/// Service de verification de compatibilite, sur un client HTTP dedie.
///
/// Volontairement distinct du Dio metier : celui-ci pointe la racine de l'API,
/// la ou le client metier vise la version courante.
final compatibilityServiceProvider = Provider<CompatibilityService>(
  (ref) => CompatibilityService(
    Dio(BaseOptions(connectTimeout: const Duration(seconds: 10))),
  ),
);
