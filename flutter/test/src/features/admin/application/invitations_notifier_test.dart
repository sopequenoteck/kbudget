import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/admin/application/invitations_notifier.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';
import 'package:k_budget/src/localization/app_localizations_fr.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';
import '../admin_test_helpers.dart';

void main() {
  late MockAdminRepository repo;
  late ProviderContainer container;
  final l10n = AppLocalizationsFr();

  InvitationsNotifier notifier() =>
      container.read(invitationsNotifierProvider.notifier);

  setUp(() async {
    repo = MockAdminRepository();
    container = await adminContainer(repo);
  });

  tearDown(() => container.dispose());

  group('loadItems', () {
    test('should_storeInvitations_when_loadSucceeds', () async {
      when(repo.listInvitations()).thenAnswer((_) async => [invitation()]);

      await notifier().loadItems();

      final state = container.read(invitationsNotifierProvider);
      expect(state.items, hasLength(1));
      expect(state.error, isNull);
      expect(state.isLoading, false);
    });

    test('should_setTranslatedErrorWithoutDetail_when_loadFails', () async {
      when(repo.listInvitations()).thenThrow(Exception('secret detail'));

      await notifier().loadItems();

      final state = container.read(invitationsNotifierProvider);
      expect(state.error, l10n.usersFeedbackLoadInvitationsError);
      expect(state.error, isNot(contains('secret detail')));
    });
  });

  group('createInvitation', () {
    test('should_returnCreatedAndReload_when_createSucceeds', () async {
      final created = InvitationCreated(
        token: 'tok',
        expiresAt: DateTime(2026, 2, 1),
      );
      when(repo.createInvitation('a@b.c')).thenAnswer((_) async => created);
      when(repo.listInvitations()).thenAnswer((_) async => [invitation()]);

      final result = await notifier().createInvitation('a@b.c');

      expect(result, created);
      expect(container.read(invitationsNotifierProvider).items, hasLength(1));
    });

    test('should_rethrowWithTranslatedError_when_createFails', () async {
      when(repo.createInvitation('a@b.c')).thenThrow(Exception('secret'));

      await expectLater(notifier().createInvitation('a@b.c'), throwsException);

      final state = container.read(invitationsNotifierProvider);
      expect(state.error, l10n.usersFeedbackInviteCreateError);
      expect(state.isLoading, false);
    });
  });

  group('revoke', () {
    test('should_reloadAndClearMutation_when_revokeSucceeds', () async {
      when(repo.revokeInvitation(1)).thenAnswer((_) async {});
      when(repo.listInvitations()).thenAnswer((_) async => [invitation()]);

      await notifier().revoke(1);

      final state = container.read(invitationsNotifierProvider);
      expect(state.mutatingIds, isEmpty);
      expect(state.error, isNull);
    });

    test('should_setTranslatedErrorWithoutDetail_when_revokeFails', () async {
      when(repo.revokeInvitation(1)).thenThrow(Exception('secret detail'));

      await notifier().revoke(1);

      final state = container.read(invitationsNotifierProvider);
      expect(state.error, l10n.usersFeedbackInviteRevokeError);
      expect(state.error, isNot(contains('secret detail')));
      expect(state.mutatingIds, isEmpty);
    });
  });
}
