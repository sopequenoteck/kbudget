import 'package:freezed_annotation/freezed_annotation.dart';

part 'invitation_model.freezed.dart';
part 'invitation_model.g.dart';

enum InvitationStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('USED')
  used,
  @JsonValue('REVOKED')
  revoked,
}

@freezed
class Invitation with _$Invitation {
  const factory Invitation({
    required int id,
    required String email,
    required String invitedByEmail,
    required InvitationStatus status,
    String? token,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
    DateTime? revokedAt,
  }) = _Invitation;

  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);
}

@freezed
class InvitationCreated with _$InvitationCreated {
  const factory InvitationCreated({
    required String token,
    required DateTime expiresAt,
  }) = _InvitationCreated;

  factory InvitationCreated.fromJson(Map<String, dynamic> json) =>
      _$InvitationCreatedFromJson(json);
}
