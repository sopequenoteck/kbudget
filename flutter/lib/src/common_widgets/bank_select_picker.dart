import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:k_budget/src/constants/app_durations.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/bank.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BankSelectPicker extends ConsumerWidget {
  const BankSelectPicker({
    super.key,
    required this.selectedBankCode,
    required this.onChanged,
    required this.banks,
  });

  final String? selectedBankCode;
  final ValueChanged<String> onChanged;
  final AsyncValue<List<Bank>> banks;

  void _openModal(BuildContext context) {
    final searchNotifier = ValueNotifier<String>('');
    AppModal.show(
      context,
      title: 'Sélectionner une banque',
      headerActions: _SearchField(notifier: searchNotifier),
      child: _BankList(
        searchNotifier: searchNotifier,
        banks: banks,
        selectedBankCode: selectedBankCode,
        onChanged: (code) {
          onChanged(code);
          Navigator.of(context).pop();
        },
      ),
      onClose: () {
        searchNotifier.value = '';
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final selectedBank = banks.whenOrNull(
      data: (list) => list.where((b) => b.code == selectedBankCode).firstOrNull,
    );

    final hasSelection = selectedBankCode != null && selectedBankCode!.isNotEmpty;
    final isOther = selectedBankCode == 'OTHER';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Banque',
          style: TextStyle(
            fontSize: AppTypography.sizeSm,
            fontWeight: AppTypography.medium,
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.space2),
        GestureDetector(
          onTap: () => _openModal(context),
          child: AnimatedContainer(
            duration: AppDurations.normal,
            curve: AppDurations.easeInOut,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.space3,
              horizontal: AppSpacing.space4,
            ),
            child: Row(
              children: [
                if (hasSelection && !isOther && selectedBank != null) ...[
                  SvgPicture.asset(
                    'assets/banks/${selectedBankCode!.toLowerCase()}.svg',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      selectedBank.name,
                      style: TextStyle(
                        fontSize: AppTypography.sizeMd,
                        fontWeight: AppTypography.medium,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else if (hasSelection && !isOther && selectedBank == null) ...[
                  // Code inconnu : n'existe pas dans la liste, traiter comme Autre
                  Expanded(
                    child: Text(
                      selectedBankCode!,
                      style: TextStyle(
                        fontSize: AppTypography.sizeMd,
                        fontWeight: AppTypography.medium,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else if (hasSelection && isOther) ...[
                  Expanded(
                    child: Text(
                      'Autre / Personnalisé',
                      style: TextStyle(
                        fontSize: AppTypography.sizeMd,
                        fontWeight: AppTypography.medium,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'Sélectionner une banque',
                      style: TextStyle(
                        fontSize: AppTypography.sizeMd,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: AppSpacing.space2),
                PhosphorIcon(
                  PhosphorIconsRegular.caretDown,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.notifier});

  final ValueNotifier<String> notifier;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space2,
        horizontal: AppSpacing.space3,
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: TextField(
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Rechercher une banque...',
                hintStyle: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              onChanged: (query) => notifier.value = query,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankList extends StatelessWidget {
  const _BankList({
    required this.searchNotifier,
    required this.banks,
    required this.selectedBankCode,
    required this.onChanged,
  });

  final ValueNotifier<String> searchNotifier;
  final AsyncValue<List<Bank>> banks;
  final String? selectedBankCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return banks.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.space6),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => _buildErrorFallback(context),
      data: (bankList) => ValueListenableBuilder<String>(
        valueListenable: searchNotifier,
        builder: (ctx, query, child) => _buildContent(ctx, bankList, query),
      ),
    );
  }

  Widget _buildErrorFallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
          child: Text(
            'Impossible de charger les banques',
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Divider(),
        _OtherBankTile(
          isSelected: selectedBankCode == 'OTHER',
          onTap: () => onChanged('OTHER'),
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<Bank> allBanks, String query) {
    final filtered = query.isEmpty
        ? allBanks.where((b) => b.code != 'OTHER').toList()
        : allBanks
            .where((b) =>
                b.code != 'OTHER' &&
                b.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

    final frBanks = filtered.where((b) => b.country == 'FR').toList();
    final tgBanks = filtered.where((b) => b.country == 'TG').toList();
    final intlBanks = filtered.where((b) => b.country == null).toList();

    final isEmpty = frBanks.isEmpty && tgBanks.isEmpty && intlBanks.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEmpty)
          _buildEmptyMessage(context)
        else ...[
          if (frBanks.isNotEmpty) ...[
            _buildSectionHeader(context, 'France'),
            ...frBanks.map(
              (b) => _BankTile(
                bank: b,
                isSelected: selectedBankCode == b.code,
                onTap: () => onChanged(b.code),
              ),
            ),
          ],
          if (tgBanks.isNotEmpty) ...[
            if (frBanks.isNotEmpty) const SizedBox(height: AppSpacing.space2),
            _buildSectionHeader(context, 'Afrique de l\'Ouest'),
            ...tgBanks.map(
              (b) => _BankTile(
                bank: b,
                isSelected: selectedBankCode == b.code,
                onTap: () => onChanged(b.code),
              ),
            ),
          ],
          if (intlBanks.isNotEmpty) ...[
            if (frBanks.isNotEmpty || tgBanks.isNotEmpty)
              const SizedBox(height: AppSpacing.space2),
            _buildSectionHeader(context, 'International'),
            ...intlBanks.map(
              (b) => _BankTile(
                bank: b,
                isSelected: selectedBankCode == b.code,
                onTap: () => onChanged(b.code),
              ),
            ),
          ],
        ],
        const Divider(height: AppSpacing.space8),
        _OtherBankTile(
          isSelected: selectedBankCode == 'OTHER',
          onTap: () => onChanged('OTHER'),
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space2,
        bottom: AppSpacing.space1,
        left: AppSpacing.space3,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.sizeXs,
          fontWeight: AppTypography.semiBold,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
      child: Center(
        child: Text(
          'Aucune banque trouvée',
          style: TextStyle(
            fontSize: AppTypography.sizeSm,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({
    required this.bank,
    required this.isSelected,
    required this.onTap,
  });

  final Bank bank;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brandColor = parseHexColor(bank.brandColor);

    return Semantics(
      label: bank.name,
      toggled: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: AppSpacing.space12,
          decoration: isSelected
              ? BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/banks/${bank.code.toLowerCase()}.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  bank.name,
                  style: TextStyle(
                    fontSize: AppTypography.sizeMd,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (brandColor != null)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: brandColor,
                    shape: BoxShape.circle,
                  ),
                ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.space2),
                PhosphorIcon(
                  PhosphorIconsBold.check,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OtherBankTile extends StatelessWidget {
  const _OtherBankTile({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Autre / Personnalisé',
      toggled: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: AppSpacing.space12,
          decoration: isSelected
              ? BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  PhosphorIconsRegular.bank,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  'Autre / Personnalisé',
                  style: TextStyle(
                    fontSize: AppTypography.sizeMd,
                    fontWeight: AppTypography.medium,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                PhosphorIcon(
                  PhosphorIconsBold.check,
                  size: 16,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
