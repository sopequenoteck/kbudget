package fr.kksdev.budget.api.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import java.time.LocalDate;
import java.time.Month;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PurchaseDateSpecTest {

    private static final String SG_PATTERN = "CARTE X\\d{4} (\\d{2}/\\d{2})";
    private static final String DD_MM = "dd/MM";
    private static final LocalDate BOOKING = LocalDate.of(2026, Month.SEPTEMBER, 16);

    private final PurchaseDateSpec sg = PurchaseDateSpec.of(SG_PATTERN, DD_MM);

    // -------------------------------------------------------------------------
    // Year inference and 29 February
    // -------------------------------------------------------------------------

    @ParameterizedTest(name = "{0}")
    @CsvSource(delimiter = '|', value = {
            "same year|CARTE X1596 14/09 BOULANGERIE DU MARCHE|2026-09-16|2026-09-14",
            "same day as the booking|CARTE X1596 16/09 EPICERIE|2026-09-16|2026-09-16",
            "previous year when the booking is in January|CARTE X1596 30/12 EPICERIE|2026-01-02|2025-12-30",
            "previous year on the first of January booking|CARTE X1596 31/12 EPICERIE|2026-01-01|2025-12-31",
            "same year when the purchase is in January and the booking in December|CARTE X1596 01/01 EPICERIE|2026-12-31|2026-01-01",
            "leap day in a leap year|CARTE X1596 29/02 EPICERIE|2024-03-01|2024-02-29",
            "leap day of the previous year, booked in January|CARTE X1596 29/02 EPICERIE|2025-01-05|2024-02-29"
    })
    void should_infer_the_year_from_the_booking_date(String description, String label, LocalDate booking, LocalDate expected) {
        assertThat(sg.extract(label, booking)).contains(expected);
    }

    @ParameterizedTest(name = "{0}")
    @CsvSource(delimiter = '|', value = {
            "later than the booking in the same month|CARTE X1596 15/09 EPICERIE|2026-09-10",
            "leap day missing from the inferred year|CARTE X1596 29/02 EPICERIE|2025-03-01",
            "31 February|CARTE X1596 31/02 EPICERIE|2026-09-16",
            "month 99|CARTE X1596 99/99 EPICERIE|2026-09-16",
            "day and month 00|CARTE X1596 00/00 EPICERIE|2026-09-16"
    })
    void should_return_empty_when_the_date_is_unreadable_or_inconsistent(String description, String label, LocalDate booking) {
        assertThat(sg.extract(label, booking)).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Missing
    // -------------------------------------------------------------------------

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"PRELEVEMENT EUROPEEN 2222222222", "VIR RECU 14/09", "CARTE X15 14/09"})
    void should_return_empty_when_label_does_not_match_the_pattern(String label) {
        assertThat(sg.extract(label, BOOKING)).isEmpty();
    }

    @Test
    void should_return_empty_when_booking_date_is_missing() {
        assertThat(sg.extract("CARTE X1596 14/09 EPICERIE", null)).isEmpty();
    }

    @Test
    void should_return_empty_when_the_capturing_group_did_not_take_part_in_the_match() {
        PurchaseDateSpec optionalGroup = PurchaseDateSpec.of("CARTE( \\d{2}/\\d{2})?", DD_MM);

        assertThat(optionalGroup.extract("CARTE", BOOKING)).isEmpty();
    }

    @Test
    void should_trim_the_captured_group_before_parsing() {
        PurchaseDateSpec spaced = PurchaseDateSpec.of("CARTE( \\d{2}/\\d{2})", DD_MM);

        assertThat(spaced.extract("CARTE 14/09", BOOKING)).contains(LocalDate.of(2026, Month.SEPTEMBER, 14));
    }

    // -------------------------------------------------------------------------
    // Factory validation
    // -------------------------------------------------------------------------

    static Stream<Arguments> incoherentSpecs() {
        return Stream.of(
                Arguments.of("null pattern", null, DD_MM),
                Arguments.of("empty pattern", "", DD_MM),
                Arguments.of("blank pattern", "   ", DD_MM),
                Arguments.of("null format", SG_PATTERN, null),
                Arguments.of("empty format", SG_PATTERN, ""),
                Arguments.of("blank format", SG_PATTERN, "   "),
                Arguments.of("pattern without capturing group", "CARTE X\\d{4} \\d{2}/\\d{2}", DD_MM),
                Arguments.of("pattern that does not compile", "(unclosed", DD_MM),
                Arguments.of("format that is not a valid pattern", SG_PATTERN, "dd/MM{"));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("incoherentSpecs")
    void should_reject_spec_when_it_is_incoherent(String description, String pattern, String format) {
        assertThatThrownBy(() -> PurchaseDateSpec.of(pattern, format))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
