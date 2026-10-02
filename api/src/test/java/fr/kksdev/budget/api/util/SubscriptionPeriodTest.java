package fr.kksdev.budget.api.util;

import fr.kksdev.budget.api.enums.Frequency;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.time.LocalDate;
import java.time.Month;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

class SubscriptionPeriodTest {

    private static LocalDate date(int year, Month month, int day) {
        return LocalDate.of(year, month, day);
    }

    static Stream<Arguments> periods() {
        LocalDate start = date(2026, Month.JANUARY, 5);
        return Stream.of(
                Arguments.of("monthly, day of the boundary", start, Frequency.MENSUEL, date(2026, Month.OCTOBER, 5),
                        date(2026, Month.OCTOBER, 5), date(2026, Month.NOVEMBER, 5)),
                Arguments.of("monthly, day before the boundary", start, Frequency.MENSUEL, date(2026, Month.OCTOBER, 4),
                        date(2026, Month.SEPTEMBER, 5), date(2026, Month.OCTOBER, 5)),
                Arguments.of("monthly, middle of the period", start, Frequency.MENSUEL, date(2026, Month.OCTOBER, 20),
                        date(2026, Month.OCTOBER, 5), date(2026, Month.NOVEMBER, 5)),
                Arguments.of("monthly, start date itself", start, Frequency.MENSUEL, start,
                        start, date(2026, Month.FEBRUARY, 5)),
                Arguments.of("monthly, before the start date", start, Frequency.MENSUEL, date(2026, Month.JANUARY, 1),
                        date(2025, Month.DECEMBER, 5), start),
                Arguments.of("monthly, long before the start date", start, Frequency.MENSUEL, date(2025, Month.JUNE, 20),
                        date(2025, Month.JUNE, 5), date(2025, Month.JULY, 5)),
                Arguments.of("weekly", start, Frequency.HEBDOMADAIRE, date(2026, Month.JANUARY, 18),
                        date(2026, Month.JANUARY, 12), date(2026, Month.JANUARY, 19)),
                Arguments.of("yearly", start, Frequency.ANNUEL, date(2026, Month.OCTOBER, 2),
                        start, date(2027, Month.JANUARY, 5)),
                Arguments.of("yearly, second year", start, Frequency.ANNUEL, date(2027, Month.MARCH, 2),
                        date(2027, Month.JANUARY, 5), date(2028, Month.JANUARY, 5)));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("periods")
    void should_find_the_period_that_contains_the_day(String description, LocalDate startDate, Frequency frequency,
                                                      LocalDate day, LocalDate expectedStart, LocalDate expectedEnd) {
        SubscriptionPeriod period = SubscriptionPeriod.containing(startDate, frequency, day);

        assertThat(period.start()).isEqualTo(expectedStart);
        assertThat(period.endExclusive()).isEqualTo(expectedEnd);
        assertThat(period.end()).isEqualTo(expectedEnd.minusDays(1));
        assertThat(day).isBetween(period.start(), period.end());
    }

    @Test
    void should_compute_every_boundary_from_the_start_date_when_the_start_is_at_the_end_of_a_month() {
        LocalDate start = date(2026, Month.JANUARY, 31);

        SubscriptionPeriod february = SubscriptionPeriod.containing(start, Frequency.MENSUEL, date(2026, Month.FEBRUARY, 28));
        SubscriptionPeriod march = SubscriptionPeriod.containing(start, Frequency.MENSUEL, date(2026, Month.MARCH, 31));

        assertThat(february.start()).isEqualTo(date(2026, Month.FEBRUARY, 28));
        assertThat(february.endExclusive()).isEqualTo(date(2026, Month.MARCH, 31));
        assertThat(march.start()).isEqualTo(date(2026, Month.MARCH, 31));
    }
}
