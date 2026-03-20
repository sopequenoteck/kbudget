import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/common_widgets/account_bank_icon.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/category_picker.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/confirm_delete_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SubscriptionForm extends ConsumerStatefulWidget {
  const SubscriptionForm({
    super.key,
    this.subscription,
    required this.frequence,
    required this.onSaved,
    this.onDeleted,
    required this.onCancelled,
  });

  final Subscription? subscription;
  final Frequency frequence;
  final Future<void> Function(Subscription sub) onSaved;
  final Future<void> Function(String id)? onDeleted;
  final VoidCallback onCancelled;

  @override
  ConsumerState<SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends ConsumerState<SubscriptionForm> {
  late final TextEditingController _nomController;
  late final TextEditingController _montantController;
  late DateTime _selectedDate;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _isActif = true;
  bool _showErrors = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  bool get _isEditMode => widget.subscription != null;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _montantController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  void _initFromEntity() {
    if (_initialized) return;
    _initialized = true;

    final sub = widget.subscription;
    if (sub != null) {
      _nomController.text = sub.nom;
      _montantController.text = sub.montant.toString();
      _selectedDate = sub.dateDebut;
      _selectedAccountId = sub.accountId;
      _selectedCategoryId = sub.categoryId;
      _isActif = sub.actif;
    } else {
      final accounts = ref.read(accountNotifierProvider).items;
      final defaultAccount = accounts
          .where((a) => a.actif && a.isDefault)
          .firstOrNull;
      _selectedAccountId = defaultAccount?.id ??
          accounts.where((a) => a.actif).firstOrNull?.id;
    }
  }

  // --- Validation ---

  String? _validateNom() {
    final value = _nomController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (value.isEmpty) return l10n.validationRequired;
    if (value.length > 255) return l10n.validationMaxLength(255);
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

  bool _isValid() {
    return _validateNom() == null && _validateMontant() == null;
  }

  // --- Actions ---

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    if (!_isValid()) return;

    setState(() => _isSubmitting = true);

    // Determine currency from selected account
    final accounts = ref.read(accountNotifierProvider).items;
    final selectedAccount = accounts
        .where((a) => a.id == _selectedAccountId)
        .firstOrNull;

    final sub = Subscription(
      id: widget.subscription?.id ??
          'pending-${DateTime.now().millisecondsSinceEpoch}',
      nom: _nomController.text.trim(),
      montant: double.parse(_montantController.text.trim()),
      frequence: widget.frequence,
      dateDebut: _selectedDate,
      currency: selectedAccount?.currency ?? Currency.eur,
      actif: _isActif,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
    );

    try {
      await widget.onSaved(sub);
    } on Exception {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
      );
    }
  }

  Future<void> _onDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: l10n.subscriptionFormDeleteConfirmTitle,
      message: l10n.subscriptionFormDeleteConfirmMessage,
    );

    if (confirmed == true && widget.onDeleted != null) {
      setState(() => _isSubmitting = true);
      try {
        await widget.onDeleted!(widget.subscription!.id);
      } on Exception {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    _initFromEntity();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accountState = ref.watch(accountNotifierProvider);
    final catState = ref.watch(categoryNotifierProvider);

    // Include active accounts + the currently associated account (even if inactive) in edit mode
    final activeAccounts = accountState.items.where((a) {
      if (a.actif) return true;
      if (_isEditMode && a.id == widget.subscription?.accountId) return true;
      return false;
    }).toList();

    final accountItems = activeAccounts
        .map((a) => SelectPickerItem(
              id: a.id,
              label: a.nom,
              icon: a.icone,
              color: parseHexColor(a.couleur),
              secondaryText: AmountFormatter.format(a.solde),
              imageUrl: resolveBankAssetPath(a),
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nom + Montant side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AppFormField(
                label: l10n.subscriptionFormNameField,
                showError: _showErrors && _validateNom() != null,
                errorMessage: _validateNom() ?? '',
                child: TextField(
                  controller: _nomController,
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  maxLength: 255,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_showErrors) setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              flex: 2,
              child: AppFormField(
                label: l10n.subscriptionFormAmountField,
                showError: _showErrors && _validateMontant() != null,
                errorMessage: _validateMontant() ?? '',
                child: TextField(
                  controller: _montantController,
                  decoration: const InputDecoration.collapsed(hintText: '0.00'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_showErrors) setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Date de debut
        AppFormField(
          label: l10n.subscriptionFormDateField,
          child: GestureDetector(
            onTap: _pickDate,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dateFormat.format(_selectedDate),
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                PhosphorIcon(
                  PhosphorIconsRegular.calendarBlank,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Compte
        if (activeAccounts.isEmpty)
          _buildEmptyMessage(l10n.subscriptionFormNoAccounts, colorScheme)
        else
          SelectPicker(
            items: accountItems,
            selectedId: _selectedAccountId,
            onChanged: (id) {
              setState(() => _selectedAccountId = id);
            },
            label: l10n.subscriptionFormAccountPicker,
          ),
        const SizedBox(height: AppSpacing.space4),

        // Categorie
        if (catState.items.isEmpty)
          _buildEmptyMessage(l10n.subscriptionFormNoCategories, colorScheme)
        else
          CategoryPicker(
            categories: catState.items,
            selectedId: _selectedCategoryId,
            onChanged: (id) {
              setState(() => _selectedCategoryId = id);
            },
            label: l10n.subscriptionFormCategoryPicker,
          ),
        const SizedBox(height: AppSpacing.space4),

        // Switch actif
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.subscriptionFormActiveSwitch,
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurface,
              ),
            ),
            Switch(
              value: _isActif,
              onChanged: (value) {
                setState(() => _isActif = value);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),

        // Action buttons
        Row(
          children: [
            // Delete (edit mode only)
            if (_isEditMode && widget.onDeleted != null)
              IconButton(
                onPressed: _isSubmitting ? null : _onDelete,
                icon: const PhosphorIcon(PhosphorIconsRegular.trash, size: 20),
                color: colorScheme.error,
                tooltip: l10n.subscriptionFormDeleteButton,
              ),
            const Spacer(),
            // Cancel + Save/Update
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
                  : Text(
                      _isEditMode
                          ? l10n.subscriptionFormUpdateButton
                          : l10n.subscriptionFormSaveButton,
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildEmptyMessage(String message, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
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
              message,
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
}
