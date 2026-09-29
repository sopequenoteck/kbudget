import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';
import 'package:k_budget/src/features/admin/presentation/users_screen.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../admin_test_helpers.dart';

void main() {
  late MockAdminRepository repo;
  late MockAppConfigRepository config;
  String? clipboard;

  setUp(() {
    repo = MockAdminRepository();
    config = MockAppConfigRepository();
    clipboard = null;
    when(repo.listUsers()).thenAnswer((_) async => []);
    when(repo.listInvitations()).thenAnswer((_) async => []);
    when(
      config.getServerUrl(),
    ).thenAnswer((_) async => 'https://budget.example.com/api');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpApp(
      const UsersScreen(),
      overrides: [
        adminRepoOverride(repo),
        appConfigRepositoryProvider.overrideWithValue(config),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> openUsersTab(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(Tab, 'Utilisateurs'));
    await tester.pumpAndSettle();
  }

  Future<void> submitInvite(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Inviter un utilisateur'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'new@example.com');
    await tester.tap(find.text('Créer et copier le lien'));
    await tester.pumpAndSettle();
  }

  group('titres et onglets', () {
    testWidgets('should_showTitleTabsAndInviteTooltip_when_built', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Utilisateurs'), findsNWidgets(2));
      expect(find.widgetWithText(Tab, 'Invitations'), findsOneWidget);
      expect(find.byTooltip('Inviter un utilisateur'), findsOneWidget);
    });
  });

  group('onglet invitations', () {
    testWidgets('should_showEmptyMessage_when_noInvitation', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Aucune invitation pour le moment'), findsOneWidget);
    });

    testWidgets('should_showTranslatedError_when_loadFails', (tester) async {
      when(repo.listInvitations()).thenThrow(Exception('secret detail'));

      await pumpScreen(tester);

      expect(
        find.text('Impossible de charger les invitations.'),
        findsOneWidget,
      );
      expect(find.textContaining('secret detail'), findsNothing);
    });

    testWidgets('should_listInvitations_when_loaded', (tester) async {
      when(repo.listInvitations()).thenAnswer((_) async => [invitation()]);

      await pumpScreen(tester);

      expect(find.text('new@example.com'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('should_copyLinkAndShowSnackbar_when_copyTapped', (
      tester,
    ) async {
      when(repo.listInvitations()).thenAnswer((_) async => [invitation()]);
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Copier le lien'));
      await tester.pumpAndSettle();

      expect(clipboard, 'https://budget.example.com/accept-invite/tok');
      expect(find.text('Lien copié dans le presse-papiers.'), findsOneWidget);
    });

    testWidgets('should_useLocalhostLink_when_noServerUrl', (tester) async {
      when(config.getServerUrl()).thenAnswer((_) async => null);
      when(repo.listInvitations()).thenAnswer((_) async => [invitation()]);
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Copier le lien'));
      await tester.pumpAndSettle();

      expect(clipboard, 'http://localhost:8080/accept-invite/tok');
    });

    testWidgets('should_revokeInvitation_when_revokeTapped', (tester) async {
      when(repo.listInvitations()).thenAnswer((_) async => [invitation()]);
      when(repo.revokeInvitation(1)).thenAnswer((_) async {});
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Révoquer'));
      await tester.pumpAndSettle();

      verify(repo.revokeInvitation(1)).called(1);
    });
  });

  group('onglet utilisateurs', () {
    testWidgets('should_showEmptyMessage_when_noUser', (tester) async {
      await pumpScreen(tester);
      await openUsersTab(tester);

      expect(find.text('Aucun utilisateur trouvé'), findsOneWidget);
    });

    testWidgets('should_showTranslatedError_when_loadFails', (tester) async {
      when(repo.listUsers()).thenThrow(Exception('secret detail'));
      await pumpScreen(tester);
      await openUsersTab(tester);

      expect(
        find.text('Impossible de charger les utilisateurs.'),
        findsOneWidget,
      );
      expect(find.textContaining('secret detail'), findsNothing);
    });

    testWidgets('should_disableUser_when_disableTapped', (tester) async {
      when(repo.listUsers()).thenAnswer((_) async => [adminUser()]);
      when(repo.disableUser('u1')).thenAnswer((_) async {});
      await pumpScreen(tester);
      await openUsersTab(tester);

      await tester.tap(find.byTooltip('Désactiver'));
      await tester.pumpAndSettle();

      verify(repo.disableUser('u1')).called(1);
    });

    testWidgets('should_showApiErrorLabel_when_disableRejectedWithCode', (
      tester,
    ) async {
      when(repo.listUsers()).thenAnswer((_) async => [adminUser()]);
      when(
        repo.disableUser('u1'),
      ).thenThrow(_dioError({'error': 'LAST_ADMIN_CANNOT_BE_DISABLED'}));
      await pumpScreen(tester);
      await openUsersTab(tester);

      await tester.tap(find.byTooltip('Désactiver'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de désactiver le dernier administrateur actif.'),
        findsOneWidget,
      );
    });

    testWidgets('should_showFallbackMessage_when_disableRejectedWithoutCode', (
      tester,
    ) async {
      when(repo.listUsers()).thenAnswer((_) async => [adminUser()]);
      when(repo.disableUser('u1')).thenThrow(_dioError(null));
      await pumpScreen(tester);
      await openUsersTab(tester);

      await tester.tap(find.byTooltip('Désactiver'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de désactiver l\'utilisateur.'),
        findsOneWidget,
      );
    });

    testWidgets('should_showDisableError_when_disableThrowsException', (
      tester,
    ) async {
      when(repo.listUsers()).thenAnswer((_) async => [adminUser()]);
      when(repo.disableUser('u1')).thenThrow(Exception('boom'));
      await pumpScreen(tester);
      await openUsersTab(tester);

      await tester.tap(find.byTooltip('Désactiver'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de désactiver l\'utilisateur.'),
        findsOneWidget,
      );
    });

    testWidgets('should_enableUser_when_enableTapped', (tester) async {
      when(
        repo.listUsers(),
      ).thenAnswer((_) async => [adminUser(disabledAt: DateTime(2026, 2, 1))]);
      when(repo.enableUser('u1')).thenAnswer((_) async {});
      await pumpScreen(tester);
      await openUsersTab(tester);

      await tester.tap(find.byTooltip('Réactiver'));
      await tester.pumpAndSettle();

      verify(repo.enableUser('u1')).called(1);
    });
  });

  group('dialogue d\'invitation', () {
    testWidgets('should_createInviteCopyLinkAndNotify_when_emailValid', (
      tester,
    ) async {
      when(repo.createInvitation('new@example.com')).thenAnswer(
        (_) async =>
            InvitationCreated(token: 'abc', expiresAt: DateTime(2026, 2, 1)),
      );
      await pumpScreen(tester);

      await submitInvite(tester);

      expect(clipboard, 'https://budget.example.com/accept-invite/abc');
      expect(
        find.text('Invitation créée et lien copié dans le presse-papiers.'),
        findsOneWidget,
      );
    });

    testWidgets('should_showCreateError_when_creationFails', (tester) async {
      when(
        repo.createInvitation('new@example.com'),
      ).thenThrow(Exception('boom'));
      await pumpScreen(tester);

      await submitInvite(tester);

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Impossible de créer l\'invitation.'),
        ),
        findsOneWidget,
      );
    });
  });
}

DioException _dioError(Object? data) => DioException(
  requestOptions: RequestOptions(path: '/admin/users/u1/disable'),
  response: data == null
      ? null
      : Response<Object?>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 409,
          data: data,
        ),
);
