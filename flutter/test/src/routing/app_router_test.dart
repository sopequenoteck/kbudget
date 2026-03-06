import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/app_router.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockAppConfigRepository mockRepo;
  late MockAuthRepository mockAuthRepo;
  late MockAccountRepository mockAccountRepo;
  late MockTransactionRepository mockTransactionRepo;
  late MockSubscriptionRepository mockSubscriptionRepo;
  late MockDebtRepository mockDebtRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockExchangeRateRepository mockExchangeRateRepo;

  const localConfig = AppConfig(
    dataMode: DataMode.local,
    onboardingCompleted: true,
  );

  setUp(() {
    mockRepo = MockAppConfigRepository();
    mockAuthRepo = MockAuthRepository();
    mockAccountRepo = MockAccountRepository();
    mockTransactionRepo = MockTransactionRepository();
    mockSubscriptionRepo = MockSubscriptionRepository();
    mockDebtRepo = MockDebtRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockExchangeRateRepo = MockExchangeRateRepository();

    when(mockAccountRepo.getAll()).thenAnswer((_) async => []);
    when(mockTransactionRepo.getAll()).thenAnswer((_) async => []);
    when(mockTransactionRepo.getByMonth(any, any))
        .thenAnswer((_) async => []);
    when(mockTransactionRepo.getMonthlySummary(any, any))
        .thenAnswer((_) async => []);
    when(mockSubscriptionRepo.getAll()).thenAnswer((_) async => []);
    when(mockDebtRepo.getAll()).thenAnswer((_) async => []);
    when(mockCategoryRepo.getAll()).thenAnswer((_) async => []);
    when(mockExchangeRateRepo.getAll()).thenAnswer((_) async => <ExchangeRate>[]);
    when(mockRepo.getEnabledFeatures()).thenAnswer(
        (_) async => [Feature.subscriptions, Feature.debts]);
    when(mockRepo.getNavOrder())
        .thenAnswer((_) async => Feature.values.toList());
  });

  Widget buildApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(mockRepo),
        authRepositoryProvider.overrideWith((_) async => mockAuthRepo),
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        subscriptionRepositoryProvider.overrideWithValue(mockSubscriptionRepo),
        debtRepositoryProvider.overrideWithValue(mockDebtRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        exchangeRateRepositoryProvider.overrideWithValue(mockExchangeRateRepo),
        currentUserNameProvider.overrideWith((_) async => null),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            routerConfig: router,
            theme: app_theme.AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }

  group('AppRouter', () {
    testWidgets('should_redirect_to_onboarding_when_not_completed',
        (WidgetTester tester) async {
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur K-Budget'), findsOneWidget);
    });

    testWidgets('should_show_dashboard_when_onboarding_completed',
        (WidgetTester tester) async {
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => true);
      when(mockRepo.getConfig()).thenAnswer((_) async => localConfig);

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Accueil'), findsWidgets);
    });

    testWidgets('should_display_bottom_nav_with_4_items_when_onboarding_done',
        (WidgetTester tester) async {
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => true);
      when(mockRepo.getConfig()).thenAnswer((_) async => localConfig);

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Abonnements'), findsOneWidget);
      expect(find.text('Dettes'), findsOneWidget);
    });

    testWidgets('should_navigate_to_transactions_when_tab_tapped',
        (WidgetTester tester) async {
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => true);
      when(mockRepo.getConfig()).thenAnswer((_) async => localConfig);

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();

      expect(find.text('Aucune transaction ce mois-ci'), findsOneWidget);
    });

    testWidgets('should_show_fab_when_onboarding_done',
        (WidgetTester tester) async {
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => true);
      when(mockRepo.getConfig()).thenAnswer((_) async => localConfig);

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(
        find.byIcon(PhosphorIconsBold.plus),
        findsOneWidget,
      );
    });

    testWidgets('should_show_navigation_rail_when_wide_screen',
        (WidgetTester tester) async {
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => true);
      when(mockRepo.getConfig()).thenAnswer((_) async => localConfig);

      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Wide layout uses a custom sidebar with VerticalDivider, not NavigationRail
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });
}
