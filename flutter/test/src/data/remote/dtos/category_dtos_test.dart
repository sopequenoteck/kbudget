// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/category_dtos.dart';

Map<String, dynamic> _json({Object? systemKey, bool withKey = true}) => {
      'id': 'cat-001',
      'nom': 'Subscription',
      'icone': '🔁',
      'couleur': '#8B5CF6',
      'isSystem': true,
      if (withKey) 'systemKey': systemKey,
    };

void main() {
  group('CategoryResponse.fromJson', () {
    test('should_readSystemKey_when_present', () {
      final r = CategoryResponse.fromJson(_json(systemKey: 'SUBSCRIPTION'));

      expect(r.systemKey, 'SUBSCRIPTION');
    });

    test('should_leaveSystemKeyNull_when_absent', () {
      final r = CategoryResponse.fromJson(_json(withKey: false));

      expect(r.systemKey, isNull);
    });

    test('should_leaveSystemKeyNull_when_null', () {
      final r = CategoryResponse.fromJson(_json());

      expect(r.systemKey, isNull);
    });

    test('should_keepUnknownSystemKey_when_serverIsNewer', () {
      final r = CategoryResponse.fromJson(_json(systemKey: 'SAVINGS'));

      expect(r.systemKey, 'SAVINGS');
    });
  });
}
