import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_dtos.freezed.dart';
part 'transfer_dtos.g.dart';

@freezed
class TransferRequest with _$TransferRequest {
  const factory TransferRequest({
    required String fromAccountId,
    required String toAccountId,
    required double montant,
    String? note,
  }) = _TransferRequest;

  factory TransferRequest.fromJson(Map<String, dynamic> json) =>
      _$TransferRequestFromJson(json);
}

@freezed
class TransferResponse with _$TransferResponse {
  const factory TransferResponse({
    required String transferId,
    required TransactionRef debitTransaction,
    required TransactionRef creditTransaction,
  }) = _TransferResponse;

  factory TransferResponse.fromJson(Map<String, dynamic> json) =>
      _$TransferResponseFromJson(json);
}

@freezed
class TransactionRef with _$TransactionRef {
  const factory TransactionRef({
    required String id,
    required double montant,
    required String libelle,
    required String type,
    required String date,
    required String accountId,
    required String accountNom,
  }) = _TransactionRef;

  factory TransactionRef.fromJson(Map<String, dynamic> json) =>
      _$TransactionRefFromJson(json);
}
