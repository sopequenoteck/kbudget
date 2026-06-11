import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/common_widgets/account_bank_icon.dart';
import 'package:k_budget/src/common_widgets/bottom_sheet_4_rows_widget.dart';
import 'package:k_budget/src/common_widgets/bsheet_delete_pill.dart';
import 'package:k_budget/src/common_widgets/bsheet_meta_pill.dart';
import 'package:k_budget/src/common_widgets/bsheet_type_toggle.dart';
import 'package:k_budget/src/common_widgets/category_select_expand.dart';
import 'package:k_budget/src/common_widgets/inline_date_picker.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
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
  String? _selectedAccountId;
  Currency? _forcedCurrency;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  DateTime? _dueDate;
  String? _expandedSection; // 'date' | 'categorie' | 'compte' | 'echeance' | 'devise' | 'reminder'
  bool _isCreatingCategory = false;
  late DebtType _currentDebtType;

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _isoFormat = DateFormat('yyyy-MM-dd');

  bool get _isEditMode => widget.debt != null;

  @override
  void initState() {
    super.initState();
    _currentDebtType = widget.debtType;
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
      _selectedAccountId = debt.accountId;
      if (debt.accountId != null) {
        _forcedCurrency = debt.currency;
      }
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

  void _toggleSection(String key) {
    FocusScope.of(context).unfocus();
    setState(() => _expandedSection = _expandedSection == key ? null : key);
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
    final parsed = double.tryParse(value.replaceAll(',', '.'));
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
      id: widget.debt?.id ?? 'pending-${DateTime.now().millisecondsSinceEpoch}',
      personne: _personneController.text.trim(),
      montant: double.parse(_montantController.text.trim().replaceAll(',', '.')),
      sens: _currentDebtType,
      date: _selectedDate,
      currency: _forcedCurrency ?? Currency.eur,
      rembourse: _rembourse,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
      includeInBalance: _selectedAccountId != null, // calculé silencieusement
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

  // --- Expanded content ---

  Widget? _buildExpandedContent(
    List<Category> categories,
    List<Account> accounts,
  ) {
    return switch (_expandedSection) {
      'date' => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: InlineDatePicker(
            value: _isoFormat.format(_selectedDate),
            originalValue:
                _isEditMode ? _isoFormat.format(widget.debt!.date) : null,
            onChanged: (v) => setState(() {
              _selectedDate = DateTime.parse(v);
              _expandedSection = null;
            }),
          ),
        ),
      'categorie' => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: CategorySelectExpand(
            categories: categories,
            selectedId: _selectedCategoryId,
            onSelected: (id) => setState(() {
              _selectedCategoryId = id;
              _expandedSection = null;
            }),
            onCreatingChanged: (v) => setState(() => _isCreatingCategory = v),
          ),
        ),
      'compte' => _buildAccountExpand(accounts),
      'echeance' => _buildEcheanceExpand(),
      'devise' => _buildDeviseExpand(),
      'reminder' => _buildReminderExpand(),
      _ => null,
    };
  }

  Widget _buildAccountExpand(List<Account> accounts) {
    final accountItems = accounts
        .where((a) {
          if (a.actif) return true;
          if (_isEditMode && a.id == widget.debt?.accountId) return true;
          return false;
        })
        .map(
          (a) => SelectPickerItem(
            id: a.id,
            label: a.nom,
            icon: a.icone,
            color: parseHexColor(a.couleur),
            secondaryText: AmountFormatter.format(a.solde),
            imageUrl: resolveBankAssetPath(a),
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: SelectPicker(
        items: accountItems,
        selectedId: _selectedAccountId,
        onChanged: (id) => setState(() {
          _selectedAccountId = id;
          if (id != null) {
            final account = accounts.where((a) => a.id == id).firstOrNull;
            _forcedCurrency = account?.currency;
          } else {
            _forcedCurrency = null;
          }
          _expandedSection = null;
        }),
        label: AppLocalizations.of(context)!.debtFormAccountPicker,
      ),
    );
  }

  Widget _buildEcheanceExpand() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: InlineDatePicker(
        value: _dueDate != null
            ? _isoFormat.format(_dueDate!)
            : _isoFormat.format(DateTime.now()),
        onChanged: (v) => setState(() {
          _dueDate = DateTime.parse(v);
          _expandedSection = null;
        }),
      ),
    );
  }

  Widget _buildDeviseExpand() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: SelectPicker(
        items: Currency.values
            .map(
              (c) => SelectPickerItem(
                id: c.name,
                label: '${c.displayName} (${c.symbol})',
              ),
            )
            .toList(),
        selectedId: _forcedCurrency?.name,
        onChanged: (id) {
          if (id != null) {
            setState(() {
              _forcedCurrency =
                  Currency.values.firstWhere((c) => c.name == id);
              _expandedSection = null;
            });
          }
        },
        label: 'Devise',
      ),
    );
  }

  Widget _buildReminderExpand() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineDatePicker(
            value: _reminderDate != null
                ? _isoFormat.format(_reminderDate!)
                : _isoFormat.format(DateTime.now()),
            onChanged: (v) async {
              final picked = DateTime.parse(v);
              setState(() => _reminderDate = picked);
              if (!mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: _reminderTime ?? TimeOfDay.now(),
              );
              if (time != null && mounted) {
                setState(() => _reminderTime = time);
              }
            },
          ),
          if (_reminderDate != null && _reminderTime != null)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.space2,
                bottom: AppSpacing.space2,
              ),
              child: Text(
                'Rappel : ${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year} à ${_reminderTime!.format(context)}',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (_reminderDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _reminderDate = null;
                  _reminderTime = null;
                }),
                icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 14),
                label: const Text('Effacer le rappel'),
              ),
            ),
        ],
      ),
    );
  }

  // --- Pills meta ---

  List<Widget> _buildMetaPills(
    List<Category> categories,
    List<Account> accounts,
  ) {
    final cs = Theme.of(context).colorScheme;

    final selectedCategory = _selectedCategoryId != null
        ? categories.where((c) => c.id == _selectedCategoryId).firstOrNull
        : null;
    final selectedAccount = _selectedAccountId != null
        ? accounts.where((a) => a.id == _selectedAccountId).firstOrNull
        : null;

    return [
      BSheetMetaPill(
        label: _dateFormat.format(_selectedDate),
        isActive: _expandedSection == 'date',
        onTap: () => _toggleSection('date'),
        colorScheme: cs,
      ),
      BSheetMetaPill(
        label: selectedCategory?.nom ?? 'Catégorie',
        isActive: _expandedSection == 'categorie',
        onTap: () => _toggleSection('categorie'),
        colorScheme: cs,
      ),
      BSheetMetaPill(
        label: selectedAccount?.nom ?? 'Compte',
        isActive: _expandedSection == 'compte',
        onTap: () => _toggleSection('compte'),
        colorScheme: cs,
      ),
      // Pill Échéance — TOUJOURS présente
      _EcheancePill(
        dueDate: _dueDate,
        isActive: _expandedSection == 'echeance',
        onTap: () => _toggleSection('echeance'),
        onClear: _dueDate != null
            ? () => setState(() => _dueDate = null)
            : null,
        colorScheme: cs,
        dateFormat: _dateFormat,
      ),
      if (_selectedAccountId == null)
        BSheetMetaPill(
          label: _forcedCurrency?.displayName ?? 'Devise',
          isActive: _expandedSection == 'devise',
          onTap: () => _toggleSection('devise'),
          colorScheme: cs,
        ),
    ];
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    _initFromEntity();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final accountState = ref.watch(accountNotifierProvider);
    final categoryState = ref.watch(categoryNotifierProvider);
    final accounts = accountState.items;
    final categories = categoryState.items;

    final montantHasError = _showErrors && _validateMontant() != null;
    final personneHasError = _showErrors && _validatePersonne() != null;

    // Couleur montant selon type
    final amountColor = _currentDebtType == DebtType.emprunt
        ? cs.error
        : ext.incomeColor;

    final reminderIsSet = _reminderDate != null;

    return PopScope(
      canPop: _expandedSection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _expandedSection = null);
      },
      child: BottomSheet4RowsWidget(
        title: _isEditMode ? 'Modifier la dette' : 'Nouvelle dette',
        topTrailing: BSheetTypeToggle(
          labels: const ['Emprunt', 'Prêt'],
          selectedIndex: _currentDebtType == DebtType.emprunt ? 0 : 1,
          onChanged: (i) => setState(
            () => _currentDebtType =
                i == 0 ? DebtType.emprunt : DebtType.pret,
          ),
        ),
        amountField: SizedBox(
          width: 110,
          child: TextField(
            key: const Key('tf_montant'),
            controller: _montantController,
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: AppTypography.size3xl,
                color: cs.onSurfaceVariant,
                fontWeight: AppTypography.semiBold,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              errorText: montantHasError ? _validateMontant() : null,
              errorStyle: TextStyle(
                fontSize: AppTypography.sizeXs,
                color: cs.error,
              ),
            ),
            style: TextStyle(
              fontSize: AppTypography.size3xl,
              fontWeight: AppTypography.semiBold,
              color: amountColor,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
          ),
        ),
        libelleField: Column(
          key: const Key('personne_field_column'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('tf_personne'),
              controller: _personneController,
              decoration: InputDecoration(
                hintText: l10n.debtFormPersonField,
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                errorText: personneHasError ? _validatePersonne() : null,
                errorStyle: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: cs.error,
                ),
              ),
              maxLength: 255,
              buildCounter: (
                _,
                {required currentLength,
                required isFocused,
                maxLength}) => null,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_showErrors) setState(() {});
              },
            ),
          ],
        ),
        iconButtons: [
          IconButton(
            tooltip: 'Rappel',
            icon: PhosphorIcon(
              reminderIsSet
                  ? PhosphorIconsFill.bell
                  : PhosphorIconsRegular.bell,
              size: 20,
              color: _expandedSection == 'reminder'
                  ? cs.primary
                  : (reminderIsSet ? cs.primary : cs.onSurfaceVariant),
            ),
            onPressed: () => _toggleSection('reminder'),
          ),
        ],
        metaPills: _buildMetaPills(categories, accounts),
        expandedContent: _buildExpandedContent(categories, accounts),
        footerLeading: _isEditMode
            ? [
                if (widget.onDeleted != null)
                  BSheetDeletePill(
                    isLoading: _isSubmitting,
                    onTap: _onDelete,
                    label: l10n.debtFormDeleteButton,
                  ),
                _StatusPill(
                  isRembourse: _rembourse,
                  isLoading: _isSubmitting,
                  onTap: () => setState(() => _rembourse = !_rembourse),
                ),
              ]
            : null,
        onCancel: widget.onCancelled,
        footerEnabled: !_isCreatingCategory,
        loading: _isSubmitting,
        onSubmit: _onSubmit,
        submitLabel: _isEditMode
            ? l10n.debtFormUpdateButton
            : l10n.debtFormSaveButton,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets privés
// ---------------------------------------------------------------------------

/// Pill Échéance — TOUJOURS présente dans les metaPills.
/// - État vide : icône calendrier + label "Échéance" (grisée)
/// - État rempli : date formatée + icône × pour effacer
class _EcheancePill extends StatelessWidget {
  const _EcheancePill({
    required this.dueDate,
    required this.isActive,
    required this.onTap,
    this.onClear,
    required this.colorScheme,
    required this.dateFormat,
  });

  final DateTime? dueDate;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final ColorScheme colorScheme;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final hasDueDate = dueDate != null;
    final borderColor = isActive
        ? colorScheme.primary
        : (hasDueDate ? colorScheme.outlineVariant : colorScheme.outlineVariant);
    final textColor = isActive
        ? colorScheme.primary
        : (hasDueDate
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.6));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 5,
          horizontal: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.calendarCheck,
              size: 13,
              color: textColor,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              hasDueDate ? dateFormat.format(dueDate!) : 'Échéance',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: textColor,
              ),
            ),
            if (hasDueDate && onClear != null) ...[
              const SizedBox(width: AppSpacing.space1),
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: PhosphorIcon(
                  PhosphorIconsRegular.x,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill Remboursé/Non remboursé pour le footer leading en mode édition.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.isRembourse,
    required this.isLoading,
    required this.onTap,
  });

  final bool isRembourse;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      key: const Key('debt_status_pill'),
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.round),
      child: Opacity(
        opacity: isLoading ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(AppRadius.round),
          ),
          child: Text(
            isRembourse ? 'Remboursé' : 'Non remboursé',
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.medium,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
