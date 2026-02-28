import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

@freezed
class AppConfig with _$AppConfig {
  const factory AppConfig({
    required DataMode dataMode,
    String? serverUrl,
    @Default(AppTheme.light) AppTheme theme,
    @Default(TextScale.medium) TextScale textScale,
    @Default(false) bool lockEnabled,
    LockMethod? lockMethod,
    String? hashedPin,
    @Default(false) bool onboardingCompleted,
    @Default([Feature.subscriptions, Feature.debts]) List<Feature> enabledFeatures,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}
