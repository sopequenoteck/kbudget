// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/category_name.dart';

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('categoryDisplayName', () {
    const cases = {
      'SUBSCRIPTION': ('Abonnement', 'Subscription'),
      'DEBT': ('Dette', 'Debt'),
      'TRANSFER': ('Virement', 'Transfer'),
      'ADJUSTMENT': ('Ajustement', 'Balance adjustment'),
    };

    for (final MapEntry(key: key, value: (frText, enText)) in cases.entries) {
      test('should_translate_when_systemKeyIs$key', () {
        expect(categoryDisplayName('Stored', key, fr), frText);
        expect(categoryDisplayName('Stored', key, en), enText);
      });
    }

    test('should_returnNom_when_systemKeyIsNull', () {
      expect(categoryDisplayName('Courses', null, fr), 'Courses');
    });

    test('should_returnNom_when_systemKeyIsEmpty', () {
      expect(categoryDisplayName('Courses', '', fr), 'Courses');
    });

    test('should_returnNom_when_systemKeyIsUnknown', () {
      expect(categoryDisplayName('Savings', 'SAVINGS', fr), 'Savings');
    });

    test('should_returnNom_when_systemKeyHasWrongCase', () {
      expect(categoryDisplayName('Debt', 'debt', fr), 'Debt');
    });
  });
}
