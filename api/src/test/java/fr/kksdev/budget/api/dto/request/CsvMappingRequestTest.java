package fr.kksdev.budget.api.dto.request;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CsvMappingRequestTest {

    private static CsvMappingRequest mappingWith(List<String> cleanupPatterns) {
        return new CsvMappingRequest(",", "yyyy-MM-dd", "Booked", "Value", null, null, "Memo",
                null, null, 0, false, null, cleanupPatterns);
    }

    private static void assertRejected(List<String> patterns, String message) {
        assertThatThrownBy(() -> mappingWith(patterns))
                .isExactlyInstanceOf(IllegalArgumentException.class)
                .hasMessage(message)
                .hasNoCause();
    }

    @Test
    void should_return_empty_list_when_cleanupPatterns_is_null() {
        assertThat(mappingWith(null).cleanupPatterns()).isEmpty();
    }

    @Test
    void should_return_empty_list_when_cleanupPatterns_is_empty() {
        assertThat(mappingWith(List.of()).cleanupPatterns()).isEmpty();
    }

    @Test
    void should_trim_patterns_when_they_are_surrounded_by_spaces() {
        assertThat(mappingWith(List.of("  A  ")).cleanupPatterns()).containsExactly("A");
    }

    @Test
    void should_keep_order_and_duplicates_when_patterns_are_valid() {
        assertThat(mappingWith(List.of("B", "A", "B")).cleanupPatterns()).containsExactly("B", "A", "B");
    }

    @Test
    void should_return_immutable_list_when_patterns_are_valid() {
        List<String> patterns = mappingWith(new ArrayList<>(List.of("A"))).cleanupPatterns();

        assertThatThrownBy(() -> patterns.add("B")).isInstanceOf(UnsupportedOperationException.class);
    }

    @Test
    void should_reject_when_pattern_is_blank() {
        assertRejected(List.of(" "), "cleanupPatterns[0] must not be blank");
    }

    @Test
    void should_reject_when_pattern_is_null() {
        assertRejected(Arrays.asList("A", null), "cleanupPatterns[1] must not be blank");
    }

    @Test
    void should_accept_pattern_when_it_has_exactly_200_characters() {
        assertThat(mappingWith(List.of("a".repeat(200))).cleanupPatterns()).hasSize(1);
    }

    @Test
    void should_accept_pattern_when_it_has_200_characters_once_trimmed() {
        assertThat(mappingWith(List.of(" " + "a".repeat(200) + " ")).cleanupPatterns()).hasSize(1);
    }

    @Test
    void should_reject_when_pattern_has_201_characters() {
        assertRejected(List.of("a".repeat(201)), "cleanupPatterns[0] must be at most 200 characters");
    }

    @Test
    void should_accept_20_patterns() {
        assertThat(mappingWith(Collections.nCopies(20, "A")).cleanupPatterns()).hasSize(20);
    }

    @Test
    void should_reject_when_there_are_21_patterns() {
        assertRejected(Collections.nCopies(21, "A"), "cleanupPatterns must contain at most 20 patterns");
    }

    @Test
    void should_reject_with_rank_when_pattern_is_not_a_valid_regex() {
        assertRejected(List.of("CARTE", "("), "cleanupPatterns[1] is not a valid regular expression");
    }

    @Test
    void should_not_expose_pattern_content_when_pattern_is_not_a_valid_regex() {
        assertThatThrownBy(() -> mappingWith(List.of("(SECRET")))
                .isExactlyInstanceOf(IllegalArgumentException.class)
                .hasNoCause()
                .message().doesNotContain("SECRET");
    }

    @Test
    void should_report_first_violation_by_rank_when_several_patterns_are_invalid() {
        assertRejected(List.of("A", " ", "("), "cleanupPatterns[1] must not be blank");
    }

    @Test
    void should_keep_default_encoding_and_decimal_separator_when_they_are_missing() {
        var mapping = mappingWith(null);

        assertThat(mapping.encoding()).isEqualTo("UTF-8");
        assertThat(mapping.decimalSeparator()).isEqualTo(".");
    }
}
