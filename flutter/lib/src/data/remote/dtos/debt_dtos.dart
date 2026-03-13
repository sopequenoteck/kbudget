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
    String? accountId,
    String? currency,
    @Default(false) bool includeInBalance,
    String? reminderDate,
    String? reminderTime,
    String? dueDate,
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
    String? accountId,
    String? accountName,
    @Default(false) bool includeInBalance,
    String? dueDate,
    String? reminderDate,
    String? reminderTime,
    double? remainingAmount,
  }) = _DebtResponse;

  factory DebtResponse.fromJson(Map<String, dynamic> json) =>
      _$DebtResponseFromJson(json);
}

@freezed
class RepayRequest with _$RepayRequest {
  const factory RepayRequest({
    required String accountId,
    double? amount,
  }) = _RepayRequest;

  factory RepayRequest.fromJson(Map<String, dynamic> json) =>
      _$RepayRequestFromJson(json);
}

@freezed
class SnoozeRequest with _$SnoozeRequest {
  const factory SnoozeRequest({
    required String reminderDate,
    required String reminderTime,
  }) = _SnoozeRequest;

  factory SnoozeRequest.fromJson(Map<String, dynamic> json) =>
      _$SnoozeRequestFromJson(json);
}

@freezed
class PaymentResponse with _$PaymentResponse {
  const factory PaymentResponse({
    required String id,
    required double montant,
    required String date,
    String? accountName,
  }) = _PaymentResponse;

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);
}
