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
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/confirm_delete_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DebtForm extends ConsumerStatefulWidget {
  const DebtForm({
    super.key,
    this.debt,
    required this.debtType,
    required this.onSaved,
    this.onDeleted,
    required this.onCancelled,
  });

  final Debt? debt;
  final DebtType debtType;
  final Future<void> Function(Debt debt) onSaved;
  final Future<void> Function(String id)? onDeleted;
  final VoidCallback onCancelled;

  @override
  ConsumerState<DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends ConsumerState<DebtForm> {
  late final TextEditingController _personneController;
  late final TextEditingController _montantController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  bool _rembourse = false;
  bool _showErrors = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  // Nouveaux champs
  String? _selectedAccountId;
  Currency? _forcedCurrency;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  bool _includeInBalance = false;
  DateTime? _dueDate;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  bool get _isEditMode => widget.debt != null;

  @override
  void initState() {
    super.initState();
    _personneController = TextEditingController();
    _montantController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _personneController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  void _initFromEntity() {
    if (_initialized) return;
    _initialized = true;

    final debt = widget.debt;
    if (debt != null) {
      _personneController.text = debt.personne;
      _montantController.text = debt.montant.toString();
      _selectedDate = debt.date;
      _selectedCategoryId = debt.categoryId;
      _rembourse = debt.rembourse;
      // Nouveaux champs
      _selectedAccountId = debt.accountId;
      if (debt.accountId != null) {
        _forcedCurrency = debt.currency;
      }
      _includeInBalance = debt.includeInBalance;
      _dueDate = debt.dueDate;
      _reminderDate = debt.reminderDate;
      if (debt.reminderTime != null) {
        final parts = debt.reminderTime!.split(':');
        if (parts.length == 2) {
          _reminderTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
    }
  }

  // --- Validation ---

  String? _validatePersonne() {
    final value = _personneController.text.trim();
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
    return _validatePersonne() == null && _validateMontant() == null;
  }

  // --- Actions ---

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    if (!_isValid()) return;

    setState(() => _isSubmitting = true);

    final debt = Debt(
      id: widget.debt?.id ??
          'pending-${DateTime.now().millisecondsSinceEpoch}',
      personne: _personneController.text.trim(),
      montant: double.parse(_montantController.text.trim()),
      sens: widget.debtType,
      date: _selectedDate,
      currency: _forcedCurrency ?? Currency.eur,
      rembourse: _rembourse,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
      includeInBalance: _selectedAccountId != null ? true : _includeInBalance,
      dueDate: _dueDate,
      reminderDate: _reminderDate,
      reminderTime: _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : (_reminderDate != null ? '09:00' : null),
    );

    try {
      await widget.onSaved(debt);
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
      title: l10n.debtFormDeleteConfirmTitle,
      message: l10n.debtFormDeleteConfirmMessage,
    );

    if (confirmed == true && widget.onDeleted != null) {
      setState(() => _isSubmitting = true);
      try {
        await widget.onDeleted!(widget.debt!.id);
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

  Future<void> _pickReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() {
        _reminderDate = picked;
        _reminderTime ??= const TimeOfDay(hour: 9, minute: 0);
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    _initFromEntity();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final catState = ref.watch(categoryNotifierProvider);
    final accountState = ref.watch(accountNotifierProvider);
    final activeAccounts = accountState.items.where((a) => a.actif).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Personne + Montant side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AppFormField(
                label: l10n.debtFormPersonField,
                showError: _showErrors && _validatePersonne() != null,
                errorMessage: _validatePersonne() ?? '',
                child: TextField(
                  controller: _personneController,
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
                label: l10n.debtFormAmountField,
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
          label: l10n.debtFormDateField,
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

        // Compte bancaire
        SelectPicker(
          items: activeAccounts
              .map((a) => SelectPickerItem(
                    id: a.id,
                    label: a.nom,
                    icon: a.icone,
                    imageUrl: resolveBankAssetPath(a),
                  ))
              .toList(),
          selectedId: _selectedAccountId,
          onChanged: (id) {
            setState(() {
              _selectedAccountId = id;
              if (id != null) {
                final account = activeAccounts.firstWhere((a) => a.id == id);
                _forcedCurrency = account.currency;
                _includeInBalance = true;
              } else {
                _forcedCurrency = null;
              }
            });
          },
          label: l10n.debtFormAccountPicker,
          placeholder: l10n.debtFormAccountPlaceholder,
          clearable: true,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Categorie
        if (catState.items.isEmpty)
          _buildEmptyMessage(l10n.debtFormNoCategories, colorScheme)
        else
          CategoryPicker(
            categories: catState.items,
            selectedId: _selectedCategoryId,
            onChanged: (id) {
              setState(() => _selectedCategoryId = id);
            },
            label: l10n.debtFormCategoryPicker,
          ),
        const SizedBox(height: AppSpacing.space4),

        // Date d'échéance
        AppFormField(
          label: l10n.debtFormDueDateField,
          child: GestureDetector(
            onTap: _pickDueDate,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate != null
                        ? _dateFormat.format(_dueDate!)
                        : l10n.debtFormDueDatePlaceholder,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      color: _dueDate != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_dueDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _dueDate = null),
                    child: PhosphorIcon(
                      PhosphorIconsRegular.x,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  PhosphorIcon(
                    PhosphorIconsRegular.calendarCheck,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Rappel (date)
        AppFormField(
          label: l10n.debtFormReminderField,
          child: GestureDetector(
            onTap: _pickReminderDate,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _reminderDate != null
                        ? _dateFormat.format(_reminderDate!)
                        : l10n.debtFormReminderPlaceholder,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMd,
                      color: _reminderDate != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_reminderDate != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _reminderDate = null;
                      _reminderTime = null;
                    }),
                    child: PhosphorIcon(
                      PhosphorIconsRegular.x,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  PhosphorIcon(
                    PhosphorIconsRegular.bell,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Heure de rappel (visible si date sélectionnée)
        if (_reminderDate != null) ...[
          AppFormField(
            label: l10n.debtFormReminderTimeField,
            child: GestureDetector(
              onTap: _pickReminderTime,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _reminderTime != null
                          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                          : '09:00',
                      style: TextStyle(
                        fontSize: AppTypography.sizeMd,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  PhosphorIcon(
                    PhosphorIconsRegular.clock,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Inclure dans le patrimoine (visible si pas de compte sélectionné)
        if (_selectedAccountId == null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.debtFormIncludeInBalance,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurface,
                ),
              ),
              Switch(
                value: _includeInBalance,
                onChanged: (value) {
                  setState(() => _includeInBalance = value);
                },
              ),
            ],
          ),
        if (_selectedAccountId == null) const SizedBox(height: AppSpacing.space4),

        // Switch Remboursé (edit mode only)
        if (_isEditMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.debtFormRepaidSwitch,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurface,
                ),
              ),
              Switch(
                value: _rembourse,
                onChanged: (value) {
                  setState(() => _rembourse = value);
                },
              ),
            ],
          ),
        if (_isEditMode) const SizedBox(height: AppSpacing.space6),
        if (!_isEditMode) const SizedBox(height: AppSpacing.space2),

        // Action buttons
        Row(
          children: [
            // Delete (edit mode only)
            if (_isEditMode && widget.onDeleted != null)
              IconButton(
                onPressed: _isSubmitting ? null : _onDelete,
                icon: const PhosphorIcon(PhosphorIconsRegular.trash, size: 20),
                color: colorScheme.error,
                tooltip: l10n.debtFormDeleteButton,
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
                          ? l10n.debtFormUpdateButton
                          : l10n.debtFormSaveButton,
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
