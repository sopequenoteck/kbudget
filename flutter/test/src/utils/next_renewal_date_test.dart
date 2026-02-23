import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/utils/next_renewal_date.dart';

void main() {
  group('nextRenewalDate', () {
    test('should_return_next_month_when_monthly_and_date_past', () {
      final result = nextRenewalDate(
        DateTime(2026, 1, 15),
        Frequency.mensuel,
        today: DateTime(2026, 2, 20),
      );
      expect(result, DateTime(2026, 3, 15));
    });

    test('should_return_next_year_when_annual_and_date_past', () {
      final result = nextRenewalDate(
        DateTime(2025, 6, 1),
        Frequency.annuel,
        today: DateTime(2026, 2, 20),
      );
      expect(result, DateTime(2026, 6, 1));
    });

    test('should_return_start_date_when_date_in_future', () {
      final result = nextRenewalDate(
        DateTime(2026, 12, 1),
        Frequency.mensuel,
        today: DateTime(2026, 2, 20),
      );
      expect(result, DateTime(2026, 12, 1));
    });

    test('should_handle_month_overflow_when_day_31_monthly', () {
      // 31 janvier + 1 mois = 3 mars (28 fev deborde)
      // DateTime(2026, 2, 31) est normalise en DateTime(2026, 3, 3)
      final result = nextRenewalDate(
        DateTime(2026, 1, 31),
        Frequency.mensuel,
        today: DateTime(2026, 2, 1),
      );
      // DateTime(2026, 2, 31) => DateTime(2026, 3, 3)
      expect(result, DateTime(2026, 3, 3));
    });

    test('should_advance_multiple_periods_when_start_date_far_past', () {
      final result = nextRenewalDate(
        DateTime(2020, 3, 1),
        Frequency.mensuel,
        today: DateTime(2026, 2, 20),
      );
      expect(result, DateTime(2026, 3, 1));
    });

    test('should_advance_multiple_years_when_annual_start_date_far_past', () {
      final result = nextRenewalDate(
        DateTime(2020, 6, 15),
        Frequency.annuel,
        today: DateTime(2026, 2, 20),
      );
      expect(result, DateTime(2026, 6, 15));
    });

    test('should_return_next_period_when_today_equals_start_date', () {
      final result = nextRenewalDate(
        DateTime(2026, 2, 20),
        Frequency.mensuel,
        today: DateTime(2026, 2, 20),
      );
      expect(result, DateTime(2026, 3, 20));
    });
  });
}
