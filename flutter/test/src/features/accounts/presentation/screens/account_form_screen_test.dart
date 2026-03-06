import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/features/accounts/presentation/screens/account_form_screen.dart';
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

  Widget buildApp({Account? account}) {
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
      ],
      child: MaterialApp.router(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      expect(find.text('Solde initial'), findsOneWidget);
    });

    testWidgets('should_showEditMode_when_accountProvided', (tester) async {
      await tester.pumpWidget(buildApp(account: testAccount));
      await tester.pumpAndSettle();

      expect(find.text('Modifier le compte'), findsOneWidget);
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

      // Clear name field and submit
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      // Tap save button in AppBar
      await tester.tap(findAppBarAction(PhosphorIconsBold.check));
      await tester.pumpAndSettle();

      expect(find.text('Champ requis'), findsWidgets);
    });

    testWidgets('should_callCreate_when_submitInCreateMode', (tester) async {
      when(mockRepo.create(any)).thenAnswer((_) async => testAccount);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Fill name field
      final nameField = find.byType(TextField).first;
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
  });
}
