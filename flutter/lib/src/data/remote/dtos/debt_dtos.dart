import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt_dtos.freezed.dart';
part 'debt_dtos.g.dart';

@freezed
class DebtRequest with _$DebtRequest {
  const factory DebtRequest({
    required String personne,
    required double montant,
    required String sens,
    required String date,
    required bool rembourse,
    String? categoryId,
  }) = _DebtRequest;

  factory DebtRequest.fromJson(Map<String, dynamic> json) =>
      _$DebtRequestFromJson(json);
}

@freezed
class DebtResponse with _$DebtResponse {
  const factory DebtResponse({
    required String id,
    required String personne,
    required double montant,
    required String sens,
    required String date,
    required String currency,
    required bool rembourse,
    String? categoryId,
    String? updatedAt,
  }) = _DebtResponse;

  factory DebtResponse.fromJson(Map<String, dynamic> json) =>
      _$DebtResponseFromJson(json);
}
