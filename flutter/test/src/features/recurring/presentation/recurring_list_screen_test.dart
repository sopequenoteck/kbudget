import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/recurring/data/recurring_transaction_repository_remote.dart';
import 'package:k_budget/src/features/recurring/presentation/recurring_list_screen.dart';
import 'package:k_budget/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

class _MockExchangeRateNotifier extends ExchangeRateNotifier {
  @override
  ListState<ExchangeRate> build() => const ListState();
}

class _MockDashboardNotifier extends DashboardNotifier {
  @override
  DashboardState build() => const DashboardState();
}

void main() {
  late MockRecurringTransactionRepository mockRepo;

  final overdueItem = RecurringTransaction(
    id: 'overdue-1',
    montant: 50.0,
    libelle: 'Netflix',
    type: TransactionType.depense,
    frequency: Frequency.mensuel,
    nextOccurrence: DateTime.now().subtract(const Duration(days: 10)),
    recurringActive: true,
    categoryIcon: '🎬',
  );

  final upcomingItem = RecurringTransaction(
    id: 'upcoming-1',
    montant: 100.0,
    libelle: 'Assurance',
    type: TransactionType.depense,
    frequency: Frequency.mensuel,
    nextOccurrence: DateTime.now().add(const Duration(days: 10)),
    recurringActive: true,
  );

  setUp(() {
    mockRepo = MockRecurringTransactionRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        recurringTransactionRepositoryProvider
            .overrideWith((_) async => mockRepo),
        exchangeRateListProvider.overrideWith(() => _MockExchangeRateNotifier()),
        dashboardNotifierProvider.overrideWith(() => _MockDashboardNotifier()),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const RecurringListScreen(),
      ),
    );
  }

  group('RecurringListScreen', () {
    testWidgets('should_show_skeleton_while_loading', (tester) async {
      final completer = Completer<List<RecurringTransaction>>();
      when(mockRepo.listActive()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.byType(RecurringListSkeleton), findsOneWidget);
      expect(find.text('Récurrences'), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('should_show_empty_state', (tester) async {
      when(mockRepo.listActive()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucune transaction récurrente'), findsOneWidget);
    });

    testWidgets('should_show_recurring_items_sorted', (tester) async {
      when(mockRepo.listActive()).thenAnswer(
        (_) async => [upcomingItem, overdueItem],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Assurance'), findsOneWidget);

      // Status group headers visible (replaced item-level badges)
      expect(find.text('EN RETARD'), findsOneWidget);
      expect(find.text('À VENIR'), findsOneWidget);

      // Overdue should appear before upcoming (sorted)
      final netflixOffset = tester.getTopLeft(find.text('Netflix')).dy;
      final assuranceOffset = tester.getTopLeft(find.text('Assurance')).dy;
      expect(netflixOffset, lessThan(assuranceOffset));
    });

    testWidgets('should_showErrorStateWithRetry_when_loadFails',
        (tester) async {
      when(mockRepo.listActive()).thenThrow(Exception('boom'));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Erreur de chargement'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      verify(mockRepo.listActive()).called(greaterThanOrEqualTo(2));
    });

    testWidgets('should_showTodayGroup_when_itemDueToday', (tester) async {
      final todayItem = RecurringTransaction(
        id: 'today-1',
        montant: 20.0,
        libelle: 'Salle de sport',
        type: TransactionType.depense,
        frequency: Frequency.mensuel,
        nextOccurrence: DateTime.now(),
        recurringActive: true,
      );
      when(mockRepo.listActive()).thenAnswer((_) async => [todayItem]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text("AUJOURD'HUI"), findsOneWidget);
      expect(find.text('Salle de sport'), findsOneWidget);
    });

    testWidgets(
        'should_openActionSheetWithAmountDateAndActions_when_itemTapped',
        (tester) async {
      when(mockRepo.listActive()).thenAnswer((_) async => [overdueItem]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();

      expect(find.text('MENSUEL'), findsOneWidget);
      expect(find.textContaining('50,00'), findsWidgets);
      expect(find.text('Marquer comme payée'), findsOneWidget);
      expect(find.text('Passer cette occurrence'), findsOneWidget);
      expect(find.text('Désactiver la récurrence'), findsOneWidget);
    });

    for (final scenario in [
      (
        action: 'validate',
        buttonLabel: 'Marquer comme payée',
        successMessage: 'Transaction validée',
        errorMessage: 'Erreur lors de la validation',
      ),
      (
        action: 'deactivate',
        buttonLabel: 'Désactiver la récurrence',
        successMessage: 'Récurrence désactivée',
        errorMessage: 'Erreur lors de la désactivation',
      ),
    ]) {
      testWidgets(
          'should_showSuccessSnackbar_when_${scenario.action}Succeeds',
          (tester) async {
        when(mockRepo.listActive()).thenAnswer((_) async => [overdueItem]);
        when(mockRepo.validate(any)).thenAnswer((_) async {});
        when(mockRepo.deactivate(any)).thenAnswer((_) async => overdueItem);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Netflix'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(scenario.buttonLabel));
        await tester.pumpAndSettle();

        expect(find.text(scenario.successMessage), findsOneWidget);
      });

      testWidgets(
          'should_showErrorSnackbar_when_${scenario.action}Fails',
          (tester) async {
        when(mockRepo.listActive()).thenAnswer((_) async => [overdueItem]);
        when(mockRepo.validate(any)).thenThrow(Exception('boom'));
        when(mockRepo.deactivate(any)).thenThrow(Exception('boom'));

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Netflix'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(scenario.buttonLabel));
        await tester.pumpAndSettle();

        expect(find.text(scenario.errorMessage), findsOneWidget);
      });
    }

    testWidgets('should_showErrorSnackbar_when_skipFails', (tester) async {
      when(mockRepo.listActive()).thenAnswer((_) async => [overdueItem]);
      when(mockRepo.skip(any)).thenThrow(Exception('boom'));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passer cette occurrence'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur lors du passage'), findsOneWidget);
    });

    testWidgets(
        'should_showSuccessSnackbarAfterValidatingAll_when_payAllTapped',
        (tester) async {
      when(mockRepo.listActive()).thenAnswer((_) async => [overdueItem]);
      when(mockRepo.validate(any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tout payé'));
      await tester.pumpAndSettle();

      expect(find.text('1 transaction validée'), findsOneWidget);
    });

    testWidgets(
        'should_showErrorSnackbarAfterValidatingAll_when_payAllFails',
        (tester) async {
      when(mockRepo.listActive()).thenAnswer((_) async => [overdueItem]);
      when(mockRepo.validate(any)).thenThrow(Exception('boom'));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tout payé'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur lors de la validation'), findsOneWidget);
    });
  });
}
