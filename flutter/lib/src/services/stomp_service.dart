import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/services/local_notification_service.dart';

final stompServiceProvider = Provider<StompService>((ref) {
  final stompService = StompService();
  ref.onDispose(() => stompService.dispose());
  return stompService;
});

class StompService with WidgetsBindingObserver {
  StompClient? _client;
  final _notificationController = StreamController<NotificationModel>.broadcast();
  VoidCallback? _onReconnect;
  AppLifecycleState _appState = AppLifecycleState.resumed;
  LocalNotificationService? _localNotificationService;
  bool _observing = false;

  Stream<NotificationModel> get notifications => _notificationController.stream;

  void connect({
    required String token,
    required String baseUrl,
    VoidCallback? onReconnect,
    LocalNotificationService? localNotificationService,
  }) {
    _onReconnect = onReconnect;
    _localNotificationService = localNotificationService;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    disconnect();

    _client = StompClient(
      config: StompConfig(
        url: baseUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onConnect: _onConnect,
        onDisconnect: (_) {},
        onWebSocketError: (_) {},
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
  }

  void _onConnect(StompFrame frame) {
    _client?.subscribe(
      destination: '/user/queue/notifications',
      callback: (frame) {
        if (frame.body != null) {
          final notification = NotificationModel.fromJson(
            jsonDecode(frame.body!) as Map<String, dynamic>,
          );
          _notificationController.add(notification);

          if (_appState != AppLifecycleState.resumed) {
            _localNotificationService?.showNotification(
              id: notification.id,
              title: notification.title,
              body: notification.message,
            );
          }
        }
      },
    );
    _onReconnect?.call();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    disconnect();
    _notificationController.close();
  }
}
