import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/compatibility_provider.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/features/compatibility/presentation/incompatible_screen.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

/// Notifier de test : expose un verdict fixe, sans appel reseau.
class _FixedCompatibilityNotifier extends CompatibilityNotifier {
  _FixedCompatibilityNotifier(this._status);
  final CompatibilityStatus _status;

  @override
  CompatibilityStatus? build() => _status;
}

Future<void> _pump(WidgetTester tester, CompatibilityStatus status) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        compatibilityNotifierProvider
            .overrideWith(() => _FixedCompatibilityNotifier(status)),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        home: const IncompatibleScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Concatene tout le texte affiche a l'ecran.
String _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ');

void main() {
  group('IncompatibleScreen', () {
    testWidgets('should_showClientUpdateMessage_when_clientTooOld',
        (tester) async {
      await _pump(
        tester,
        const CompatibilityClientTooOld(
          clientVersion: '5.0.0',
          requiredVersion: '6.1.0',
        ),
      );

      final text = _visibleText(tester);
      expect(text, contains('Application a mettre a jour'));
      expect(text, contains('6.1.0'));
      expect(text, contains('5.0.0'));
    });

    testWidgets('should_showServerUpdateMessage_when_serverTooOld',
        (tester) async {
      await _pump(
        tester,
        const CompatibilityServerTooOld(
          serverVersion: '5.4.0',
          requiredVersion: '6.1.0',
        ),
      );

      final text = _visibleText(tester);
      expect(text, contains('Serveur a mettre a jour'));
      expect(text, contains('5.4.0'));
    });

    testWidgets('should_explainAbsenceOfVersion_when_serverPredatesMeta',
        (tester) async {
      // serverVersion null : le serveur est anterieur a /api/meta, il ne sait
      // pas annoncer sa version. Le message ne doit pas afficher un trou.
      await _pump(
        tester,
        const CompatibilityServerTooOld(requiredVersion: '6.1.0'),
      );

      final text = _visibleText(tester);
      expect(text, contains('trop ancien pour indiquer sa version'));
      expect(text, isNot(contains('null')));
    });

    testWidgets('should_neverExposeTechnicalError_when_displayingMessage',
        (tester) async {
      // La raison d'etre de cet ecran : remplacer l'erreur de deserialisation
      // incomprehensible par un message actionnable.
      await _pump(
        tester,
        const CompatibilityServerTooOld(
          serverVersion: '5.4.0',
          requiredVersion: '6.1.0',
        ),
      );

      final text = _visibleText(tester).toLowerCase();
      for (final forbidden in ['json', 'http', 'exception', '404', 'null']) {
        expect(text, isNot(contains(forbidden)));
      }
    });

    testWidgets('should_offerRetryAction_when_incompatible', (tester) async {
      await _pump(
        tester,
        const CompatibilityServerTooOld(
          serverVersion: '5.4.0',
          requiredVersion: '6.1.0',
        ),
      );

      expect(find.widgetWithText(FilledButton, 'Reessayer'), findsOneWidget);
    });

    testWidgets('should_clearVerdict_when_retryTapped', (tester) async {
      await _pump(
        tester,
        const CompatibilityServerTooOld(
          serverVersion: '5.4.0',
          requiredVersion: '6.1.0',
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Reessayer'));
      await tester.pumpAndSettle();

      // Le verdict efface, le routeur reverifiera a la prochaine redirection.
      expect(find.byType(IncompatibleScreen), findsOneWidget);
    });
  });
}
