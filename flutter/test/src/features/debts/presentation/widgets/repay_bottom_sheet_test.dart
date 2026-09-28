import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/repay_bottom_sheet.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

class _TestAccountNotifier extends AccountNotifier {
  _TestAccountNotifier(this.preloadedItems);

  final List<Account> preloadedItems;

  @override
  ListState<Account> build() => ListState<Account>(items: preloadedItems);
}

class _TestDebtNotifier extends DebtNotifier {
  _TestDebtNotifier({this.repayResult = true});

  final bool repayResult;
  String? lastAccountId;
  double? lastAmount;

  @override
  Future<bool> repay(String debtId, String accountId, double? amount) async {
    lastAccountId = accountId;
    lastAmount = amount;
    return repayResult;
  }
}

void main() {
  const testAccount = Account(
    id: 'acc1',
    nom: 'Compte courant',
    type: AccountType.courant,
    soldeInitial: 1000,
    icone: '🏦',
    couleur: '#4CAF50',
    isDefault: true,
    actif: true,
    solde: 1000,
  );

  final testDebt = Debt(
    id: 'debt1',
    personne: 'Alice',
    montant: 100.0,
    sens: DebtType.emprunt,
    date: DateTime(2026, 1, 15),
    remainingAmount: 100.0,
    accountId: 'acc1',
  );

  late _TestDebtNotifier testDebtNotifier;

  setUp(() {
    testDebtNotifier = _TestDebtNotifier();
  });

  Widget buildApp({
    List<Account> accounts = const [testAccount],
    VoidCallback? onRepaid,
  }) {
    return ProviderScope(
      overrides: [
        accountNotifierProvider.overrideWith(
          () => _TestAccountNotifier(accounts),
        ),
        debtNotifierProvider.overrideWith(() => testDebtNotifier),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => RepayBottomSheet.show(
                context: context,
                debt: testDebt,
                onRepaid: onRepaid,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester, {
    List<Account> accounts = const [testAccount],
    VoidCallback? onRepaid,
  }) async {
    await tester.pumpWidget(buildApp(accounts: accounts, onRepaid: onRepaid));
    await tester.pump();
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  group('RepayBottomSheet', () {
    testWidgets(
        'should_showPrefilledFormFields_when_shown', (tester) async {
      await openSheet(tester);

      expect(find.text('Remboursement'), findsOneWidget);
      expect(find.text('Rembourser'), findsOneWidget);
      expect(find.text('Compte'), findsOneWidget);
      expect(find.text('Montant'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets(
        'should_showInvalidAmountError_when_amountIsZero',
        (tester) async {
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.widgetWithText(FilledButton, 'Rembourser'));
      await tester.pumpAndSettle();

      expect(find.text('Montant invalide'), findsOneWidget);
    });

    testWidgets(
        'should_showMaxAmountError_when_amountExceedsRemaining',
        (tester) async {
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), '500');
      await tester.tap(find.widgetWithText(FilledButton, 'Rembourser'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Maximum :'), findsOneWidget);
    });

    testWidgets(
        'should_showErrorSnackbar_when_repayFails', (tester) async {
      testDebtNotifier = _TestDebtNotifier(repayResult: false);
      await openSheet(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Rembourser'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur lors du remboursement'), findsOneWidget);
    });

    testWidgets(
        'should_invokeOnRepaidAndClose_when_repaySucceeds', (tester) async {
      var repaidCalled = false;
      await openSheet(tester, onRepaid: () => repaidCalled = true);

      await tester.tap(find.widgetWithText(FilledButton, 'Rembourser'));
      await tester.pumpAndSettle();

      expect(repaidCalled, isTrue);
      expect(testDebtNotifier.lastAccountId, 'acc1');
      expect(testDebtNotifier.lastAmount, 100.0);
      expect(find.text('Remboursement enregistré'), findsOneWidget);
    });
  });
}
