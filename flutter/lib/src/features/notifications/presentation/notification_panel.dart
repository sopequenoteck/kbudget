import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/features/notifications/application/notification_notifier.dart';

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

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, state),
            const Divider(height: 1),
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildList(state, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ListState<NotificationModel> state) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        children: [
          Text(
            'Notifications',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (unreadCount > 0)
            IconButton(
              onPressed: () => ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
              icon: const PhosphorIcon(PhosphorIconsRegular.checks, size: 20),
              tooltip: 'Tout marquer lu',
            ),
          if (state.items.isNotEmpty)
            IconButton(
              onPressed: _onDeleteAll,
              icon: PhosphorIcon(
                PhosphorIconsRegular.trash,
                size: 20,
                color: theme.colorScheme.error,
              ),
              tooltip: "Vider l'historique",
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
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
            'Aucune notification',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ListState<NotificationModel> state, ThemeData theme) {
    final groups = _groupByDay(state.items);

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
              ...group.notifications.map((n) => _buildNotificationItem(n, theme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, ThemeData theme) {
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
        onTap: () {
          if (!notification.read) {
            ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
          }
        },
      ),
    );
  }

  void _onDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vider l'historique"),
        content: const Text('Supprimer toutes les notifications ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationNotifierProvider.notifier).deleteAll();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  List<_NotificationGroup> _groupByDay(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<NotificationModel>>{};

    for (final notification in notifications) {
      final local = notification.createdAt.toLocal();
      final date = DateTime(local.year, local.month, local.day);

      String label;
      if (date == today) {
        label = "Aujourd'hui";
      } else if (date == yesterday) {
        label = 'Hier';
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
