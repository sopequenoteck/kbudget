import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/data/remote/dtos/transfer_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transfer_form.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

import '../../../../../helpers/display_locale.dart';

void main() {
  const accountA = Account(
    id: 'acc-a',
    nom: 'Compte courant',
    type: AccountType.courant,
    soldeInitial: 250,
    icone: '🏦',
    couleur: '#4CAF50',
    isDefault: true,
    actif: true,
    solde: 250,
  );

  const accountB = Account(
    id: 'acc-b',
    nom: 'Épargne',
    type: AccountType.epargne,
    soldeInitial: 500,
    icone: '🐷',
    couleur: '#2196F3',
    actif: true,
    solde: 500,
  );

  Widget buildApp({
    required Future<void> Function(TransferRequest) onSaved,
    VoidCallback? onCancelled,
  }) {
    return ProviderScope(
      overrides: [displayLocaleOverride()],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: TransferForm(
            accounts: const [accountA, accountB],
            onSaved: onSaved,
            onCancelled: onCancelled ?? () {},
          ),
        ),
      ),
    );
  }

  /// Ouvre le [SelectPicker] à l'index [pickerIndex] (0 = source, 1 =
  /// destination) et sélectionne l'item [accountName] dans la modale.
  Future<void> selectAccount(
    WidgetTester tester, {
    required int pickerIndex,
    required String accountName,
  }) async {
    final trigger = find.descendant(
      of: find.byType(SelectPicker).at(pickerIndex),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(trigger.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(accountName));
    await tester.pumpAndSettle();
  }

  group('TransferForm', () {
    testWidgets(
        'should_displayFieldsAndAccountBalances_when_rendered',
        (tester) async {
      await tester.pumpWidget(buildApp(onSaved: (_) async {}));
      await tester.pumpAndSettle();

      expect(find.text('Compte source'), findsOneWidget);
      expect(find.text('Compte destination'), findsOneWidget);
      expect(find.text('Montant'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Effectuer le virement'), findsOneWidget);

      // Ouvre le picker source : les soldes formatés sont affichés
      await selectAccount(tester, pickerIndex: 0, accountName: 'Compte courant');

      expect(find.textContaining('250,00'), findsWidgets);
    });

    testWidgets(
        'should_showErrorSnackbarAndKeepForm_when_onSavedThrows',
        (tester) async {
      await tester.pumpWidget(
        buildApp(onSaved: (_) async => throw Exception('boom')),
      );
      await tester.pumpAndSettle();

      await selectAccount(tester, pickerIndex: 0, accountName: 'Compte courant');
      await selectAccount(tester, pickerIndex: 1, accountName: 'Épargne');
      await tester.enterText(find.byType(TextField).first, '100');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effectuer le virement'));
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets(
        'should_callOnSavedWithRequest_when_formValidAndSubmitted',
        (tester) async {
      TransferRequest? captured;
      await tester.pumpWidget(
        buildApp(onSaved: (request) async => captured = request),
      );
      await tester.pumpAndSettle();

      await selectAccount(tester, pickerIndex: 0, accountName: 'Compte courant');
      await selectAccount(tester, pickerIndex: 1, accountName: 'Épargne');
      await tester.enterText(find.byType(TextField).first, '75');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effectuer le virement'));
      // La soumission réussie laisse le bouton en état "isSubmitting" (le
      // spinner tourne indéfiniment tant que l'écran n'est pas fermé par
      // l'appelant) : on avance de quelques frames plutôt que pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(captured, isNotNull);
      expect(captured!.fromAccountId, 'acc-a');
      expect(captured!.toAccountId, 'acc-b');
      expect(captured!.montant, 75.0);
      expect(captured!.libelleDebit, 'Virement vers Épargne');
      expect(captured!.libelleCredit, 'Virement depuis Compte courant');
    });

    testWidgets('should_callOnCancelled_when_cancelButtonTapped',
        (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        buildApp(
          onSaved: (_) async {},
          onCancelled: () => cancelled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
    });
  });
}
