// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('CompatibilityMessage.userMessage', () {
    test('should_returnNull_when_ok', () {
      const status = CompatibilityOk(
        ServerMeta(
          serverVersion: '6.1.0',
          apiVersion: 'v1',
          minClientVersion: '1.0.0',
          capabilities: [],
        ),
      );

      expect(status.userMessage(fr), isNull);
    });

    test('should_returnOfflineMessage_when_offline', () {
      const status = CompatibilityOffline();

      expect(
        status.userMessage(fr),
        "Serveur injoignable. Vérifiez l'URL et votre connexion.",
      );
      expect(
        status.userMessage(en),
        'Server unreachable. Check the URL and your connection.',
      );
    });

    test('should_returnUnknownVersionMessage_when_serverVersionMissing', () {
      const status = CompatibilityServerTooOld(requiredVersion: '6.1.0');

      final message = status.userMessage(fr)!;
      expect(message, contains('trop ancien pour indiquer sa version'));
      expect(message, contains('6.1.0'));
    });

    test('should_returnVersionMessage_when_serverVersionKnown', () {
      const status = CompatibilityServerTooOld(
        serverVersion: '5.4.0',
        requiredVersion: '6.1.0',
      );

      final message = status.userMessage(fr)!;
      expect(message, contains('5.4.0'));
      expect(message, contains('6.1.0'));
    });

    test('should_omitClientVersion_when_clientTooOldAndNotVerbose', () {
      const status = CompatibilityClientTooOld(
        clientVersion: '5.0.0',
        requiredVersion: '6.1.0',
      );

      final message = status.userMessage(fr)!;
      expect(message, contains('6.1.0'));
      expect(message, isNot(contains('5.0.0')));
    });

    test('should_includeClientVersion_when_clientTooOldAndVerbose', () {
      const status = CompatibilityClientTooOld(
        clientVersion: '5.0.0',
        requiredVersion: '6.1.0',
      );

      final message = status.userMessage(fr, verbose: true)!;
      expect(message, contains('6.1.0'));
      expect(message, contains('5.0.0'));
    });
  });
}
