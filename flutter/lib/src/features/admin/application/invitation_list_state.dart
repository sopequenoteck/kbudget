// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
