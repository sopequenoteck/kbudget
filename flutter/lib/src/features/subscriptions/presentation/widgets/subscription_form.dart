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
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
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
  String? _expandedSection; // 'date' | 'categorie' | 'compte' | 'devise'
  Currency? _forcedCurrency;
  bool _isCreatingCategory = false;
  late Frequency _selectedFrequency;

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _isoFormat = DateFormat('yyyy-MM-dd');

  static const _frequencies = [
    Frequency.hebdomadaire,
    Frequency.mensuel,
    Frequency.annuel,
  ];

  bool get _isEditMode => widget.subscription != null;

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.frequence;
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
      _selectedFrequency = sub.frequence;
    } else {
      final accounts = ref.read(accountNotifierProvider).items;
      final defaultAccount =
          accounts.where((a) => a.actif && a.isDefault).firstOrNull;
      _selectedAccountId =
          defaultAccount?.id ?? accounts.where((a) => a.actif).firstOrNull?.id;
    }
  }

  void _toggleSection(String key) {
    FocusScope.of(context).unfocus();
    setState(() => _expandedSection = _expandedSection == key ? null : key);
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
    final parsed = double.tryParse(value.replaceAll(',', '.'));
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

    final accounts = ref.read(accountNotifierProvider).items;
    final selectedAccount =
        accounts.where((a) => a.id == _selectedAccountId).firstOrNull;

    final currency =
        _forcedCurrency ?? selectedAccount?.currency ?? Currency.eur;

    final sub = Subscription(
      id: widget.subscription?.id ??
          'pending-${DateTime.now().millisecondsSinceEpoch}',
      nom: _nomController.text.trim(),
      montant: double.parse(_montantController.text.trim().replaceAll(',', '.')),
      frequence: _selectedFrequency,
      dateDebut: _selectedDate,
      currency: currency,
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
            originalValue: _isEditMode
                ? _isoFormat.format(widget.subscription!.dateDebut)
                : null,
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
      'devise' => _buildDeviseExpand(),
      _ => null,
    };
  }

  Widget _buildAccountExpand(List<Account> accounts) {
    final accountItems = accounts
        .where((a) {
          if (a.actif) return true;
          if (_isEditMode && a.id == widget.subscription?.accountId) return true;
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
          // Réinitialiser la devise forcée quand un compte est sélectionné
          if (id != null) _forcedCurrency = null;
          _expandedSection = null;
        }),
        label: AppLocalizations.of(context)!.subscriptionFormAccountPicker,
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
    final accountState = ref.watch(accountNotifierProvider);
    final categoryState = ref.watch(categoryNotifierProvider);
    final accounts = accountState.items;
    final categories = categoryState.items;

    final nomHasError = _showErrors && _validateNom() != null;
    final montantHasError = _showErrors && _validateMontant() != null;

    return PopScope(
      canPop: _expandedSection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _expandedSection = null);
      },
      child: BottomSheet4RowsWidget(
        title: _isEditMode ? 'Modifier abonnement' : 'Nouvel abonnement',
        topTrailing: BSheetTypeToggle(
          labels: const ['Hebdo', 'Mensuel', 'Annuel'],
          selectedIndex:
              _frequencies.indexOf(_selectedFrequency).clamp(0, 2),
          onChanged: (i) =>
              setState(() => _selectedFrequency = _frequencies[i]),
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
              color: cs.onSurface,
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
          key: const Key('nom_field_column'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('tf_nom'),
              controller: _nomController,
              decoration: InputDecoration(
                hintText: l10n.subscriptionFormNameField,
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                errorText: nomHasError ? _validateNom() : null,
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
        iconButtons: _isEditMode
            ? [
                IconButton(
                  icon: PhosphorIcon(
                    _isActif
                        ? PhosphorIconsRegular.toggleRight
                        : PhosphorIconsRegular.toggleLeft,
                    size: 20,
                    color: _isActif ? cs.primary : cs.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() => _isActif = !_isActif),
                  tooltip: l10n.subscriptionFormActiveSwitch,
                ),
              ]
            : null,
        metaPills: _buildMetaPills(categories, accounts),
        expandedContent: _buildExpandedContent(categories, accounts),
        footerLeading: _isEditMode && widget.onDeleted != null
            ? [
                BSheetDeletePill(
                  isLoading: _isSubmitting,
                  onTap: _onDelete,
                  label: l10n.subscriptionFormDeleteButton,
                ),
              ]
            : null,
        onCancel: widget.onCancelled,
        footerEnabled: !_isCreatingCategory,
        loading: _isSubmitting,
        onSubmit: _onSubmit,
        submitLabel: _isEditMode
            ? l10n.subscriptionFormUpdateButton
            : l10n.subscriptionFormSaveButton,
      ),
    );
  }
}

