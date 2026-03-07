import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/notifications/presentation/notification_settings_screen.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

// Fake notifier permettant d'injecter un état initial sans déclencher _loadFeatures
class _FakeFeatureConfigNotifier extends FeatureConfigNotifier {
  final FeatureConfigState initialState;

  _FakeFeatureConfigNotifier(this.initialState);

  @override
  FeatureConfigState build() => initialState;

  @override
  Future<void> updateNotificationTypes(List<NotificationType> types) async {
    state = state.copyWith(enabledNotificationTypes: types);
  }

  @override
  Future<void> updateTimezone(String timezone) async {
    state = state.copyWith(timezone: timezone);
  }
}

Widget buildApp(FeatureConfigState configState) {
  return ProviderScope(
    overrides: [
      featureConfigNotifierProvider.overrideWith(
        () => _FakeFeatureConfigNotifier(configState),
      ),
    ],
    child: MaterialApp(
      theme: theme.AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationSettingsScreen(),
    ),
  );
}

void main() {
  group('NotificationSettingsScreen', () {
    testWidgets('should_show_loading_when_state_is_loading', (tester) async {
      // Arrange
      const configState = FeatureConfigState(isLoading: true);

      // Act
      await tester.pumpWidget(buildApp(configState));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_display_all_notification_types_when_loaded',
        (tester) async {
      // Arrange — tous les types activés, état chargé
      const configState = FeatureConfigState(
        isLoading: false,
        enabledNotificationTypes: NotificationType.values,
      );

      // Act
      await tester.pumpWidget(buildApp(configState));
      await tester.pumpAndSettle();

      // Assert — les 2 labels de NotificationType sont affichés
      expect(find.text('Échéance abonnement'), findsOneWidget);
      expect(find.text('Échéance dette'), findsOneWidget);
    });

    testWidgets('should_toggle_notification_type_when_switch_tapped',
        (tester) async {
      // Arrange — subscriptionDue activé, debtDue désactivé
      final configState = FeatureConfigState(
        isLoading: false,
        enabledNotificationTypes: [NotificationType.subscriptionDue],
      );

      // Act
      await tester.pumpWidget(buildApp(configState));
      await tester.pumpAndSettle();

      // Trouver le Switch correspondant à 'Échéance abonnement' (actuellement ON)
      // et le désactiver
      final switchFinder = find.byType(Switch).first;
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Assert — le switch est maintenant OFF (état mis à jour dans le fake notifier)
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    });

    testWidgets('should_display_timezone_dropdown_when_loaded', (tester) async {
      // Arrange
      const configState = FeatureConfigState(
        isLoading: false,
        timezone: 'Europe/Paris',
      );

      // Act
      await tester.pumpWidget(buildApp(configState));
      await tester.pumpAndSettle();

      // Assert — le label du dropdown est présent
      expect(find.text('Fuseau horaire'), findsOneWidget);
      // La valeur initiale est affichée
      expect(find.text('Europe/Paris'), findsOneWidget);
    });

    testWidgets('should_update_timezone_when_selected', (tester) async {
      // Arrange — timezone initiale : Europe/Paris
      const configState = FeatureConfigState(
        isLoading: false,
        timezone: 'Europe/Paris',
      );

      // Act
      await tester.pumpWidget(buildApp(configState));
      await tester.pumpAndSettle();

      // Ouvrir le dropdown
      await tester.tap(find.text('Europe/Paris'));
      await tester.pumpAndSettle();

      // Sélectionner une autre valeur
      await tester.tap(find.text('Europe/London').last);
      await tester.pumpAndSettle();

      // Assert — la nouvelle valeur est affichée dans le dropdown
      expect(find.text('Europe/London'), findsOneWidget);
    });
  });
}
