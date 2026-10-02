package fr.kksdev.budget.api.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class StatementHeaderSpecTest {

    private static final String SG_HEADER = "00000000001596;15/09/2026;01/10/2026;24;01/10/2026;1842.37 EUR";
    private static final List<String> SG_LINES = List.of(SG_HEADER);

    private static final String DD_MM_YYYY = "dd/MM/yyyy";

    private final StatementHeaderSpec sg = StatementHeaderSpec.of(0, ";", 0, 5, 4, DD_MM_YYYY, ".");

    // -------------------------------------------------------------------------
    // Nominal: the Société Générale header
    // -------------------------------------------------------------------------

    @Test
    void should_extract_account_number_when_field_is_a_plain_number() {
        assertThat(sg.accountNumber(SG_LINES)).contains("00000000001596");
    }

    @Test
    void should_extract_digits_only_when_account_field_is_wrapped_in_quotes() {
        List<String> quoted = List.of("=\"00000000001596\";15/09/2026;01/10/2026;24;01/10/2026;1842.37 EUR");

        assertThat(sg.accountNumber(quoted)).contains("00000000001596");
    }

    @Test
    void should_return_last_four_digits_when_asking_for_account_suffix() {
        assertThat(sg.accountSuffix(SG_LINES)).contains("1596");
    }

    @Test
    void should_extract_balance_when_field_holds_amount_and_currency() {
        assertThat(sg.balance(SG_LINES, ",")).contains(new BigDecimal("1842.37"));
    }

    @Test
    void should_extract_balance_date_when_field_matches_format() {
        assertThat(sg.balanceDate(SG_LINES)).contains(LocalDate.of(2026, Month.OCTOBER, 1));
    }

    // -------------------------------------------------------------------------
    // Account number
    // -------------------------------------------------------------------------

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "FR76 3000 6000 0112 3456 7890 189|7630006000011234567890189|0189",
            "=\"0001234567\"|0001234567|4567",
            "12345|12345|2345",
            "1234|1234|1234"
    })
    void should_normalize_account_number_and_keep_four_digits_when_at_least_four(String raw, String digits, String suffix) {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", 0, null, null, null, null);

        assertThat(spec.accountNumber(List.of(raw))).contains(digits);
        assertThat(spec.accountSuffix(List.of(raw))).contains(suffix);
    }

    @Test
    void should_return_number_but_no_suffix_when_account_has_fewer_than_four_digits() {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", 0, null, null, null, null);

        assertThat(spec.accountNumber(List.of("=\"123\";x"))).contains("123");
        assertThat(spec.accountSuffix(List.of("=\"123\";x"))).isEmpty();
    }

    @ParameterizedTest
    @ValueSource(strings = {"=\"\";x", "ABC;x", ";x", "   ;x"})
    void should_return_empty_when_account_field_has_no_digit(String line) {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", 0, null, null, null, null);

        assertThat(spec.accountNumber(List.of(line))).isEmpty();
        assertThat(spec.accountSuffix(List.of(line))).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Balance
    // -------------------------------------------------------------------------

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "x;1842,37 EUR|1842.37",
            "x;-1842,37 EUR|-1842.37",
            "x;+12,5|12.5",
            "x;0,00 EUR|0.00",
            "x;1 842,37 EUR|1842.37",
            "x;-1 842,37 EUR|-1842.37",
            "x;EUR -12,00|-12.00",
            "x;7 EUR|7"
    })
    void should_read_balance_with_comma_decimal_separator_when_currency_and_spaces_surround_it(String line, String expected) {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", null, 1, null, null, null);

        assertThat(spec.balance(List.of(line), ",")).contains(new BigDecimal(expected));
    }

    @Test
    void should_read_balance_with_dot_decimal_separator_when_thousands_use_comma() {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", null, 1, null, null, null);

        assertThat(spec.balance(List.of("x;-1,842.37 USD"), ".")).contains(new BigDecimal("-1842.37"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"x;EUR", "x;", "x;abc", "x;12-3", "x;1,2,3 EUR", "x;--5"})
    void should_return_empty_balance_when_value_is_unreadable(String line) {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", null, 1, null, null, null);

        assertThat(spec.balance(List.of(line), ",")).isEmpty();
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {",,", "ab"})
    void should_return_empty_balance_when_decimal_separator_is_not_a_single_character(String decimalSeparator) {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", 0, 5, 4, DD_MM_YYYY, null);

        assertThat(spec.balance(SG_LINES, decimalSeparator)).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Balance: decimal separator of the header
    // -------------------------------------------------------------------------

    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
            "1842.37 EUR|1842.37",
            "-1842.37 EUR|-1842.37",
            "0.00 EUR|0.00",
            "1 842.37 EUR|1842.37",
            "1,842.37 EUR|1842.37"
    })
    void should_read_balance_when_header_declares_dot_and_operations_use_comma(String balance, String expected) {
        List<String> lines = List.of("00000000001596;15/09/2026;01/10/2026;24;01/10/2026;" + balance);

        assertThat(sg.balance(lines, ",")).contains(new BigDecimal(expected));
    }

    @ParameterizedTest
    @CsvSource(nullValues = "null", value = {
            "., ',', '1842.37 EUR', 1842.37",
            "., null, '1842.37 EUR', 1842.37",
            "',', '.', '1842,37 EUR', 1842.37",
            "null, ',', '1842,37 EUR', 1842.37",
            "null, '.', '1842.37 EUR', 1842.37"
    })
    void should_prefer_the_header_decimal_separator_over_the_one_of_the_profile_when_declared(
            String headerSeparator, String profileSeparator, String balance, String expected) {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", null, 1, null, null, headerSeparator);

        assertThat(spec.balance(List.of("x;" + balance), profileSeparator)).contains(new BigDecimal(expected));
    }

    @Test
    void should_return_empty_balance_when_neither_header_nor_profile_gives_a_separator() {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", null, 1, null, null, null);

        assertThat(spec.balance(List.of("x;1842.37 EUR"), null)).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Balance date
    // -------------------------------------------------------------------------

    @ParameterizedTest
    @ValueSource(strings = {"x;not a date", "x;2026-10-01", "x;", "x;99/99/2026"})
    void should_return_empty_balance_date_when_value_is_unreadable(String line) {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", null, null, 1, DD_MM_YYYY, null);

        assertThat(spec.balanceDate(List.of(line))).isEmpty();
    }

    @Test
    void should_read_balance_date_when_format_is_not_the_default_one() {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", null, null, 1, "yyyy-MM-dd", null);

        assertThat(spec.balanceDate(List.of("x;2026-02-28"))).contains(LocalDate.of(2026, Month.FEBRUARY, 28));
    }

    // -------------------------------------------------------------------------
    // Missing line, missing field
    // -------------------------------------------------------------------------

    @Test
    void should_return_empty_when_no_line_was_skipped() {
        assertThat(sg.accountNumber(List.of())).isEmpty();
        assertThat(sg.accountSuffix(List.of())).isEmpty();
        assertThat(sg.balance(List.of(), ",")).isEmpty();
        assertThat(sg.balanceDate(List.of())).isEmpty();
    }

    @Test
    void should_return_empty_when_header_line_index_is_beyond_the_skipped_lines() {
        StatementHeaderSpec secondLine = StatementHeaderSpec.of(1, ";", 0, 5, 4, DD_MM_YYYY, null);

        assertThat(secondLine.accountNumber(SG_LINES)).isEmpty();
    }

    @Test
    void should_read_the_declared_line_when_it_is_not_the_first() {
        StatementHeaderSpec secondLine = StatementHeaderSpec.of(1, ";", 0, null, null, null, null);

        assertThat(secondLine.accountSuffix(List.of("bank name", SG_HEADER))).contains("1596");
    }

    @Test
    void should_return_empty_when_field_index_is_beyond_the_fields_of_the_line() {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", 9, 9, 9, DD_MM_YYYY, null);

        assertThat(spec.accountNumber(SG_LINES)).isEmpty();
        assertThat(spec.balance(SG_LINES, ",")).isEmpty();
        assertThat(spec.balanceDate(SG_LINES)).isEmpty();
    }

    @Test
    void should_return_empty_when_the_field_is_not_declared_by_the_spec() {
        StatementHeaderSpec accountOnly = StatementHeaderSpec.of(0, ";", 0, null, null, null, null);

        assertThat(accountOnly.balance(SG_LINES, ",")).isEmpty();
        assertThat(accountOnly.balanceDate(SG_LINES)).isEmpty();
    }

    @Test
    void should_return_empty_when_the_last_field_is_empty_after_a_trailing_separator() {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, ";", null, 2, null, null, null);

        assertThat(spec.balance(List.of("a;b;"), ",")).isEmpty();
    }

    @Test
    void should_split_on_a_separator_that_is_a_regex_metacharacter() {
        StatementHeaderSpec spec = StatementHeaderSpec.of(0, "|", 0, null, null, null, null);

        assertThat(spec.accountSuffix(List.of("00001596|x"))).contains("1596");
    }

    // -------------------------------------------------------------------------
    // Factory validation
    // -------------------------------------------------------------------------

    static Stream<Arguments> incoherentSpecs() {
        return Stream.of(
                Arguments.of("negative line", -1, ";", 0, null, null, null, "line"),
                Arguments.of("null separator", 0, null, 0, null, null, null, "separator"),
                Arguments.of("empty separator", 0, "", 0, null, null, null, "separator"),
                Arguments.of("long separator", 0, ";;", 0, null, null, null, "separator"),
                Arguments.of("negative account field", 0, ";", -1, null, null, null, "negative"),
                Arguments.of("negative balance field", 0, ";", null, -1, null, null, "negative"),
                Arguments.of("negative balance date field", 0, ";", null, null, -1, DD_MM_YYYY, "negative"),
                Arguments.of("no field", 0, ";", null, null, null, null, "at least one field"),
                Arguments.of("balance date without format", 0, ";", null, null, 4, null, "balanceDateFormat"),
                Arguments.of("balance date with empty format", 0, ";", null, null, 4, "", "balanceDateFormat"),
                Arguments.of("balance date with blank format", 0, ";", null, null, 4, "  ", "balanceDateFormat"),
                Arguments.of("balance date with invalid format", 0, ";", null, null, 4, "dd/MM{", "Pattern"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"", ",,", "ab"})
    void should_reject_spec_when_header_decimal_separator_is_not_a_single_character(String decimalSeparator) {
        assertThatThrownBy(() -> StatementHeaderSpec.of(0, ";", null, 5, null, null, decimalSeparator))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("statementHeader.decimalSeparator must be a single character");
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("incoherentSpecs")
    void should_reject_spec_when_it_is_incoherent(String description, int line, String separator,
                                                  Integer accountField, Integer balanceField,
                                                  Integer balanceDateField, String balanceDateFormat,
                                                  String expectedMessage) {
        assertThatThrownBy(() -> StatementHeaderSpec.of(line, separator, accountField, balanceField,
                balanceDateField, balanceDateFormat, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining(expectedMessage);
    }
}
