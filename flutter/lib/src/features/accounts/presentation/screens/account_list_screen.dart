import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/empty_state_widget.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_list_skeleton.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_list_tile.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AccountListScreen extends ConsumerStatefulWidget {
  const AccountListScreen({super.key});

  @override
  ConsumerState<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends ConsumerState<AccountListScreen> {
  String? _confirmDeleteId;
  String? _deleteError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(accountNotifierProvider);
      if (state.items.isEmpty && !state.isLoading) {
        ref.read(accountNotifierProvider.notifier).loadItems();
      }
    });
  }

  void _requestDelete(String accountId) {
    setState(() {
      _confirmDeleteId = accountId;
      _deleteError = null;
    });
  }

  void _cancelDelete() {
    setState(() {
      _confirmDeleteId = null;
      _deleteError = null;
    });
  }

  Future<void> _confirmDelete() async {
    final id = _confirmDeleteId;
    if (id == null) return;
    try {
      await ref.read(accountNotifierProvider.notifier).delete(id);
      if (mounted) {
        setState(() {
          _confirmDeleteId = null;
          _deleteError = null;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _deleteError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(accountNotifierProvider.notifier).refresh();
          } on Exception {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.errorGeneric)),
              );
            }
          }
        },
        child: CustomScrollView(
          slivers: _buildContent(state, l10n),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    ListState<Account> state,
    AppLocalizations l10n,
  ) {
    // Loading
    if (state.isLoading && state.items.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: AccountListSkeleton(),
        ),
      ];
    }

    // Error
    if (state.error != null && state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: PhosphorIconsRegular.warning,
            message: l10n.accountErrorLoad,
            ctaLabel: l10n.accountsRetry,
            onCtaTap: () =>
                ref.read(accountNotifierProvider.notifier).refresh(),
          ),
        ),
      ];
    }

    // Empty
    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: PhosphorIconsRegular.bank,
            message: l10n.accountsEmpty,
            ctaLabel: 'Créer un compte',
            onCtaTap: () => context.push(
              '${RouteNames.settings}/${RouteNames.settingsAccounts}/${RouteNames.settingsAccountsNew}',
            ),
          ),
        ),
      ];
    }

    // Data
    final items = state.items;
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Section header
              Row(
                children: [
                  Text(
                    '${items.length} comptes'.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppTypography.sizeXs,
                      fontWeight: AppTypography.semiBold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: AppTypography.labelLetterSpacingForSize12,
                    ),
                  ),
                  const Spacer(),
                  _AddButton(
                    onTap: () => context.push(
                      '${RouteNames.settings}/${RouteNames.settingsAccounts}/${RouteNames.settingsAccountsNew}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              // Carte surface avec items
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(items.length, (i) {
                    final account = items[i];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AccountListTile(
                          account: account,
                          onTap: () => context.push(
                            '${RouteNames.settings}/${RouteNames.settingsAccounts}/${account.id}',
                            extra: account,
                          ),
                          onSetDefault: () => _onSetDefault(account),
                          onEdit: () => context.push(
                            '${RouteNames.settings}/${RouteNames.settingsAccounts}/${account.id}',
                            extra: account,
                          ),
                          isConfirmingDelete: _confirmDeleteId == account.id,
                          deleteError: _confirmDeleteId == account.id
                              ? _deleteError
                              : null,
                          onRequestDelete: () => _requestDelete(account.id),
                          onConfirmDelete: _confirmDelete,
                          onCancelDelete: _cancelDelete,
                        ),
                        if (i < items.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colorScheme.outlineVariant,
                          ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.space12 * 2),
            ],
          ),
        ),
      ),
    ];
  }

  void _onSetDefault(Account account) {
    ref.read(accountNotifierProvider.notifier).setDefault(account.id);
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppSpacing.space7,
      height: AppSpacing.space7,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: PhosphorIcon(
          PhosphorIconsRegular.plus,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
