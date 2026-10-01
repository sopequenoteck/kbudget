package fr.kksdev.budget.api.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

/** Reading of the bank header lines skipped before the column header (KKS-384). */
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
}
