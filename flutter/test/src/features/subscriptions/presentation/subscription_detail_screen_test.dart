import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/subscription_payment.dart';
import 'package:k_budget/src/domain/models/subscription_total_paid.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/subscriptions/presentation/subscription_detail_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/fixtures/test_fixtures.dart';
import '../../../../helpers/mocks.mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockSubscriptionRepository mockSubRepo;
  late MockCategoryRepository mockCatRepo;
  late MockAccountRepository mockAccRepo;

  final sub1 = Subscription(
    id: 'sub-1',
    nom: 'Netflix',
    montant: 15.99,
    frequence: Frequency.mensuel,
    dateDebut: DateTime(2026, 1, 1),
    actif: true,
    categoryId: 'cat1',
  );

  final payment1 = SubscriptionPayment(
    id: 'pay-1',
    montant: 15.99,
    date: DateTime(2026, 2, 1),
    subscriptionName: 'Netflix',
    accountName: 'Compte courant',
  );

  const totalPaid = SubscriptionTotalPaid(
    subscriptionId: 'sub-1',
    subscriptionName: 'Netflix',
    totalPaid: 15.99,
    paymentCount: 1,
  );

  setUp(() {
    mockSubRepo = MockSubscriptionRepository();
    mockCatRepo = MockCategoryRepository();
    mockAccRepo = MockAccountRepository();
    when(mockSubRepo.getById(any)).thenAnswer((_) async => sub1);
    when(mockCatRepo.getAll()).thenAnswer((_) async => []);
    when(mockAccRepo.getAll()).thenAnswer((_) async => []);
  });

  Widget buildApp({Subscription? initialSubscription}) {
    return ProviderScope(
      overrides: [
        dataModeProvider.overrideWith((_) => DataMode.server),
        subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
        categoryRepositoryProvider.overrideWithValue(mockCatRepo),
        accountRepositoryProvider.overrideWithValue(mockAccRepo),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: SubscriptionDetailScreen(
          subscriptionId: 'sub-1',
          initialSubscription: initialSubscription,
        ),
      ),
    );
  }

  group('SubscriptionDetailScreen', () {
    testWidgets('should_show_subscription_info_when_initial_subscription_provided',
        (tester) async {
      when(mockSubRepo.getPayments(any)).thenAnswer((_) async => [payment1]);
      when(mockSubRepo.getTotalPaid(any)).thenAnswer((_) async => totalPaid);

      await tester.pumpWidget(buildApp(initialSubscription: sub1));
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsWidgets);
      // Vérifier la présence du montant et de la fréquence (formatage peut varier)
      expect(find.textContaining('15'), findsWidgets);
      expect(find.textContaining('/mois'), findsWidgets);
    });

    testWidgets('should_show_payment_history_section_when_subscription_loaded',
        (tester) async {
      when(mockSubRepo.getPayments(any)).thenAnswer((_) async => [payment1]);
      when(mockSubRepo.getTotalPaid(any)).thenAnswer((_) async => totalPaid);

      await tester.pumpWidget(buildApp(initialSubscription: sub1));
      await tester.pumpAndSettle();

      expect(find.text('Historique'), findsOneWidget);
    });

    testWidgets('should_show_pay_button_when_subscription_loaded',
        (tester) async {
      when(mockSubRepo.getPayments(any)).thenAnswer((_) async => []);
      when(mockSubRepo.getTotalPaid(any)).thenAnswer((_) async => totalPaid);

      await tester.pumpWidget(buildApp(initialSubscription: sub1));
      await tester.pumpAndSettle();

      expect(find.text('Payer'), findsOneWidget);
    });

    testWidgets('should_show_translated_category_when_category_is_system',
        (tester) async {
      when(mockSubRepo.getPayments(any)).thenAnswer((_) async => []);
      when(mockSubRepo.getTotalPaid(any)).thenAnswer((_) async => totalPaid);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [TestFixtures.systemCategory]);
      final systemSub = sub1.copyWith(categoryId: 'cat-sys');
      when(mockSubRepo.getById(any)).thenAnswer((_) async => systemSub);

      await tester.pumpWidget(buildApp(initialSubscription: systemSub));
      await tester.pumpAndSettle();
      await ProviderScope.containerOf(tester.element(find.byType(Scaffold)))
          .read(categoryNotifierProvider.notifier)
          .loadItems();
      await tester.pumpAndSettle();

      expect(find.text('🔁 Abonnement'), findsOneWidget);
      expect(find.textContaining('Subscription'), findsNothing);
    });
  });
}
