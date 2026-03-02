import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/feature_config_notifier.dart';

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
        dataMode: DataMode.local,
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
  Future<DataMode> getDataMode() async => DataMode.local;

  @override
  Future<void> setDataMode(DataMode mode) async {}

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
  Future<void> setLockEnabled(bool enabled) async {}

  @override
  Future<void> setLockMethod(LockMethod? method) async {}

  @override
  Future<void> setHashedPin(String? pin) async {}
}

void main() {
  late MockAppConfigRepository mockRepo;
  late ProviderContainer container;

  FeatureConfigNotifier notifier() =>
      container.read(featureConfigNotifierProvider.notifier);

  FeatureConfigState state() => container.read(featureConfigNotifierProvider);

  setUp(() {
    mockRepo = MockAppConfigRepository();
    container = ProviderContainer(
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(mockRepo),
        dataModeProvider.overrideWith((ref) async => DataMode.local),
      ],
    );
    // Let _loadFeatures() complete
    state();
  });

  tearDown(() {
    container.dispose();
  });

  group('reorderNavigation', () {
    test('should_update_navOrder_when_reorderNavigation_called', () async {
      final newOrder = [Feature.shop, Feature.subscriptions, Feature.debts];
      await notifier().reorderNavigation(newOrder);
      expect(state().navOrder, newOrder);
    });

    test('should_persist_navOrder_locally_when_reordering', () async {
      final newOrder = [Feature.shop, Feature.subscriptions, Feature.debts];
      await notifier().reorderNavigation(newOrder);
      expect(mockRepo.lastSavedNavOrder, newOrder);
    });

    test(
        'should_preserve_disabled_features_position_when_reordering_enabled_only',
        () async {
      // Only subscriptions and debts are enabled (shop disabled)
      // Reorder: debts before subscriptions, shop keeps its position
      final newOrder = [Feature.debts, Feature.subscriptions, Feature.shop];
      await notifier().reorderNavigation(newOrder);
      expect(state().navOrder,
          [Feature.debts, Feature.subscriptions, Feature.shop]);
    });

    test('should_reset_error_when_reordering', () async {
      final newOrder = [Feature.debts, Feature.subscriptions, Feature.shop];
      await notifier().reorderNavigation(newOrder);
      expect(state().error, isNull);
    });
  });
}
