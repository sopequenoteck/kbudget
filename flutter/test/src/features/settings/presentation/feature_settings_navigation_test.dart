import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/debts/application/debt_list_state.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/features/settings/presentation/feature_settings_screen.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_list_state.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

// Mock notifier retournant un état fixe sans appel réseau/storage
class _TestFeatureConfigNotifier extends FeatureConfigNotifier {
  final FeatureConfigState _initialState;

  _TestFeatureConfigNotifier(this._initialState);

  @override
  FeatureConfigState build() {
    return _initialState;
  }
}

class _MockSubscriptionNotifier extends SubscriptionNotifier {
  @override
  SubscriptionListState build() {
    return const SubscriptionListState();
  }
}

class _MockDebtNotifier extends DebtNotifier {
  @override
  DebtListState build() {
    return const DebtListState();
  }
}

void main() {
  Widget buildApp({
    List<Feature> enabledFeatures = const [
      Feature.subscriptions,
      Feature.debts,
    ],
    List<Feature>? navOrder,
  }) {
    final testState = FeatureConfigState(
      enabledFeatures: enabledFeatures,
      navOrder: navOrder ?? Feature.values.toList(),
    );

    return ProviderScope(
      overrides: [
        featureConfigNotifierProvider.overrideWith(
          () => _TestFeatureConfigNotifier(testState),
        ),
        subscriptionNotifierProvider.overrideWith(
          () => _MockSubscriptionNotifier(),
        ),
        debtNotifierProvider.overrideWith(
          () => _MockDebtNotifier(),
        ),
      ],
      child: MaterialApp(
        theme: app_theme.AppTheme.light,
        home: const FeatureSettingsScreen(),
      ),
    );
  }

  group('FeatureSettingsScreen - Section Navigation', () {
    testWidgets(
      'should_display_core_items_as_non_draggable',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Les items du noyau fixe doivent être affichés
        expect(find.text('Accueil'), findsWidgets);
        expect(find.text('Transactions'), findsWidgets);

        // 2 icônes de verrou pour les items fixes
        expect(
          find.byIcon(PhosphorIconsRegular.lock),
          findsNWidgets(2),
        );

        // Pas d'icône drag_handle pour les items du noyau
        // (dotsSixVertical est présent pour les features activées : subscriptions + debts = 2)
        // On vérifie que les lock sont bien présents et distincts des dotsSixVertical
        expect(
          find.byIcon(PhosphorIconsRegular.dotsSixVertical),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
      'should_display_enabled_features_with_drag_handle',
      (tester) async {
        await tester.pumpWidget(buildApp(
          enabledFeatures: [Feature.subscriptions, Feature.debts],
        ));
        await tester.pumpAndSettle();

        // Les features activées doivent apparaître dans la section Navigation
        // (les SwitchListTile + les ListTile de la section nav affichent les labels)
        expect(find.text('Abonnements'), findsWidgets);
        expect(find.text('Dettes'), findsWidgets);

        // 2 icônes dotsSixVertical (une pour chaque feature activée)
        expect(
          find.byIcon(PhosphorIconsRegular.dotsSixVertical),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
      'should_display_empty_message_when_no_features_enabled',
      (tester) async {
        await tester.pumpWidget(buildApp(enabledFeatures: const []));
        await tester.pumpAndSettle();

        // Message d'invitation à activer des features
        expect(
          find.text(
            'Activez des fonctionnalités pour personnaliser la navigation',
          ),
          findsOneWidget,
        );

        // Pas de dotsSixVertical car aucune feature activée
        expect(
          find.byIcon(PhosphorIconsRegular.dotsSixVertical),
          findsNothing,
        );
      },
    );

    testWidgets(
      'should_display_preview_with_correct_order',
      (tester) async {
        // navOrder : debts en premier, puis subscriptions, puis budgets
        // enabledFeatures : subscriptions + debts (budgets désactivé)
        // enabledOrdered = navOrder.where(enabled) = [debts, subscriptions]
        await tester.pumpWidget(buildApp(
          enabledFeatures: [Feature.subscriptions, Feature.debts],
          navOrder: [Feature.debts, Feature.subscriptions, Feature.budgets],
        ));
        await tester.pumpAndSettle();

        // La preview doit contenir Accueil et Transactions (items fixes)
        // puis Dettes et Abonnements dans l'ordre du navOrder filtré
        expect(find.text('Accueil'), findsWidgets);
        expect(find.text('Transactions'), findsWidgets);
        expect(find.text('Dettes'), findsWidgets);
        expect(find.text('Abonnements'), findsWidgets);

        // Scroller jusqu'en bas pour rendre la preview visible
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();

        // La preview _BottomNavPreview affiche ses items dans un Row horizontal.
        // On récupère les textes de la preview en prenant, pour chaque label,
        // l'occurrence avec le dy le plus grand (= la plus basse = dans la preview).
        final targetLabels = ['Accueil', 'Transactions', 'Dettes', 'Abonnements'];
        final positions = <String, double>{};

        for (final label in targetLabels) {
          final found = find.text(label);
          expect(found, findsWidgets);

          double maxDy = double.negativeInfinity;
          double dxAtMaxDy = 0;
          for (final element in found.evaluate()) {
            final box = element.renderObject;
            if (box is! RenderBox || !box.hasSize) continue;
            final center = box.localToGlobal(box.size.center(Offset.zero));
            if (center.dy > maxDy) {
              maxDy = center.dy;
              dxAtMaxDy = center.dx;
            }
          }
          positions[label] = dxAtMaxDy;
        }

        // Vérifier l'ordre horizontal dans la preview :
        // Accueil < Transactions < Dettes < Abonnements (gauche à droite)
        expect(
          positions['Accueil']! < positions['Transactions']!,
          isTrue,
          reason: 'Accueil doit être avant Transactions dans la preview',
        );
        expect(
          positions['Transactions']! < positions['Dettes']!,
          isTrue,
          reason: 'Transactions doit être avant Dettes dans la preview',
        );
        expect(
          positions['Dettes']! < positions['Abonnements']!,
          isTrue,
          reason: 'Dettes doit être avant Abonnements dans la preview',
        );
      },
    );
  });
}
