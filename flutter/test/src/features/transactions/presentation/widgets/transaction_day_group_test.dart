// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/transaction_day_group.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

import '../../../../../helpers/fixtures/test_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  Transaction buildTransaction({String? categoryId}) => Transaction(
        id: 'tx1',
        montant: 9.99,
        libelle: 'Netflix',
        type: TransactionType.depense,
        date: DateTime(2026, 3, 3),
        categoryId: categoryId,
        accountId: 'acc1',
      );

  Widget buildApp({
    required Transaction transaction,
    Map<String, Category> categories = const {},
  }) {
    return MaterialApp(
      theme: theme.AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: TransactionDayGroup(
          transactions: [transaction],
          categories: categories,
        ),
      ),
    );
  }

  group('TransactionDayGroup', () {
    testWidgets('should_showTranslatedSubtitle_when_categoryIsSystem',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          transaction: buildTransaction(categoryId: 'cat-sys'),
          categories: {'cat-sys': TestFixtures.systemCategory},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.text('Subscription'), findsNothing);
    });

    testWidgets('should_showNoCategoryLabel_when_transactionHasNoCategory',
        (tester) async {
      await tester.pumpWidget(buildApp(transaction: buildTransaction()));
      await tester.pumpAndSettle();

      expect(find.text('Sans catégorie'), findsOneWidget);
    });
  });
}
