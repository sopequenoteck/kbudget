// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/repay_bottom_sheet.dart';
import 'package:k_budget/src/features/debts/presentation/widgets/snooze_dialog.dart';
import 'package:k_budget/src/features/notifications/application/notification_notifier.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

class NotificationPanel extends ConsumerStatefulWidget {
  const NotificationPanel({super.key});

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationNotifierProvider.notifier).loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, state, l10n),
            const Divider(height: 1),
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                      ? _buildEmptyState(theme, l10n)
                      : _buildList(state, theme, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ListState<NotificationModel> state, AppLocalizations l10n) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        children: [
          Text(
            l10n.notificationTitle,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (unreadCount > 0)
            IconButton(
              onPressed: () => ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
              icon: const PhosphorIcon(PhosphorIconsRegular.checks, size: 20),
              tooltip: l10n.notificationMarkAllRead,
            ),
          if (state.items.isNotEmpty)
            IconButton(
              onPressed: () => _onDeleteAll(l10n),
              icon: PhosphorIcon(
                PhosphorIconsRegular.trash,
                size: 20,
                color: theme.colorScheme.error,
              ),
              tooltip: l10n.notificationClearHistory,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.bellRinging,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            l10n.notificationEmpty,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ListState<NotificationModel> state, ThemeData theme, AppLocalizations l10n) {
    final groups = _groupByDay(state.items, l10n);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 100) {
          ref.read(notificationNotifierProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space1,
                ),
                child: Text(
                  group.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...group.notifications.map((n) => _buildNotificationItem(n, theme, l10n)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, ThemeData theme, AppLocalizations l10n) {
    final isDebtNotification = notification.type == NotificationType.debtDue ||
        notification.type == NotificationType.debtReminder;
    final isRecurringNotification =
        notification.type == NotificationType.recurringTransactionDue;
    final isSubscriptionNotification =
        notification.type == NotificationType.subscriptionDue;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space4),
        color: theme.colorScheme.error,
        child: const PhosphorIcon(PhosphorIconsRegular.trash, color: Colors.white, size: 20),
      ),
      onDismissed: (_) {
        ref.read(notificationNotifierProvider.notifier).delete(notification.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: notification.read
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          child: PhosphorIcon(
            notification.type.icon,
            size: 20,
            color: notification.read
                ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat.Hm('fr_FR').format(notification.createdAt.toLocal()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        onTap: () => _onNotificationTap(notification),
        trailing: isDebtNotification && notification.entityId != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _onRepayAction(notification, l10n),
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.currencyCircleDollar,
                      size: 18,
                    ),
                    tooltip: l10n.notificationRepayTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  IconButton(
                    onPressed: () => _onSnoozeAction(notification, l10n),
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.bellSlash,
                      size: 18,
                    ),
                    tooltip: l10n.notificationSnoozeTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              )
            : isRecurringNotification && notification.entityId != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _onValidateRecurringAction(notification),
                        icon: const PhosphorIcon(
                          PhosphorIconsRegular.check,
                          size: 18,
                          color: AppColors.success,
                        ),
                        tooltip: 'Valider',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      IconButton(
                        onPressed: () => _onSkipRecurringAction(notification),
                        icon: const PhosphorIcon(
                          PhosphorIconsRegular.skipForward,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        tooltip: 'Passer',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  )
                : isSubscriptionNotification && notification.entityId != null
                    ? IconButton(
                        onPressed: () => _onPaySubscriptionAction(notification),
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.currencyEur,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: 'Payer',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      )
                    : null,
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) {
    if (!notification.read) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }

    if ((notification.type == NotificationType.debtDue ||
            notification.type == NotificationType.debtReminder) &&
        notification.entityId != null) {
      Navigator.of(context).pop();
      context.push('/debts/${notification.entityId}');
    } else if (notification.type == NotificationType.recurringTransactionDue) {
      Navigator.of(context).pop();
      context.push('/transactions/recurring');
    } else if (notification.type == NotificationType.subscriptionDue &&
        notification.entityId != null) {
      Navigator.of(context).pop();
      context.push('/subscriptions/${notification.entityId}');
    } else if (notification.type == NotificationType.budgetThreshold ||
        notification.type == NotificationType.budgetExceeded) {
      Navigator.of(context).pop();
      context.push('/budgets');
    }
  }

  Future<void> _onRepayAction(NotificationModel notification, AppLocalizations l10n) async {
    if (notification.entityId == null) return;
    if (!notification.read) {
      await ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }
    try {
      final repo = ref.read(debtRepositoryProvider);
      final debt = await repo.getById(notification.entityId!);
      if (!mounted) return;
      Navigator.of(context).pop();
      RepayBottomSheet.show(context: context, debt: debt);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationLoadError)),
      );
    }
  }

  Future<void> _onSnoozeAction(NotificationModel notification, AppLocalizations l10n) async {
    if (notification.entityId == null) return;
    if (!notification.read) {
      await ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }

    try {
      final repo = ref.read(debtRepositoryProvider);
      final debt = await repo.getById(notification.entityId!);
      if (!mounted) return;
      Navigator.of(context).pop();
      SnoozeDialog.show(
        context: context,
        debt: debt,
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationLoadError)),
      );
    }
  }

  Future<void> _onValidateRecurringAction(NotificationModel notification) async {
    if (notification.entityId == null) return;
    if (!notification.read) {
      await ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }
    await ref.read(recurringListNotifierProvider.notifier).validate(notification.entityId!);
  }

  Future<void> _onSkipRecurringAction(NotificationModel notification) async {
    if (notification.entityId == null) return;
    if (!notification.read) {
      await ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }
    await ref.read(recurringListNotifierProvider.notifier).skip(notification.entityId!);
  }

  Future<void> _onPaySubscriptionAction(NotificationModel notification) async {
    if (notification.entityId == null) return;
    if (!notification.read) {
      await ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }
    await ref.read(subscriptionNotifierProvider.notifier).pay(notification.entityId!);
  }

  void _onDeleteAll(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationClearConfirmTitle),
        content: Text(l10n.notificationClearConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationNotifierProvider.notifier).deleteAll();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  List<_NotificationGroup> _groupByDay(List<NotificationModel> notifications, AppLocalizations l10n) {
    final sorted = [...notifications]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<NotificationModel>>{};

    for (final notification in sorted) {
      final local = notification.createdAt.toLocal();
      final date = DateTime(local.year, local.month, local.day);

      String label;
      if (date == today) {
        label = l10n.notificationGroupToday;
      } else if (date == yesterday) {
        label = l10n.notificationGroupYesterday;
      } else {
        label = DateFormat.yMMMMd('fr_FR').format(local);
      }

      (map[label] ??= []).add(notification);
    }

    return map.entries
        .map((e) => _NotificationGroup(label: e.key, notifications: List.unmodifiable(e.value)))
        .toList();
  }
}

class _NotificationGroup {
  final String label;
  final List<NotificationModel> notifications;

  _NotificationGroup({required this.label, required this.notifications});
}
