import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

void main() {
  Widget buildWidget({String? userName}) {
    return MaterialApp(
      theme: app_theme.AppTheme.light,
      home: Scaffold(
        body: DashboardHeader(userName: userName),
      ),
    );
  }

  group('DashboardHeader', () {
    testWidgets('should_displayGreetingWithUserName_when_userNameProvided',
        (tester) async {
      await tester.pumpWidget(buildWidget(userName: 'Kelly'));

      expect(find.text('Bonjour Kelly'), findsOneWidget);
    });

    testWidgets('should_displayBonjour_when_noUserName', (tester) async {
      await tester.pumpWidget(buildWidget(userName: null));

      expect(find.text('Bonjour'), findsOneWidget);
    });
  });
}
