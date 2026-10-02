package fr.kksdev.budget.api.util;

import fr.kksdev.budget.api.enums.Frequency;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * Billing period of a subscription (KKS-385): the period of its frequency that
 * contains a given day, counted from the start date of the subscription.
 *
 * <p>Every boundary is computed from the start date, never from the previous one:
 * a monthly subscription starting on January 31st is due on February 28th, then
 * on March 31st.
 *
 * @param start        first day of the period
 * @param endExclusive first day of the next period
 */
public record SubscriptionPeriod(LocalDate start, LocalDate endExclusive) {

    /**
     * Period containing {@code day}. A day before the start date falls in the
     * period that would have preceded it.
     */
    public static SubscriptionPeriod containing(LocalDate startDate, Frequency frequency, LocalDate day) {
        ChronoUnit unit = unitOf(frequency);
        long index = unit.between(startDate, day);
        while (startDate.plus(index, unit).isAfter(day)) {
            index--;
        }
        while (!startDate.plus(index + 1, unit).isAfter(day)) {
            index++;
        }
        return new SubscriptionPeriod(startDate.plus(index, unit), startDate.plus(index + 1, unit));
    }

    private static ChronoUnit unitOf(Frequency frequency) {
        return switch (frequency) {
            case HEBDOMADAIRE -> ChronoUnit.WEEKS;
            case MENSUEL -> ChronoUnit.MONTHS;
            case ANNUEL -> ChronoUnit.YEARS;
        };
    }

    /** Last day of the period. */
    public LocalDate end() {
        return endExclusive.minusDays(1);
    }
}
