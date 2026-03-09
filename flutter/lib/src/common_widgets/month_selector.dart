import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_shadows.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';

/// Sélecteur de mois avec boutons précédent/suivant et label formaté en français.
///
/// Widget uncontrolled : gère son propre état interne (mois/année) après
/// initialisation et notifie le parent via [onChanged].
class MonthSelector extends StatefulWidget {
  const MonthSelector({
    super.key,
    this.initialMonth,
    this.initialYear,
    this.onChanged,
  });

  /// Mois initial (1-12). Défaut : mois courant.
  final int? initialMonth;

  /// Année initiale. Défaut : année courante.
  final int? initialYear;

  /// Callback appelé à chaque changement de mois/année.
  final void Function(int month, int year)? onChanged;

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  late int _month;
  late int _year;

  static final DateFormat _dateFormat = DateFormat('MMMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialMonth = widget.initialMonth;
    if (initialMonth != null && initialMonth >= 1 && initialMonth <= 12) {
      _month = initialMonth;
      _year = widget.initialYear ?? now.year;
    } else {
      _month = now.month;
      _year = now.year;
    }
  }

  String get _formattedLabel {
    final raw = _dateFormat.format(DateTime(_year, _month));
    return raw[0].toUpperCase() + raw.substring(1);
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
    widget.onChanged?.call(_month, _year);
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
    widget.onChanged?.call(_month, _year);
  }

  Widget _buildNavButton({
    required PhosphorIconData icon,
    required VoidCallback onPressed,
    required String semanticsLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticsLabel,
      button: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.round),
            boxShadow: AppShadows.sm,
          ),
          child: IconButton(
            icon: PhosphorIcon(icon),
            onPressed: onPressed,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNavButton(
          icon: PhosphorIconsRegular.caretLeft,
          onPressed: _prevMonth,
          semanticsLabel: 'Mois précédent',
        ),
        const SizedBox(width: AppSpacing.space4),
        Flexible(
          child: Text(
            _formattedLabel,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTypography.sizeLg,
              fontWeight: AppTypography.semiBold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space4),
        _buildNavButton(
          icon: PhosphorIconsRegular.caretRight,
          onPressed: _nextMonth,
          semanticsLabel: 'Mois suivant',
        ),
      ],
    );
  }
}
