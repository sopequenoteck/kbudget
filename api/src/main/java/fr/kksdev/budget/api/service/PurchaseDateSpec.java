package fr.kksdev.budget.api.service;

import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.MonthDay;
import java.time.format.DateTimeFormatter;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Purchase date carried by a card operation label, without its year (KKS-440).
 * The year is inferred from the booking date, since a purchase is never later
 * than its booking.
 *
 * <p>Extraction is pure and never throws: an unreadable value is reported as absent.
 *
 * @param pattern regex applied to the raw label, with one capturing group holding the date
 * @param format  format of the captured date, holding a day and a month (e.g. {@code dd/MM})
 */
public record PurchaseDateSpec(Pattern pattern, DateTimeFormatter format) {

    /** Builds a spec, rejecting an incoherent one with an {@link IllegalArgumentException}. */
    public static PurchaseDateSpec of(String pattern, String format) {
        if (pattern == null || pattern.isBlank() || format == null || format.isBlank()) {
            throw new IllegalArgumentException("purchaseDate requires a pattern and a format");
        }
        Pattern compiled = Pattern.compile(pattern);
        if (compiled.matcher("").groupCount() < 1) {
            throw new IllegalArgumentException("purchaseDate.pattern must have a capturing group");
        }
        return new PurchaseDateSpec(compiled, DateTimeFormatter.ofPattern(format));
    }

    /**
     * @param label       raw label of the operation
     * @param bookingDate booking date of the operation
     * @return the purchase date, absent when the label holds none, when it is
     *         unreadable, or when it would fall after the booking date
     */
    public Optional<LocalDate> extract(String label, LocalDate bookingDate) {
        if (label == null || bookingDate == null) {
            return Optional.empty();
        }
        Matcher matcher = pattern.matcher(label);
        if (!matcher.find() || matcher.group(1) == null) {
            return Optional.empty();
        }
        MonthDay monthDay;
        try {
            monthDay = MonthDay.parse(matcher.group(1).trim(), format);
        } catch (DateTimeException e) {
            return Optional.empty();
        }
        int year = monthDay.getMonth().compareTo(bookingDate.getMonth()) > 0
                ? bookingDate.getYear() - 1
                : bookingDate.getYear();
        if (!monthDay.isValidYear(year)) {
            return Optional.empty();
        }
        LocalDate purchase = monthDay.atYear(year);
        return purchase.isAfter(bookingDate) ? Optional.empty() : Optional.of(purchase);
    }
}
