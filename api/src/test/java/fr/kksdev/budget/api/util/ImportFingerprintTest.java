package fr.kksdev.budget.api.util;

import fr.kksdev.budget.api.enums.TransactionType;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;

import static org.assertj.core.api.Assertions.assertThat;

class ImportFingerprintTest {

    private static final LocalDate DATE = LocalDate.of(2026, Month.MARCH, 3);
    private static final String LABEL = "FRAIS BANCAIRES TEST";

    private static String fingerprint(LocalDate date, String amount, TransactionType type, String label) {
        return ImportFingerprint.of(date, new BigDecimal(amount), type, label);
    }

    @Test
    void should_be_stable_hex_sha256_when_computed_twice() {
        String first = fingerprint(DATE, "45.00", TransactionType.DEPENSE, LABEL);

        assertThat(first).hasSize(64).matches("[0-9a-f]+");
        assertThat(fingerprint(DATE, "45.00", TransactionType.DEPENSE, LABEL)).isEqualTo(first);
    }

    @Test
    void should_ignore_amount_scale_and_label_spacing_when_they_differ() {
        String reference = fingerprint(DATE, "45.00", TransactionType.DEPENSE, LABEL);

        assertThat(fingerprint(DATE, "45", TransactionType.DEPENSE, LABEL)).isEqualTo(reference);
        assertThat(fingerprint(DATE, "45.0", TransactionType.DEPENSE, "  FRAIS   BANCAIRES TEST ")).isEqualTo(reference);
    }

    @Test
    void should_differ_when_any_file_field_differs() {
        String reference = fingerprint(DATE, "45.00", TransactionType.DEPENSE, LABEL);

        assertThat(fingerprint(DATE.plusDays(1), "45.00", TransactionType.DEPENSE, LABEL)).isNotEqualTo(reference);
        assertThat(fingerprint(DATE, "45.01", TransactionType.DEPENSE, LABEL)).isNotEqualTo(reference);
        assertThat(fingerprint(DATE, "45.00", TransactionType.RECETTE, LABEL)).isNotEqualTo(reference);
        assertThat(fingerprint(DATE, "45.00", TransactionType.DEPENSE, LABEL + " 2")).isNotEqualTo(reference);
    }

    @Test
    void should_accept_null_label_when_line_has_none() {
        assertThat(fingerprint(DATE, "45.00", TransactionType.DEPENSE, null)).hasSize(64);
    }
}
