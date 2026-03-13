import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SnoozeDialog extends ConsumerStatefulWidget {
  final Debt debt;
  final VoidCallback? onSnoozed;

  const SnoozeDialog({
    super.key,
    required this.debt,
    this.onSnoozed,
  });

  static void show({
    required BuildContext context,
    required Debt debt,
    VoidCallback? onSnoozed,
  }) {
    final l10n = AppLocalizations.of(context)!;
    AppModal.show(
      context,
      title: l10n.snoozeTitle,
      child: SnoozeDialog(debt: debt, onSnoozed: onSnoozed),
      onClose: () {},
    );
  }

  @override
  ConsumerState<SnoozeDialog> createState() => _SnoozeDialogState();
}

class _SnoozeDialogState extends ConsumerState<SnoozeDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _showErrors = false;
  bool _isSubmitting = false;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.debt.reminderDate ??
        DateTime.now().add(const Duration(days: 1));

    if (widget.debt.reminderTime != null) {
      final parts = widget.debt.reminderTime!.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } else {
        _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      }
    } else {
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String? _validateDate(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!_selectedDate.isAfter(today)) {
      return l10n.snoozeDateFutureRequired;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    final l10n = AppLocalizations.of(context)!;
    if (_validateDate(l10n) != null) return;

    setState(() => _isSubmitting = true);

    final dateStr = _selectedDate.toIso8601String().split('T').first;
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final success = await ref.read(debtNotifierProvider.notifier).snooze(
          widget.debt.id,
          dateStr,
          timeStr,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snoozeSuccess)),
      );
      widget.onSnoozed?.call();
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snoozeError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dateError = _validateDate(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Date
        AppFormField(
          label: l10n.snoozeDateLabel,
          showError: _showErrors && dateError != null,
          errorMessage: dateError ?? '',
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

        // Heure
        AppFormField(
          label: l10n.snoozeTimeLabel,
          child: GestureDetector(
            onTap: _pickTime,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
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
        const SizedBox(height: AppSpacing.space6),

        // Actions
        Row(
          children: [
            const Spacer(),
            OutlinedButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                  : Text(l10n.snoozeSubmitButton),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
