import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/notifications/application/notification_notifier.dart';
import 'package:k_budget/src/features/notifications/presentation/notification_badge.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

void main() {
  Widget buildApp({
    required int unreadCount,
    VoidCallback? onTap,
  }) {
    return ProviderScope(
      overrides: [
        unreadCountProvider.overrideWith((ref) => unreadCount),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        home: Scaffold(
          body: NotificationBadge(onTap: onTap),
        ),
      ),
    );
  }

  group('NotificationBadge', () {
    testWidgets('should_display_count_when_has_unread', (tester) async {
      await tester.pumpWidget(
        buildApp(unreadCount: 5),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should_hide_badge_when_zero_unread', (tester) async {
      await tester.pumpWidget(
        buildApp(unreadCount: 0),
      );
      await tester.pumpAndSettle();

      // Badge with isLabelVisible: false — le texte "0" ne doit pas être visible
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isFalse);
    });

    testWidgets('should_trigger_callback_when_tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildApp(
          unreadCount: 3,
          onTap: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
