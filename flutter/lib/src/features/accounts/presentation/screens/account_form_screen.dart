// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:k_budget/src/common_widgets/bank_select_picker.dart';
import 'package:k_budget/src/common_widgets/emoji_input.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/accounts/application/bank_provider.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_preview_card.dart';
import 'package:k_budget/src/features/accounts/presentation/widgets/account_type_selector.dart';
import 'package:k_budget/src/common_widgets/color_palette_picker.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/widgets/rate_form.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/common_widgets/confirm_dialog_custom.dart';
import 'package:k_budget/src/utils/image_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  late String _selectedBankCode;
  String? _bankCustomName;
  String? _bankCustomLogo;
  String? _bankLogoLocalPath;

  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  final _newBalanceController = TextEditingController();
  final _bankCustomNameController = TextEditingController();

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
      _selectedBankCode = a.bankCode;
      _bankCustomName = a.bankCustomName;
      _bankCustomLogo = a.bankCustomLogo;
      if (_bankCustomName != null) {
        _bankCustomNameController.text = _bankCustomName!;
      }
    } else {
      _selectedType = AccountType.courant;
      _selectedEmoji = AccountTypeSelector.defaultEmoji(AccountType.courant);
      _selectedColor = AccountTypeSelector.defaultColor(AccountType.courant);
      _selectedCurrency = Currency.eur;
      _isActive = true;
      _selectedBankCode = 'OTHER';
      _initialBalanceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _newBalanceController.dispose();
    _bankCustomNameController.dispose();
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

  void _onBankCodeChanged(String code) {
    setState(() {
      _selectedBankCode = code;
      if (code != 'OTHER') {
        // Auto-fill color with bank brand color
        final banksAsync = ref.read(banksProvider);
        final bank = banksAsync.whenOrNull(
          data: (list) => list.where((b) => b.code == code).firstOrNull,
        );
        if (bank != null) {
          final brandColor = parseHexColor(bank.brandColor);
          if (brandColor != null) {
            _selectedColor =
                '#${brandColor.r.toInt().toRadixString(16).padLeft(2, '0')}${brandColor.g.toInt().toRadixString(16).padLeft(2, '0')}${brandColor.b.toInt().toRadixString(16).padLeft(2, '0')}';
          }
        }
        // Reset custom fields
        _bankCustomName = null;
        _bankCustomLogo = null;
        _bankLogoLocalPath = null;
        _bankCustomNameController.clear();
      } else {
        _bankCustomName = null;
        _bankCustomLogo = null;
        _bankLogoLocalPath = null;
        _bankCustomNameController.clear();
      }
    });
  }

  Future<void> _pickBankLogo() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const PhosphorIcon(PhosphorIconsRegular.camera, size: 20),
              title: const Text('Caméra'),
              onTap: () {
                Navigator.pop(context);
                _doPickBankLogo(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const PhosphorIcon(PhosphorIconsRegular.image, size: 20),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(context);
                _doPickBankLogo(ImageSource.gallery);
              },
            ),
            if (_bankCustomLogo != null)
              ListTile(
                leading:
                    const PhosphorIcon(PhosphorIconsRegular.trash, size: 20),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _bankCustomLogo = null;
                    _bankLogoLocalPath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _doPickBankLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (picked == null) return;
      final file = File(picked.path);
      final dataUri = ImageUtils.fileToBase64DataUri(file);
      setState(() {
        _bankLogoLocalPath = picked.path;
        _bankCustomLogo = dataUri;
      });
    } on Exception {
      // Permission denied or cancelled — silent no-op
    }
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
          bankCode: _selectedBankCode,
          bankCustomName: _selectedBankCode == 'OTHER'
              ? (_bankCustomNameController.text.trim().isEmpty
                  ? null
                  : _bankCustomNameController.text.trim())
              : null,
          bankCustomLogo:
              _selectedBankCode == 'OTHER' ? _bankCustomLogo : null,
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
          bankCode: _selectedBankCode,
          bankCustomName: _selectedBankCode == 'OTHER'
              ? (_bankCustomNameController.text.trim().isEmpty
                  ? null
                  : _bankCustomNameController.text.trim())
              : null,
          bankCustomLogo:
              _selectedBankCode == 'OTHER' ? _bankCustomLogo : null,
        );
        await notifier.create(account);

        if (mounted) {
          await _proposeRateDialog(_selectedCurrency);
        }
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

  Future<void> _proposeRateDialog(Currency accountCurrency) async {
    final currencies = ref.read(currencyConfigNotifierProvider);
    final primaryCurrency = currencies.isNotEmpty ? currencies.first : Currency.eur;

    if (accountCurrency == primaryCurrency) return;

    final rateState = ref.read(exchangeRateListProvider);
    final hasRate = rateState.items.any(
      (r) =>
          (r.baseCurrency == primaryCurrency && r.targetCurrency == accountCurrency) ||
          (r.baseCurrency == accountCurrency && r.targetCurrency == primaryCurrency),
    );

    if (hasRate) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Taux de conversion manquant'),
        content: Text(
          'Aucun taux ${primaryCurrency.symbol} → ${accountCurrency.symbol} n\'est défini.\nVoulez-vous le saisir maintenant ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Saisir le taux'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AppModal.show(
        context,
        title: 'Ajouter un taux',
        onClose: () {},
        child: RateForm(
          baseCurrency: primaryCurrency,
          onSaved: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  Future<void> _onDelete() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await ConfirmDialogCustom.show(
      context: context,
      icon: PhosphorIconsRegular.trash,
      title: l10n.accountDeleteConfirmTitle,
      message: l10n.accountDeleteConfirmMessage,
      confirmLabel: l10n.delete,
      variant: ConfirmVariant.danger,
    );

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
              icon: const PhosphorIcon(PhosphorIconsBold.check, size: 24),
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
            bankCode: _selectedBankCode != 'OTHER' ? _selectedBankCode : null,
            accountType: _selectedType,
          ),
          const SizedBox(height: AppSpacing.space6),

          // Type selector
          const _SectionHeader('TYPE DE COMPTE'),
          const SizedBox(height: AppSpacing.space2),
          AccountTypeSelector(
            selectedType: _selectedType,
            onChanged: _onTypeChanged,
            disabled: _isEditMode,
          ),
          const SizedBox(height: AppSpacing.space6),

          // Bank selector
          const _SectionHeader('BANQUE'),
          const SizedBox(height: AppSpacing.space2),
          BankSelectPicker(
            selectedBankCode: _selectedBankCode,
            onChanged: _onBankCodeChanged,
            banks: ref.watch(banksProvider),
          ),
          const SizedBox(height: AppSpacing.space6),

          // Emoji + Color row (masqué si une banque connue est sélectionnée)
          if (_selectedBankCode == 'OTHER') ...[
            const _SectionHeader('PERSONNALISATION'),
            const SizedBox(height: AppSpacing.space2),
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
                    onChanged: (color) =>
                        setState(() => _selectedColor = color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),

            // Custom bank name
            AppFormField(
              label: 'Nom de la banque',
              child: TextField(
                controller: _bankCustomNameController,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Optionnel',
                ),
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  color: colorScheme.onSurface,
                ),
                maxLength: 50,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    null,
                onChanged: (v) => setState(() => _bankCustomName = v.trim()),
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Custom logo upload
            _BankLogoUpload(
              localPath: _bankLogoLocalPath,
              dataUri: _bankCustomLogo,
              onTap: _pickBankLogo,
            ),
            const SizedBox(height: AppSpacing.space6),
          ] else
            const SizedBox(height: AppSpacing.space0),

          // Name field
          const _SectionHeader('DÉTAILS'),
          const SizedBox(height: AppSpacing.space2),
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

          // Currency picker (create mode only)
          if (!_isEditMode)
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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.accountFormCurrentBalance,
                    style: TextStyle(
                      fontSize: AppTypography.sizeSm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    AmountFormatter.format(
                      widget.account!.solde,
                      currency: widget.account!.currency,
                    ),
                    style: TextStyle(
                      fontSize: AppTypography.sizeSm,
                      fontWeight: AppTypography.semiBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
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
                icon: PhosphorIcon(PhosphorIconsRegular.trash, color: colorScheme.error, size: 20),
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

class _BankLogoUpload extends StatelessWidget {
  const _BankLogoUpload({
    required this.localPath,
    required this.dataUri,
    required this.onTap,
  });

  final String? localPath;
  final String? dataUri;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = localPath != null || dataUri != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Logo personnalisé',
          style: TextStyle(
            fontSize: AppTypography.sizeSm,
            fontWeight: AppTypography.medium,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: localPath != null
                        ? Image.file(
                            File(localPath!),
                            width: 72,
                            height: 72,
                            fit: BoxFit.contain,
                          )
                        : Image.memory(
                            ImageUtils.base64DataUriToBytes(dataUri!),
                            width: 72,
                            height: 72,
                            fit: BoxFit.contain,
                          ),
                  )
                : PhosphorIcon(
                    PhosphorIconsRegular.upload,
                    color: colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: AppTypography.sizeXs,
        fontWeight: AppTypography.semiBold,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }
}
