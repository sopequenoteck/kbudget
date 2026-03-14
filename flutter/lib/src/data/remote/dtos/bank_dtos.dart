import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_dtos.freezed.dart';
part 'bank_dtos.g.dart';

@freezed
class BankResponse with _$BankResponse {
  const factory BankResponse({
    required String code,
    required String name,
    String? country,
    required String brandColor,
    String? logoUrl,
  }) = _BankResponse;

  factory BankResponse.fromJson(Map<String, dynamic> json) =>
      _$BankResponseFromJson(json);
}
