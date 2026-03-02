import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

List<Feature> _safeParseNavOrder(dynamic json) {
  if (json == null) return Feature.values.toList();
  if (json is! List) return Feature.values.toList();
  final parsed = json
      .map((e) => Feature.values.where((f) => f.name == e || f.name == e.toString()).firstOrNull)
      .whereType<Feature>()
      .toList();
  return parsed.isEmpty ? Feature.values.toList() : parsed;
}

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
    @Default(Feature.values)
    @JsonKey(fromJson: _safeParseNavOrder)
    List<Feature> navOrder,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}
