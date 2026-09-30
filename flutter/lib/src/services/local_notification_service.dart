// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService(
    readL10n: () => ref.read(appLocalizationsProvider),
  );
});

class LocalNotificationService {
  /// Cree le service ; [readL10n] est lu a chaque notification, pour
  /// nommer le canal Android dans la langue affichee a ce moment.
  LocalNotificationService({required this.readL10n});

  /// Traductions de la langue affichee, lues a l'appel.
  final AppLocalizations Function() readL10n;
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

    // Demander explicitement les permissions iOS
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    await _plugin.show(
      id: id.hashCode & 0x7FFFFFFF,
      title: title,
      body: body,
      notificationDetails: notificationDetails(),
      payload: payload,
    );
  }

  /// Details d'affichage : canal Android nomme et decrit depuis les ARB,
  /// identifiant `k_budget_notifications` inchange.
  @visibleForTesting
  NotificationDetails notificationDetails() {
    final l10n = readL10n();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'k_budget_notifications',
        l10n.notificationsPageTitle,
        channelDescription: l10n.notificationsPageChannelDescription,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }
}
