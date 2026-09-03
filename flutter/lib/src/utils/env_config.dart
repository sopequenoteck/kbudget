// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

class EnvConfig {
  EnvConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  /// Segment de version des endpoints metier (KKS-313).
  ///
  /// [apiBaseUrl] reste la racine de l'API : c'est l'URL que le self-hoster
  /// saisit, et celle dont derivent le WebSocket et le health check, qui ne
  /// sont pas versionnes. Seul le client HTTP metier ajoute ce segment.
  static const String apiVersionPath = '/v1';

  /// Racine des endpoints metier, version comprise.
  static String versionedUrl(String baseUrl) =>
      '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}'
      '$apiVersionPath';

  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}
