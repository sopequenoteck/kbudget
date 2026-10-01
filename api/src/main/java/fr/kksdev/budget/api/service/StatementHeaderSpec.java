package fr.kksdev.budget.api.service;

import java.math.BigDecimal;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.regex.Pattern;
import java.util.stream.Stream;

/**
 * Bank header of a statement file: the lines skipped before the column header
 * (KKS-440). It carries the account number, the balance and the balance date.
 *
 * <p>Extraction is pure: it reads the skipped lines given by the caller and
 * never throws. Any unreadable value is reported as absent.
 *
 * @param line              0-based index of the header line among the skipped lines
 * @param separator         field separator of that line
 * @param accountNumberField 0-based index of the account number field, or {@code null}
 * @param balanceField      0-based index of the balance field, or {@code null}
 * @param balanceDateField  0-based index of the balance date field, or {@code null}
 * @param balanceDateFormat format of the balance date, set when {@code balanceDateField} is
 */
public record StatementHeaderSpec(
        int line,
        String separator,
        Integer accountNumberField,
        Integer balanceField,
        Integer balanceDateField,
        DateTimeFormatter balanceDateFormat
) {

    private static final int ACCOUNT_SUFFIX_LENGTH = 4;

    /** Builds a spec, rejecting an incoherent one with an {@link IllegalArgumentException}. */
    public static StatementHeaderSpec of(int line, String separator, Integer accountNumberField,
                                         Integer balanceField, Integer balanceDateField,
                                         String balanceDateFormat) {
        if (line < 0) {
            throw new IllegalArgumentException("statementHeader.line must not be negative");
        }
        if (separator == null || separator.length() != 1) {
            throw new IllegalArgumentException("statementHeader.separator must be a single character");
        }
        requireValidFields(accountNumberField, balanceField, balanceDateField);
        return new StatementHeaderSpec(line, separator, accountNumberField, balanceField, balanceDateField,
                balanceDateFormatter(balanceDateField, balanceDateFormat));
    }

    private static void requireValidFields(Integer... fields) {
        List<Integer> declared = Stream.of(fields).filter(Objects::nonNull).toList();
        if (declared.isEmpty()) {
            throw new IllegalArgumentException("statementHeader must declare at least one field");
        }
        if (declared.stream().anyMatch(field -> field < 0)) {
            throw new IllegalArgumentException("statementHeader field indexes must not be negative");
        }
    }

    private static DateTimeFormatter balanceDateFormatter(Integer balanceDateField, String balanceDateFormat) {
        if (balanceDateField == null) {
            return null;
        }
        if (balanceDateFormat == null || balanceDateFormat.isBlank()) {
            throw new IllegalArgumentException("statementHeader.balanceDateFormat is required with balanceDateField");
        }
        return DateTimeFormatter.ofPattern(balanceDateFormat);
    }

    /** Account number reduced to its digits. */
    public Optional<String> accountNumber(List<String> skippedLines) {
        return field(skippedLines, accountNumberField)
                .map(raw -> raw.replaceAll("\\D", ""))
                .filter(digits -> !digits.isEmpty());
    }

    /** Last four digits of the account number; absent when it has fewer than four. */
    public Optional<String> accountSuffix(List<String> skippedLines) {
        return accountNumber(skippedLines)
                .filter(digits -> digits.length() >= ACCOUNT_SUFFIX_LENGTH)
                .map(digits -> digits.substring(digits.length() - ACCOUNT_SUFFIX_LENGTH));
    }

    /** Balance, read with the decimal separator of the profile; currency and spaces are dropped. */
    public Optional<BigDecimal> balance(List<String> skippedLines, String decimalSeparator) {
        if (decimalSeparator == null || decimalSeparator.length() != 1) {
            return Optional.empty();
        }
        return field(skippedLines, balanceField).flatMap(raw -> toAmount(raw, decimalSeparator));
    }

    public Optional<LocalDate> balanceDate(List<String> skippedLines) {
        return field(skippedLines, balanceDateField).flatMap(this::toDate);
    }

    private Optional<String> field(List<String> skippedLines, Integer index) {
        if (index == null || line >= skippedLines.size()) {
            return Optional.empty();
        }
        String[] fields = skippedLines.get(line).split(Pattern.quote(separator), -1);
        if (index >= fields.length) {
            return Optional.empty();
        }
        return Optional.of(fields[index].trim()).filter(value -> !value.isEmpty());
    }

    private static Optional<BigDecimal> toAmount(String raw, String decimalSeparator) {
        String cleaned = raw.replaceAll("[^0-9+\\-" + Pattern.quote(decimalSeparator) + "]", "")
                .replace(decimalSeparator, ".");
        try {
            return Optional.of(new BigDecimal(cleaned));
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }

    private Optional<LocalDate> toDate(String raw) {
        try {
            return Optional.of(LocalDate.parse(raw, balanceDateFormat));
        } catch (DateTimeException e) {
            return Optional.empty();
        }
    }
}
