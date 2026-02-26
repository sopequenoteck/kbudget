import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/features/accounts/presentation/screens/account_list_screen.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_list_skeleton.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAccountRepository mockRepo;

  const acc1 = Account(
    id: '1',
    nom: 'Principal',
    type: AccountType.courant,
    soldeInitial: 1000.0,
    solde: 1250.50,
    icone: '\u{1F3E6}',
    couleur: '#3b82f6',
    isDefault: true,
  );
  const acc2 = Account(
    id: '2',
    nom: 'Vacances',
    type: AccountType.epargne,
    soldeInitial: 5000.0,
    solde: 5200.0,
    icone: '\u{1F437}',
    couleur: '#22c55e',
  );

  setUp(() {
    mockRepo = MockAccountRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AccountListScreen(),
      ),
    );
  }

  group('AccountListScreen', () {
    testWidgets('should_showSkeleton_when_loading', (tester) async {
      final completer = Completer<List<Account>>();
      when(mockRepo.getAll()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildApp());
      await tester.pump(); // trigger initState
      await tester.pump(); // trigger addPostFrameCallback

      expect(find.byType(AccountListSkeleton), findsOneWidget);

      // Complete to avoid pending futures
      completer.complete([acc1]);
      await tester.pumpAndSettle();
    });

    testWidgets('should_showError_when_loadFails', (tester) async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger les comptes'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should_showEmptyState_when_noAccounts', (tester) async {
      when(mockRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucun compte'), findsOneWidget);
    });

    testWidgets('should_showAccountList_when_dataLoaded', (tester) async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1, acc2]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('Vacances'), findsOneWidget);
    });

    testWidgets('should_showAddButton_when_rendered', (tester) async {
      when(mockRepo.getAll()).thenAnswer((_) async => [acc1]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should_retryLoad_when_retryTapped', (tester) async {
      int callCount = 0;
      when(mockRepo.getAll()).thenAnswer((_) {
        callCount++;
        if (callCount == 1) throw Exception('Network error');
        return Future.value([acc1]);
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger les comptes'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Principal'), findsOneWidget);
    });
  });
}
