import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'k_budget_notifications',
      'Notifications',
      channelDescription: 'Notifications K-Budget',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: id.hashCode & 0x7FFFFFFF,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
