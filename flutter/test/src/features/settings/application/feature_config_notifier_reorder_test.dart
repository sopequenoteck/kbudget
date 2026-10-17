import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';

import '../../../../helpers/display_locale.dart';
import 'language_notifier_test.dart' show FakePreferenceDataSource, FakeAuthNotifier;

class MockAppConfigRepository implements AppConfigRepository {
  List<Feature> enabledFeatures = [Feature.subscriptions, Feature.debts];
  List<Feature> navOrder = Feature.values.toList();
  List<Feature>? lastSavedNavOrder;

  @override
  Future<List<Feature>> getEnabledFeatures() async => enabledFeatures;

  @override
  Future<void> setEnabledFeatures(List<Feature> features) async {
    enabledFeatures = features;
  }

  @override
  Future<List<Feature>> getNavOrder() async => navOrder;

  @override
  Future<void> setNavOrder(List<Feature> order) async {
    lastSavedNavOrder = order;
    navOrder = order;
  }

  @override
  Future<AppConfig> getConfig() async => AppConfig(
        enabledFeatures: enabledFeatures,
        navOrder: navOrder,
      );

  @override
  Future<void> saveConfig(AppConfig config) async {}

  @override
  Future<bool> isOnboardingCompleted() async => true;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}

  @override
  Future<void> setServerUrl(String url) async {}

  @override
  Future<String?> getServerUrl() async => null;

  @override
  Future<void> setTheme(AppTheme theme) async {}

  @override
  Future<AppTheme> getTheme() async => AppTheme.light;

  @override
  Future<void> setTextScale(TextScale textScale) async {}

  @override
  Future<TextScale> getTextScale() async => TextScale.medium;

  @override
  Future<String?> getLanguage() async => null;

  @override
  Future<void> setLanguage(String? language) async {}
}

void main() {
  late MockAppConfigRepository mockRepo;
  late ProviderContainer container;

  FeatureConfigNotifier notifier() =>
      container.read(featureConfigNotifierProvider.notifier);

  FeatureConfigState state() => container.read(featureConfigNotifierProvider);

  setUp(() async {
    mockRepo = MockAppConfigRepository();
    container = ProviderContainer(
      overrides: [
        displayLocaleOverride(),
        appConfigRepositoryProvider.overrideWithValue(mockRepo),
        preferenceRemoteDataSourceProvider
            .overrideWith((ref) async => FakePreferenceDataSource()),
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(const AuthState.authenticated()),
        ),
      ],
    );
    // Let _loadFeatures() complete
    state();
    await pumpEventQueue();
  });

  tearDown(() {
    container.dispose();
  });

  group('reorderNavigation', () {
    test('should_update_navOrder_when_reorderNavigation_called', () async {
      final newOrder = [Feature.subscriptions, Feature.debts, Feature.budgets];
      await notifier().reorderNavigation(newOrder);
      expect(state().navOrder, newOrder);
    });

    test('should_persist_navOrder_locally_when_reordering', () async {
      final newOrder = [Feature.subscriptions, Feature.debts, Feature.budgets];
      await notifier().reorderNavigation(newOrder);
      expect(mockRepo.lastSavedNavOrder, newOrder);
    });

    test(
        'should_preserve_disabled_features_position_when_reordering_enabled_only',
        () async {
      // Only subscriptions and debts are enabled (budgets disabled)
      // Reorder: debts before subscriptions, budgets keeps its position
      final newOrder = [Feature.debts, Feature.subscriptions, Feature.budgets];
      await notifier().reorderNavigation(newOrder);
      expect(state().navOrder,
          [Feature.debts, Feature.subscriptions, Feature.budgets]);
    });

    test('should_reset_error_when_reordering', () async {
      final newOrder = [Feature.debts, Feature.subscriptions, Feature.budgets];
      await notifier().reorderNavigation(newOrder);
      expect(state().error, isNull);
    });
  });

  group('server errors', () {
    late ProviderContainer serverContainer;

    Future<void> startInServerMode() async {
      serverContainer = ProviderContainer(
        overrides: [
          displayLocaleOverride(),
          appConfigRepositoryProvider.overrideWithValue(mockRepo),
          preferenceRemoteDataSourceProvider.overrideWith(
            (ref) => Future.error(Exception('offline')),
          ),
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthState.authenticated()),
          ),
        ],
      );
      addTearDown(serverContainer.dispose);
      serverContainer.read(featureConfigNotifierProvider);
      await pumpEventQueue();
    }

    test('should_setLoadError_when_serverPreferencesUnavailable', () async {
      await startInServerMode();

      final s = serverContainer.read(featureConfigNotifierProvider);
      expect(s.isLoading, false);
      expect(s.error, 'Impossible de charger les préférences');
    });

    test('should_setSaveError_when_syncToServerFails', () async {
      await startInServerMode();

      await serverContainer
          .read(featureConfigNotifierProvider.notifier)
          .reorderNavigation(
              [Feature.debts, Feature.subscriptions, Feature.budgets]);
      await pumpEventQueue();

      expect(
        serverContainer.read(featureConfigNotifierProvider).error,
        'Impossible de sauvegarder les préférences',
      );
    });
  });

  group('reload at login', () {
    late FakePreferenceDataSource remote;
    late FakeAuthNotifier auth;
    late ProviderContainer loginContainer;

    FeatureConfigState loginState() =>
        loginContainer.read(featureConfigNotifierProvider);

    Future<void> start(AuthState initial) async {
      remote = FakePreferenceDataSource();
      auth = FakeAuthNotifier(initial);
      loginContainer = ProviderContainer(
        overrides: [
          displayLocaleOverride(),
          appConfigRepositoryProvider.overrideWithValue(mockRepo),
          preferenceRemoteDataSourceProvider
              .overrideWith((ref) async => remote),
          authNotifierProvider.overrideWith(() => auth),
        ],
      );
      addTearDown(loginContainer.dispose);
      loginContainer.read(authNotifierProvider);
      loginContainer.read(featureConfigNotifierProvider);
      await pumpEventQueue();
    }

    test('should_keepLocalFeatures_when_notAuthenticated', () async {
      mockRepo.enabledFeatures = [Feature.debts];

      await start(const AuthState.unauthenticated());

      expect(loginState().enabledFeatures, [Feature.debts]);
      expect(remote.reads, 0);
    });

    test('should_loadServerFeatures_when_userLogsIn', () async {
      mockRepo.enabledFeatures = [Feature.debts];
      await start(const AuthState.unauthenticated());
      expect(remote.reads, 0);

      auth.emit(const AuthState.authenticated());
      await pumpEventQueue();

      expect(loginState().enabledFeatures, [Feature.budgets]);
      expect(remote.reads, 1);
      expect(mockRepo.enabledFeatures, [Feature.budgets]);
    });

    test('should_reloadServerFeatures_when_userLogsInAgain', () async {
      await start(const AuthState.authenticated());
      expect(remote.reads, 1);

      auth.emit(const AuthState.unauthenticated());
      await pumpEventQueue();
      auth.emit(const AuthState.authenticated());
      await pumpEventQueue();

      expect(remote.reads, 2);
    });

    test('should_notReload_when_authStateChangesWithoutLogin', () async {
      await start(const AuthState.authenticated());

      auth.emit(const AuthState.authenticated());
      await pumpEventQueue();
      auth.emit(const AuthState.authenticating());
      await pumpEventQueue();
      auth.emit(const AuthState.unauthenticated());
      await pumpEventQueue();

      expect(remote.reads, 1);
    });

    test('should_keepFeatures_when_reloadFails', () async {
      mockRepo.enabledFeatures = [Feature.debts];
      await start(const AuthState.unauthenticated());
      remote.failReads = true;

      auth.emit(const AuthState.authenticated());
      await pumpEventQueue();

      final s = loginState();
      expect(s.enabledFeatures, [Feature.debts]);
      expect(s.error, 'Impossible de charger les préférences');
      expect(s.isLoading, false);
    });
  });
}
