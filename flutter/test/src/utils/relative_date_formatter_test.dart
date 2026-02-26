import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/utils/relative_date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('RelativeDateFormatter.format', () {
    test('should_return_empty_string_when_null', () {
      expect(RelativeDateFormatter.format(null), '');
    });

    test('should_return_aujourdhui_for_today', () {
      expect(RelativeDateFormatter.format(DateTime.now()), "Aujourd'hui");
    });

    test('should_return_hier_for_yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(RelativeDateFormatter.format(yesterday), 'Hier');
    });

    test('should_return_demain_for_tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(RelativeDateFormatter.format(tomorrow), 'Demain');
    });

    test('should_return_il_y_a_X_jours_for_2_to_7_days_ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(RelativeDateFormatter.format(threeDaysAgo), 'il y a 3 jours');
    });

    test('should_return_il_y_a_7_jours_for_exactly_7_days', () {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      expect(RelativeDateFormatter.format(sevenDaysAgo), 'il y a 7 jours');
    });

    test('should_return_il_y_a_1_semaine_for_8_to_13_days', () {
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
      expect(RelativeDateFormatter.format(eightDaysAgo), 'il y a 1 semaine');
    });

    test('should_return_il_y_a_2_semaines_for_14_to_20_days', () {
      final fourteenDaysAgo = DateTime.now().subtract(const Duration(days: 14));
      expect(
        RelativeDateFormatter.format(fourteenDaysAgo),
        'il y a 2 semaines',
      );
    });

    test('should_return_il_y_a_4_semaines_for_30_days', () {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      expect(
        RelativeDateFormatter.format(thirtyDaysAgo),
        'il y a 4 semaines',
      );
    });

    test('should_return_long_date_for_more_than_30_days', () {
      final oldDate = DateTime(2026, 1, 15);
      final result = RelativeDateFormatter.format(oldDate);
      expect(result, contains('janvier'));
      expect(result, contains('2026'));
      expect(result, contains('15'));
    });

    test('should_return_long_date_for_future_beyond_tomorrow', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final result = RelativeDateFormatter.format(futureDate);
      // Future > demain falls through to long date format
      expect(result, isNotEmpty);
      expect(result, isNot("Aujourd'hui"));
      expect(result, isNot('Demain'));
    });

    test('should_ignore_time_component', () {
      final todayLateNight = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        23,
        59,
        59,
      );
      expect(RelativeDateFormatter.format(todayLateNight), "Aujourd'hui");
    });
  });
}
