package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.service.ImportProfileRegistry.ImportProfileConfig;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.io.StringReader;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ImportProfileFileParserTest {

    private static final String VALID = """
            formatVersion: 1
            bankCode: "tb"
            name: "Test Bank"
            separator: ";"
            encoding: "ISO-8859-1"
            dateFormat: "dd/MM/yyyy"
            dateColumn: "Date"
            amountColumn: "Amount"
            labelColumn: "Label"
            decimalSeparator: ","
            skipHeaderLines: 2
            cleanupPatterns:
              - 'CARD\\s+\\d{4}'
            signature:
              headerColumns:
                - "Date"
                - "Label"
            statementHeader:
              line: 1
              separator: "|"
              accountNumberField: 0
              balanceField: 2
              balanceDateField: 1
              balanceDateFormat: "dd/MM/yyyy"
            purchaseDate:
              pattern: 'CARD (\\d{2}/\\d{2})'
              format: "dd/MM"
            """;

    private static ImportProfileConfig parse(String yaml) {
        return ImportProfileFileParser.parse(new StringReader(yaml));
    }

    // -------------------------------------------------------------------------
    // Valid files
    // -------------------------------------------------------------------------

    @Test
    void should_read_every_field_when_file_is_complete() {
        ImportProfileConfig config = parse(VALID);

        assertThat(config.bankCode()).isEqualTo("TB");
        assertThat(config.name()).isEqualTo("Test Bank");
        assertThat(config.separator()).isEqualTo(";");
        assertThat(config.encoding()).isEqualTo("ISO-8859-1");
        assertThat(config.dateFormat()).isEqualTo("dd/MM/yyyy");
        assertThat(config.dateColumn()).isEqualTo("Date");
        assertThat(config.amountColumn()).isEqualTo("Amount");
        assertThat(config.debitColumn()).isNull();
        assertThat(config.creditColumn()).isNull();
        assertThat(config.labelColumn()).isEqualTo("Label");
        assertThat(config.decimalSeparator()).isEqualTo(",");
        assertThat(config.skipHeaderLines()).isEqualTo(2);
        assertThat(config.cleanupPatterns()).containsExactly("CARD\\s+\\d{4}");
        assertThat(config.signatureColumns()).containsExactly("Date", "Label");
        assertThat(config.statementHeader().line()).isEqualTo(1);
        assertThat(config.statementHeader().balance(List.of("", "12345|01/10/2026|1 842,37 EUR"), ","))
                .contains(new BigDecimal("1842.37"));
        assertThat(config.statementHeader().balanceDate(List.of("", "12345|01/10/2026|1 842,37 EUR")))
                .contains(LocalDate.of(2026, Month.OCTOBER, 1));
        assertThat(config.purchaseDate().extract("CARD 14/09 SHOP", LocalDate.of(2026, Month.SEPTEMBER, 16)))
                .contains(LocalDate.of(2026, Month.SEPTEMBER, 14));
    }

    @Test
    void should_read_the_header_decimal_separator_when_the_file_declares_it() {
        String yaml = VALID.replace("  balanceDateFormat: \"dd/MM/yyyy\"\n",
                "  balanceDateFormat: \"dd/MM/yyyy\"\n  decimalSeparator: \".\"\n");

        ImportProfileConfig config = parse(yaml);

        assertThat(config.decimalSeparator()).isEqualTo(",");
        assertThat(config.statementHeader().decimalSeparator()).isEqualTo(".");
        assertThat(config.statementHeader().balance(List.of("", "12345|01/10/2026|1842.37 EUR"), ","))
                .contains(new BigDecimal("1842.37"));
    }

    @Test
    void should_leave_the_header_decimal_separator_undeclared_when_the_file_omits_it() {
        ImportProfileConfig config = parse(VALID);

        assertThat(config.statementHeader().decimalSeparator()).isNull();
    }

    @Test
    void should_apply_defaults_when_optional_sections_are_absent() {
        String minimal = VALID.substring(0, VALID.indexOf("skipHeaderLines"))
                + """
                signature:
                  headerColumns: ["Date"]
                """;

        ImportProfileConfig config = parse(minimal);

        assertThat(config.skipHeaderLines()).isZero();
        assertThat(config.cleanupPatterns()).isEmpty();
        assertThat(config.statementHeader()).isNull();
        assertThat(config.purchaseDate()).isNull();
    }

    @Test
    void should_accept_debit_and_credit_columns_when_there_is_no_amount_column() {
        String yaml = VALID.replace("amountColumn: \"Amount\"", "debitColumn: \"Debit\"\ncreditColumn: \"Credit\"");

        ImportProfileConfig config = parse(yaml);

        assertThat(config.amountColumn()).isNull();
        assertThat(config.debitColumn()).isEqualTo("Debit");
        assertThat(config.creditColumn()).isEqualTo("Credit");
    }

    @Test
    void should_accept_a_tab_separator() {
        assertThat(parse(VALID.replace("separator: \";\"\n", "separator: \"\\t\"\n")).separator()).isEqualTo("\t");
    }

    @Test
    void should_treat_a_blank_optional_column_as_absent() {
        String yaml = VALID.replace("amountColumn: \"Amount\"", "amountColumn: \" \"\ndebitColumn: \"D\"\ncreditColumn: \"C\"");

        assertThat(parse(yaml).amountColumn()).isNull();
    }

    @Test
    void should_ignore_unknown_keys() {
        assertThat(parse(VALID + "futureKey: \"whatever\"\n").bankCode()).isEqualTo("TB");
    }

    // -------------------------------------------------------------------------
    // Invalid files
    // -------------------------------------------------------------------------

    static Stream<Arguments> invalidFiles() {
        return Stream.of(
                Arguments.of("missing formatVersion", VALID.replace("formatVersion: 1\n", ""), "formatVersion is required"),
                Arguments.of("unknown formatVersion", VALID.replace("formatVersion: 1", "formatVersion: 2"), "Unsupported formatVersion: 2"),
                Arguments.of("formatVersion as string", VALID.replace("formatVersion: 1", "formatVersion: \"1\""), "Unsupported formatVersion"),
                Arguments.of("empty document", "", "mapping"),
                Arguments.of("list at the root", "- a\n- b\n", "mapping"),
                Arguments.of("missing bankCode", VALID.replace("bankCode: \"tb\"\n", ""), "bankCode is required"),
                Arguments.of("blank name", VALID.replace("name: \"Test Bank\"", "name: \" \""), "name is required"),
                Arguments.of("unquoted number as name", VALID.replace("name: \"Test Bank\"", "name: 12"), "name must be a quoted string"),
                Arguments.of("missing separator", VALID.replace("separator: \";\"\n", ""), "separator must be a single character"),
                Arguments.of("long separator", VALID.replace("separator: \";\"\n", "separator: \";;\"\n"), "separator must be a single character"),
                Arguments.of("empty decimal separator", VALID.replace("decimalSeparator: \",\"", "decimalSeparator: \"\""), "decimalSeparator must be a single character"),
                Arguments.of("invalid date format", VALID.replace("dateFormat: \"dd/MM/yyyy\"", "dateFormat: \"dd/MM{\""), "Pattern"),
                Arguments.of("date format without year", VALID.replace("dateFormat: \"dd/MM/yyyy\"", "dateFormat: \"dd/MM\""), "dateFormat must read a full date"),
                Arguments.of("unknown encoding", VALID.replace("ISO-8859-1", "NOPE-9"), "Unsupported encoding: NOPE-9"),
                Arguments.of("illegal encoding name", VALID.replace("ISO-8859-1", "not a charset!"), "not a charset!"),
                Arguments.of("missing dateColumn", VALID.replace("dateColumn: \"Date\"\n", ""), "dateColumn is required"),
                Arguments.of("missing labelColumn", VALID.replace("labelColumn: \"Label\"\n", ""), "labelColumn is required"),
                Arguments.of("no amount column", VALID.replace("amountColumn: \"Amount\"\n", ""), "amountColumn"),
                Arguments.of("debit without credit", VALID.replace("amountColumn: \"Amount\"", "debitColumn: \"Debit\""), "amountColumn"),
                Arguments.of("credit without debit", VALID.replace("amountColumn: \"Amount\"", "creditColumn: \"Credit\""), "amountColumn"),
                Arguments.of("negative skipHeaderLines", VALID.replace("skipHeaderLines: 2", "skipHeaderLines: -1"), "skipHeaderLines"),
                Arguments.of("skipHeaderLines as string", VALID.replace("skipHeaderLines: 2", "skipHeaderLines: \"2\""), "skipHeaderLines"),
                Arguments.of("cleanupPatterns not a list", VALID.replace("cleanupPatterns:\n  - 'CARD\\s+\\d{4}'\n", "cleanupPatterns: \"CARD\"\n"), "cleanupPatterns must be a list"),
                Arguments.of("cleanup pattern with invalid regex", VALID.replace("'CARD\\s+\\d{4}'", "'[unclosed'"), "Unclosed character class"),
                Arguments.of("cleanup pattern blank", VALID.replace("'CARD\\s+\\d{4}'", "' '"), "non-blank strings"),
                Arguments.of("cleanup pattern not a string", VALID.replace("'CARD\\s+\\d{4}'", "12"), "non-blank strings"),
                Arguments.of("missing signature", VALID.replace("signature:\n  headerColumns:\n    - \"Date\"\n    - \"Label\"\n", ""), "signature is required"),
                Arguments.of("signature without headerColumns", VALID.replace("  headerColumns:\n    - \"Date\"\n    - \"Label\"\n", "  other: 1\n"), "signature.headerColumns must be a list"),
                Arguments.of("empty signature", VALID.replace("  headerColumns:\n    - \"Date\"\n    - \"Label\"\n", "  headerColumns: []\n"), "must not be empty"),
                Arguments.of("statementHeader not a mapping", VALID.substring(0, VALID.indexOf("statementHeader:")) + "statementHeader: \"x\"\n", "statementHeader must be a mapping"),
                Arguments.of("statementHeader without line", VALID.replace("  line: 1\n", ""), "line is required"),
                Arguments.of("statementHeader line as string", VALID.replace("line: 1", "line: \"1\""), "line must be an integer"),
                Arguments.of("statementHeader without separator", VALID.replace("  separator: \"|\"\n", ""), "separator"),
                Arguments.of("statementHeader without fields", VALID.replace("  accountNumberField: 0\n  balanceField: 2\n  balanceDateField: 1\n  balanceDateFormat: \"dd/MM/yyyy\"\n", ""), "at least one field"),
                Arguments.of("statementHeader decimalSeparator empty", VALID.replace("  balanceDateFormat: \"dd/MM/yyyy\"\n", "  balanceDateFormat: \"dd/MM/yyyy\"\n  decimalSeparator: \"\"\n"), "statementHeader.decimalSeparator must be a single character"),
                Arguments.of("statementHeader decimalSeparator too long", VALID.replace("  balanceDateFormat: \"dd/MM/yyyy\"\n", "  balanceDateFormat: \"dd/MM/yyyy\"\n  decimalSeparator: \"..\"\n"), "statementHeader.decimalSeparator must be a single character"),
                Arguments.of("statementHeader decimalSeparator not a string", VALID.replace("  balanceDateFormat: \"dd/MM/yyyy\"\n", "  balanceDateFormat: \"dd/MM/yyyy\"\n  decimalSeparator: 1\n"), "decimalSeparator must be a quoted string"),
                Arguments.of("purchaseDate not a mapping", VALID.substring(0, VALID.indexOf("purchaseDate:")) + "purchaseDate: 3\n", "purchaseDate must be a mapping"),
                Arguments.of("purchaseDate without group", VALID.replace("'CARD (\\d{2}/\\d{2})'", "'CARD \\d{2}/\\d{2}'"), "capturing group"),
                Arguments.of("purchaseDate without format", VALID.replace("  format: \"dd/MM\"\n", ""), "purchaseDate requires"),
                Arguments.of("malformed yaml", "formatVersion: [1\n", "")
        );
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("invalidFiles")
    void should_reject_file_when_it_is_invalid(String description, String yaml, String expectedMessage) {
        assertThatThrownBy(() -> parse(yaml))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining(expectedMessage);
    }
}
