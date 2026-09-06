// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/api_error.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/localization/app_localizations_fr.dart';

DioException _dioError(Object? data) => DioException(
  requestOptions: RequestOptions(),
  response: Response(
    requestOptions: RequestOptions(),
    statusCode: 400,
    data: data,
  ),
);

void main() {
  final AppLocalizations l10n = AppLocalizationsFr();

  group('apiErrorCode', () {
    test('should_returnCode_when_bodyCarriesOne', () {
      final e = _dioError({'error': 'NOT_FOUND', 'message': 'peu importe'});

      expect(apiErrorCode(e), 'NOT_FOUND');
    });

    test('should_returnNull_when_bodyIsNotAMap', () {
      // Un 502 de reverse proxy renvoie du HTML.
      expect(apiErrorCode(_dioError('<html>502</html>')), isNull);
      expect(apiErrorCode(_dioError(<String>['NOT_FOUND'])), isNull);
      expect(apiErrorCode(_dioError(null)), isNull);
    });

    test('should_returnNull_when_errorFieldIsAbsentOrNotAString', () {
      expect(apiErrorCode(_dioError({'message': 'sans code'})), isNull);
      expect(apiErrorCode(_dioError({'error': 42})), isNull);
      expect(apiErrorCode(_dioError({'error': ''})), isNull);
    });

    test('should_returnNull_when_thereIsNoResponse', () {
      final e = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );

      expect(apiErrorCode(e), isNull);
    });
  });

  group('errorLabel', () {
    test('should_returnArbLabel_when_codeIsKnown', () {
      expect(errorLabel(l10n, 'NOT_FOUND'), l10n.errorCodeNotFound);
      expect(
        errorLabel(l10n, 'TOO_MANY_REQUESTS'),
        l10n.errorCodeTooManyRequests,
      );
    });

    test('should_distinguishTokenExpired_from_unauthenticated', () {
      // Le code actuel produisait le meme texte pour les deux (KKS-324).
      expect(
        errorLabel(l10n, 'TOKEN_EXPIRED'),
        isNot(errorLabel(l10n, 'UNAUTHENTICATED')),
      );
    });

    test('should_returnGenericLabel_when_codeIsUnknown', () {
      // Un client ancien face a un serveur recent : nominal, pas une anomalie.
      expect(errorLabel(l10n, 'BREWING_COFFEE'), l10n.errorGeneric);
    });

    test('should_returnGenericLabel_when_codeIsNull', () {
      expect(errorLabel(l10n, null), l10n.errorGeneric);
    });

    test('should_returnFallback_when_codeIsNullOrUnknown', () {
      expect(errorLabel(l10n, null, fallback: 'Repli'), 'Repli');
      expect(errorLabel(l10n, 'BREWING_COFFEE', fallback: 'Repli'), 'Repli');
    });

    test('should_preferOverride_when_codeIsOverridden', () {
      // Sur /auth/login, BAD_REQUEST ne signifie qu'une chose.
      final label = errorLabel(
        l10n,
        'BAD_REQUEST',
        overrides: {'BAD_REQUEST': l10n.loginInvalidCredentials},
      );

      expect(label, l10n.loginInvalidCredentials);
      expect(label, isNot(l10n.errorCodeBadRequest));
    });

    test('should_useCatalogue_when_codeIsNotOverridden', () {
      final label = errorLabel(
        l10n,
        'CONFLICT',
        overrides: {'BAD_REQUEST': l10n.loginInvalidCredentials},
      );

      expect(label, l10n.errorCodeConflict);
    });

    test('should_returnLabelWithoutThrowing_when_bodyIsMalformed', () {
      // Le chemin complet : corps non conforme -> code null -> libelle.
      final label = errorLabel(
        l10n,
        apiErrorCode(_dioError('<html>502</html>')),
        fallback: 'Repli contextuel',
      );

      expect(label, 'Repli contextuel');
    });
  });
}
