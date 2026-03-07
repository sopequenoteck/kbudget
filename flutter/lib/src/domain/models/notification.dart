import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required NotificationType type,
    required String title,
    required String message,
    EntityType? entityType,
    String? entityId,
    @Default(false) bool read,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
