import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/budgets/presentation/widgets/budget_form.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../helpers/fixtures/test_fixtures.dart';

class _TestCategoryNotifier extends CategoryNotifier {
  _TestCategoryNotifier(this.preloadedItems);

  final List<Category> preloadedItems;

  @override
  ListState<Category> build() => ListState<Category>(items: preloadedItems);
}

void main() {
  const testCategory = Category(
    id: 'cat1',
    nom: 'Alimentation',
    icone: '🛒',
    couleur: '#4CAF50',
  );

  Widget buildApp({
    Budget? budget,
    List<Category> categories = const [testCategory],
    required Future<void> Function(Budget) onSaved,
    Future<void> Function(String)? onDeleted,
    VoidCallback? onCancelled,
  }) {
    return ProviderScope(
      overrides: [
        categoryNotifierProvider.overrideWith(
          () => _TestCategoryNotifier(categories),
        ),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BudgetForm(
            budget: budget,
            onSaved: onSaved,
            onDeleted: onDeleted,
            onCancelled: onCancelled ?? () {},
          ),
        ),
      ),
    );
  }

  group('BudgetForm', () {
    testWidgets(
        'should_showCreateModeFieldsWithSaveLabel_when_noBudgetProvided',
        (tester) async {
      await tester.pumpWidget(buildApp(onSaved: (_) async {}));
      await tester.pumpAndSettle();

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Catégorie'), findsOneWidget);
      expect(find.text('Seuil d\'alerte'), findsOneWidget);
    });

    testWidgets(
        'should_showLockedCategoryWithName_when_editingBudgetWithCategoryName',
        (tester) async {
      const budget = Budget(
        id: 'b1',
        categoryId: 'cat1',
        montant: 200,
        frequence: Frequency.mensuel,
        categoryNom: 'Alimentation',
        categoryIcone: '🛒',
        categoryCouleur: '#4CAF50',
      );

      await tester.pumpWidget(buildApp(budget: budget, onSaved: (_) async {}));
      await tester.pumpAndSettle();

      expect(find.text('Modifier'), findsOneWidget);
      expect(find.text('Catégorie'), findsOneWidget);
      expect(find.text('Alimentation'), findsOneWidget);
    });

    testWidgets(
        'should_showFallbackCategoryLabel_when_editingBudgetWithoutCategoryName',
        (tester) async {
      const budget = Budget(
        id: 'b1',
        categoryId: 'cat1',
        montant: 200,
        frequence: Frequency.mensuel,
      );

      await tester.pumpWidget(buildApp(budget: budget, onSaved: (_) async {}));
      await tester.pumpAndSettle();

      // Le titre du champ ET le contenu verrouillé retombent tous deux
      // sur le libellé générique "Catégorie".
      expect(find.text('Catégorie'), findsNWidgets(2));
    });

    testWidgets(
        'should_showErrorSnackbar_when_saveFails', (tester) async {
      await tester.pumpWidget(
        buildApp(onSaved: (_) async => throw Exception('boom')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choisir une catégorie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alimentation'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '50');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets(
        'should_showErrorSnackbar_when_deleteFails', (tester) async {
      const budget = Budget(
        id: 'b1',
        categoryId: 'cat1',
        montant: 200,
        frequence: Frequency.mensuel,
        categoryNom: 'Alimentation',
      );

      await tester.pumpWidget(
        buildApp(
          budget: budget,
          onSaved: (_) async {},
          onDeleted: (_) async => throw Exception('boom'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(PhosphorIconsRegular.trash));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets(
        'should_showAllBudgetedMessage_when_noCategoryLeft', (tester) async {
      await tester.pumpWidget(
        buildApp(categories: const [], onSaved: (_) async {}),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Toutes les catégories ont déjà un budget.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'should_formatThresholdAsLocalePercent_when_rendered', (tester) async {
      await tester.pumpWidget(buildApp(onSaved: (_) async {}));
      await tester.pumpAndSettle();

      // fr_FR : espace insecable avant le signe %
      expect(find.textContaining(RegExp(r'^80\s%$')), findsOneWidget);
      expect(find.textContaining(RegExp(r'^50\s%$')), findsOneWidget);
      expect(find.textContaining(RegExp(r'^100\s%$')), findsOneWidget);
      expect(find.text('Mensuel'), findsOneWidget);
    });

    testWidgets(
        'should_showTranslatedCategoryName_when_creatingWithSystemCategory',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          categories: [TestFixtures.systemCategory],
          onSaved: (_) async {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choisir une catégorie'));
      await tester.pumpAndSettle();

      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.text('Subscription'), findsNothing);
    });

    testWidgets(
        'should_showTranslatedLockedCategory_when_editingSystemCategoryBudget',
        (tester) async {
      const budget = Budget(
        id: 'b1',
        categoryId: 'cat-sys',
        montant: 200,
        frequence: Frequency.mensuel,
        categoryNom: 'Subscription',
        categorySystemKey: 'SUBSCRIPTION',
        categoryIcone: '🔁',
        categoryCouleur: '#8B5CF6',
      );

      await tester.pumpWidget(buildApp(budget: budget, onSaved: (_) async {}));
      await tester.pumpAndSettle();

      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.text('Subscription'), findsNothing);
    });

    testWidgets(
        'should_keepCategorySystemKey_when_savingSystemCategoryBudget',
        (tester) async {
      Budget? saved;
      const budget = Budget(
        id: 'b1',
        categoryId: 'cat-sys',
        montant: 200,
        frequence: Frequency.mensuel,
        categoryNom: 'Subscription',
        categorySystemKey: 'SUBSCRIPTION',
      );

      await tester.pumpWidget(
        buildApp(budget: budget, onSaved: (b) async => saved = b),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier'));
      await tester.pump();

      expect(saved?.categorySystemKey, 'SUBSCRIPTION');
      expect(saved?.categoryNom, 'Subscription');
    });
  });
}
