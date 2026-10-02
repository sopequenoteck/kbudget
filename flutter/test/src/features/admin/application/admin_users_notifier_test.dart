import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/admin/application/admin_users_notifier.dart';
import 'package:k_budget/src/localization/app_localizations_fr.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';
import '../admin_test_helpers.dart';

void main() {
  late MockAdminRepository repo;
  late ProviderContainer container;
  final l10n = AppLocalizationsFr();

  AdminUsersNotifier notifier() =>
      container.read(adminUsersNotifierProvider.notifier);

  setUp(() async {
    repo = MockAdminRepository();
    container = await adminContainer(repo);
  });

  tearDown(() => container.dispose());

  group('loadItems', () {
    test('should_storeUsers_when_loadSucceeds', () async {
      when(repo.listUsers()).thenAnswer((_) async => [adminUser()]);

      await notifier().loadItems();

      final state = container.read(adminUsersNotifierProvider);
      expect(state.items, hasLength(1));
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should_setTranslatedErrorWithoutDetail_when_loadFails', () async {
      when(repo.listUsers()).thenThrow(Exception('secret detail'));

      await notifier().loadItems();

      final state = container.read(adminUsersNotifierProvider);
      expect(state.error, l10n.usersFeedbackLoadUsersError);
      expect(state.error, isNot(contains('secret detail')));
      expect(state.isLoading, false);
    });
  });

  group('disable', () {
    test('should_reloadAndClearMutation_when_disableSucceeds', () async {
      when(repo.disableUser('u1')).thenAnswer((_) async {});
      when(repo.listUsers()).thenAnswer((_) async => [adminUser()]);

      await notifier().disable('u1');

      verify(repo.disableUser('u1')).called(1);
      final state = container.read(adminUsersNotifierProvider);
      expect(state.mutatingIds, isEmpty);
      expect(state.items, hasLength(1));
    });

    test('should_rethrowAndClearMutation_when_disableFails', () async {
      when(repo.disableUser('u1')).thenThrow(Exception('boom'));

      await expectLater(notifier().disable('u1'), throwsException);

      expect(container.read(adminUsersNotifierProvider).mutatingIds, isEmpty);
    });
  });

  group('enable', () {
    test('should_reloadAndClearMutation_when_enableSucceeds', () async {
      when(repo.enableUser('u1')).thenAnswer((_) async {});
      when(repo.listUsers()).thenAnswer((_) async => [adminUser()]);

      await notifier().enable('u1');

      final state = container.read(adminUsersNotifierProvider);
      expect(state.mutatingIds, isEmpty);
      expect(state.error, isNull);
    });

    test('should_setTranslatedErrorWithoutDetail_when_enableFails', () async {
      when(repo.enableUser('u1')).thenThrow(Exception('secret detail'));

      await notifier().enable('u1');

      final state = container.read(adminUsersNotifierProvider);
      expect(state.error, l10n.usersFeedbackUserEnableError);
      expect(state.error, isNot(contains('secret detail')));
      expect(state.mutatingIds, isEmpty);
    });
  });
}
