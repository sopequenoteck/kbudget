// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_response.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

void main() {
  group('UserPreferenceResponse', () {
    Map<String, dynamic> json({String? language}) => {
          'enabledFeatures': ['BUDGETS'],
          'navOrder': ['BUDGETS'],
          'language': ?language,
        };

    test('should_readLanguage_when_present', () {
      final response = UserPreferenceResponse.fromJson(json(language: 'fr'));

      expect(response.language, 'fr');
      expect(response.enabledFeatures, [Feature.budgets]);
    });

    test('should_readNullLanguage_when_absent', () {
      final response = UserPreferenceResponse.fromJson(json());

      expect(response.language, isNull);
    });

    test('should_readNullLanguage_when_explicitlyNull', () {
      final response = UserPreferenceResponse.fromJson(
        {...json(), 'language': null},
      );

      expect(response.language, isNull);
    });
  });

  group('UserPreferenceRequest', () {
    test('should_serializeLanguage_when_provided', () {
      const request = UserPreferenceRequest(
        enabledFeatures: [Feature.budgets],
        language: 'en',
      );

      expect(request.toJson()['language'], 'en');
    });

    test('should_serializeNullLanguage_when_absent', () {
      const request = UserPreferenceRequest(enabledFeatures: []);

      final body = request.toJson();

      expect(body.containsKey('language'), isTrue);
      expect(body['language'], isNull);
    });
  });
}
