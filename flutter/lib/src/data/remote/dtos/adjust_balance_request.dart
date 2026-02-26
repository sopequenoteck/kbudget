import 'package:json_annotation/json_annotation.dart';

part 'adjust_balance_request.g.dart';

@JsonSerializable()
class AdjustBalanceRequest {
  final double newBalance;

  const AdjustBalanceRequest({required this.newBalance});

  factory AdjustBalanceRequest.fromJson(Map<String, dynamic> json) =>
      _$AdjustBalanceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdjustBalanceRequestToJson(this);
}
