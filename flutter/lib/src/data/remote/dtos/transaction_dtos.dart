// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
    @JsonKey(name: 'category', fromJson: _extractNestedId)
    String? categoryId,
    @JsonKey(name: 'account', fromJson: _extractNestedId)
    String? accountId,
    String? updatedAt,
  }) = _TransactionResponse;

  factory TransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionResponseFromJson(json);
}

/// Extrait l'ID d'un objet imbrique (ex: {"id": "uuid", "nom": "..."})
/// ou retourne la valeur directement si c'est deja une string.
String? _extractNestedId(dynamic json) {
  if (json is Map<String, dynamic>) return json['id']?.toString();
  if (json is String) return json;
  return null;
}

@freezed
class MonthlySummaryResponse with _$MonthlySummaryResponse {
  const factory MonthlySummaryResponse({
    required int month,
    required int year,
    required double totalRecettes,
    required double totalDepenses,
    @JsonKey(name: 'solde') required double bilan,
    required String currency,
  }) = _MonthlySummaryResponse;

  factory MonthlySummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryResponseFromJson(json);
}
