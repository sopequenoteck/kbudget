import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/category_picker.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/confirm_delete_dialog.dart';

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({
    super.key,
    this.transaction,
    required this.type,
    required this.onSaved,
    this.onDeleted,
    required this.onCancelled,
  });

  final Transaction? transaction;
  final TransactionType type;
  final Future<void> Function(Transaction tx) onSaved;
  final Future<void> Function(String id)? onDeleted;
  final VoidCallback onCancelled;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late final TextEditingController _libelleController;
  late final TextEditingController _montantController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _showErrors = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _libelleController = TextEditingController();
    _montantController = TextEditingController();
    _noteController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _montantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initFromEntity() {
    if (_initialized) return;
    _initialized = true;

    final tx = widget.transaction;
    if (tx != null) {
      _libelleController.text = tx.libelle;
      _montantController.text = tx.montant.toString();
      _noteController.text = tx.note ?? '';
      _selectedDate = tx.date;
      _selectedAccountId = tx.accountId;
      _selectedCategoryId = tx.categoryId;
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

  String? _validateLibelle() {
    final value = _libelleController.text.trim();
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

  String? _validateAccount() {
    if (_selectedAccountId == null) return AppLocalizations.of(context)!.validationRequired;
    return null;
  }

  String? _validateCategory() {
    if (_selectedCategoryId == null) return AppLocalizations.of(context)!.validationRequired;
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
    return _validateLibelle() == null &&
        _validateMontant() == null &&
        _validateAccount() == null &&
        _validateCategory() == null &&
        _validateNote() == null;
  }

  // --- Actions ---

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    if (!_isValid()) return;

    setState(() => _isSubmitting = true);

    final tx = Transaction(
      id: widget.transaction?.id ??
          'pending-${DateTime.now().millisecondsSinceEpoch}',
      montant: double.parse(_montantController.text.trim()),
      libelle: _libelleController.text.trim(),
      type: widget.type,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
    );

    try {
      await widget.onSaved(tx);
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
      title: l10n.transactionFormDeleteConfirmTitle,
      message: l10n.transactionFormDeleteConfirmMessage,
    );

    if (confirmed == true && widget.onDeleted != null) {
      setState(() => _isSubmitting = true);
      try {
        await widget.onDeleted!(widget.transaction!.id);
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

    final activeAccounts = accountState.items.where((a) => a.actif).toList();

    final accountItems = activeAccounts
        .map((a) => SelectPickerItem(
              id: a.id,
              label: a.nom,
              icon: a.icone,
              color: parseHexColor(a.couleur),
              secondaryText: AmountFormatter.format(a.solde),
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Libellé + Montant côte à côte
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AppFormField(
                label: l10n.transactionFormLabelField,
                showError: _showErrors && _validateLibelle() != null,
                errorMessage: _validateLibelle() ?? '',
                child: TextField(
                  controller: _libelleController,
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
                label: l10n.transactionFormAmountField,
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

        // Date
        AppFormField(
          label: l10n.transactionFormDateField,
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
                Icon(
                  Icons.calendar_today,
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
          _buildEmptyMessage(l10n.transactionFormNoAccounts, colorScheme)
        else
          SelectPicker(
            items: accountItems,
            selectedId: _selectedAccountId,
            onChanged: (id) {
              setState(() => _selectedAccountId = id);
            },
            label: l10n.transactionFormAccountPicker,
            validator: (_) => _showErrors ? _validateAccount() : null,
            autovalidateMode: AutovalidateMode.always,
          ),
        const SizedBox(height: AppSpacing.space4),

        // Catégorie
        if (catState.items.isEmpty)
          _buildEmptyMessage(l10n.transactionFormNoCategories, colorScheme)
        else
          CategoryPicker(
            categories: catState.items,
            selectedId: _selectedCategoryId,
            onChanged: (id) {
              setState(() => _selectedCategoryId = id);
            },
            label: l10n.transactionFormCategoryPicker,
            validator: (_) => _showErrors ? _validateCategory() : null,
            autovalidateMode: AutovalidateMode.always,
          ),
        const SizedBox(height: AppSpacing.space4),

        // Note
        AppFormField(
          label: l10n.transactionFormNoteField,
          showError: _showErrors && _validateNote() != null,
          errorMessage: _validateNote() ?? '',
          child: TextField(
            controller: _noteController,
            decoration: const InputDecoration.collapsed(hintText: ''),
            maxLines: 3,
            maxLength: 500,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
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
            // Delete (edit mode only, à gauche)
            if (_isEditMode && widget.onDeleted != null)
              IconButton(
                onPressed: _isSubmitting ? null : _onDelete,
                icon: const Icon(Icons.delete_outline),
                color: colorScheme.error,
                tooltip: l10n.transactionFormDeleteButton,
              ),
            const Spacer(),
            // Annuler + Enregistrer/Modifier (à droite)
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
                          ? l10n.transactionFormUpdateButton
                          : l10n.transactionFormSaveButton,
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
          Icon(
            Icons.info_outline,
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
