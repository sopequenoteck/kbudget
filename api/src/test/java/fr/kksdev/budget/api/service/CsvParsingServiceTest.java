package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.model.ImportDraftLine;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

/** Reading of the bank header lines skipped before the column header (KKS-384), purchase date of the lines (KKS-385). */
class CsvParsingServiceTest {

    private final CsvParsingService service = new CsvParsingService(
            mock(LabelCleaningService.class), mock(CategorySuggestionService.class));

    private final ImportProfileRegistry registry = new ImportProfileRegistry();

    private ImportProfileRegistry.ImportProfileConfig profile(String encoding, int skipHeaderLines) {
        return new ImportProfileRegistry.ImportProfileConfig(
                "XX", "Test", ";", "dd/MM/yyyy", "Date", "Amount", null, null, "Label", encoding, ",",
                skipHeaderLines, List.of(), List.of(), null, null);
    }

    @Test
    void should_read_the_bank_header_line_of_a_societe_generale_statement() {
        var sg = registry.findByBankCode("SG").orElseThrow();

        List<String> lines = service.readSkippedLines(ImportTestFiles.sgStatement(), sg);

        assertThat(lines).containsExactly("=\"0000000000001596\";15/09/2026;01/10/2026;2;01/10/2026;1842,37 EUR");
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

}
