import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'user_preference_response.freezed.dart';
part 'user_preference_response.g.dart';

@freezed
class UserPreferenceResponse with _$UserPreferenceResponse {
  const factory UserPreferenceResponse({
    required List<Feature> enabledFeatures,
    required List<Feature> navOrder,
    @Default(['EUR']) List<String> currencies,
    @Default([]) List<NotificationType> enabledNotificationTypes,
    @Default('Europe/Paris') String timezone,
    String? textScale,
  }) = _UserPreferenceResponse;

  factory UserPreferenceResponse.fromJson(Map<String, dynamic> json) =>
      _$UserPreferenceResponseFromJson(json);
}
