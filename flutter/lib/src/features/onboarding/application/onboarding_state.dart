// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    DataMode? selectedMode,
    String? serverUrl,
    @Default(false) bool isCheckingServer,
    @Default(false) bool isServerReachable,
    @Default(false) bool isSaving,
    @Default(false) bool isCompleted,
    String? error,
  }) = _OnboardingState;
}
