// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// `@JsonKey` sur un parametre de factory Freezed est le seul moyen de
// tolerer une valeur d'enum inconnue (KKS-425). analysis_options.yaml ignore
// deja ce diagnostic ; l'analyse Sonar rejoue l'analyseur sans ce fichier.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    required NotificationType? type,
    required String title,
    required String message,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    EntityType? entityType,
    String? entityId,
    @Default(false) bool read,
    DateTime? readAt,
    required DateTime createdAt,
    Map<String, String>? params,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
