import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/loading_indicator.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets(
      'should_displaySpinner_when_noMessageProvided',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingIndicator(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Text), findsNothing);
      },
    );

    testWidgets(
      'should_displaySpinnerAndMessage_when_messageProvided',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingIndicator(message: 'Chargement...'),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Chargement...'), findsOneWidget);
      },
    );
  });
}
