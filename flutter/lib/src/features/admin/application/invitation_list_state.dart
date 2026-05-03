import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/features/admin/data/invitation_model.dart';

part 'invitation_list_state.freezed.dart';

@freezed
class InvitationListState with _$InvitationListState {
  const factory InvitationListState({
    @Default([]) List<Invitation> items,
    @Default(false) bool isLoading,
    String? error,
    @Default({}) Set<int> mutatingIds,
  }) = _InvitationListState;
}
