import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/emoji_input.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_preview_card.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_type_selector.dart';
import 'package:k_budget/src/common_widgets/color_palette_picker.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final Account? account;

  const AccountFormScreen({super.key, this.account});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  bool get _isEditMode => widget.account != null;

  late AccountType _selectedType;
  late String _selectedEmoji;
  late String _selectedColor;
  late Currency _selectedCurrency;
  late bool _isActive;

  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  final _newBalanceController = TextEditingController();

  bool _showErrors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final a = widget.account!;
      _selectedType = a.type;
      _selectedEmoji = a.icone;
      _selectedColor = a.couleur;
      _selectedCurrency = a.currency;
      _isActive = a.actif;
      _nameController.text = a.nom;
    } else {
      _selectedType = AccountType.courant;
      _selectedEmoji = AccountTypeSelector.defaultEmoji(AccountType.courant);
      _selectedColor = AccountTypeSelector.defaultColor(AccountType.courant);
      _selectedCurrency = Currency.eur;
      _isActive = true;
      _initialBalanceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _newBalanceController.dispose();
    super.dispose();
  }

  String? _validateNom(String value) {
    final l10n = AppLocalizations.of(context)!;
    if (value.trim().isEmpty) return l10n.validationRequired;
    if (value.length > 50) return l10n.validationMaxLength(50);
    return null;
  }

  String? _validateMontant(String value) {
    final l10n = AppLocalizations.of(context)!;
    if (value.trim().isEmpty) return l10n.validationRequired;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return l10n.validationAmountPositive;
    return null;
  }

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);

    final nomError = _validateNom(_nameController.text);
    final montantError =
        _isEditMode ? null : _validateMontant(_initialBalanceController.text);

    if (nomError != null || montantError != null) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(accountNotifierProvider.notifier);

    try {
      if (_isEditMode) {
        final updated = widget.account!.copyWith(
          nom: _nameController.text.trim(),
          icone: _selectedEmoji,
          couleur: _selectedColor,
          actif: _isActive,
        );
        await notifier.update(updated);

        // Adjust balance if needed
        final newBalanceText = _newBalanceController.text.trim();
        if (newBalanceText.isNotEmpty) {
          final newBalance =
              double.tryParse(newBalanceText.replaceAll(',', '.'));
          if (newBalance != null && newBalance != widget.account!.solde) {
            await notifier.adjustBalance(widget.account!.id, newBalance);
          }
        }
      } else {
        final soldeInitial = double.tryParse(
                _initialBalanceController.text.replaceAll(',', '.')) ??
            0;
        final account = Account(
          id: '',
          nom: _nameController.text.trim(),
          type: _selectedType,
          soldeInitial: soldeInitial,
          icone: _selectedEmoji,
          couleur: _selectedColor,
          currency: _selectedCurrency,
          actif: true,
        );
        await notifier.create(account);
      }

      if (mounted) context.pop();
    } on Exception {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? l10n.accountErrorUpdate : l10n.accountErrorCreate,
            ),
          ),
        );
      }
    }
  }

  void _onDelete() {
    final l10n = AppLocalizations.of(context)!;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountDeleteConfirmTitle),
        content: Text(l10n.accountDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      try {
        await ref
            .read(accountNotifierProvider.notifier)
            .delete(widget.account!.id);
        if (mounted) context.pop();
      } on Exception {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.accountErrorDelete)),
          );
        }
      }
    });
  }

  void _onTypeChanged(AccountType type) {
    setState(() {
      _selectedType = type;
      _selectedEmoji = AccountTypeSelector.defaultEmoji(type);
      _selectedColor = AccountTypeSelector.defaultColor(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final nomError = _showErrors ? _validateNom(_nameController.text) : null;
    final montantError = _showErrors && !_isEditMode
        ? _validateMontant(_initialBalanceController.text)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.accountsEditTitle : l10n.accountsNewTitle),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.space4),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _onSubmit,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          // Preview card
          AccountPreviewCard(
            emoji: _selectedEmoji,
            name: _nameController.text,
            colorHex: _selectedColor,
          ),
          const SizedBox(height: AppSpacing.space6),

          // Type selector
          AccountTypeSelector(
            selectedType: _selectedType,
            onChanged: _onTypeChanged,
            disabled: _isEditMode,
          ),
          const SizedBox(height: AppSpacing.space6),

          // Emoji + Color row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiInput(
                label: l10n.accountFormIconField,
                initialValue: _selectedEmoji,
                onChanged: (emoji) => setState(() => _selectedEmoji = emoji),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: ColorPalettePicker(
                  label: l10n.accountFormColorField,
                  selectedColor: _selectedColor,
                  onChanged: (color) => setState(() => _selectedColor = color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),

          // Name field
          AppFormField(
            label: l10n.accountFormNameField,
            showError: nomError != null,
            errorMessage: nomError ?? '',
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration.collapsed(hintText: ''),
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                color: colorScheme.onSurface,
              ),
              maxLength: 50,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),

          // Currency picker
          SelectPicker(
            label: l10n.accountFormCurrencyPicker,
            items: Currency.values
                .map((c) => SelectPickerItem(
                      id: c.name,
                      label: '${c.symbol} — ${c.name}',
                    ))
                .toList(),
            selectedId: _selectedCurrency.name,
            onChanged: (id) {
              if (id != null) {
                setState(() {
                  _selectedCurrency = Currency.values.byName(id);
                });
              }
            },
            enabled: !_isEditMode,
          ),
          const SizedBox(height: AppSpacing.space6),

          // Initial balance (create mode) or current balance + adjust (edit mode)
          if (!_isEditMode) ...[
            AppFormField(
              label: l10n.accountFormInitialBalanceField,
              showError: montantError != null,
              errorMessage: montantError ?? '',
              child: TextField(
                controller: _initialBalanceController,
                decoration: InputDecoration.collapsed(
                  hintText: '0',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  color: colorScheme.onSurface,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ] else ...[
            // Current balance (read-only)
            _ReadOnlyField(
              label: l10n.accountFormCurrentBalance,
              value: AmountFormatter.format(
                widget.account!.solde,
                currency: widget.account!.currency,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            // New balance field
            AppFormField(
              label: l10n.accountFormNewBalance,
              child: TextField(
                controller: _newBalanceController,
                decoration: InputDecoration.collapsed(
                  hintText: '',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  color: colorScheme.onSurface,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]')),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space6),

          // Active switch (edit mode only)
          if (_isEditMode) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountFormActiveSwitch,
                        style: TextStyle(
                          fontSize: AppTypography.sizeMd,
                          fontWeight: AppTypography.medium,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (widget.account!.isDefault)
                        Text(
                          l10n.accountFormActiveDefaultHint,
                          style: TextStyle(
                            fontSize: AppTypography.sizeXs,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: widget.account!.isDefault
                      ? null
                      : (value) => setState(() => _isActive = value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),

            // Delete button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _onDelete,
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                label: Text(
                  l10n.delete,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space12),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
