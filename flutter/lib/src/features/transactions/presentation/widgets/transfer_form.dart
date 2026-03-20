import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/account_bank_icon.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/data/remote/dtos/transfer_dtos.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';

class TransferForm extends ConsumerStatefulWidget {
  const TransferForm({
    super.key,
    required this.accounts,
    required this.onSaved,
    required this.onCancelled,
  });

  final List<Account> accounts;
  final Future<void> Function(TransferRequest request) onSaved;
  final VoidCallback onCancelled;

  @override
  ConsumerState<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends ConsumerState<TransferForm> {
  late final TextEditingController _montantController;
  late final TextEditingController _noteController;
  String? _sourceAccountId;
  String? _destinationAccountId;
  bool _showErrors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _montantController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- Validation ---

  String? _validateSource() {
    if (_sourceAccountId == null) {
      return AppLocalizations.of(context)!.validationRequired;
    }
    return null;
  }

  String? _validateDestination() {
    final l10n = AppLocalizations.of(context)!;
    if (_destinationAccountId == null) return l10n.validationRequired;
    if (_destinationAccountId == _sourceAccountId) {
      return l10n.validationSameAccount;
    }
    return null;
  }

  String? _validateMontant() {
    final value = _montantController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (value.isEmpty) return l10n.validationRequired;
    final parsed = double.tryParse(value);
    if (parsed == null) return l10n.validationRequired;
    if (parsed <= 0) return l10n.validationAmountPositive;
    return null;
  }

  String? _validateNote() {
    final value = _noteController.text.trim();
    if (value.isNotEmpty && value.length > 500) {
      return AppLocalizations.of(context)!.validationMaxLength(500);
    }
    return null;
  }

  bool _isValid() {
    return _validateSource() == null &&
        _validateDestination() == null &&
        _validateMontant() == null &&
        _validateNote() == null;
  }

  // --- Actions ---

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    if (!_isValid()) return;

    setState(() => _isSubmitting = true);

    final request = TransferRequest(
      fromAccountId: _sourceAccountId!,
      toAccountId: _destinationAccountId!,
      montant: double.parse(_montantController.text.trim()),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      await widget.onSaved(request);
    } on Exception {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
      );
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final activeAccounts = widget.accounts.where((a) => a.actif).toList();

    final sourceItems = activeAccounts
        .where((a) => a.id != _destinationAccountId)
        .map((a) => SelectPickerItem(
              id: a.id,
              label: a.nom,
              icon: a.icone,
              color: parseHexColor(a.couleur),
              secondaryText:
                  AmountFormatter.format(a.solde, currency: a.currency),
              imageUrl: resolveBankAssetPath(a),
            ))
        .toList();

    final destinationItems = activeAccounts
        .where((a) => a.id != _sourceAccountId)
        .map((a) => SelectPickerItem(
              id: a.id,
              label: a.nom,
              icon: a.icone,
              color: parseHexColor(a.couleur),
              secondaryText:
                  AmountFormatter.format(a.solde, currency: a.currency),
              imageUrl: resolveBankAssetPath(a),
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compte source
        SelectPicker(
          items: sourceItems,
          selectedId: _sourceAccountId,
          onChanged: (id) {
            setState(() => _sourceAccountId = id);
          },
          label: l10n.transferFormSourcePicker,
          validator: (_) => _showErrors ? _validateSource() : null,
          autovalidateMode: AutovalidateMode.always,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Compte destination
        SelectPicker(
          items: destinationItems,
          selectedId: _destinationAccountId,
          onChanged: (id) {
            setState(() => _destinationAccountId = id);
          },
          label: l10n.transferFormDestinationPicker,
          validator: (_) => _showErrors ? _validateDestination() : null,
          autovalidateMode: AutovalidateMode.always,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Montant
        AppFormField(
          label: l10n.transferFormAmountField,
          showError: _showErrors && _validateMontant() != null,
          errorMessage: _validateMontant() ?? '',
          child: TextField(
            controller: _montantController,
            decoration: const InputDecoration.collapsed(hintText: '0.00'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Note (optionnel)
        AppFormField(
          label: l10n.transferFormNoteField,
          showError: _showErrors && _validateNote() != null,
          errorMessage: _validateNote() ?? '',
          child: TextField(
            controller: _noteController,
            decoration: const InputDecoration.collapsed(hintText: ''),
            maxLines: 3,
            maxLength: 500,
            buildCounter: (_,
                    {required currentLength,
                    required isFocused,
                    maxLength}) =>
                null,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
          ),
        ),
        const SizedBox(height: AppSpacing.space6),

        // Action buttons
        Row(
          children: [
            const Spacer(),
            OutlinedButton(
              onPressed: _isSubmitting ? null : widget.onCancelled,
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
                  : Text(l10n.transferFormSaveButton),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
