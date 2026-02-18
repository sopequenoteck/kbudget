import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_dtos.freezed.dart';
part 'transaction_dtos.g.dart';

@freezed
class TransactionRequest with _$TransactionRequest {
  const factory TransactionRequest({
    required double montant,
    required String libelle,
    required String type,
    required String date,
    String? note,
    String? categoryId,
    String? accountId,
  }) = _TransactionRequest;

  factory TransactionRequest.fromJson(Map<String, dynamic> json) =>
      _$TransactionRequestFromJson(json);
}

@freezed
class TransactionResponse with _$TransactionResponse {
  const factory TransactionResponse({
    required String id,
    required double montant,
    required String libelle,
    required String type,
    required String date,
    String? note,
    String? transferId,
    String? categoryId,
    String? accountId,
    String? updatedAt,
  }) = _TransactionResponse;

  factory TransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionResponseFromJson(json);
}
