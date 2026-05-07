import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const List<String> _kMonthNames = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

const List<String> _kDayHeaders = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

// ---------------------------------------------------------------------------
// T-024 — Model + helpers privés
// ---------------------------------------------------------------------------

/// Représente un jour dans la grille du calendrier.
class _CalendarDay {
  final DateTime date;
  final int dayNumber;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;

  /// Vrai si le jour est la valeur originale en mode édition.
  /// Toujours `false` quand [isSelected] est `true` (la sélection prime).
  final bool isOriginal;
  final bool isDisabled;
  final String isoDate;

  const _CalendarDay({
    required this.date,
    required this.dayNumber,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.isOriginal,
    required this.isDisabled,
    required this.isoDate,
  });
}

/// Convertit un [DateTime] en `'YYYY-MM-DD'`.
String _toIsoDate(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parse une chaîne ISO `'YYYY-MM-DD'` en [DateTime].
/// Retourne `null` si [iso] est null ou si le format est invalide.
DateTime? _isoToDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    final parts = iso.split('-');
    if (parts.length != 3) return null;
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime(y, m, d);
  } catch (_) {
    return null;
  }
}

/// Retourne l'offset (0–6) permettant d'aligner le 1er jour du mois avec
/// lundi-first. Dart : `weekday` 1=lundi → offset 0, 7=dimanche → offset 6.
int _normalizeStartOffset(DateTime firstDay) {
  final offset = firstDay.weekday - 1;
  return offset < 0 ? 6 : offset;
}

// ---------------------------------------------------------------------------
// T-025 — Sub-widgets privés
// ---------------------------------------------------------------------------

/// Header du calendrier : `[‹] [Mois Année cliquable] [›]`.
class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
    required this.onLabelTap,
  });

  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onLabelTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: PhosphorIconsRegular.caretLeft,
            onTap: onPrev,
            colorScheme: colorScheme,
          ),
          Expanded(
            child: InkWell(
              onTap: onLabelTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space1,
                  horizontal: AppSpacing.space2,
                ),
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          _NavButton(
            icon: PhosphorIconsRegular.caretRight,
            onTap: onNext,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

/// Bouton de navigation (précédent / suivant) 28×28 cercle avec bordure.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: AppSpacing.space7,
        height: AppSpacing.space7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: AppTypography.sizeSm,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Grille 7 colonnes : ligne de headers `L M M J V S D` + cellules jours.
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.onSelectDay,
  });

  final List<_CalendarDay> days;
  final ValueChanged<_CalendarDay> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Ligne de headers de jours
    final headerRow = Row(
      children: _kDayHeaders
          .map(
            (h) => Expanded(
              child: SizedBox(
                height: AppSpacing.space7,
                child: Center(
                  child: Text(
                    h,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );

    // Lignes de jours (par blocs de 7)
    final dayRows = <Widget>[];
    for (var i = 0; i < days.length; i += 7) {
      final slice = days.sublist(i, (i + 7).clamp(0, days.length));
      dayRows.add(
        Row(
          children: slice
              .map(
                (day) => Expanded(
                  child: _DayCell(
                    day: day,
                    onTap: onSelectDay,
                  ),
                ),
              )
              .toList(),
        ),
      );
      if (i + 7 < days.length) {
        dayRows.add(const SizedBox(height: 2));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [headerRow, ...dayRows],
    );
  }
}

/// Cellule jour 36×36 cercle complet avec états visuels.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.onTap,
  });

  final _CalendarDay day;
  final ValueChanged<_CalendarDay> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<AppThemeExtension>()!;

    // Jours hors-mois ou désactivés : opacité + non-tappable
    if (!day.isCurrentMonth || day.isDisabled) {
      return Opacity(
        opacity: 0.3,
        child: _buildCell(
          context,
          colorScheme: colorScheme,
          themeExt: themeExt,
          tappable: false,
        ),
      );
    }

    return _buildCell(
      context,
      colorScheme: colorScheme,
      themeExt: themeExt,
      tappable: true,
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required ColorScheme colorScheme,
    required AppThemeExtension themeExt,
    required bool tappable,
  }) {
    final Color bgColor;
    final Color textColor;
    final FontWeight fontWeight;
    BoxBorder? border;

    if (day.isSelected) {
      bgColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      fontWeight = FontWeight.w600;
      border = null;
    } else if (day.isOriginal) {
      bgColor = themeExt.hoverSubtle;
      textColor = colorScheme.onSurfaceVariant;
      fontWeight = FontWeight.w500;
      border = null;
    } else if (day.isToday) {
      bgColor = Colors.transparent;
      textColor = colorScheme.onSurface;
      fontWeight = FontWeight.w400;
      border = Border.all(color: colorScheme.outlineVariant, width: 1);
    } else {
      bgColor = Colors.transparent;
      textColor = colorScheme.onSurfaceVariant;
      fontWeight = FontWeight.w400;
      border = null;
    }

    final cell = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: border,
      ),
      child: Center(
        child: Text(
          day.dayNumber.toString(),
          style: TextStyle(
            fontSize: AppTypography.sizeSm,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );

    if (!tappable) return cell;

    return InkWell(
      onTap: () => onTap(day),
      customBorder: const CircleBorder(),
      child: cell,
    );
  }
}

// ---------------------------------------------------------------------------
// T-026 — Public widget InlineDatePicker
// ---------------------------------------------------------------------------

/// Sélecteur de date inline custom Flutter (sans dialog, sans overlay).
///
/// Reproduit fidèlement le composant Angular `<app-inline-date-picker>` :
/// calendrier 7 colonnes, lundi-first hardcodé, cellules cercle 36×36,
/// support du mode édition via [originalValue].
///
/// Le format d'entrée/sortie est `'YYYY-MM-DD'` (ISO 8601).
/// La conversion vers [DateTime] est à la charge du consommateur.
///
/// Exemple d'usage :
/// ```dart
/// InlineDatePicker(
///   value: '2026-05-15',
///   onChanged: (iso) => print('Nouvelle date : $iso'),
///   originalValue: '2026-05-01', // mode édition
///   minDate: '2026-01-01',
///   maxDate: '2026-12-31',
/// )
/// ```
class InlineDatePicker extends StatefulWidget {
  /// Crée un sélecteur de date inline.
  const InlineDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.originalValue,
    this.minDate,
    this.maxDate,
  });

  /// Date sélectionnée au format ISO `'YYYY-MM-DD'` (ex : `'2026-05-07'`).
  final String value;

  /// Callback déclenché quand l'utilisateur sélectionne un jour.
  /// Reçoit la nouvelle ISO `'YYYY-MM-DD'`.
  final ValueChanged<String> onChanged;

  /// Date initiale en mode édition (ISO). La cellule correspondante est mise
  /// en valeur discrète ([AppThemeExtension.hoverSubtle]) tant que
  /// [value] != [originalValue].
  final String? originalValue;

  /// Borne inférieure ISO. Les jours antérieurs sont désactivés.
  final String? minDate;

  /// Borne supérieure ISO. Les jours postérieurs sont désactivés.
  final String? maxDate;

  @override
  State<InlineDatePicker> createState() => _InlineDatePickerState();
}

class _InlineDatePickerState extends State<InlineDatePicker> {
  late int _currentMonth;
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    final parsed = _isoToDate(widget.value);
    final ref = parsed ?? DateTime.now();
    _currentMonth = ref.month;
    _currentYear = ref.year;
  }

  /// Label du mois courant : `'Mai 2026'` (première lettre capitalisée).
  String get _monthLabel {
    final name = _kMonthNames[_currentMonth - 1];
    final capitalized = name[0].toUpperCase() + name.substring(1);
    return '$capitalized $_currentYear';
  }

  void _prevMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear -= 1;
      } else {
        _currentMonth -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear += 1;
      } else {
        _currentMonth += 1;
      }
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = now.month;
      _currentYear = now.year;
    });
  }

  void _selectDay(_CalendarDay day) {
    if (day.isDisabled) return;
    widget.onChanged(day.isoDate);
  }

  List<_CalendarDay> _computeDays() {
    final month = _currentMonth;
    final year = _currentYear;
    final selectedIso = widget.value;
    final originalIso = widget.originalValue;
    final hasOriginal = originalIso != null && originalIso.isNotEmpty;
    final hasChanged = hasOriginal && selectedIso != originalIso;
    final minIso = widget.minDate;
    final maxIso = widget.maxDate;

    final todayIso = _toIsoDate(DateTime.now());

    final firstDay = DateTime(year, month, 1);
    final startOffset = _normalizeStartOffset(firstDay);

    final days = <_CalendarDay>[];

    // Jours du mois précédent pour combler l'offset du début
    for (var i = startOffset; i > 0; i--) {
      final date = DateTime(year, month, 1 - i);
      final iso = _toIsoDate(date);
      days.add(_CalendarDay(
        date: date,
        dayNumber: date.day,
        isCurrentMonth: false,
        isToday: iso == todayIso,
        isSelected: false,
        isOriginal: false,
        isDisabled: true,
        isoDate: iso,
      ));
    }

    // Jours du mois courant
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final iso = _toIsoDate(date);

      var isDisabled = false;
      if (minIso != null && minIso.isNotEmpty && iso.compareTo(minIso) < 0) {
        isDisabled = true;
      }
      if (maxIso != null && maxIso.isNotEmpty && iso.compareTo(maxIso) > 0) {
        isDisabled = true;
      }

      // Logique isSelected alignée sur Angular (ligne 128)
      final isSelected = hasOriginal
          ? (hasChanged ? iso == selectedIso : false)
          : iso == selectedIso;

      // isOriginal masqué si isSelected (la sélection prime — Angular ligne 136)
      final isOriginal = hasOriginal ? (iso == originalIso && !isSelected) : false;

      days.add(_CalendarDay(
        date: date,
        dayNumber: d,
        isCurrentMonth: true,
        isToday: iso == todayIso,
        isSelected: isSelected,
        isOriginal: isOriginal,
        isDisabled: isDisabled,
        isoDate: iso,
      ));
    }

    // Jours du mois suivant pour compléter la dernière ligne (multiple de 7)
    final remainder = days.length % 7;
    if (remainder > 0) {
      final toAdd = 7 - remainder;
      for (var i = 1; i <= toAdd; i++) {
        final date = DateTime(year, month + 1, i);
        final iso = _toIsoDate(date);
        days.add(_CalendarDay(
          date: date,
          dayNumber: i,
          isCurrentMonth: false,
          isToday: iso == todayIso,
          isSelected: false,
          isOriginal: false,
          isDisabled: true,
          isoDate: iso,
        ));
      }
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarHeader(
            monthLabel: _monthLabel,
            onPrev: _prevMonth,
            onNext: _nextMonth,
            onLabelTap: _goToToday,
          ),
          _CalendarGrid(
            days: _computeDays(),
            onSelectDay: _selectDay,
          ),
        ],
      ),
    );
  }
}
