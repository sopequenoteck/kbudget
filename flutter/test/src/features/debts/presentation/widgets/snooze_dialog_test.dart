import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/snooze_dialog.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../../helpers/mocks.mocks.dart';

void main() {
  late MockDebtRepository mockRepo;

  final debt = Debt(
    id: 'debt1',
    personne: 'Alice',
    montant: 250,
    sens: DebtType.pret,
    date: DateTime(2026, 1, 15),
    rembourse: false,
    reminderDate: DateTime(2099, 1, 15),
    reminderTime: '14:30',
  );

  setUp(() {
    mockRepo = MockDebtRepository();
  });

  Future<void> pumpDialog(WidgetTester tester, Debt debt) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [debtRepositoryProvider.overrideWithValue(mockRepo)],
        child: MaterialApp(
          theme: theme.AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(body: SnoozeDialog(debt: debt)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SnoozeDialog', () {
    testWidgets('should_showReminderDateAndTime_when_opened', (tester) async {
      await pumpDialog(tester, debt);

      expect(find.text('Date du rappel'), findsOneWidget);
      expect(find.text('Heure du rappel'), findsOneWidget);
      expect(find.text('15/01/2099'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('should_showPastDateError_when_reminderDateIsPast',
        (tester) async {
      await pumpDialog(
        tester,
        debt.copyWith(reminderDate: DateTime(2020, 1, 1)),
      );

      await tester.tap(find.text('Reporter'));
      await tester.pumpAndSettle();

      expect(
        find.text('La date ne peut pas être dans le passé'),
        findsOneWidget,
      );
      verifyNever(mockRepo.snooze(any, any, any));
    });

    testWidgets('should_showSnoozeError_when_snoozeFails', (tester) async {
      when(mockRepo.snooze(any, any, any)).thenThrow(Exception('boom'));
      await pumpDialog(tester, debt);

      await tester.tap(find.text('Reporter'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur lors du report du rappel'), findsOneWidget);
    });
  });
}
