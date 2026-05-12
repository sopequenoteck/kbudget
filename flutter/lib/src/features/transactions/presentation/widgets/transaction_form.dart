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
import 'package:k_budget/src/data/remote/dtos/recurring_transaction_create_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/features/transactions/presentation/widgets/libelle_autocomplete_field.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/confirm_delete_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  String? _expandedSection; // 'date' | 'categorie' | 'compte' | 'note' | 'recurring'
  bool _isRecurring = false;
  Frequency _recurringFrequency = Frequency.mensuel;
  DateTime? _recurringNextOccurrence;
  bool _isCreatingCategory = false;
  late TransactionType _currentType;

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _isoFormat = DateFormat('yyyy-MM-dd');

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _currentType = widget.type;
    _libelleController = TextEditingController();
    _montantController = TextEditingController();
    _noteController = TextEditingController();
    _selectedDate = DateTime.now();
    _libelleController.addListener(_onLibelleChanged);
  }

  void _onLibelleChanged() {
    if (_showErrors) setState(() {});
  }

  @override
  void dispose() {
    _libelleController.removeListener(_onLibelleChanged);
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
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return l10n.validationRequired;
    if (parsed <= 0) return l10n.validationAmountPositive;
    return null;
  }

  bool _isValid() {
    return _validateLibelle() == null && _validateMontant() == null;
  }

  // --- Actions ---

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    if (!_isValid()) return;

    setState(() => _isSubmitting = true);

    final tx = Transaction(
      id: widget.transaction?.id ??
          'pending-${DateTime.now().millisecondsSinceEpoch}',
      montant: double.parse(_montantController.text.trim().replaceAll(',', '.')),
      libelle: _libelleController.text.trim(),
      type: _currentType,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
    );

    try {
      await widget.onSaved(tx);

      if (_isRecurring && !_isEditMode) {
        try {
          final req = RecurringTransactionCreateRequest(
            montant: tx.montant,
            libelle: tx.libelle,
            type: tx.type.name.toUpperCase(),
            frequency: _recurringFrequency.name.toUpperCase(),
            nextOccurrence: _isoFormat.format(
              _recurringNextOccurrence ??
                  DateTime.now().add(const Duration(days: 30)),
            ),
            categoryId: tx.categoryId,
            accountId: tx.accountId,
            note: tx.note,
          );
          await ref.read(recurringListNotifierProvider.notifier).create(req);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction créée. Échec de la récurrence.'),
              ),
            );
          }
        }
      }
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
      'note' => _buildNoteExpand(),
      'recurring' => _buildRecurringExpand(),
      _ => null,
    };
  }

  Widget _buildAccountExpand(List<Account> accounts) {
    final accountItems = accounts
        .where((a) => a.actif)
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
          _expandedSection = null;
        }),
        label: AppLocalizations.of(context)!.transactionFormAccountPicker,
      ),
    );
  }

  Widget _buildNoteExpand() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space2,
        AppSpacing.space4,
        AppSpacing.space3,
      ),
      child: TextField(
        controller: _noteController,
        decoration: InputDecoration(
          hintText: 'Ajouter une note...',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          isDense: true,
        ),
        maxLines: 3,
        maxLength: 500,
        buildCounter: (
          _, {
          required currentLength,
          required isFocused,
          maxLength,
        }) =>
            null,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildRecurringExpand() {
    final colorScheme = Theme.of(context).colorScheme;
    final frequencies = [
      Frequency.hebdomadaire,
      Frequency.mensuel,
      Frequency.annuel,
    ];
    final selectedFreqIndex = frequencies.indexOf(_recurringFrequency);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Transaction récurrente',
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                color: colorScheme.onSurface,
              ),
            ),
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v),
          ),
          if (_isRecurring) ...[
            const SizedBox(height: AppSpacing.space2),
            BSheetTypeToggle(
              labels: const ['Hebdo', 'Mensuel', 'Annuel'],
              selectedIndex: selectedFreqIndex.clamp(0, 2),
              onChanged: (i) =>
                  setState(() => _recurringFrequency = frequencies[i]),
            ),
            const SizedBox(height: AppSpacing.space3),
            InlineDatePicker(
              value: _isoFormat.format(
                _recurringNextOccurrence ??
                    DateTime.now().add(const Duration(days: 30)),
              ),
              onChanged: (v) =>
                  setState(() => _recurringNextOccurrence = DateTime.parse(v)),
            ),
          ],
          const SizedBox(height: AppSpacing.space2),
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

    final libelleHasError = _showErrors && _validateLibelle() != null;
    final montantHasError = _showErrors && _validateMontant() != null;

    return PopScope(
      canPop: _expandedSection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _expandedSection = null);
      },
      child: BottomSheet4RowsWidget(
        title: _isEditMode ? 'Modifier transaction' : 'Nouvelle transaction',
        topTrailing: BSheetTypeToggle(
          labels: const ['Dépense', 'Recette'],
          selectedIndex: _currentType == TransactionType.depense ? 0 : 1,
          onChanged: (i) => setState(
            () => _currentType =
                i == 0 ? TransactionType.depense : TransactionType.recette,
          ),
        ),
        amountField: SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
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
            ],
          ),
        ),
        libelleField: Column(
          key: const Key('libelle_field_column'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LibelleAutocompleteField(
              controller: _libelleController,
              decoration: InputDecoration(
                hintText: l10n.transactionFormLabelField,
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                errorText: libelleHasError ? _validateLibelle() : null,
                errorStyle: TextStyle(
                  fontSize: AppTypography.sizeXs,
                  color: cs.error,
                ),
              ),
              validator: (_) => _validateLibelle(),
            ),
          ],
        ),
        notePreview: _noteController.text.isNotEmpty
            ? Text(
                _noteController.text,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        iconButtons: [
          IconButton(
            icon: PhosphorIcon(
              _noteController.text.isNotEmpty
                  ? PhosphorIconsFill.noteBlank
                  : PhosphorIconsRegular.noteBlank,
              size: 20,
              color: _expandedSection == 'note'
                  ? cs.primary
                  : cs.onSurfaceVariant,
            ),
            onPressed: () => _toggleSection('note'),
            tooltip: 'Note',
          ),
          if (!_isEditMode)
            IconButton(
              icon: PhosphorIcon(
                _isRecurring
                    ? PhosphorIconsFill.repeat
                    : PhosphorIconsRegular.repeat,
                size: 20,
                color: _expandedSection == 'recurring'
                    ? cs.primary
                    : (_isRecurring ? cs.primary : cs.onSurfaceVariant),
              ),
              onPressed: () => _toggleSection('recurring'),
              tooltip: 'Récurrence',
            ),
        ],
        metaPills: _buildMetaPills(categories, accounts),
        expandedContent: _buildExpandedContent(categories, accounts),
        footerLeading: _isEditMode && widget.onDeleted != null
            ? [
                BSheetDeletePill(
                  isLoading: _isSubmitting,
                  onTap: _onDelete,
                  label: l10n.transactionFormDeleteButton,
                ),
              ]
            : null,
        onCancel: widget.onCancelled,
        footerEnabled: !_isCreatingCategory,
        loading: _isSubmitting,
        onSubmit: _onSubmit,
        submitLabel:
            _isEditMode ? l10n.transactionFormUpdateButton : l10n.transactionFormSaveButton,
      ),
    );
  }
}

