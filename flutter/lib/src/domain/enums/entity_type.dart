import 'package:json_annotation/json_annotation.dart';

enum EntityType {
  @JsonValue('SUBSCRIPTION')
  subscription,
  @JsonValue('DEBT')
  debt;
}
