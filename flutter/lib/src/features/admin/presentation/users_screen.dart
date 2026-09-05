// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/admin/application/admin_users_list_state.dart';
import 'package:k_budget/src/features/admin/application/admin_users_notifier.dart';
import 'package:k_budget/src/features/admin/application/invitation_list_state.dart';
import 'package:k_budget/src/features/admin/application/invitations_notifier.dart';
import 'package:k_budget/src/features/admin/data/admin_remote_repository.dart';
import 'package:k_budget/src/features/admin/presentation/invite_dialog.dart';
import 'package:k_budget/src/features/admin/presentation/widgets/admin_user_list_item.dart';
import 'package:k_budget/src/features/admin/presentation/widgets/invitation_list_item.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Attendre que les providers soient prêts
    await ref.read(adminRepositoryProvider.future);
    if (!mounted) return;
    await Future.wait([
      ref.read(invitationsNotifierProvider.notifier).loadItems(),
      ref.read(adminUsersNotifierProvider.notifier).loadItems(),
    ]);
  }

  Future<String> _buildInviteLink(String token) async {
    final configRepo = ref.read(appConfigRepositoryProvider);
    final serverUrl = await configRepo.getServerUrl();
    final baseUrl = serverUrl ?? 'http://localhost:8080/api';
    final frontendBase = baseUrl.replaceFirst(RegExp(r'/api$'), '');
    return '$frontendBase/accept-invite/$token';
  }

  Future<void> _copyLink(String token) async {
    final link = await _buildInviteLink(token);
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien copié dans le presse-papier')),
      );
    }
  }

  void _showInviteDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return _InviteDialogSheet(
          onInvited: (token) async {
            final link = await _buildInviteLink(token);
            await Clipboard.setData(ClipboardData(text: link));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Invitation créée — lien copié automatiquement')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _disableUser(String id) async {
    try {
      await ref.read(adminUsersNotifierProvider.notifier).disable(id);
    } on DioException catch (e) {
      if (!mounted) return;
      final errorCode = e.response?.data?['error'] as String?;
      if (e.response?.statusCode == 409 &&
          errorCode == 'LAST_ADMIN_CANNOT_BE_DISABLED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Impossible de désactiver le dernier administrateur actif.'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la désactivation')),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la désactivation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(invitationsNotifierProvider);
    final usersState = ref.watch(adminUsersNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Invitations'),
            Tab(text: 'Comptes'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Inviter un utilisateur',
            onPressed: _showInviteDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Invitations
          _buildInvitationsTab(invState),
          // Onglet Utilisateurs
          _buildUsersTab(usersState),
        ],
      ),
    );
  }

  Widget _buildInvitationsTab(InvitationListState invState) {
    if (invState.isLoading && invState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (invState.error != null && invState.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            invState.error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (invState.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, size: 48),
            SizedBox(height: AppSpacing.space2),
            Text('Aucune invitation'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(invitationsNotifierProvider.notifier).loadItems(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        itemCount: invState.items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final invitation = invState.items[index];
          final isMutating = invState.mutatingIds.contains(invitation.id);
          return InvitationListItem(
            invitation: invitation,
            isMutating: isMutating,
            onCopyLink: invitation.token != null
                ? () => _copyLink(invitation.token!)
                : null,
            onRevoke: () =>
                ref.read(invitationsNotifierProvider.notifier).revoke(invitation.id),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab(AdminUsersListState usersState) {
    if (usersState.isLoading && usersState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (usersState.error != null && usersState.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            usersState.error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (usersState.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 48),
            SizedBox(height: AppSpacing.space2),
            Text('Aucun utilisateur'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminUsersNotifierProvider.notifier).loadItems(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        itemCount: usersState.items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = usersState.items[index];
          final isMutating = usersState.mutatingIds.contains(user.id);
          return AdminUserListItem(
            user: user,
            isMutating: isMutating,
            onDisable: () => _disableUser(user.id),
            onEnable: () =>
                ref.read(adminUsersNotifierProvider.notifier).enable(user.id),
          );
        },
      ),
    );
  }
}

// Widget interne pour le dialogue d'invitation
class _InviteDialogSheet extends ConsumerWidget {
  final void Function(String token) onInvited;

  const _InviteDialogSheet({required this.onInvited});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(invitationsNotifierProvider);
    final isLoading = invState.isLoading;

    return InviteDialog(
      isLoading: isLoading,
      onSubmit: (email) async {
        try {
          final created = await ref
              .read(invitationsNotifierProvider.notifier)
              .createInvitation(email);
          if (context.mounted) {
            Navigator.of(context).pop();
            onInvited(created.token);
          }
        } on Exception {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Erreur lors de la création de l\'invitation')),
            );
          }
        }
      },
    );
  }
}
