import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_dtos.freezed.dart';
part 'subscription_dtos.g.dart';

@freezed
class SubscriptionRequest with _$SubscriptionRequest {
  const factory SubscriptionRequest({
    required String nom,
    required double montant,
    required String frequence,
    required String dateDebut,
    required bool actif,
    String? categoryId,
    String? accountId,
  }) = _SubscriptionRequest;

  factory SubscriptionRequest.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionRequestFromJson(json);
}

@freezed
class SubscriptionResponse with _$SubscriptionResponse {
  const factory SubscriptionResponse({
    required String id,
    required String nom,
    required double montant,
    required String frequence,
    required String dateDebut,
    required String currency,
    required bool actif,
    String? categoryId,
    String? accountId,
    String? updatedAt,
  }) = _SubscriptionResponse;

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionResponseFromJson(json);
}
