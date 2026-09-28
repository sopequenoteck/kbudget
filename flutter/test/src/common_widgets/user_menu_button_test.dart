// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/user_menu_button.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.mocks.dart';

/// Notifier de test : expose un [AuthState] fixe.
class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

Future<void> pumpUserMenuButton(WidgetTester tester, AuthState authState) async {
  final mockAuthRepo = MockAuthRepository();
  when(mockAuthRepo.logout()).thenAnswer((_) async {});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _FixedAuthNotifier(authState)),
        authRepositoryProvider.overrideWith((_) async => mockAuthRepo),
      ],
      child: MaterialApp(
        theme: app_theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const Scaffold(body: UserMenuButton()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('UserMenuButton', () {
    testWidgets(
      'should_showSettingsOnly_when_unauthenticated',
      (tester) async {
        await pumpUserMenuButton(tester, const AuthState.unauthenticated());

        await tester.tap(find.byType(UserMenuButton));
        await tester.pumpAndSettle();

        expect(find.text('Paramètres'), findsOneWidget);
        expect(find.text('Déconnexion'), findsNothing);
      },
    );

    testWidgets(
      'should_showLogoutOption_when_authenticated',
      (tester) async {
        await pumpUserMenuButton(tester, const AuthState.authenticated());

        await tester.tap(find.byType(UserMenuButton));
        await tester.pumpAndSettle();

        expect(find.text('Paramètres'), findsOneWidget);
        expect(find.text('Déconnexion'), findsOneWidget);
      },
    );

    testWidgets(
      'should_logout_when_logoutTapped',
      (tester) async {
        await pumpUserMenuButton(tester, const AuthState.authenticated());

        await tester.tap(find.byType(UserMenuButton));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Déconnexion'));
        await tester.pumpAndSettle();

        // Le menu se referme, sans lever d'exception.
        expect(find.text('Déconnexion'), findsNothing);
      },
    );
  });
}
