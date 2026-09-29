// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:json_annotation/json_annotation.dart';

part 'adjust_balance_request.g.dart';

@JsonSerializable()
class AdjustBalanceRequest {
  /// Ajustement du solde a [newBalance], libelle de la transaction creee
  /// par [libelle].
  const AdjustBalanceRequest({required this.newBalance, this.libelle});

  /// Lecture depuis le JSON de l'API.
  factory AdjustBalanceRequest.fromJson(Map<String, dynamic> json) =>
      _$AdjustBalanceRequestFromJson(json);

  /// Nouveau solde du compte.
  final double newBalance;

  /// Libelle de la transaction d'ajustement ; sans lui, l'API ecrit un
  /// defaut anglais (KKS-423).
  final String? libelle;

  /// Corps JSON envoye a l'API.
  Map<String, dynamic> toJson() => _$AdjustBalanceRequestToJson(this);
}
