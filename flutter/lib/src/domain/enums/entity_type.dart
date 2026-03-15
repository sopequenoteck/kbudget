import 'package:json_annotation/json_annotation.dart';

enum EntityType {
  @JsonValue('SUBSCRIPTION')
  subscription,
  @JsonValue('DEBT')
  debt,
  @JsonValue('RECURRING_TRANSACTION')
  recurringTransaction,
  @JsonValue('BUDGET')
  budget,
  @JsonValue('TRANSACTION')
  transaction;
}
