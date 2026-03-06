import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/features/subscriptions/presentation/widgets/subscription_form.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../../helpers/mocks.mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockAccountRepository mockAccountRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockSubscriptionRepository mockSubRepo;

  const testAccount = Account(
    id: 'acc1',
    nom: 'Compte courant',
    type: AccountType.courant,
    soldeInitial: 1000,
    icone: '🏦',
    couleur: '#4CAF50',
    isDefault: true,
    actif: true,
    solde: 1500,
  );

  const testCategory = Category(
    id: 'cat1',
    nom: 'Loisirs',
    icone: '🎮',
    couleur: '#FF9800',
  );

  final testSubscription = Subscription(
    id: 'sub1',
    nom: 'Netflix',
    montant: 15.99,
    frequence: Frequency.mensuel,
    dateDebut: DateTime(2026, 1, 1),
    actif: true,
    categoryId: 'cat1',
    accountId: 'acc1',
  );

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockSubRepo = MockSubscriptionRepository();

    when(mockAccountRepo.getAll()).thenAnswer((_) async => [testAccount]);
    when(mockCategoryRepo.getAll()).thenAnswer((_) async => [testCategory]);
    when(mockSubRepo.getAll()).thenAnswer((_) async => []);
  });

  Widget buildApp({
    Subscription? subscription,
    Frequency frequence = Frequency.mensuel,
    Future<void> Function(Subscription)? onSaved,
    Future<void> Function(String)? onDeleted,
    VoidCallback? onCancelled,
  }) {
    return ProviderScope(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        subscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SubscriptionForm(
              subscription: subscription,
              frequence: frequence,
              onSaved: onSaved ?? (_) async {},
              onDeleted: onDeleted,
              onCancelled: onCancelled ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('SubscriptionForm', () {
    testWidgets('should_render_all_fields_when_opened_in_creation_mode',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Montant'), findsOneWidget);
      expect(find.text('Date de début'), findsOneWidget);
      expect(find.text('Actif'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('should_show_validation_errors_when_submitting_empty_form',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Champ requis'), findsAtLeast(1));
    });

    testWidgets(
        'should_call_onSaved_with_valid_subscription_when_form_filled',
        (tester) async {
      Subscription? savedSub;

      await tester.pumpWidget(buildApp(
        onSaved: (sub) async {
          savedSub = sub;
        },
      ));
      await tester.pumpAndSettle();

      // Fill nom
      await tester.enterText(
        find.byType(TextField).first,
        'Spotify',
      );

      // Fill montant
      await tester.enterText(
        find.byType(TextField).last,
        '9.99',
      );

      // Tap save
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();

      expect(savedSub, isNotNull);
      expect(savedSub!.nom, 'Spotify');
      expect(savedSub!.montant, 9.99);
      expect(savedSub!.frequence, Frequency.mensuel);
      expect(savedSub!.actif, true);
    });

    testWidgets('should_prefill_fields_when_opened_in_edit_mode',
        (tester) async {
      await tester.pumpWidget(buildApp(
        subscription: testSubscription,
        frequence: testSubscription.frequence,
        onDeleted: (_) async {},
      ));
      await tester.pumpAndSettle();

      // Verify pre-filled values
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('15.99'), findsOneWidget);
      expect(find.text('Modifier'), findsOneWidget);
    });

    testWidgets('should_show_delete_confirmation_when_delete_tapped',
        (tester) async {
      await tester.pumpWidget(buildApp(
        subscription: testSubscription,
        frequence: testSubscription.frequence,
        onDeleted: (_) async {},
      ));
      await tester.pumpAndSettle();

      // Find and tap delete icon
      await tester.tap(find.byIcon(PhosphorIconsRegular.trash));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text("Supprimer l'abonnement"), findsOneWidget);
      expect(
        find.text(
            'Êtes-vous sûr de vouloir supprimer cet abonnement ? Cette action est irréversible.'),
        findsOneWidget,
      );
    });

    testWidgets('should_not_show_delete_button_in_creation_mode',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.byIcon(PhosphorIconsRegular.trash),
        findsNothing,
      );
    });

    testWidgets(
        'should_default_frequency_to_mensuel_when_opened_in_creation_mode',
        (tester) async {
      Subscription? savedSub;

      await tester.pumpWidget(buildApp(
        frequence: Frequency.mensuel,
        onSaved: (sub) async {
          savedSub = sub;
        },
      ));
      await tester.pumpAndSettle();

      // Fill required fields
      await tester.enterText(find.byType(TextField).first, 'Test');
      await tester.enterText(find.byType(TextField).last, '10');

      await tester.tap(find.text('Enregistrer'));
      await tester.pump();

      expect(savedSub, isNotNull);
      expect(savedSub!.frequence, Frequency.mensuel);
    });

    testWidgets(
        'should_pass_selected_frequency_to_subscription_when_saved',
        (tester) async {
      Subscription? savedSub;

      await tester.pumpWidget(buildApp(
        frequence: Frequency.annuel,
        onSaved: (sub) async {
          savedSub = sub;
        },
      ));
      await tester.pumpAndSettle();

      // Fill required fields
      await tester.enterText(find.byType(TextField).first, 'Assurance');
      await tester.enterText(find.byType(TextField).last, '600');

      await tester.tap(find.text('Enregistrer'));
      await tester.pump();

      expect(savedSub, isNotNull);
      expect(savedSub!.frequence, Frequency.annuel);
    });
  });
}
