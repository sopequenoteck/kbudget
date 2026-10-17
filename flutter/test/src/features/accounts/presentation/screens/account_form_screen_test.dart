import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/bank_select_picker.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/bank.dart';
import 'package:k_budget/src/features/accounts/application/bank_provider.dart';
import 'package:k_budget/src/features/accounts/presentation/screens/account_form_screen.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_type_selector.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAccountRepository mockRepo;

  const testAccount = Account(
    id: '1',
    nom: 'Mon Compte',
    type: AccountType.courant,
    soldeInitial: 1000.0,
    solde: 1250.50,
    icone: '\u{1F3E6}',
    couleur: '#3b82f6',
    isDefault: false,
    actif: true,
  );

  setUp(() {
    mockRepo = MockAccountRepository();
  });

  Widget buildApp({Account? account, Currency primaryCurrency = Currency.eur}) {
    final router = GoRouter(
      initialLocation: '/list/form',
      routes: [
        GoRoute(
          path: '/list',
          builder: (context, state) =>
              const Scaffold(body: Text('list')),
          routes: [
            GoRoute(
              path: 'form',
              builder: (context, state) =>
                  AccountFormScreen(account: account),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockRepo),
        banksProvider.overrideWith((_) async => const <Bank>[]),
        currencyConfigNotifierProvider
            .overrideWith(() => _FixedCurrencies([primaryCurrency])),
        exchangeRateRepositoryProvider
            .overrideWith((_) async => MockExchangeRateRepository()),
      ],
      child: MaterialApp.router(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
      ),
    );
  }

  Finder findAppBarAction(PhosphorIconData icon) {
    return find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(icon),
    );
  }

  group('AccountFormScreen', () {
    testWidgets('should_showCreateMode_when_noAccount', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Nouveau compte'), findsOneWidget);
      // Bank picker present — default is "OTHER" showing "Autre / Personnalisé"
      expect(find.text('Autre / Personnalisé'), findsOneWidget);
    });

    testWidgets('should_showEditMode_when_accountProvided', (tester) async {
      await tester.pumpWidget(buildApp(account: testAccount));
      await tester.pumpAndSettle();

      expect(find.text('Modifier le compte'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Solde actuel'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Solde actuel'), findsOneWidget);
    });

    testWidgets('should_prefillDefaults_when_typeSelected', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Épargne'), findsOneWidget);
      expect(find.text('Espèces'), findsOneWidget);
    });

    testWidgets('should_showValidationError_when_nameEmpty', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll to name field (it may be below bank picker + custom fields)
      await tester.scrollUntilVisible(
        find.text('Nom du compte'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // Clear name field and submit
      final nameField = find.descendant(
        of: find.ancestor(of: find.text('Nom du compte'), matching: find.byType(AppFormField)),
        matching: find.byType(TextField),
      );
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      // Tap save button in AppBar
      await tester.tap(findAppBarAction(PhosphorIconsBold.check));
      await tester.pumpAndSettle();

      expect(find.text('Ce champ est requis.'), findsWidgets);
    });

    testWidgets('should_callCreate_when_submitInCreateMode', (tester) async {
      when(mockRepo.create(any)).thenAnswer((_) async => testAccount);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll to name field
      await tester.scrollUntilVisible(
        find.text('Nom du compte'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // Fill name field
      final nameField = find.descendant(
        of: find.ancestor(of: find.text('Nom du compte'), matching: find.byType(AppFormField)),
        matching: find.byType(TextField),
      );
      await tester.enterText(nameField, 'Mon Compte');
      await tester.pumpAndSettle();

      // Tap save in AppBar
      await tester.tap(findAppBarAction(PhosphorIconsBold.check));
      await tester.pumpAndSettle();

      verify(mockRepo.create(any)).called(1);
    });

    testWidgets('should_callUpdate_when_submitInEditMode', (tester) async {
      when(mockRepo.update(any)).thenAnswer(
        (_) async => testAccount.copyWith(nom: 'Updated'),
      );

      await tester.pumpWidget(buildApp(account: testAccount));
      await tester.pumpAndSettle();

      // Tap save in AppBar
      await tester.tap(findAppBarAction(PhosphorIconsBold.check));
      await tester.pumpAndSettle();

      verify(mockRepo.update(any)).called(1);
    });

    testWidgets('should_showDeleteButton_when_editMode', (tester) async {
      await tester.pumpWidget(buildApp(account: testAccount));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(PhosphorIconsRegular.trash),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byIcon(PhosphorIconsRegular.trash), findsOneWidget);
    });

    testWidgets('should_showActiveSwitch_when_editMode', (tester) async {
      await tester.pumpWidget(buildApp(account: testAccount));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(Switch),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byType(Switch), findsOneWidget);
    });

    // SC-001 : AccountTypeSelector apparaît avant BankSelectPicker dans le tree
    testWidgets('should_showTypeSectionBeforeBank_when_createMode',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final typeSelectorPos =
          tester.getTopLeft(find.byType(AccountTypeSelector));
      final bankPickerPos = tester.getTopLeft(find.byType(BankSelectPicker));
      expect(typeSelectorPos.dy, lessThan(bankPickerPos.dy));
    });

    // SC-002 : Les 4 SectionHeaders sont présents en mode création
    testWidgets('should_showSectionHeaders_when_createMode', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Les premiers headers sont visibles sans scroll
      expect(find.text('TYPE DE COMPTE'), findsOneWidget);
      expect(find.text('BANQUE'), findsOneWidget);
      // PERSONNALISATION visible car _selectedBankCode == 'OTHER' par défaut
      expect(find.text('PERSONNALISATION'), findsOneWidget);

      // DÉTAILS peut être hors viewport — scroller pour l'atteindre
      await tester.scrollUntilVisible(
        find.text('DÉTAILS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('DÉTAILS'), findsOneWidget);
    });

    // SC-003 : La preview affiche "COURANT" (type par défaut en mode création)
    testWidgets('should_showTypeLabel_when_defaultTypeInPreview',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('COURANT'), findsOneWidget);
    });

    testWidgets('should_listTranslatedCurrencyNames_when_createMode',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(SelectPicker),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final picker = tester.widget<SelectPicker>(find.byType(SelectPicker));
      expect(picker.items.map((i) => i.label), [
        '€ — Euro',
        'CFA — Franc CFA (BCEAO)',
        r'$ — Dollar US',
        '£ — Livre sterling',
        'CHF — Franc suisse',
        r'CA$ — Dollar canadien',
        'MAD — Dirham marocain',
      ]);
    });

    // SC-005 : SelectPicker devise absent en mode édition
    testWidgets('should_hideCurrencyPicker_when_editMode', (tester) async {
      await tester.pumpWidget(buildApp(account: testAccount));
      await tester.pumpAndSettle();

      expect(find.byType(SelectPicker), findsNothing);
    });

    // SC-006 : ConfirmDialogCustom (Dialog) affiché au tap delete
    testWidgets('should_useConfirmDialogCustom_when_deletePressed',
        (tester) async {
      await tester.pumpWidget(buildApp(account: testAccount));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(PhosphorIconsRegular.trash),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byIcon(PhosphorIconsRegular.trash));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    // SC-007 : Bloc solde actuel avec Container présent en mode édition
    testWidgets('should_showCurrentBalanceBlock_when_editMode', (tester) async {
      await tester.pumpWidget(buildApp(account: testAccount));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Solde actuel'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final containerFinder = find.ancestor(
        of: find.text('Solde actuel'),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
      // Format fr_FR : "1 250,50 €" — utiliser textContaining pour éviter
      // les variations d'espace insécable selon la plateforme
      expect(find.textContaining('250'), findsWidgets);
    });

    testWidgets('should_offerCameraAndGallery_when_logoTapped', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(PhosphorIconsRegular.upload),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byIcon(PhosphorIconsRegular.upload));
      await tester.pumpAndSettle();

      expect(find.text('Caméra'), findsOneWidget);
      expect(find.text('Galerie'), findsOneWidget);
      expect(find.text('Supprimer'), findsNothing);
    });

    testWidgets('should_removeCustomLogo_when_deleteChosenInLogoSheet',
        (tester) async {
      await tester.pumpWidget(buildApp(
        account: testAccount.copyWith(bankCustomLogo: _pngDataUri),
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Logo personnalisé (optionnel)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final logoTap = find.descendant(
        of: find
            .ancestor(
              of: find.text('Logo personnalisé (optionnel)'),
              matching: find.byType(Column),
            )
            .first,
        matching: find.byType(GestureDetector),
      );
      await tester.scrollUntilVisible(
        logoTap,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(logoTap);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Supprimer'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(PhosphorIconsRegular.upload), findsOneWidget);
    });

    testWidgets('should_showActiveHint_when_accountIsDefault', (tester) async {
      await tester.pumpWidget(
        buildApp(account: testAccount.copyWith(isDefault: true)),
      );
      await tester.pumpAndSettle();

      const hint =
          'Définissez un autre compte par défaut avant de désactiver celui-ci';
      await tester.scrollUntilVisible(
        find.text(hint),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(hint), findsOneWidget);
    });

    for (final (label, button, opensRateForm) in [
      ('later', 'Plus tard', false),
      ('enterRate', 'Saisir le taux', true),
    ]) {
      testWidgets(
          'should_proposeMissingRate_when_created_and_${label}Chosen',
          (tester) async {
        when(mockRepo.create(any)).thenAnswer((_) async => testAccount);

        await tester.pumpWidget(buildApp(primaryCurrency: Currency.usd));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Nom du compte'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.descendant(
            of: find.ancestor(
              of: find.text('Nom du compte'),
              matching: find.byType(AppFormField),
            ),
            matching: find.byType(TextField),
          ),
          'Compte euro',
        );
        await tester.tap(findAppBarAction(PhosphorIconsBold.check));
        // L'indicateur de sauvegarde tourne tant que le dialogue est ouvert :
        // pumpAndSettle ne rendrait jamais la main.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Taux de conversion manquant'), findsOneWidget);
        expect(
          find.text(
            "Aucun taux \$ → € n'est défini.\nVoulez-vous le saisir maintenant ?",
          ),
          findsOneWidget,
        );

        await tester.tap(find.text(button));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.text('Ajouter un taux'),
          opensRateForm ? findsOneWidget : findsNothing,
        );
      });
    }
  });
}

const _pngDataUri = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAf'
    'FcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

class _FixedCurrencies extends CurrencyConfigNotifier {
  _FixedCurrencies(this._currencies);

  final List<Currency> _currencies;

  @override
  List<Currency> build() => _currencies;
}
