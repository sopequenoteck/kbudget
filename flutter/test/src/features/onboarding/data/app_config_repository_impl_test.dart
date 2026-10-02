// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/onboarding/data/app_config_repository_impl.dart';

void main() {
  group('AppConfigRepositoryImpl language', () {
    late AppConfigRepositoryImpl repo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      repo = AppConfigRepositoryImpl();
    });

    test('should_returnNull_when_noLanguageStored', () async {
      expect(await repo.getLanguage(), isNull);
    });

    test('should_returnLanguage_when_stored', () async {
      await repo.setLanguage('fr');

      expect(await repo.getLanguage(), 'fr');
    });

    test('should_clearLanguage_when_setToNull', () async {
      await repo.setLanguage('fr');

      await repo.setLanguage(null);

      expect(await repo.getLanguage(), isNull);
    });

    test('should_keepOtherSettings_when_languageStored', () async {
      await repo.setDataMode(DataMode.server);

      await repo.setLanguage('en');

      expect(await repo.getDataMode(), DataMode.server);
      expect((await repo.getConfig()).language, 'en');
    });
  });
}
