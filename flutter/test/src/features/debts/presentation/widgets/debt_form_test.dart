import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/common_widgets/bottom_sheet_4_rows_widget.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/debt_form.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../helpers/mocks.mocks.dart';

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
  }) {
    return ProviderScope(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        debtRepositoryProvider.overrideWithValue(mockDebtRepo),
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
  });
}
