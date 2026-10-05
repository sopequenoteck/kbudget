package fr.kksdev.budget.api.service;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.ImportReadError;
import fr.kksdev.budget.api.model.ImportDraftLine;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;

/** Reading of the bank header lines skipped before the column header (KKS-384), purchase date of the lines (KKS-385), read errors of the lines (KKS-441). */
class CsvParsingServiceTest {

    private final CsvParsingService service = new CsvParsingService(
            mock(LabelCleaningService.class), mock(CategorySuggestionService.class));

    private final ImportProfileRegistry registry = new ImportProfileRegistry();

    private ListAppender<ILoggingEvent> logAppender;
    private Logger serviceLogger;

    @BeforeEach
    void setUpLogCapture() {
        serviceLogger = (Logger) LoggerFactory.getLogger(CsvParsingService.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        serviceLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDownLogCapture() {
        serviceLogger.detachAppender(logAppender);
    }

    private ImportProfileRegistry.ImportProfileConfig profile(String encoding, int skipHeaderLines) {
        return new ImportProfileRegistry.ImportProfileConfig(
                "XX", "Test", ";", "dd/MM/yyyy", "Date", "Amount", null, null, "Label", encoding, ",",
                skipHeaderLines, List.of(), List.of(), null, null);
    }

    @Test
    void should_read_the_bank_header_line_of_a_societe_generale_statement() {
        var sg = registry.findByBankCode("SG").orElseThrow();

        List<String> lines = service.readSkippedLines(ImportTestFiles.sgStatement(), sg);

        assertThat(lines).containsExactly("00000000001596;15/09/2026;01/10/2026;2;01/10/2026;1842.37 EUR");
    }

    @Test
    void should_decode_the_skipped_lines_with_the_encoding_of_the_profile() {
        byte[] content = "Société;1\n\nDate;Amount\n".getBytes(StandardCharsets.ISO_8859_1);

        assertThat(service.readSkippedLines(content, profile("ISO-8859-1", 1))).containsExactly("Société;1");
    }

    @ParameterizedTest
    @CsvSource({"0,0", "1,1", "2,2", "3,3", "10,3"})
    void should_read_at_most_the_lines_the_profile_skips_and_at_most_the_lines_of_the_file(
            int skipHeaderLines, int expectedCount) {
        byte[] content = "one\ntwo\nthree".getBytes(StandardCharsets.UTF_8);

        assertThat(service.readSkippedLines(content, profile("UTF-8", skipHeaderLines))).hasSize(expectedCount);
    }

    @Test
    void should_read_nothing_from_an_empty_file() {
        assertThat(service.readSkippedLines(new byte[0], profile("UTF-8", 2))).isEmpty();
    }

    @Test
    void should_read_nothing_when_the_encoding_of_the_profile_is_unknown() {
        assertThat(service.readSkippedLines("one\n".getBytes(StandardCharsets.UTF_8), profile("NOT-A-CHARSET", 1)))
                .isEmpty();
    }

    private ImportProfileRegistry.ImportProfileConfig profileWithPurchaseDate(PurchaseDateSpec purchaseDate) {
        return new ImportProfileRegistry.ImportProfileConfig(
                "XX", "Test", ";", "dd/MM/yyyy", "Date", "Amount", null, null, "Label", "UTF-8", ",",
                0, List.of(), List.of(), null, purchaseDate);
    }

    private List<ImportDraftLine> parse(String label, PurchaseDateSpec purchaseDate) {
        byte[] content = ("Date;Amount;Label\n24/08/2026;-12,50;" + label + "\n").getBytes(StandardCharsets.UTF_8);
        return service.parse(new ByteArrayInputStream(content), profileWithPurchaseDate(purchaseDate), UUID.randomUUID());
    }

    @Test
    void should_read_the_purchase_date_from_the_raw_label_and_keep_the_booking_date_when_the_profile_declares_one() {
        PurchaseDateSpec spec = PurchaseDateSpec.of("CARTE X\\d{4} (\\d{2}/\\d{2})", "dd/MM");

        ImportDraftLine line = parse("CARTE X0000 21/08 BOUTIQUE TEST", spec).getFirst();

        assertThat(line.getPurchaseDate()).isEqualTo(LocalDate.of(2026, Month.AUGUST, 21));
        assertThat(line.getDate()).isEqualTo(LocalDate.of(2026, Month.AUGUST, 24));
        assertThat(line.transactionDate()).isEqualTo(LocalDate.of(2026, Month.AUGUST, 21));
    }

    @ParameterizedTest(name = "label \"{0}\", profile declares a purchase date: {1}")
    @CsvSource({"PRELEVEMENT EUROPEEN OPERATEUR TEST, true", "CARTE X0000 21/08 BOUTIQUE TEST, false"})
    void should_leave_the_purchase_date_empty_when_the_label_carries_none_or_the_profile_declares_none(
            String label, boolean declared) {
        PurchaseDateSpec spec = declared ? PurchaseDateSpec.of("CARTE X\\d{4} (\\d{2}/\\d{2})", "dd/MM") : null;

        ImportDraftLine line = parse(label, spec).getFirst();

        assertThat(line.getPurchaseDate()).isNull();
        assertThat(line.transactionDate()).isEqualTo(LocalDate.of(2026, Month.AUGUST, 24));
    }

    private ImportProfileRegistry.ImportProfileConfig debitCreditProfile() {
        return new ImportProfileRegistry.ImportProfileConfig(
                "XX", "Test", ";", "dd/MM/yyyy", "Date", null, "Debit", "Credit", "Label", "UTF-8", ",",
                0, List.of(), List.of(), null, null);
    }

    private ImportDraftLine parseOne(ImportProfileRegistry.ImportProfileConfig profile, String content) {
        return service.parse(new ByteArrayInputStream(content.getBytes(StandardCharsets.UTF_8)), profile,
                UUID.randomUUID()).getFirst();
    }

    @Test
    void should_carry_no_read_error_when_the_line_is_read() {
        ImportDraftLine line = parse("BOUTIQUE TEST", null).getFirst();

        assertThat(line.getStatus()).isEqualTo(ImportLineStatus.READY);
        assertThat(line.getReadError()).isNull();
        assertThat(line.getReadErrorValue()).isNull();
        assertThat(line.getStatusMessage()).isNull();
    }

    @Test
    void should_report_an_invalid_date_with_its_raw_value_and_an_english_message_when_the_date_cannot_be_parsed() {
        ImportDraftLine line = parseOne(profile("UTF-8", 0), "Date;Amount;Label\n2026-08-24;-12,50;BOUTIQUE TEST\n");

        assertThat(line.getStatus()).isEqualTo(ImportLineStatus.NEEDS_REVIEW);
        assertThat(line.getReadError()).isEqualTo(ImportReadError.INVALID_DATE);
        assertThat(line.getReadErrorValue()).isEqualTo("2026-08-24");
        assertThat(line.getStatusMessage()).startsWith("Invalid date: ");
        assertThat(line.getRawLabel()).isEqualTo("BOUTIQUE TEST");
    }

    @Test
    void should_report_an_invalid_amount_with_the_raw_cell_when_the_profile_has_one_amount_column() {
        ImportDraftLine line = parseOne(profile("UTF-8", 0), "Date;Amount;Label\n24/08/2026;abc;BOUTIQUE TEST\n");

        assertThat(line.getStatus()).isEqualTo(ImportLineStatus.NEEDS_REVIEW);
        assertThat(line.getReadError()).isEqualTo(ImportReadError.INVALID_AMOUNT);
        assertThat(line.getReadErrorValue()).isEqualTo("abc");
        assertThat(line.getStatusMessage()).startsWith("Invalid amount: ");
    }

    @ParameterizedTest(name = "debit \"{0}\", credit \"{1}\" -> value \"{2}\"")
    @CsvSource({"x1,'',x1", "'',y2,y2", "x1,y2,x1"})
    void should_report_the_faulty_amount_cell_when_the_profile_has_debit_and_credit_columns(
            String debit, String credit, String expectedValue) {
        ImportDraftLine line = parseOne(debitCreditProfile(),
                "Date;Debit;Credit;Label\n24/08/2026;" + debit + ";" + credit + ";BOUTIQUE TEST\n");

        assertThat(line.getReadError()).isEqualTo(ImportReadError.INVALID_AMOUNT);
        assertThat(line.getReadErrorValue()).isEqualTo(expectedValue);
        assertThat(line.getStatusMessage()).startsWith("Invalid amount: ");
    }

    @Test
    void should_report_an_unreadable_line_without_value_when_no_debit_nor_credit_is_found() {
        ImportDraftLine line = parseOne(debitCreditProfile(), "Date;Debit;Credit;Label\n24/08/2026;;;BOUTIQUE TEST\n");

        assertThat(line.getStatus()).isEqualTo(ImportLineStatus.NEEDS_REVIEW);
        assertThat(line.getReadError()).isEqualTo(ImportReadError.UNREADABLE_LINE);
        assertThat(line.getReadErrorValue()).isNull();
        assertThat(line.getStatusMessage()).isEqualTo("Unreadable line: No amount found in the debit/credit columns");
    }

    @Test
    void should_report_an_unreadable_line_when_a_column_of_the_profile_is_missing_from_the_record() {
        ImportDraftLine line = parseOne(profile("UTF-8", 0), "Date;Label\n24/08/2026;BOUTIQUE TEST\n");

        assertThat(line.getReadError()).isEqualTo(ImportReadError.UNREADABLE_LINE);
        assertThat(line.getReadErrorValue()).isNull();
        assertThat(line.getStatusMessage()).startsWith("Unreadable line: ");
    }

    @Test
    void should_keep_an_empty_raw_value_when_the_faulty_cell_is_empty() {
        ImportDraftLine line = parseOne(profile("UTF-8", 0), "Date;Amount;Label\n24/08/2026;;BOUTIQUE TEST\n");

        assertThat(line.getReadError()).isEqualTo(ImportReadError.INVALID_AMOUNT);
        assertThat(line.getReadErrorValue()).isEmpty();
    }

    @ParameterizedTest(name = "raw value of {0} characters -> {1} kept")
    @CsvSource({"499,499", "500,500", "501,500", "800,500"})
    void should_truncate_the_raw_value_to_500_characters_when_the_cell_is_longer(int length, int expectedLength) {
        ImportDraftLine line = parseOne(profile("UTF-8", 0),
                "Date;Amount;Label\n24/08/2026;" + "a".repeat(length) + ";BOUTIQUE TEST\n");

        assertThat(line.getReadError()).isEqualTo(ImportReadError.INVALID_AMOUNT);
        assertThat(line.getReadErrorValue()).hasSize(expectedLength);
    }

    @Test
    void should_log_only_exception_type_and_line_number_when_the_csv_cannot_be_read() {
        InputStream failing = new InputStream() {
            @Override
            public int read() throws IOException {
                throw new IOException("unreadable: 24/08/2026;-12,50;SECRET-LABEL-OF-THE-STATEMENT");
            }
        };

        ImportProfileRegistry.ImportProfileConfig profile = profile("UTF-8", 0);
        UUID userId = UUID.randomUUID();

        assertThatThrownBy(() -> service.parse(failing, profile, userId))
                .isInstanceOf(IllegalArgumentException.class);

        List<ILoggingEvent> errors = logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.ERROR)
                .toList();
        assertThat(errors).hasSize(1);
        assertThat(errors.get(0).getFormattedMessage()).isEqualTo("CSV read error (IOException) at line 1");
        assertThat(errors.get(0).getThrowableProxy()).isNull();
        assertThat(logAppender.list)
                .noneMatch(e -> e.getFormattedMessage().contains("SECRET-LABEL-OF-THE-STATEMENT"));
    }
}
