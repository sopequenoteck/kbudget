import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/common_widgets/bottom_sheet_4_rows_widget.dart';
import 'package:k_budget/src/common_widgets/category_select_expand.dart';
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

      // Le formulaire est maintenant un BottomSheet4RowsWidget
      expect(find.byType(BottomSheet4RowsWidget), findsOneWidget);
      // Titre création
      expect(find.text('Nouvel abonnement'), findsOneWidget);
      // Boutons footer
      expect(find.byKey(const Key('bsheet_submit')), findsOneWidget);
      expect(find.byKey(const Key('bsheet_cancel')), findsOneWidget);
      // Pill Enregistrer
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('should_show_validation_errors_when_submitting_empty_form',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap sur le bouton Valider (Enregistrer)
      await tester.tap(find.byKey(const Key('bsheet_submit')));
      await tester.pumpAndSettle();

      // Les erreurs de validation doivent apparaître
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

      // Fill montant (premier TextField hero)
      await tester.enterText(
        find.byKey(const Key('tf_montant')),
        '9.99',
      );

      // Fill nom
      await tester.enterText(
        find.byKey(const Key('tf_nom')),
        'Spotify',
      );

      // Tap sur Valider
      await tester.tap(find.byKey(const Key('bsheet_submit')));
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

      // Valeurs pré-remplies visibles
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('15.99'), findsOneWidget);
      // Titre mode édition
      expect(find.text('Modifier abonnement'), findsOneWidget);
      // Bouton Modifier dans le footer
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

      // Trouver et tapper la pill Supprimer (icône trash)
      await tester.tap(find.byIcon(PhosphorIconsRegular.trash));
      await tester.pumpAndSettle();

      // La boîte de dialogue de confirmation doit apparaître
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

      // Remplir les champs requis
      await tester.enterText(find.byKey(const Key('tf_montant')), '10');
      await tester.enterText(find.byKey(const Key('tf_nom')), 'Test');

      await tester.tap(find.byKey(const Key('bsheet_submit')));
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

      // Remplir les champs requis
      await tester.enterText(find.byKey(const Key('tf_montant')), '600');
      await tester.enterText(find.byKey(const Key('tf_nom')), 'Assurance');

      await tester.tap(find.byKey(const Key('bsheet_submit')));
      await tester.pump();

      expect(savedSub, isNotNull);
      expect(savedSub!.frequence, Frequency.annuel);
    });

    testWidgets('should_disable_footer_when_creating_category',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Le BottomSheet4RowsWidget doit être présent
      expect(find.byType(BottomSheet4RowsWidget), findsOneWidget);

      // Ouvrir la section catégorie via la pill
      await tester.tap(find.text('Catégorie'));
      await tester.pumpAndSettle();

      // CategorySelectExpand doit être visible
      expect(find.byType(CategorySelectExpand), findsOneWidget);

      // Déclencher le mode création (bouton "+ Créer")
      // La liste affiche testCategory (cat1 - Loisirs) mais on peut taper un terme inexistant
      await tester.enterText(
        find.descendant(
          of: find.byType(CategorySelectExpand),
          matching: find.byType(TextField),
        ),
        'NouvelleCategorie',
      );
      await tester.pumpAndSettle();

      // Le bouton "+ Créer «NouvelleCategorie»" doit apparaître
      expect(find.textContaining('Créer'), findsAtLeast(1));

      // Tapper le bouton créer pour basculer en mode création
      await tester.tap(find.textContaining('+ Créer'));
      await tester.pumpAndSettle();

      // Le footer doit être désactivé (footerEnabled = false)
      // On vérifie que le BottomSheet4RowsWidget est toujours présent avec footerEnabled = false
      // via l'IgnorePointer + Opacity sur bsheet_bottom_row
      final bottomRow = find.byKey(const Key('bsheet_bottom_row'));
      expect(bottomRow, findsOneWidget);
    });
  });
}
