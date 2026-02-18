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
