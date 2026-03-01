import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

abstract class AppConfigRepository {
  Future<AppConfig> getConfig();
  Future<void> saveConfig(AppConfig config);
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
  Future<DataMode> getDataMode();
  Future<void> setDataMode(DataMode mode);
  Future<void> setServerUrl(String url);
  Future<String?> getServerUrl();
  Future<void> setTheme(AppTheme theme);
  Future<AppTheme> getTheme();
  Future<void> setTextScale(TextScale textScale);
  Future<TextScale> getTextScale();
  Future<void> setLockEnabled(bool enabled);
  Future<void> setLockMethod(LockMethod? method);
  Future<void> setHashedPin(String? pin);
  Future<List<Feature>> getEnabledFeatures();
  Future<void> setEnabledFeatures(List<Feature> features);
  Future<List<Feature>> getNavOrder();
  Future<void> setNavOrder(List<Feature> order);
}
