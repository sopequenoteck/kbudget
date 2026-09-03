// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'avatar_metadata.freezed.dart';
part 'avatar_metadata.g.dart';

@freezed
class AvatarMetadata with _$AvatarMetadata {
  const factory AvatarMetadata({
    required String url,
    required String etag,
    required DateTime uploadedAt,
  }) = _AvatarMetadata;

  factory AvatarMetadata.fromJson(Map<String, dynamic> json) =>
      _$AvatarMetadataFromJson(json);
}
