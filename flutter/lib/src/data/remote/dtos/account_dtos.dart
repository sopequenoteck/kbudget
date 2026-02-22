import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_dtos.freezed.dart';
part 'account_dtos.g.dart';

@freezed
class AccountRequest with _$AccountRequest {
  const factory AccountRequest({
    required String nom,
    required String type,
    required double soldeInitial,
    required String icone,
    required String couleur,
    required bool isDefault,
    required String currency,
    required bool actif,
  }) = _AccountRequest;

  factory AccountRequest.fromJson(Map<String, dynamic> json) =>
      _$AccountRequestFromJson(json);
}

@freezed
class AccountResponse with _$AccountResponse {
  const factory AccountResponse({
    required String id,
    required String nom,
    required String type,
    required double soldeInitial,
    required String icone,
    required String couleur,
    required bool isDefault,
    required String currency,
    required bool actif,
    @Default(0) double solde,
    String? updatedAt,
  }) = _AccountResponse;

  factory AccountResponse.fromJson(Map<String, dynamic> json) =>
      _$AccountResponseFromJson(json);
}
