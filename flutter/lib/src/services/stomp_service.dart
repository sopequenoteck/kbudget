// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/services/local_notification_service.dart';
import 'package:k_budget/src/utils/notification_text.dart';

final stompServiceProvider = Provider<StompService>((ref) {
  final stompService = StompService(
    readL10n: () => ref.read(appLocalizationsProvider),
    readIntlLocale: () => ref.read(intlLocaleProvider),
  );
  ref.onDispose(() => stompService.dispose());
  return stompService;
});

class StompService with WidgetsBindingObserver {
  /// Cree le service ; [readL10n] et [readIntlLocale] sont lus a l'arrivee
  /// de chaque notification, pour l'afficher dans la langue de ce moment.
  /// [localNotificationService] est remplace par celui passe a [connect].
  StompService({
    required this.readL10n,
    required this.readIntlLocale,
    LocalNotificationService? localNotificationService,
  }) : _localNotificationService = localNotificationService;

  /// Traductions de la langue affichee, lues a l'appel.
  final AppLocalizations Function() readL10n;

  /// Locale `intl` de la langue affichee, lue a l'appel.
  final String Function() readIntlLocale;

  StompClient? _client;
  final _notificationController = StreamController<NotificationModel>.broadcast();
  final _exchangeRatesUpdatedController = StreamController<void>.broadcast();
  VoidCallback? _onReconnect;
  AppLifecycleState _appState = AppLifecycleState.resumed;
  LocalNotificationService? _localNotificationService;
  bool _observing = false;

  Stream<NotificationModel> get notifications => _notificationController.stream;
  Stream<void> get exchangeRatesUpdated => _exchangeRatesUpdatedController.stream;

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
      callback: handleNotificationFrame,
    );
    _client?.subscribe(
      destination: '/user/queue/exchange-rates',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          if (data['type'] == 'EXCHANGE_RATES_UPDATED') {
            _exchangeRatesUpdatedController.add(null);
          }
        }
      },
    );
    _onReconnect?.call();
  }

  /// Publie la notification portee par [frame] et, hors premier plan,
  /// l'affiche dans le systeme avec son texte traduit.
  @visibleForTesting
  void handleNotificationFrame(StompFrame frame) {
    final body = frame.body;
    if (body == null) {
      return;
    }
    final notification = NotificationModel.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
    _notificationController.add(notification);

    if (_appState != AppLifecycleState.resumed) {
      final text =
          buildNotificationText(notification, readL10n(), readIntlLocale());
      unawaited(
        _localNotificationService?.showNotification(
          id: notification.id,
          title: text.title,
          body: text.message,
        ),
      );
    }
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
    _exchangeRatesUpdatedController.close();
  }
}
