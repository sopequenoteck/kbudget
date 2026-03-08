/// Helpers partagés pour la gestion du mois sélectionné dans les écrans budget.
mixin BudgetMonthHelpers {
  int get selectedMonth;
  int get selectedYear;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth == now.month && selectedYear == now.year;
  }

  String get historyMonth {
    final m = selectedMonth.toString().padLeft(2, '0');
    return '$selectedYear-$m';
  }

  bool isPastMonthLimit(int month, int year) {
    final now = DateTime.now();
    final limit = DateTime(now.year, now.month - 12);
    final selected = DateTime(year, month);
    return selected.isBefore(limit);
  }
}
