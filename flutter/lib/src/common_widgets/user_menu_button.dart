// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/routing/route_names.dart';

class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState is AuthAuthenticated;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            context.push(RouteNames.settings);
          case 'logout':
            ref.read(authNotifierProvider.notifier).logout();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              PhosphorIcon(PhosphorIconsRegular.gear, size: 20),
              SizedBox(width: 12),
              Text('Paramètres'),
            ],
          ),
        ),
        if (isAuthenticated) ...[
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.signOut, size: 20),
                SizedBox(width: 12),
                Text('Déconnexion'),
              ],
            ),
          ),
        ],
      ],
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: PhosphorIcon(
          PhosphorIconsRegular.user,
          size: 18,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
