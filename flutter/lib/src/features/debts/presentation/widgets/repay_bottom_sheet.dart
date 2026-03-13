import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/decimal_input_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RepayBottomSheet extends ConsumerStatefulWidget {
  final Debt debt;
  final VoidCallback? onRepaid;

  const RepayBottomSheet({
    super.key,
    required this.debt,
    this.onRepaid,
  });

  static void show({
    required BuildContext context,
    required Debt debt,
    VoidCallback? onRepaid,
  }) {
    final l10n = AppLocalizations.of(context)!;
    AppModal.show(
      context,
      title: l10n.repayTitle,
      child: RepayBottomSheet(debt: debt, onRepaid: onRepaid),
      onClose: () {},
    );
  }

  @override
  ConsumerState<RepayBottomSheet> createState() => _RepayBottomSheetState();
}

class _RepayBottomSheetState extends ConsumerState<RepayBottomSheet> {
  late final TextEditingController _amountController;
  String? _selectedAccountId;
  bool _showErrors = false;
  bool _isSubmitting = false;

  double get _remaining =>
      widget.debt.remainingAmount ?? widget.debt.montant;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: _remaining.toString());
    _selectedAccountId = widget.debt.accountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAccount(AppLocalizations l10n) {
    if (_selectedAccountId == null) return l10n.repayAccountRequired;
    return null;
  }

  String? _validateAmount(AppLocalizations l10n) {
    final value = _amountController.text.trim();
    if (value.isEmpty) return l10n.repayAmountRequired;
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return l10n.repayAmountInvalid;
    if (parsed > _remaining) {
      return l10n.repayAmountMax(
          AmountFormatter.format(_remaining, currency: widget.debt.currency));
    }
    return null;
  }

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    final l10n = AppLocalizations.of(context)!;
    if (_validateAccount(l10n) != null || _validateAmount(l10n) != null) return;

    setState(() => _isSubmitting = true);

    final amount = double.parse(_amountController.text.trim());
    final accountId = _selectedAccountId ??
        ref.read(accountNotifierProvider).items.where((a) => a.actif).firstOrNull?.id;
    if (accountId == null) return;

    final success = await ref.read(debtNotifierProvider.notifier).repay(
          widget.debt.id,
          accountId,
          amount,
        );

    if (!mounted) return;

    if (success) {
      ref.invalidate(debtPaymentsProvider(widget.debt.id));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repaySuccess)),
      );
      widget.onRepaid?.call();
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repayError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accountState = ref.watch(accountNotifierProvider);
    final activeAccounts =
        accountState.items.where((a) => a.actif).toList();

    final effectiveAccountId = _selectedAccountId ??
        (activeAccounts.isNotEmpty ? activeAccounts.first.id : null);

    if (activeAccounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.info,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                l10n.repayNoAccounts,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final amountError = _validateAmount(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compte
        SelectPicker(
          items: activeAccounts
              .map((a) => SelectPickerItem(
                    id: a.id,
                    label: a.nom,
                    icon: a.icone,
                  ))
              .toList(),
          selectedId: effectiveAccountId,
          onChanged: (id) => setState(() => _selectedAccountId = id),
          label: l10n.repayAccountLabel,
          placeholder: l10n.repayAccountPlaceholder,
          validator: (_) => _showErrors ? _validateAccount(l10n) : null,
          autovalidateMode: _showErrors
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Montant
        AppFormField(
          label: l10n.repayAmountLabel,
          showError: _showErrors && amountError != null,
          errorMessage: amountError ?? '',
          child: TextField(
            controller: _amountController,
            decoration: InputDecoration.collapsed(
              hintText: AmountFormatter.format(_remaining,
                  currency: widget.debt.currency),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [DecimalTextInputFormatter()],
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
          ),
        ),
        const SizedBox(height: AppSpacing.space6),

        // Actions
        Row(
          children: [
            const Spacer(),
            OutlinedButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: AppSpacing.space3),
            FilledButton(
              onPressed: _isSubmitting ? null : _onSubmit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(l10n.repayTitle),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
