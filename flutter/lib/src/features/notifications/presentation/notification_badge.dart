// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/features/notifications/application/notification_notifier.dart';

class NotificationBadge extends ConsumerWidget {
  final VoidCallback? onTap;

  const NotificationBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    final theme = Theme.of(context);

    return IconButton(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          '$unreadCount',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        child: PhosphorIcon(
          PhosphorIconsRegular.bell,
          size: 22,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
