import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/common_widgets/bottom_sheet_4_rows_widget.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/debt_form.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../helpers/fixtures/test_fixtures.dart';
import '../../../../../helpers/mocks.mocks.dart';

class _TestAccountNotifier extends AccountNotifier {
  _TestAccountNotifier(this.preloadedItems);

  final List<Account> preloadedItems;

  @override
  ListState<Account> build() => ListState<Account>(items: preloadedItems);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockAccountRepository mockAccountRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockDebtRepository mockDebtRepo;

  const testAccount = Account(
    id: 'acc1',
    nom: 'Compte courant',
    type: AccountType.courant,
    soldeInitial: 1000,
    icone: '🏦',
    couleur: '#4CAF50',
    isDefault: true,
    actif: true,
    solde: 1500,
  );

  const testCategory = Category(
    id: 'cat1',
    nom: 'Loisirs',
    icone: '🎮',
    couleur: '#FF9800',
  );

  final testDebt = Debt(
    id: 'debt1',
    personne: 'Alice',
    montant: 250.0,
    sens: DebtType.emprunt,
    date: DateTime(2026, 1, 15),
    rembourse: false,
    categoryId: 'cat1',
    accountId: 'acc1',
  );

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockDebtRepo = MockDebtRepository();

    when(mockAccountRepo.getAll()).thenAnswer((_) async => [testAccount]);
    when(mockCategoryRepo.getAll()).thenAnswer((_) async => [testCategory]);
    when(mockDebtRepo.getAll()).thenAnswer((_) async => []);
  });

  Widget buildApp({
    Debt? debt,
    DebtType debtType = DebtType.emprunt,
    Future<void> Function(Debt)? onSaved,
    Future<void> Function(String)? onDeleted,
    VoidCallback? onCancelled,
    List<Account>? preloadedAccounts,
  }) {
    return ProviderScope(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        debtRepositoryProvider.overrideWithValue(mockDebtRepo),
        if (preloadedAccounts != null)
          accountNotifierProvider.overrideWith(
            () => _TestAccountNotifier(preloadedAccounts),
          ),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DebtForm(
              debt: debt,
              debtType: debtType,
              onSaved: onSaved ?? (_) async {},
              onDeleted: onDeleted,
              onCancelled: onCancelled ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('DebtForm', () {
    testWidgets('should_display_echeance_pill_always', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Le formulaire est un BottomSheet4RowsWidget
      expect(find.byType(BottomSheet4RowsWidget), findsOneWidget);

      // La pill Échéance doit être présente même sans dueDate
      expect(find.text('Échéance'), findsOneWidget);
    });

    testWidgets('should_submit_debt_when_valid', (tester) async {
      Debt? savedDebt;

      await tester.pumpWidget(buildApp(
        onSaved: (debt) async {
          savedDebt = debt;
        },
      ));
      await tester.pumpAndSettle();

      // Saisir le montant
      await tester.enterText(
        find.byKey(const Key('tf_montant')),
        '100',
      );

      // Saisir la personne
      await tester.enterText(
        find.byKey(const Key('tf_personne')),
        'Bob',
      );

      // Tap sur Valider
      await tester.tap(find.byKey(const Key('bsheet_submit')));
      await tester.pump();

      expect(savedDebt, isNotNull);
      expect(savedDebt!.personne, 'Bob');
      expect(savedDebt!.montant, 100.0);
      expect(savedDebt!.sens, DebtType.emprunt);
    });

    testWidgets('should_show_delete_pill_when_edit_mode', (tester) async {
      await tester.pumpWidget(buildApp(
        debt: testDebt,
        debtType: testDebt.sens,
        onDeleted: (_) async {},
      ));
      await tester.pumpAndSettle();

      // En mode édition avec onDeleted fourni, la pill Supprimer doit être visible
      expect(find.byIcon(PhosphorIconsRegular.trash), findsOneWidget);
    });

    testWidgets('should_show_rembourse_pill_when_edit_mode', (tester) async {
      await tester.pumpWidget(buildApp(
        debt: testDebt,
        debtType: testDebt.sens,
      ));
      await tester.pumpAndSettle();

      // En mode édition, la pill Remboursé/Non remboursé doit être visible
      expect(find.byKey(const Key('debt_status_pill')), findsOneWidget);

      // La dette de test n'est pas remboursée
      expect(find.text('Non remboursé'), findsOneWidget);
    });

    testWidgets('should_showAccountSecondaryBalance_when_accountSectionOpened',
        (tester) async {
      await tester.pumpWidget(
        buildApp(preloadedAccounts: const [testAccount]),
      );
      await tester.pumpAndSettle();

      // Aucun compte pré-sélectionné en création : la pastille affiche le placeholder
      await tester.tap(find.text('Compte'));
      await tester.pumpAndSettle();

      // Ouvre la modale du SelectPicker de compte imbriqué dans la section
      final trigger = find.descendant(
        of: find.byType(SelectPicker),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(trigger.first);
      await tester.pumpAndSettle();

      // Le solde formaté du compte est affiché dans la liste déroulante
      expect(find.textContaining('500,00'), findsWidgets);
    });

    testWidgets('should_showErrorSnackbar_when_saveFails', (tester) async {
      await tester.pumpWidget(
        buildApp(onSaved: (_) async => throw Exception('boom')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('tf_montant')), '100');
      await tester.enterText(find.byKey(const Key('tf_personne')), 'Bob');

      await tester.tap(find.byKey(const Key('bsheet_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets('should_showErrorSnackbar_when_deleteFails', (tester) async {
      await tester.pumpWidget(buildApp(
        debt: testDebt,
        debtType: testDebt.sens,
        onDeleted: (_) async => throw Exception('boom'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(PhosphorIconsRegular.trash));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Supprimer'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(
        find
            .descendant(
              of: find.byType(SelectPicker),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('should_hideCurrencyPill_when_accountChosen', (tester) async {
      await tester.pumpWidget(
        buildApp(preloadedAccounts: const [testAccount]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Devise par défaut'), findsOneWidget);

      await tester.tap(find.text('Compte'));
      await tester.pumpAndSettle();
      await openPicker(tester);
      await tester.tap(find.text('Compte courant').last);
      await tester.pumpAndSettle();

      expect(find.text('Devise par défaut'), findsNothing);
      expect(find.text('Compte courant'), findsOneWidget);
    });

    testWidgets('should_showCurrencyName_when_currencyChosen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Devise par défaut'));
      await tester.tap(find.text('Devise par défaut'));
      await tester.pumpAndSettle();

      await openPicker(tester);
      await tester.tap(find.text(r'Dollar US ($)'));
      await tester.pumpAndSettle();

      expect(find.text('Dollar US'), findsOneWidget);
    });

    testWidgets('should_showReminderSummary_when_debtHasReminder',
        (tester) async {
      await tester.pumpWidget(buildApp(
        debt: testDebt.copyWith(
          reminderDate: DateTime(2026, 2, 1),
          reminderTime: '14:00',
        ),
        onDeleted: (_) async {},
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Rappel'));
      await tester.pumpAndSettle();
      expect(find.text('Rappel : 01/02/2026 à 14:00'), findsOneWidget);

      await tester.tap(find.text('Effacer le rappel'));
      await tester.pumpAndSettle();

      expect(find.text('Effacer le rappel'), findsNothing);
    });

    testWidgets('should_showDueDateAndRepaidStatus_when_debtRepaid',
        (tester) async {
      await tester.pumpWidget(buildApp(
        debt: testDebt.copyWith(
          dueDate: DateTime(2026, 3, 10),
          rembourse: true,
        ),
        onDeleted: (_) async {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('10/03/2026'), findsOneWidget);
      expect(find.text('Remboursé'), findsOneWidget);
    });

    testWidgets('should_showTranslatedCategory_when_categoryIsSystem',
        (tester) async {
      when(mockCategoryRepo.getAll())
          .thenAnswer((_) async => [TestFixtures.systemCategory]);

      await tester.pumpWidget(buildApp(
        debt: testDebt.copyWith(categoryId: 'cat-sys'),
      ));
      await tester.pumpAndSettle();
      await ProviderScope.containerOf(tester.element(find.byType(Scaffold)))
          .read(categoryNotifierProvider.notifier)
          .loadItems();
      await tester.pumpAndSettle();

      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.text('Subscription'), findsNothing);
    });
  });
}
