import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/common_widgets/bottom_sheet_4_rows_widget.dart';
import 'package:k_budget/src/common_widgets/bsheet_delete_pill.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/recurring/data/recurring_transaction_repository_remote.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

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
  late MockTransactionRepository mockTransactionRepo;
  late MockRecurringTransactionRepository mockRecurringRepo;

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

  final testTransaction = Transaction(
    id: 'tx1',
    montant: 42.50,
    libelle: 'Netflix',
    type: TransactionType.depense,
    date: DateTime(2026, 5, 1),
    categoryId: 'cat1',
    accountId: 'acc1',
  );

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockTransactionRepo = MockTransactionRepository();
    mockRecurringRepo = MockRecurringTransactionRepository();

    when(mockAccountRepo.getAll()).thenAnswer((_) async => [testAccount]);
    when(mockCategoryRepo.getAll()).thenAnswer((_) async => [testCategory]);
    when(mockTransactionRepo.getAll()).thenAnswer((_) async => []);
    when(mockRecurringRepo.listActive()).thenAnswer((_) async => []);
  });

  Widget buildApp({
    Transaction? transaction,
    TransactionType type = TransactionType.depense,
    Future<void> Function(Transaction)? onSaved,
    Future<void> Function(String)? onDeleted,
    VoidCallback? onCancelled,
    List<Account>? preloadedAccounts,
  }) {
    return ProviderScope(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        recurringTransactionRepositoryProvider
            .overrideWith((_) async => mockRecurringRepo),
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
          body: SizedBox(
            height: 600,
            child: TransactionForm(
              transaction: transaction,
              type: type,
              onSaved: onSaved ?? (_) async {},
              onDeleted: onDeleted,
              onCancelled: onCancelled ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('TransactionForm', () {
    testWidgets('should_display_bsheet4rows_when_form_opens', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet4RowsWidget), findsOneWidget);
      // Le titre "Nouvelle transaction" doit être visible
      expect(find.text('Nouvelle transaction'), findsOneWidget);
      // Le bouton Valider (Enregistrer) doit être présent
      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('should_call_onSaved_when_valid_form_submitted', (tester) async {
      Transaction? savedTx;

      await tester.pumpWidget(buildApp(
        type: TransactionType.depense,
        onSaved: (tx) async {
          savedTx = tx;
        },
      ));
      await tester.pumpAndSettle();

      // Vérifier que le champ montant est présent
      expect(find.byKey(const Key('tf_montant')), findsOneWidget);

      // Cibler le champ libellé par son keyboardType text (RawAutocomplete → TextFormField)
      // On saisit le libellé EN PREMIER avant le montant pour éviter les conflits de focus
      final libelleField = find.byWidgetPredicate(
        (w) =>
            w is EditableText &&
            w.keyboardType == TextInputType.text,
      );
      expect(libelleField, findsOneWidget);
      await tester.tap(libelleField.first);
      // Utiliser 1 seul caractère pour éviter le debounce des suggestions
      await tester.enterText(libelleField.first, 'C');
      await tester.pump();

      // Puis saisir le montant
      await tester.tap(find.byKey(const Key('tf_montant')));
      await tester.enterText(find.byKey(const Key('tf_montant')), '25.00');
      await tester.pump();

      // Vérifier que le bouton submit est présent
      expect(find.text('Enregistrer'), findsOneWidget);

      // Taper sur Enregistrer
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Si les deux champs ont des valeurs valides, onSaved est appelé
      expect(savedTx, isNotNull);
    });

    testWidgets('should_show_errors_when_libelle_empty_on_submit',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Saisir uniquement le montant, laisser le libellé vide
      await tester.enterText(find.byKey(const Key('tf_montant')), '10.00');
      await tester.pump();

      // Taper sur Enregistrer sans libellé
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Une erreur "Ce champ est requis." doit apparaître (libellé vide)
      expect(find.text('Ce champ est requis.'), findsAtLeast(1));
    });

    testWidgets('should_show_errors_when_amount_invalid_on_submit',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Saisir un montant invalide (lettres)
      await tester.enterText(find.byKey(const Key('tf_montant')), 'abc');
      await tester.pump();

      // Saisir un libellé valide
      await tester.enterText(find.byType(TextFormField).first, 'Test');
      await tester.pump();

      // Taper sur Enregistrer
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Une erreur de validation doit apparaître (montant invalide)
      expect(find.text('Ce champ est requis.'), findsAtLeast(1));
    });

    testWidgets('should_show_delete_pill_when_edit_mode', (tester) async {
      await tester.pumpWidget(buildApp(
        transaction: testTransaction,
        onDeleted: (_) async {},
      ));
      await tester.pumpAndSettle();

      // Le bouton Supprimer doit être présent en mode édition
      expect(find.text('Supprimer'), findsOneWidget);
      // Le titre "Modifier la transaction" doit être visible
      expect(find.text('Modifier la transaction'), findsOneWidget);
    });

    testWidgets('should_hide_recurring_icon_when_edit_mode', (tester) async {
      await tester.pumpWidget(buildApp(
        transaction: testTransaction,
        onDeleted: (_) async {},
      ));
      await tester.pumpAndSettle();

      // En mode édition, le bouton de récurrence ne doit pas être affiché
      // On vérifie l'absence du tooltip 'Récurrence'
      expect(find.byTooltip('Récurrence'), findsNothing);
    });

    testWidgets('should_showAccountSecondaryBalance_when_accountSectionOpened',
        (tester) async {
      await tester.pumpWidget(
        buildApp(preloadedAccounts: const [testAccount]),
      );
      await tester.pumpAndSettle();

      // Le compte par défaut est pré-sélectionné : la pastille affiche son nom
      await tester.tap(find.text('Compte courant'));
      await tester.pumpAndSettle();

      expect(find.text('Compte'), findsOneWidget);
      expect(find.textContaining('500,00'), findsWidgets);
    });

    testWidgets('should_showErrorSnackbar_when_saveFails', (tester) async {
      await tester.pumpWidget(buildApp(
        onSaved: (_) async => throw Exception('boom'),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Test');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('tf_montant')), '10.00');
      await tester.pump();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets('should_showErrorSnackbar_when_deleteFails', (tester) async {
      await tester.pumpWidget(buildApp(
        transaction: testTransaction,
        onDeleted: (_) async => throw Exception('boom'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BSheetDeletePill));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Supprimer'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets('should_showNotePlaceholder_when_noteSectionOpened',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Note'));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter une note...'), findsOneWidget);
    });

    testWidgets('should_showFrequencies_when_recurringEnabled',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Récurrence'));
      await tester.pumpAndSettle();
      expect(find.text('Transaction récurrente'), findsOneWidget);
      expect(find.text('Hebdomadaire'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Hebdomadaire'), findsOneWidget);
      expect(find.text('Mensuel'), findsOneWidget);
      expect(find.text('Annuel'), findsOneWidget);
    });

    testWidgets('should_showTypeLabels_when_formOpens', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Dépense'), findsOneWidget);
      expect(find.text('Recette'), findsOneWidget);
      expect(find.text('Catégorie'), findsOneWidget);
    });
  });
}
