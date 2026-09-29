import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/models/unbudgeted_item.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/unbudgeted_detail_sheet.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  const items = [
    UnbudgetedItem(
      categoryId: 'cat1',
      categoryNom: 'Divers',
      categoryIcone: '📎',
      categoryCouleur: '#4CAF50',
      montantDepense: 45.0,
    ),
  ];

  group('UnbudgetedDetailSheet', () {
    testWidgets(
        'should_displayFormattedTotalAndItems_when_rendered',
        (tester) async {
      await tester.pumpApp(
        const UnbudgetedDetailSheet(
          items: items,
          total: 45.0,
          currency: 'EUR',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Total :'), findsOneWidget);
      expect(find.textContaining('45,00'), findsWidgets);
      expect(find.text('Divers'), findsOneWidget);
      expect(find.text('Non budgété'), findsOneWidget);
    });

    testWidgets(
        'should_displayFormattedTotal_when_buildOtherRowUsedStandalone',
        (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => Column(
            children: [
              UnbudgetedDetailSheet.buildOtherRow(context, 45.0, 'EUR'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Non budgété'), findsOneWidget);
      expect(find.textContaining('45,00'), findsOneWidget);
    });

    testWidgets(
        'should_displayTranslatedCategory_when_itemIsSystem',
        (tester) async {
      await tester.pumpApp(
        const UnbudgetedDetailSheet(
          items: [
            UnbudgetedItem(
              categoryId: 'cat-sys',
              categoryNom: 'Balance adjustment',
              categorySystemKey: 'ADJUSTMENT',
              categoryIcone: '⚖️',
              categoryCouleur: '#8B5CF6',
              montantDepense: 30.0,
            ),
          ],
          total: 30.0,
          currency: 'EUR',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ajustement'), findsOneWidget);
      expect(find.text('Balance adjustment'), findsNothing);
    });
  });
}
