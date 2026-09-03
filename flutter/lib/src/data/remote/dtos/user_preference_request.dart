// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'user_preference_request.freezed.dart';
part 'user_preference_request.g.dart';

@freezed
class UserPreferenceRequest with _$UserPreferenceRequest {
  const factory UserPreferenceRequest({
    required List<Feature> enabledFeatures,
    List<Feature>? navOrder,
    List<String>? currencies,
    List<NotificationType>? enabledNotificationTypes,
    String? timezone,
    String? textScale,
  }) = _UserPreferenceRequest;

  factory UserPreferenceRequest.fromJson(Map<String, dynamic> json) =>
      _$UserPreferenceRequestFromJson(json);
}
