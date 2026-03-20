import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/budget.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/confirm_delete_dialog.dart';
import 'package:k_budget/src/utils/decimal_input_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BudgetForm extends ConsumerStatefulWidget {
  const BudgetForm({
    super.key,
    this.budget,
    required this.onSaved,
    this.onDeleted,
    required this.onCancelled,
  });

  final Budget? budget;
  final Future<void> Function(Budget budget) onSaved;
  final Future<void> Function(String id)? onDeleted;
  final VoidCallback onCancelled;

  @override
  ConsumerState<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<BudgetForm> {
  late final TextEditingController _montantController;
  String? _selectedCategoryId;
  Currency _selectedCurrency = Currency.eur;
  Frequency _selectedFrequence = Frequency.mensuel;
  int _seuilNotification = 80;
  bool _actif = true;
  bool _showErrors = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  bool get _isEditMode => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _montantController = TextEditingController();
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  void _initFromEntity() {
    if (_initialized) return;
    _initialized = true;

    final budget = widget.budget;
    if (budget != null) {
      _montantController.text = budget.montant.toString();
      _selectedCategoryId = budget.categoryId;
      _selectedCurrency = budget.currency;
      _selectedFrequence = budget.frequence;
      _seuilNotification = budget.seuilNotification;
      _actif = budget.actif;
    } else {
      // Default to first user currency
      final currencies = ref.read(currencyConfigNotifierProvider);
      if (currencies.isNotEmpty) {
        _selectedCurrency = currencies.first;
      }
    }
  }

  // --- Validation ---

  String? _validateMontant() {
    final value = _montantController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (value.isEmpty) return l10n.validationRequired;
    final parsed = double.tryParse(value);
    if (parsed == null) return l10n.validationRequired;
    if (parsed <= 0) return l10n.validationAmountPositive;
    return null;
  }

  String? _validateCategory() {
    if (_selectedCategoryId == null) {
      return AppLocalizations.of(context)!.validationRequired;
    }
    return null;
  }

  bool _isValid() {
    return _validateMontant() == null && _validateCategory() == null;
  }

  // --- Actions ---

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    if (!_isValid()) return;

    setState(() => _isSubmitting = true);

    final budget = Budget(
      id: widget.budget?.id ??
          'pending-${DateTime.now().millisecondsSinceEpoch}',
      categoryId: _selectedCategoryId!,
      montant: double.parse(_montantController.text.trim()),
      frequence: _selectedFrequence,
      currency: _selectedCurrency,
      seuilNotification: _seuilNotification,
      actif: _actif,
      categoryNom: widget.budget?.categoryNom,
      categoryIcone: widget.budget?.categoryIcone,
      categoryCouleur: widget.budget?.categoryCouleur,
    );

    try {
      await widget.onSaved(budget);
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
      title: l10n.deleteBudgetTitle,
      message: l10n.deleteBudgetMessage,
    );

    if (confirmed == true && widget.onDeleted != null) {
      setState(() => _isSubmitting = true);
      try {
        await widget.onDeleted!(widget.budget!.id);
      } on Exception {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    _initFromEntity();

    final colorScheme = Theme.of(context).colorScheme;
    final catState = ref.watch(categoryNotifierProvider);
    final budgetState = ref.watch(budgetNotifierProvider);
    final currencies = ref.watch(currencyConfigNotifierProvider);

    // In create mode, filter out categories that already have a budget
    final existingBudgetCategoryIds =
        budgetState.items.map((b) => b.categoryId).toSet();

    final availableCategories = _isEditMode
        ? catState.items
        : catState.items
            .where((c) => !existingBudgetCategoryIds.contains(c.id))
            .toList();

    final categoryItems = availableCategories
        .map((c) => SelectPickerItem(
              id: c.id,
              label: c.nom,
              icon: c.icone,
              color: parseHexColor(c.couleur),
            ))
        .toList();

    final currencyItems = currencies
        .map((c) => SelectPickerItem(
              id: c.name,
              label: '${c.displayName} (${c.symbol})',
            ))
        .toList();

    final frequenceItems = [
      SelectPickerItem(id: Frequency.hebdomadaire.name, label: 'Hebdomadaire'),
      SelectPickerItem(id: Frequency.mensuel.name, label: 'Mensuel'),
      SelectPickerItem(id: Frequency.annuel.name, label: 'Annuel'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Catégorie
        if (availableCategories.isEmpty && !_isEditMode)
          _buildEmptyMessage(
            AppLocalizations.of(context)!.allCategoriesHaveBudgets,
            colorScheme,
          )
        else
          _buildCategoryField(categoryItems, colorScheme),
        const SizedBox(height: AppSpacing.space4),

        // Montant + Devise
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AppFormField(
                label: AppLocalizations.of(context)!.amount,
                showError: _showErrors && _validateMontant() != null,
                errorMessage: _validateMontant() ?? '',
                child: TextField(
                  controller: _montantController,
                  decoration:
                      const InputDecoration.collapsed(hintText: '0.00'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalTextInputFormatter()],
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
              child: SelectPicker(
                items: currencyItems,
                selectedId: _selectedCurrency.name,
                onChanged: (id) {
                  if (id != null) {
                    setState(() {
                      _selectedCurrency =
                          Currency.values.byName(id);
                    });
                  }
                },
                label: AppLocalizations.of(context)!.currency,
                placeholder: AppLocalizations.of(context)!.currency,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Fréquence
        SelectPicker(
          items: frequenceItems,
          selectedId: _selectedFrequence.name,
          onChanged: (id) {
            if (id != null) {
              setState(() {
                _selectedFrequence = Frequency.values.byName(id);
              });
            }
          },
          label: AppLocalizations.of(context)!.frequency,
          placeholder: AppLocalizations.of(context)!.frequency,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Seuil de notification
        _buildSeuilSlider(colorScheme),
        const SizedBox(height: AppSpacing.space4),

        // Toggle actif (mode édition uniquement)
        if (_isEditMode) ...[
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.budgetActive),
            value: _actif,
            onChanged: (v) => setState(() => _actif = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.space4),
        ] else
          const SizedBox(height: AppSpacing.space2),

        // Action buttons
        Row(
          children: [
            // Delete (edit mode only)
            if (_isEditMode && widget.onDeleted != null)
              IconButton(
                onPressed: _isSubmitting ? null : _onDelete,
                icon: const PhosphorIcon(PhosphorIconsRegular.trash, size: 20),
                color: colorScheme.error,
                tooltip: AppLocalizations.of(context)!.deleteBudgetTitle,
              ),
            const Spacer(),
            OutlinedButton(
              onPressed: _isSubmitting ? null : widget.onCancelled,
              child: Text(AppLocalizations.of(context)!.cancel),
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
                          ? AppLocalizations.of(context)!.edit
                          : AppLocalizations.of(context)!.save,
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildCategoryField(
    List<SelectPickerItem> categoryItems,
    ColorScheme colorScheme,
  ) {
    if (_isEditMode) {
      // In edit mode, category is locked — show a read-only field
      final budget = widget.budget!;
      final label = budget.categoryNom ?? AppLocalizations.of(context)!.category;
      final icon = budget.categoryIcone;
      final color = parseHexColor(budget.categoryCouleur);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.category,
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.medium,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Opacity(
            opacity: 0.6,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.space3,
                horizontal: AppSpacing.space4,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Text(icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.space3),
                  ],
                  if (color != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTypography.sizeMd,
                        fontWeight: AppTypography.medium,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PhosphorIcon(
                    PhosphorIconsRegular.lock,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Create mode: SelectPicker
    return SelectPicker(
      items: categoryItems,
      selectedId: _selectedCategoryId,
      onChanged: (id) {
        setState(() => _selectedCategoryId = id);
        if (_showErrors) setState(() {});
      },
      label: AppLocalizations.of(context)!.category,
      placeholder: AppLocalizations.of(context)!.selectCategory,
      validator: _showErrors
          ? (_) => _validateCategory()
          : null,
    );
  }

  Widget _buildSeuilSlider(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.alertThreshold,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$_seuilNotification%',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Slider(
          value: _seuilNotification.toDouble(),
          min: 50,
          max: 100,
          divisions: 10,
          label: '$_seuilNotification%',
          onChanged: (value) {
            setState(() => _seuilNotification = value.round());
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '50%',
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '100%',
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
