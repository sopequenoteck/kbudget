import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dtos.freezed.dart';
part 'user_dtos.g.dart';

@freezed
class UserResponse with _$UserResponse {
  const factory UserResponse({
    String? name,
    required String email,
    @Default('EUR') String defaultCurrency,
    @Default(false) bool isAdmin,
  }) = _UserResponse;

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
}

@freezed
class UserUpdateRequest with _$UserUpdateRequest {
  const factory UserUpdateRequest({
    required String defaultCurrency,
  }) = _UserUpdateRequest;

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$UserUpdateRequestFromJson(json);
}
