import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';
import 'package:k_budget/src/features/admin/presentation/invite_dialog.dart';
import 'package:k_budget/src/features/admin/presentation/widgets/admin_user_list_item.dart';
import 'package:k_budget/src/features/admin/presentation/widgets/invitation_list_item.dart';

import '../../../../helpers/pump_app.dart';
import '../admin_test_helpers.dart';

void main() {
  group('AdminUserListItem', () {
    testWidgets('should_showAdminTooltipAndDisable_when_activeAdmin', (
      tester,
    ) async {
      var disabled = false;
      await tester.pumpApp(
        Scaffold(
          body: AdminUserListItem(
            user: adminUser(isAdmin: true),
            onDisable: () => disabled = true,
          ),
        ),
      );

      expect(find.byTooltip('Admin'), findsOneWidget);
      expect(find.byTooltip('Réactiver'), findsNothing);
      await tester.tap(find.byTooltip('Désactiver'));
      expect(disabled, true);
    });

    testWidgets('should_showEnableAction_when_userDisabled', (tester) async {
      var enabled = false;
      await tester.pumpApp(
        Scaffold(
          body: AdminUserListItem(
            user: adminUser(disabledAt: DateTime(2026, 2, 1)),
            onEnable: () => enabled = true,
          ),
        ),
      );

      expect(find.byTooltip('Admin'), findsNothing);
      expect(find.byTooltip('Désactiver'), findsNothing);
      await tester.tap(find.byTooltip('Réactiver'));
      expect(enabled, true);
    });

    testWidgets('should_showSpinnerWithoutActions_when_mutating', (
      tester,
    ) async {
      await tester.pumpApp(
        Scaffold(body: AdminUserListItem(user: adminUser(), isMutating: true)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Désactiver'), findsNothing);
    });

    testWidgets('should_useEmailInitial_when_displayNameEmpty', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: AdminUserListItem(user: adminUser(displayName: '')),
        ),
      );

      expect(find.text('A'), findsOneWidget);
    });
  });

  group('InvitationListItem', () {
    const labels = {
      InvitationStatus.active: 'Active',
      InvitationStatus.expired: 'Expirée',
      InvitationStatus.used: 'Utilisée',
      InvitationStatus.revoked: 'Révoquée',
    };

    for (final entry in labels.entries) {
      testWidgets('should_showFeminineLabel_when_status${entry.key.name}', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: InvitationListItem(invitation: invitation(status: entry.key)),
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('Par boss@example.com'), findsOneWidget);
      });
    }

    testWidgets('should_showCopyAndRevoke_when_activeWithToken', (
      tester,
    ) async {
      var copied = false;
      var revoked = false;
      await tester.pumpApp(
        Scaffold(
          body: InvitationListItem(
            invitation: invitation(),
            onCopyLink: () => copied = true,
            onRevoke: () => revoked = true,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Copier le lien'));
      await tester.tap(find.byTooltip('Révoquer'));

      expect(copied, true);
      expect(revoked, true);
    });

    testWidgets('should_hideActions_when_notActiveOrNoToken', (tester) async {
      await tester.pumpApp(
        Scaffold(body: InvitationListItem(invitation: invitation(token: null))),
      );

      expect(find.byTooltip('Copier le lien'), findsNothing);
      expect(find.byTooltip('Révoquer'), findsNothing);
    });

    testWidgets('should_showSpinner_when_mutating', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: InvitationListItem(invitation: invitation(), isMutating: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Active'), findsNothing);
    });
  });

  group('InviteDialog', () {
    testWidgets('should_showTranslatedLabels_when_built', (tester) async {
      await tester.pumpApp(Scaffold(body: InviteDialog(onSubmit: (_) {})));

      expect(find.text('Inviter un utilisateur'), findsOneWidget);
      expect(find.text('Adresse email'), findsOneWidget);
      expect(find.text('nouveau@exemple.com'), findsOneWidget);
      expect(find.text('Créer et copier le lien'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('should_showRequiredError_when_emailEmpty', (tester) async {
      String? submitted;
      await tester.pumpApp(
        Scaffold(body: InviteDialog(onSubmit: (e) => submitted = e)),
      );

      await tester.tap(find.text('Créer et copier le lien'));
      await tester.pump();

      expect(find.text('Email requis'), findsOneWidget);
      expect(submitted, isNull);
    });

    testWidgets('should_showInvalidError_when_emailWithoutAt', (tester) async {
      await tester.pumpApp(Scaffold(body: InviteDialog(onSubmit: (_) {})));

      await tester.enterText(find.byType(TextFormField), 'nope');
      await tester.tap(find.text('Créer et copier le lien'));
      await tester.pump();

      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('should_submitTrimmedEmail_when_valid', (tester) async {
      String? submitted;
      await tester.pumpApp(
        Scaffold(body: InviteDialog(onSubmit: (e) => submitted = e)),
      );

      await tester.enterText(find.byType(TextFormField), ' a@b.c ');
      await tester.tap(find.text('Créer et copier le lien'));
      await tester.pump();

      expect(submitted, 'a@b.c');
    });

    testWidgets('should_disableButtonsAndShowSpinner_when_loading', (
      tester,
    ) async {
      await tester.pumpApp(
        Scaffold(body: InviteDialog(onSubmit: (_) {}, isLoading: true)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Créer et copier le lien'), findsNothing);
      final cancel = tester.widget<TextButton>(find.byType(TextButton));
      expect(cancel.onPressed, isNull);
    });
  });
}
