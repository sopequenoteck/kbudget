package fr.kksdev.budget.api.service;

import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.List;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;

class LabelCleaningServiceTest {

    private static final String CATASTROPHIC = "(\\w+\\s?)+$";
    // JDK 21 memoizes the nested-quantifier form above; this one still backtracks exponentially
    private static final String BACKTRACKING = "(.*a){12}x";

    private final LabelCleaningService service = new LabelCleaningService();

    @Test
    void should_apply_profile_pattern_when_pattern_is_ordinary() {
        String result = service.clean("CARTE X1234 14/09 BOULANGERIE DUPONT",
                List.of("CARTE\\s+\\w+\\d{4}\\s+\\d{2}/\\d{2}\\s+"));

        assertThat(result).isEqualTo("BOULANGERIE DUPONT");
    }

    @Test
    void should_return_label_unchanged_when_no_pattern_is_given() {
        assertThat(service.clean("BOULANGERIE DUPONT")).isEqualTo("BOULANGERIE DUPONT");
    }

    @Test
    void should_return_empty_when_label_is_null() {
        assertThat(service.clean(null, List.of("A"))).isEmpty();
    }

    @Test
    void should_skip_invalid_pattern_when_pattern_does_not_compile() {
        String result = service.clean("BOULANGERIE DUPONT", List.of("(", "DUPONT"));

        assertThat(result).isEqualTo("BOULANGERIE");
    }

    @Test
    void should_return_quickly_with_other_patterns_result_when_nested_quantifier_pattern_is_given() {
        String label = "ZZ " + "a".repeat(196) + "!";
        assertThat(label).hasSize(200);

        String result = assertTimeoutPreemptively(Duration.ofSeconds(1),
                () -> service.clean(label, List.of("ZZ", CATASTROPHIC)));

        assertThat(result).isEqualTo("a".repeat(196) + "!");
    }

    @Test
    void should_skip_pattern_and_keep_other_patterns_result_when_budget_is_exceeded() {
        String label = "ZZ " + "a".repeat(196) + "!";
        assertThat(label).hasSize(200);

        String result = assertTimeoutPreemptively(Duration.ofSeconds(1),
                () -> service.clean(label, List.of("ZZ", BACKTRACKING)));

        assertThat(result).isEqualTo("a".repeat(196) + "!");
    }

    @Test
    void should_be_catastrophic_without_guard_when_pattern_backtracks_exponentially() {
        String label = "a".repeat(199) + "!";
        long start = System.nanoTime();
        var matcher = Pattern.compile(BACKTRACKING).matcher(
                new DeadlineCharSequence(label, start + Duration.ofSeconds(2).toNanos()));

        // Still running after 500 ms: only the deadline stops it
        assertThatThrownBy(matcher::find)
                .isInstanceOf(DeadlineCharSequence.DeadlineExceededException.class);
        assertThat(System.nanoTime() - start).isGreaterThan(Duration.ofMillis(500).toNanos());
    }

    @Test
    void should_read_characters_when_deadline_is_not_reached() {
        var sequence = new DeadlineCharSequence("abc", System.nanoTime() + 10_000_000_000L);

        assertThat(sequence.charAt(1)).isEqualTo('b');
        assertThat(sequence.length()).isEqualTo(3);
        assertThat(sequence.toString()).isEqualTo("abc");
        assertThat(sequence.subSequence(1, 3).toString()).isEqualTo("bc");
    }

    @Test
    void should_throw_when_deadline_is_passed() {
        var sequence = new DeadlineCharSequence("abc", System.nanoTime() - 1);

        assertThatThrownBy(() -> sequence.charAt(0))
                .isInstanceOf(DeadlineCharSequence.DeadlineExceededException.class);
        assertThat(sequence.length()).isEqualTo(3);
    }

    @Test
    void should_keep_deadline_when_sub_sequence_is_read_after_deadline() {
        var sequence = new DeadlineCharSequence("abc", System.nanoTime() - 1);
        CharSequence sub = sequence.subSequence(0, 2);

        assertThatThrownBy(() -> sub.charAt(0))
                .isInstanceOf(DeadlineCharSequence.DeadlineExceededException.class);
    }
}
