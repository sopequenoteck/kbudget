// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/admin/data/admin_user_model.dart';

class AdminUserListItem extends StatelessWidget {
  final AdminUser user;
  final bool isMutating;
  final VoidCallback? onDisable;
  final VoidCallback? onEnable;

  const AdminUserListItem({
    super.key,
    required this.user,
    this.isMutating = false,
    this.onDisable,
    this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = user.disabledAt != null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDisabled
            ? AppColors.gray600
            : theme.colorScheme.primaryContainer,
        child: Text(
          user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : user.email[0].toUpperCase(),
          style: TextStyle(
            color: isDisabled
                ? AppColors.gray400
                : theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDisabled ? theme.colorScheme.onSurfaceVariant : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isAdmin) ...[
            const SizedBox(width: AppSpacing.space1),
            Tooltip(
              message: 'Admin',
              child: Icon(
                Icons.shield_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        user.email,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isMutating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isDisabled
              ? IconButton(
                  icon: const Icon(
                    Icons.lock_open_outlined,
                    size: 20,
                    color: AppColors.success,
                  ),
                  tooltip: 'Réactiver',
                  onPressed: onEnable,
                )
              : IconButton(
                  icon: Icon(
                    Icons.block_outlined,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Désactiver',
                  onPressed: onDisable,
                ),
    );
  }
}
