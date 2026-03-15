import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/features/recurring/data/recurring_transaction_repository_remote.dart';
import 'package:k_budget/src/features/recurring/presentation/recurring_list_screen.dart';
import 'package:k_budget/src/features/recurring/presentation/widgets/recurring_list_skeleton.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockRecurringTransactionRepository mockRepo;

  final overdueItem = RecurringTransaction(
    id: 'overdue-1',
    montant: 50.0,
    libelle: 'Netflix',
    type: TransactionType.depense,
    frequency: Frequency.mensuel,
    nextOccurrence: DateTime(2026, 3, 10),
    recurringActive: true,
    categoryIcon: '🎬',
  );

  final upcomingItem = RecurringTransaction(
    id: 'upcoming-1',
    montant: 100.0,
    libelle: 'Assurance',
    type: TransactionType.depense,
    frequency: Frequency.mensuel,
    nextOccurrence: DateTime(2026, 3, 20),
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
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RecurringListScreen(),
      ),
    );
  }

  group('RecurringListScreen', () {
    testWidgets('should_show_skeleton_while_loading', (tester) async {
      final completer = Completer<List<RecurringTransaction>>();
      when(mockRepo.listActive()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildApp());
      // Trigger postFrameCallback → loadItems() called → isLoading = true
      await tester.pump();

      // Skeleton should be visible (isLoading=true, items empty)
      expect(find.byType(RecurringListSkeleton), findsOneWidget);
      expect(find.text('Récurrences'), findsOneWidget);

      // Complete to avoid pending future warning
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('should_show_empty_state', (tester) async {
      when(mockRepo.listActive()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucune récurrence active'), findsOneWidget);
    });

    testWidgets('should_show_recurring_items_sorted', (tester) async {
      when(mockRepo.listActive()).thenAnswer(
        (_) async => [upcomingItem, overdueItem],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Both items visible
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Assurance'), findsOneWidget);

      // Overdue badge visible
      expect(find.text('En retard'), findsOneWidget);

      // Upcoming badge visible
      expect(find.text('À venir'), findsOneWidget);

      // Overdue should appear before upcoming (sorted)
      final netflixOffset =
          tester.getTopLeft(find.text('Netflix')).dy;
      final assuranceOffset =
          tester.getTopLeft(find.text('Assurance')).dy;
      expect(netflixOffset, lessThan(assuranceOffset));
    });
  });
}
