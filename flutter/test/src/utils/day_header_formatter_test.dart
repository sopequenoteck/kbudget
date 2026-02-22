import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/utils/day_header_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('DayHeaderFormatter', () {
    test('should_return_aujourdhui_when_date_is_today', () {
      final today = DateTime.now();
      expect(DayHeaderFormatter.format(today), "Aujourd'hui");
    });

    test('should_return_hier_when_date_is_yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DayHeaderFormatter.format(yesterday), 'Hier');
    });

    test('should_return_full_format_when_date_is_older', () {
      final date = DateTime(2026, 2, 20); // Vendredi 20 février
      final result = DayHeaderFormatter.format(date);
      expect(result, contains('20'));
      expect(result, contains('évrier'));
      expect(result[0], result[0].toUpperCase());
    });

    test('should_capitalize_first_letter_when_formatted', () {
      final date = DateTime(2026, 1, 15); // Jeudi 15 janvier
      final result = DayHeaderFormatter.format(date);
      expect(result[0], result[0].toUpperCase());
    });
  });
}
