// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/onboarding/data/legacy_local_database.dart';

void main() {
  group('deleteLegacyLocalDatabase', () {
    late Directory dir;

    File fileOf(String name) =>
        File('${dir.path}${Platform.pathSeparator}$name');

    setUp(() {
      dir = Directory.systemTemp.createTempSync('k_budget_legacy_db_');
    });

    tearDown(() {
      dir.deleteSync(recursive: true);
    });

    test('should_deleteDatabaseAndSidecarFiles_when_present', () async {
      for (final name in [
        'k_budget.sqlite',
        'k_budget.sqlite-wal',
        'k_budget.sqlite-shm',
        'k_budget.sqlite-journal',
      ]) {
        fileOf(name).writeAsStringSync('data');
      }

      await deleteLegacyLocalDatabase(directory: () async => dir);

      expect(dir.listSync(), isEmpty);
    });

    test('should_leaveOtherFilesUntouched_when_deleting', () async {
      fileOf('k_budget.sqlite').writeAsStringSync('data');
      fileOf('avatar.png').writeAsStringSync('keep');

      await deleteLegacyLocalDatabase(directory: () async => dir);

      expect(fileOf('k_budget.sqlite').existsSync(), isFalse);
      expect(fileOf('avatar.png').existsSync(), isTrue);
    });

    test('should_notFail_when_databaseAbsent', () async {
      await expectLater(
        deleteLegacyLocalDatabase(directory: () async => dir),
        completes,
      );
    });

    test('should_notFail_when_directoryUnavailable', () async {
      await expectLater(
        deleteLegacyLocalDatabase(
          directory: () async => throw const FileSystemException('unavailable'),
        ),
        completes,
      );
    });
  });
}
