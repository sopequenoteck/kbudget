import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  Widget buildApp({required double width, required double height}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  AppModal.show(
                    context,
                    title: 'Test Modal',
                    onClose: () {},
                    child: const Text('Modal Body'),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
  }

  group('AppModal', () {
    testWidgets('should_showBottomSheet_when_screenWidthBelow768',
        (tester) async {
      await tester.pumpWidget(buildApp(width: 400, height: 800));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Bottom sheet renders a BottomSheet widget
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Test Modal'), findsOneWidget);
      expect(find.text('Modal Body'), findsOneWidget);
    });

    testWidgets('should_showDialog_when_screenWidthAbove768', (tester) async {
      await tester.pumpWidget(buildApp(width: 1024, height: 768));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dialog doesn't render a BottomSheet
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Test Modal'), findsOneWidget);
      expect(find.text('Modal Body'), findsOneWidget);
    });

    testWidgets('should_displayTitle_when_modalOpened', (tester) async {
      await tester.pumpWidget(buildApp(width: 400, height: 800));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test Modal'), findsOneWidget);
    });

    testWidgets('should_closeModal_when_closeButtonTapped', (tester) async {
      var closed = false;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    AppModal.show(
                      context,
                      title: 'Test',
                      onClose: () => closed = true,
                      child: const Text('Body'),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(PhosphorIconsBold.x));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(find.text('Test'), findsNothing);
    });

    testWidgets('should_closeModal_when_swipeDown', (tester) async {
      await tester.pumpWidget(buildApp(width: 400, height: 800));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Swipe down on the modal
      await tester.drag(find.text('Modal Body'), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.text('Test Modal'), findsNothing);
    });

    testWidgets('should_closeModal_when_overlayTapped', (tester) async {
      await tester.pumpWidget(buildApp(width: 1024, height: 768));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the barrier (dialog overlay)
      // The barrier is behind the dialog, tap at a corner
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Test Modal'), findsNothing);
    });
  });
}
