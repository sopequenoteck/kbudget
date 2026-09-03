// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_account_request.freezed.dart';
part 'delete_account_request.g.dart';

@freezed
class DeleteAccountRequest with _$DeleteAccountRequest {
  const factory DeleteAccountRequest({
    required String currentPassword,
    required bool confirmed,
  }) = _DeleteAccountRequest;

  factory DeleteAccountRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountRequestFromJson(json);
}
