// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/modal_type.dart';

part 'modal_state.freezed.dart';

@freezed
sealed class ModalState with _$ModalState {
  const factory ModalState.closed() = ModalClosed;
  const factory ModalState.open({
    required ModalType type,
    required ModalMode mode,
    Object? entity,
    dynamic subType,
  }) = ModalOpen;
}
