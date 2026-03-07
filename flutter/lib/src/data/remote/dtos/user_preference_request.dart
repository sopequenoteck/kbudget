import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'user_preference_request.freezed.dart';
part 'user_preference_request.g.dart';

@freezed
class UserPreferenceRequest with _$UserPreferenceRequest {
  const factory UserPreferenceRequest({
    required List<Feature> enabledFeatures,
    List<Feature>? navOrder,
    String? shopAccountId,
    bool? includeShopInBalance,
    List<String>? currencies,
    List<NotificationType>? enabledNotificationTypes,
    String? timezone,
  }) = _UserPreferenceRequest;

  factory UserPreferenceRequest.fromJson(Map<String, dynamic> json) =>
      _$UserPreferenceRequestFromJson(json);
}
