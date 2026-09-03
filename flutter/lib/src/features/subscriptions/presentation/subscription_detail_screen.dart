// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/modal/application/modal_notifier.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/features/subscriptions/presentation/widgets/payment_history_section.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  final String subscriptionId;
  final Subscription? initialSubscription;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
    this.initialSubscription,
  });

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  Subscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscription = widget.initialSubscription;
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    try {
      final cached = ref
          .read(subscriptionNotifierProvider.notifier)
          .getSubscriptionById(widget.subscriptionId);
      if (cached != null) {
        setState(() {
          _subscription = cached;
          _isLoading = false;
        });
      } else {
        final repo = ref.read(subscriptionRepositoryProvider);
        final sub = await repo.getById(widget.subscriptionId);
        if (mounted) {
          setState(() {
            _subscription = sub;
            _isLoading = false;
          });
        }
      }
    } on Exception {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pay() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(subscriptionNotifierProvider.notifier)
          .pay(widget.subscriptionId);
      // Invalider les providers de paiements pour forcer le rechargement
      ref.invalidate(subscriptionPaymentsProvider(widget.subscriptionId));
      ref.invalidate(subscriptionTotalPaidProvider(widget.subscriptionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscriptionPaySuccess)),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Écouter les changements du notifier pour mettre à jour l'écran
    ref.watch(subscriptionNotifierProvider);
    final updated = ref
        .read(subscriptionNotifierProvider.notifier)
        .getSubscriptionById(widget.subscriptionId);
    if (updated != null && updated != _subscription) {
      _subscription = updated;
    }

    final isServerMode = ref.watch(dataModeProvider).whenOrNull(
          data: (mode) => mode == DataMode.server,
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_subscription?.nom ?? ''),
        actions: [
          if (_subscription != null)
            IconButton(
              onPressed: () {
                ref.read(modalNotifierProvider.notifier).open(
                      ModalType.subscription,
                      entity: _subscription,
                    );
              },
              icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple,
                  size: 20),
              tooltip: l10n.edit,
            ),
        ],
      ),
      body: _isLoading && _subscription == null
          ? _buildSkeleton(colorScheme)
          : _subscription == null
              ? Center(child: Text(l10n.errorGeneric))
              : _buildContent(
                  context, _subscription!, colorScheme, l10n, isServerMode),
      floatingActionButton: _subscription != null && isServerMode
          ? FloatingActionButton.extended(
              onPressed: _pay,
              icon: const PhosphorIcon(
                  PhosphorIconsRegular.currencyCircleDollar,
                  size: 20),
              label: Text(l10n.subscriptionPay),
            )
          : null,
    );
  }

  Widget _buildContent(
    BuildContext context,
    Subscription sub,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    bool isServerMode,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        top: AppSpacing.space4,
        bottom: AppSpacing.space12 * 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge statut
          _StatusBadge(subscription: sub, colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.space4),

          // Section infos
          _InfoSection(subscription: sub, colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.space4),

          // Historique des paiements (server-only)
          if (isServerMode)
            PaymentHistorySection(
              subscriptionId: widget.subscriptionId,
              currency: sub.currency,
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme colorScheme) {
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Subscription subscription;
  final ColorScheme colorScheme;

  const _StatusBadge({
    required this.subscription,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final themeExt = Theme.of(context).extension<AppThemeExtension>();
    final color = subscription.actif
        ? (themeExt?.incomeColor ?? Colors.green)
        : colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context)!;
    final label = subscription.actif ? l10n.subscriptionFormActiveSwitch : l10n.subscriptionBadgeInactif;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          fontWeight: AppTypography.semiBold,
          color: color,
        ),
      ),
    );
  }
}

class _InfoSection extends ConsumerWidget {
  final Subscription subscription;
  final ColorScheme colorScheme;

  const _InfoSection({
    required this.subscription,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');
    final categories = ref.watch(categoryNotifierProvider).items;
    final accounts = ref.watch(accountNotifierProvider).items;

    final category = subscription.categoryId != null
        ? categories.where((c) => c.id == subscription.categoryId).firstOrNull
        : null;
    final account = subscription.accountId != null
        ? accounts.where((a) => a.id == subscription.accountId).firstOrNull
        : null;

    final frequencySuffix = switch (subscription.frequence) {
      Frequency.hebdomadaire => '/sem.',
      Frequency.mensuel => '/mois',
      Frequency.annuel => '/an',
    };

    final formattedAmount = AmountFormatter.format(
      subscription.montant,
      currency: subscription.currency,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: PhosphorIconsRegular.currencyEur,
            label: 'Montant',
            value: '$formattedAmount$frequencySuffix',
            colorScheme: colorScheme,
          ),
          _InfoRow(
            icon: PhosphorIconsRegular.calendarBlank,
            label: 'Date de début',
            value: dateFormat.format(subscription.dateDebut),
            colorScheme: colorScheme,
          ),
          if (category != null)
            _InfoRow(
              icon: PhosphorIconsRegular.tag,
              label: 'Catégorie',
              value: '${category.icone} ${category.nom}',
              valueColor: parseHexColor(category.couleur),
              colorScheme: colorScheme,
            ),
          if (account != null)
            _InfoRow(
              icon: PhosphorIconsRegular.bank,
              label: 'Compte',
              value: account.nom,
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.space3),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.medium,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
