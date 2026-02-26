import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/adaptive_scaffold.dart';

void main() {
  group('AdaptiveScaffold', () {
    Widget buildScaffold({
      required Size size,
      int currentIndex = 0,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: AdaptiveScaffold(
                currentIndex: currentIndex,
                onDestinationSelected: (_) {},
                body: const Text('Body'),
                floatingActionButton: const FloatingActionButton(
                  onPressed: null,
                  child: Icon(Icons.add),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('should_show_bottom_nav_when_narrow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScaffold(size: const Size(400, 800)));
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should_show_sidebar_when_wide',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScaffold(size: const Size(1024, 768)));
      await tester.pump();

      // Wide layout uses a custom sidebar with VerticalDivider, not NavigationRail
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('should_show_4_destinations',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScaffold(size: const Size(400, 800)));
      await tester.pump();

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Abonnements'), findsOneWidget);
      expect(find.text('Dettes'), findsOneWidget);
    });

    testWidgets('should_show_fab_in_narrow_mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScaffold(size: const Size(400, 800)));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
