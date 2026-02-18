import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/routing/app_router.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockAppConfigRepository mockRepo;
  late MockAuthRepository mockAuthRepo;

  const localConfig = AppConfig(
    dataMode: DataMode.local,
    onboardingCompleted: true,
  );

  setUp(() {
    mockRepo = MockAppConfigRepository();
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(mockRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            routerConfig: router,
            theme: app_theme.AppTheme.light,
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

      expect(find.text('Aucune transaction'), findsOneWidget);
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
      expect(find.byIcon(Icons.add), findsOneWidget);
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

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });
}
