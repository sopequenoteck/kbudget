import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/features/admin/data/admin_user_model.dart';

part 'admin_users_list_state.freezed.dart';

@freezed
class AdminUsersListState with _$AdminUsersListState {
  const factory AdminUsersListState({
    @Default([]) List<AdminUser> items,
    @Default(false) bool isLoading,
    String? error,
    @Default({}) Set<String> mutatingIds,
  }) = _AdminUsersListState;
}
