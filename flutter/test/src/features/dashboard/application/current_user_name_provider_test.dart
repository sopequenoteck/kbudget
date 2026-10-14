// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';

import '../../settings/application/language_notifier_test.dart'
    show FakeAuthNotifier;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('currentUserNameProvider', () {
    late ProviderContainer container;

    Future<String?> userName() =>
        container.read(currentUserNameProvider.future);

    void emit(AuthState next) =>
        (container.read(authNotifierProvider.notifier) as FakeAuthNotifier)
            .emit(next);

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({'user_name': 'Alice'});
      container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthState.unauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('should_readStoredName_when_built', () async {
      expect(await userName(), 'Alice');
    });

    test('should_returnNull_when_noNameStored', () async {
      FlutterSecureStorage.setMockInitialValues({});

      expect(await userName(), isNull);
    });

    test('should_readNewName_when_userLogsIn', () async {
      expect(await userName(), 'Alice');
      // Another account signs in: its name replaces the stored one
      await const FlutterSecureStorage().write(key: 'user_name', value: 'Bob');

      emit(const AuthState.authenticated());

      expect(await userName(), 'Bob');
    });

    test('should_forgetName_when_userLogsOut', () async {
      emit(const AuthState.authenticated());
      expect(await userName(), 'Alice');
      await const FlutterSecureStorage().delete(key: 'user_name');

      emit(const AuthState.unauthenticated());

      expect(await userName(), isNull);
    });
  });
}
