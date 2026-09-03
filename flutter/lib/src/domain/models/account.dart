// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
    @Default(0) double solde,
    DateTime? updatedAt,
    @Default('OTHER') String bankCode,
    String? bankName,
    String? bankCountry,
    String? bankBrandColor,
    String? bankLogoUrl,
    String? bankCustomName,
    String? bankCustomLogo,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
