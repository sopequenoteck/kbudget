import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

const _featureJsonValues = {
  'SUBSCRIPTIONS': Feature.subscriptions,
  'DEBTS': Feature.debts,
  'BUDGETS': Feature.budgets,
};

Feature? _decodeFeature(dynamic raw) {
  if (raw == null) return null;
  final key = raw.toString();
  return _featureJsonValues[key] ??
      Feature.values.where((f) => f.name == key).firstOrNull;
}

List<Feature> _safeParseNavOrder(dynamic json) {
  if (json == null) return Feature.values.toList();
  if (json is! List) return Feature.values.toList();
  final parsed = json.map(_decodeFeature).whereType<Feature>().toList();
  return parsed.isEmpty ? Feature.values.toList() : parsed;
}

List<Feature> _safeParseEnabledFeatures(dynamic json) {
  if (json == null) return const [Feature.subscriptions, Feature.debts];
  if (json is! List) return const [Feature.subscriptions, Feature.debts];
  return json.map(_decodeFeature).whereType<Feature>().toList();
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
    @Default([Feature.subscriptions, Feature.debts])
    @JsonKey(fromJson: _safeParseEnabledFeatures)
    List<Feature> enabledFeatures,
    @Default(Feature.values)
    @JsonKey(fromJson: _safeParseNavOrder)
    List<Feature> navOrder,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}
