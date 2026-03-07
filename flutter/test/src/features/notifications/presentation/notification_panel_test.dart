import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/domain/enums/entity_type.dart';
import 'package:k_budget/src/domain/enums/notification_type.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/features/notifications/application/notification_notifier.dart';
import 'package:k_budget/src/features/notifications/presentation/notification_panel.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

// Notifier de test permettant d'injecter un état initial
class _FakeNotificationNotifier extends NotificationNotifier {
  final ListState<NotificationModel> initialState;

  _FakeNotificationNotifier(this.initialState);

  @override
  ListState<NotificationModel> build() => initialState;

  @override
  Future<void> loadItems() async {
    // Ne recharge pas — l'état est déjà injecté
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  final now = DateTime.now();

  final notifToday = NotificationModel(
    id: '1',
    type: NotificationType.subscriptionDue,
    title: 'Abonnement Netflix',
    message: 'Votre abonnement Netflix arrive à échéance',
    entityType: EntityType.subscription,
    entityId: 'sub-1',
    read: false,
    createdAt: DateTime(now.year, now.month, now.day, 10, 0),
  );

  final notifYesterday = NotificationModel(
    id: '2',
    type: NotificationType.debtDue,
    title: 'Échéance dette',
    message: 'Votre dette arrive à échéance demain',
    entityType: EntityType.debt,
    entityId: 'debt-1',
    read: true,
    readAt: DateTime(now.year, now.month, now.day - 1, 15, 0),
    createdAt: DateTime(now.year, now.month, now.day - 1, 9, 30),
  );

  Widget buildApp(ListState<NotificationModel> state) {
    return ProviderScope(
      overrides: [
        notificationNotifierProvider.overrideWith(
          () => _FakeNotificationNotifier(state),
        ),
        unreadCountProvider.overrideWith(
          (ref) => state.items.where((n) => !n.read).length,
        ),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: NotificationPanel(),
        ),
      ),
    );
  }

  group('NotificationPanel', () {
    testWidgets(
        'should_display_grouped_notifications_when_loaded', (tester) async {
      final state = ListState<NotificationModel>(
        items: [notifToday, notifYesterday],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Abonnement Netflix'), findsOneWidget);
      expect(find.text('Échéance dette'), findsOneWidget);
    });

    testWidgets(
        'should_show_empty_state_when_no_notifications', (tester) async {
      const state = ListState<NotificationModel>(
        items: [],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Aucune notification'), findsOneWidget);
    });

    testWidgets(
        'should_display_header_title_when_rendered', (tester) async {
      const state = ListState<NotificationModel>(
        items: [],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets(
        'should_display_loading_indicator_when_loading', (tester) async {
      const state = ListState<NotificationModel>(
        items: [],
        isLoading: true,
      );

      await tester.pumpWidget(buildApp(state));
      // Ne pas appeler pumpAndSettle — on observe l'état loading avant resolve
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
