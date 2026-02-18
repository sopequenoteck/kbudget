import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required String nom,
    required AccountType type,
    required double soldeInitial,
    required String icone,
    required String couleur,
    @Default(false) bool isDefault,
    @Default(Currency.eur) Currency currency,
    @Default(true) bool actif,
    DateTime? updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
