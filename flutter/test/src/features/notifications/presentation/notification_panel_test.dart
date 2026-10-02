import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/domain/enums/entity_type.dart';
import 'package:k_budget/src/domain/enums/notification_type.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/features/notifications/application/notification_notifier.dart';
import 'package:k_budget/src/features/notifications/presentation/notification_panel.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_list_state.dart';

// Notifier de test permettant d'injecter un état initial
class _FakeNotificationNotifier extends NotificationNotifier {
  final ListState<NotificationModel> initialState;
  final List<String> readIds = [];

  _FakeNotificationNotifier(this.initialState);

  @override
  ListState<NotificationModel> build() => initialState;

  @override
  Future<void> loadItems() async {
    // Ne recharge pas — l'état est déjà injecté
  }

  @override
  Future<void> markAsRead(String id) async {
    // Enregistre l'appel sans accès réseau
    readIds.add(id);
  }
}

class _FakeRecurringListNotifier extends RecurringListNotifier {
  final List<String> validatedIds = [];
  final List<String> skippedIds = [];

  @override
  ListState<RecurringTransaction> build() =>
      const ListState<RecurringTransaction>();

  @override
  Future<void> loadItems() async {}

  @override
  Future<void> validate(String id) async {
    validatedIds.add(id);
  }

  @override
  Future<void> skip(String id) async {
    skippedIds.add(id);
  }
}

class _FakeSubscriptionNotifier extends SubscriptionNotifier {
  final List<String> paidIds = [];

  @override
  SubscriptionListState build() => const SubscriptionListState();

  @override
  Future<void> loadItems() async {}

  @override
  Future<void> pay(String id) async {
    paidIds.add(id);
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

  final notifRecurring = NotificationModel(
    id: '3',
    type: NotificationType.recurringTransactionDue,
    title: 'Récurrence due',
    message: 'Votre transaction récurrente arrive à échéance',
    entityType: EntityType.recurringTransaction,
    entityId: 'recurring-1',
    read: false,
    createdAt: DateTime(now.year, now.month, now.day, 8, 0),
  );

  final notifSubscription = NotificationModel(
    id: '4',
    type: NotificationType.subscriptionDue,
    title: 'Abonnement Spotify',
    message: 'Votre abonnement Spotify arrive à échéance',
    entityType: EntityType.subscription,
    entityId: 'sub-2',
    read: false,
    createdAt: DateTime(now.year, now.month, now.day, 9, 0),
  );

  final notifWithParams = NotificationModel(
    id: '5',
    type: NotificationType.budgetExceeded,
    title: 'Budget Groceries exceeded',
    message: 'You have exceeded the Groceries budget (120%)',
    entityType: EntityType.budget,
    entityId: 'budget-1',
    createdAt: DateTime(now.year, now.month, now.day, 11, 0),
    params: const {'category': 'Courses', 'percentage': '120'},
  );

  final notifUnknownType = NotificationModel(
    id: '6',
    type: null,
    title: 'Stored title',
    message: 'Stored message',
    entityId: 'entity-1',
    createdAt: DateTime(now.year, now.month, now.day, 12, 0),
    params: const {'name': 'Netflix'},
  );

  Widget buildApp(
    ListState<NotificationModel> state, {
    _FakeRecurringListNotifier? recurringNotifier,
    _FakeSubscriptionNotifier? subscriptionNotifier,
    _FakeNotificationNotifier? notificationNotifier,
  }) {
    final fakeRecurring = recurringNotifier ?? _FakeRecurringListNotifier();
    final fakeSubscription = subscriptionNotifier ?? _FakeSubscriptionNotifier();

    return ProviderScope(
      overrides: [
        notificationNotifierProvider.overrideWith(
          () => notificationNotifier ?? _FakeNotificationNotifier(state),
        ),
        unreadCountProvider.overrideWith(
          (ref) => state.items.where((n) => !n.read).length,
        ),
        recurringListNotifierProvider.overrideWith(() => fakeRecurring),
        subscriptionNotifierProvider.overrideWith(() => fakeSubscription),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
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

    testWidgets(
        'should_show_validate_skip_buttons_for_recurring', (tester) async {
      final state = ListState<NotificationModel>(
        items: [notifRecurring],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Valider'), findsOneWidget);
      expect(find.byTooltip('Passer'), findsOneWidget);
    });

    testWidgets(
        'should_show_pay_button_for_subscription', (tester) async {
      final state = ListState<NotificationModel>(
        items: [notifSubscription],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Payer'), findsOneWidget);
    });

    testWidgets(
        'should_call_validate_on_recurring_validate_button_tap', (tester) async {
      final fakeRecurring = _FakeRecurringListNotifier();
      final state = ListState<NotificationModel>(
        items: [notifRecurring],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state, recurringNotifier: fakeRecurring));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Valider'));
      await tester.pumpAndSettle();

      expect(fakeRecurring.validatedIds, contains('recurring-1'));
    });

    testWidgets(
        'should_call_skip_on_recurring_skip_button_tap', (tester) async {
      final fakeRecurring = _FakeRecurringListNotifier();
      final state = ListState<NotificationModel>(
        items: [notifRecurring],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state, recurringNotifier: fakeRecurring));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Passer'));
      await tester.pumpAndSettle();

      expect(fakeRecurring.skippedIds, contains('recurring-1'));
    });

    testWidgets(
        'should_call_pay_on_subscription_pay_button_tap', (tester) async {
      final fakeSubscription = _FakeSubscriptionNotifier();
      final state = ListState<NotificationModel>(
        items: [notifSubscription],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state, subscriptionNotifier: fakeSubscription));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Payer'));
      await tester.pumpAndSettle();

      expect(fakeSubscription.paidIds, contains('sub-2'));
    });

    testWidgets(
        'should_askConfirmation_when_deleteAllTapped', (tester) async {
      final state = ListState<NotificationModel>(
        items: [notifToday],
        isLoading: false,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip("Vider l'historique"));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Supprimer toutes les notifications ? Cette action est irréversible.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_displayTranslatedText_when_paramsArePresent',
        (tester) async {
      final state = ListState<NotificationModel>(items: [notifWithParams]);

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Budget Courses dépassé !'), findsOneWidget);
      expect(
        find.text('Vous avez dépassé le budget Courses (120 %)'),
        findsOneWidget,
      );
      expect(find.text('Budget Groceries exceeded'), findsNothing);
    });

    testWidgets('should_displayStoredText_when_paramsAreAbsent',
        (tester) async {
      final state = ListState<NotificationModel>(items: [notifToday]);

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Abonnement Netflix'), findsOneWidget);
      expect(
        find.text('Votre abonnement Netflix arrive à échéance'),
        findsOneWidget,
      );
    });

    testWidgets('should_showBellWithoutAction_when_typeIsUnknown',
        (tester) async {
      final state = ListState<NotificationModel>(items: [notifUnknownType]);

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Stored title'), findsOneWidget);
      expect(find.text('Stored message'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is PhosphorIcon && w.icon == PhosphorIconsRegular.bell,
        ),
        findsOneWidget,
      );
      // Seuls les deux boutons de l'en-tête : aucune action rapide
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('should_onlyMarkAsRead_when_unknownTypeTapped',
        (tester) async {
      final state = ListState<NotificationModel>(items: [notifUnknownType]);
      final fakeNotifier = _FakeNotificationNotifier(state);

      await tester.pumpWidget(
        buildApp(state, notificationNotifier: fakeNotifier),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stored title'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.readIds, ['6']);
      expect(find.byType(NotificationPanel), findsOneWidget);
    });
  });
}
