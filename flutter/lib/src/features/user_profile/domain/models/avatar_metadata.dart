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
