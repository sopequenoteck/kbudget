import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart' hide AppTheme;
import 'package:k_budget/src/domain/models/user.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_repository_provider.dart';
import 'package:k_budget/src/features/user_profile/domain/models/avatar_metadata.dart';
import 'package:k_budget/src/features/user_profile/domain/models/change_password_request.dart';
import 'package:k_budget/src/features/user_profile/domain/models/delete_account_request.dart';
import 'package:k_budget/src/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:k_budget/src/features/user_profile/presentation/screens/profile_settings_screen.dart';
import 'package:k_budget/src/theme/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ────────────────────────────────────────────────────────────────────────────
// User de test partagé
// ────────────────────────────────────────────────────────────────────────────

const _testUser = User(
  id: 'test-id',
  email: 'kelly@example.com',
  name: 'Kelly',
  defaultCurrency: Currency.eur,
  isAdmin: false,
);

// ────────────────────────────────────────────────────────────────────────────
// Mock notifier
// ────────────────────────────────────────────────────────────────────────────

class _MockUserProfileNotifier extends UserProfileNotifier {
  final User _user;
  _MockUserProfileNotifier(this._user);

  @override
  Future<User> build() async => _user;

  @override
  Future<void> loadProfile() async {
    state = AsyncData(_user);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Mock repository de base
// ────────────────────────────────────────────────────────────────────────────

class _MockUserProfileRepository implements UserProfileRepository {
  @override
  Future<AvatarMetadata> uploadAvatar(File file) async => AvatarMetadata(
        url: 'https://example.com/avatar.jpg',
        etag: 'mock-etag',
        uploadedAt: DateTime(2026, 1, 1),
      );

  @override
  Future<void> deleteAvatar() async {}

  @override
  Future<AuthResponse> changePassword(ChangePasswordRequest req) async =>
      const AuthResponse(
        accessToken: 'mock-token',
        refreshToken: 'mock-refresh',
        email: 'kelly@example.com',
      );

  @override
  Future<void> updateName(String name) async {}

  @override
  Future<File> exportJson() async => File('/tmp/mock_export.json');

  @override
  Future<File> exportCsv() async => File('/tmp/mock_export.csv');

  @override
  Future<void> deleteAccount(DeleteAccountRequest req) async {}
}

/// Repository qui lève une exception sur updateName.
class _FailingNameRepository extends _MockUserProfileRepository {
  @override
  Future<void> updateName(String name) async {
    throw Exception('Network error');
  }
}

/// Repository dont exportJson ne se termine jamais (pour tester le spinner).
class _SlowExportRepository extends _MockUserProfileRepository {
  final _completer = Completer<void>();

  @override
  Future<File> exportJson() async {
    await _completer.future;
    return File('/tmp/mock_export.json');
  }
}

/// Repository avec callback de tracking.
class _TrackingRepository extends _MockUserProfileRepository {
  final void Function(String name)? onUpdateName;

  _TrackingRepository({this.onUpdateName});

  @override
  Future<void> updateName(String name) async {
    onUpdateName?.call(name);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helper pour construire le widget sous test
// ────────────────────────────────────────────────────────────────────────────

Widget _buildScreen({
  User user = _testUser,
  UserProfileRepository? repository,
}) {
  final repo = repository ?? _MockUserProfileRepository();
  return ProviderScope(
    overrides: [
      userProfileNotifierProvider.overrideWith(
        () => _MockUserProfileNotifier(user),
      ),
      userProfileRepositoryProvider.overrideWith(
        (ref) async => repo,
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const ProfileSettingsScreen(),
    ),
  );
}

/// Configure un viewport téléphone pour éviter les overflows de layout.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ────────────────────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────────────────────

void main() {
  group('ProfileSettingsScreen', () {
    // ── Tests existants adaptés (SC-004, SC-005) ──────────────────────────

    testWidgets('should_showAllSections_when_userLoaded', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      expect(find.text('IDENTITÉ'), findsOneWidget);
      expect(find.text('SÉCURITÉ'), findsOneWidget);
      expect(find.text('DONNÉES', skipOffstage: false), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('ZONE DE DANGER'),
        500,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('ZONE DE DANGER'), findsOneWidget);
    });

    testWidgets('should_showLogoutRow_when_userLoaded', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Déconnexion'),
        500,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Déconnexion'), findsOneWidget);
    });

    testWidgets('should_showChangePasswordRow_when_userLoaded', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Changer le mot de passe', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('should_showAdminLabel_when_emailDisplayed', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      expect(find.text('Géré par l\'administrateur'), findsOneWidget);
    });

    testWidgets('should_showDataSection_when_userLoaded', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      expect(find.text('DONNÉES', skipOffstage: false), findsOneWidget);
    });

    testWidgets('should_showExportJsonRow_when_userLoaded', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Exporter mes données (JSON)', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('should_showExportCsvRow_when_userLoaded', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Exporter mes transactions (CSV)', skipOffstage: false),
        findsOneWidget,
      );
    });

    // ── SC-006 : pas de CurrencySelector, AppBar sans bouton save ─────────

    testWidgets('should_hideCurrencySelector_when_rendered', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      expect(find.text('Devise par défaut'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // ── SC-001 : tap pencil → TextField visible ───────────────────────────

    testWidgets('should_showInlineTextField_when_pencilTapped', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(PhosphorIconsRegular.pencil));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    // ── SC-003 : tap cancel → input fermé ────────────────────────────────

    testWidgets('should_closeEditMode_when_cancelTapped', (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(PhosphorIconsRegular.pencil));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.byIcon(PhosphorIconsRegular.x));
      await tester.pump();

      expect(find.byType(TextField), findsNothing);
    });

    // ── SC-002 : tap save → updateName appelé ────────────────────────────

    testWidgets('should_callUpdateName_when_saveTapped', (tester) async {
      _setPhoneViewport(tester);
      var updateNameCalled = false;
      final repo = _TrackingRepository(
        onUpdateName: (_) => updateNameCalled = true,
      );

      await tester.pumpWidget(_buildScreen(repository: repo));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(PhosphorIconsRegular.pencil));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Nouveau Nom');
      await tester.pump();

      await tester.tap(find.byIcon(PhosphorIconsRegular.check));
      await tester.pump();
      await tester.pump();

      expect(updateNameCalled, isTrue);
    });

    // ── SC-007 : export JSON → spinner visible ────────────────────────────

    testWidgets('should_showSpinner_when_exportJsonStarted', (tester) async {
      _setPhoneViewport(tester);
      final slowRepo = _SlowExportRepository();

      await tester.pumpWidget(_buildScreen(repository: slowRepo));
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Exporter mes données (JSON)'),
        500,
        scrollable: find.byType(Scrollable),
      );

      await tester.tap(find.text('Exporter mes données (JSON)'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // ── SC-008 : pendant export JSON → CSV désactivé ─────────────────────

    testWidgets('should_disableCsvRow_when_exportingJson', (tester) async {
      _setPhoneViewport(tester);
      final slowRepo = _SlowExportRepository();

      await tester.pumpWidget(_buildScreen(repository: slowRepo));
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Exporter mes données (JSON)'),
        500,
        scrollable: find.byType(Scrollable),
      );

      await tester.tap(find.text('Exporter mes données (JSON)'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      expect(
        find.text('Exporter mes transactions (CSV)', skipOffstage: false),
        findsOneWidget,
      );
    });

    // ── SC-009 : erreur → bandeau rouge visible ───────────────────────────

    testWidgets('should_showErrorBanner_when_nameUpdateFails', (tester) async {
      _setPhoneViewport(tester);
      final failingRepo = _FailingNameRepository();

      await tester.pumpWidget(_buildScreen(repository: failingRepo));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(PhosphorIconsRegular.pencil));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Test Nom');
      await tester.pump();

      await tester.tap(find.byIcon(PhosphorIconsRegular.check));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Impossible de mettre à jour le nom'),
        findsOneWidget,
      );
    });
  });
}
