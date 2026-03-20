import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank.freezed.dart';
part 'bank.g.dart';

@freezed
class Bank with _$Bank {
  const factory Bank({
    required String code,
    required String name,
    String? country,
    required String brandColor,
    String? logoUrl,
  }) = _Bank;

  factory Bank.fromJson(Map<String, dynamic> json) => _$BankFromJson(json);
}
