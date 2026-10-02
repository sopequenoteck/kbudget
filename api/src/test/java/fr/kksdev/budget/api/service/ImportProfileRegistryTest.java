package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.service.ImportProfileRegistry.ImportProfileConfig;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ImportProfileRegistryTest {

    private static final String MIXED = "classpath*:import-profiles-test/mixed/";

    private final ImportProfileRegistry registry = new ImportProfileRegistry();

    // -------------------------------------------------------------------------
    // Bundled profile
    // -------------------------------------------------------------------------

    @Test
    void should_load_societe_generale_when_registry_starts() {
        ImportProfileConfig sg = registry.findByBankCode("SG").orElseThrow();

        assertThat(sg.bankCode()).isEqualTo("SG");
        assertThat(sg.name()).isEqualTo("Société Générale");
        assertThat(sg.separator()).isEqualTo(";");
        assertThat(sg.dateFormat()).isEqualTo("dd/MM/yyyy");
        assertThat(sg.dateColumn()).isEqualTo("Date de l'opération");
        assertThat(sg.amountColumn()).isEqualTo("Montant de l'opération");
        assertThat(sg.debitColumn()).isNull();
        assertThat(sg.creditColumn()).isNull();
        assertThat(sg.labelColumn()).isEqualTo("Détail de l'écriture");
        assertThat(sg.encoding()).isEqualTo("ISO-8859-1");
        assertThat(sg.decimalSeparator()).isEqualTo(",");
        assertThat(sg.skipHeaderLines()).isEqualTo(1);
        assertThat(sg.cleanupPatterns()).containsExactly(
                "CARTE\\s+\\w+\\d{4}\\s+\\d{2}/\\d{2}\\s+",
                "CARTE\\s+\\w+\\d{4}\\s+TRANSF\\s+\\d{2}/\\d{2}\\s+",
                "UEP\\*");
        assertThat(sg.signatureColumns()).containsExactlyInAnyOrder(
                "Date de l'opération", "Détail de l'écriture", "Montant de l'opération", "Libellé");
    }

    @Test
    void should_read_statement_header_and_purchase_date_when_profile_is_societe_generale() {
        ImportProfileConfig sg = registry.findByBankCode("SG").orElseThrow();
        List<String> skipped = List.of("00000000001596;15/09/2026;01/10/2026;24;01/10/2026;1842.37 EUR");

        assertThat(sg.statementHeader().accountSuffix(skipped)).contains("1596");
        assertThat(sg.statementHeader().balance(skipped, sg.decimalSeparator())).contains(new BigDecimal("1842.37"));
        assertThat(sg.statementHeader().balanceDate(skipped)).contains(LocalDate.of(2026, Month.OCTOBER, 1));
        assertThat(sg.purchaseDate().extract("CARTE X1596 14/09 ", LocalDate.of(2026, Month.SEPTEMBER, 16)))
                .contains(LocalDate.of(2026, Month.SEPTEMBER, 14));
    }

    @Test
    void should_read_the_dot_balance_of_the_header_when_profile_is_societe_generale() {
        ImportProfileConfig sg = registry.findByBankCode("SG").orElseThrow();
        List<String> skipped = List.of("00000000001596;15/09/2026;01/10/2026;24;01/10/2026;1842.37 EUR");

        assertThat(sg.decimalSeparator()).isEqualTo(",");
        assertThat(sg.statementHeader().decimalSeparator()).isEqualTo(".");
        assertThat(sg.statementHeader().balance(skipped, sg.decimalSeparator())).contains(new BigDecimal("1842.37"));
    }

    @Test
    void should_list_the_bundled_profiles() {
        assertThat(registry.getAll()).extracting(ImportProfileConfig::bankCode).containsExactly("SG");
    }

    @ParameterizedTest
    @ValueSource(strings = {"SG", "sg", "Sg"})
    void should_find_profile_regardless_of_case(String bankCode) {
        assertThat(registry.findByBankCode(bankCode)).isPresent();
    }

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = {"", "UNKNOWN"})
    void should_find_nothing_when_bank_code_is_null_or_unknown(String bankCode) {
        assertThat(registry.findByBankCode(bankCode)).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Invalid files never prevent startup
    // -------------------------------------------------------------------------

    @Test
    void should_load_only_the_valid_file_when_directory_also_holds_invalid_ones() {
        ImportProfileRegistry loaded = new ImportProfileRegistry(MIXED + "*.yaml");

        assertThat(loaded.getAll()).extracting(ImportProfileConfig::bankCode).containsExactly("TESTBANK");
        ImportProfileConfig testBank = loaded.findByBankCode("testbank").orElseThrow();
        assertThat(testBank.separator()).isEqualTo("\t");
        assertThat(testBank.debitColumn()).isEqualTo("Debit");
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "invalid-syntax.yaml",
            "invalid-empty.yaml",
            "invalid-version.yaml",
            "invalid-regex.yaml",
            "invalid-no-amount.yaml",
            "invalid-no-signature.yaml"
    })
    void should_ignore_the_file_without_failing_when_it_is_invalid(String fileName) {
        ImportProfileRegistry loaded = new ImportProfileRegistry(MIXED + fileName);

        assertThat(loaded.getAll()).isEmpty();
    }

    @Test
    void should_keep_the_first_file_by_name_when_two_files_share_a_bank_code() {
        ImportProfileRegistry loaded = new ImportProfileRegistry("classpath*:import-profiles-test/duplicate/*.yaml");

        assertThat(loaded.getAll()).extracting(ImportProfileConfig::name).containsExactly("Duplicate first");
    }

    @Test
    void should_start_empty_when_no_file_matches_the_location() {
        ImportProfileRegistry loaded = new ImportProfileRegistry("classpath*:import-profiles-test/none/*.yaml");

        assertThat(loaded.getAll()).isEmpty();
        assertThat(loaded.findByBankCode("SG")).isEmpty();
    }

    @Test
    void should_start_empty_when_the_location_cannot_be_listed() throws IOException {
        ResourcePatternResolver resolver = mock(ResourcePatternResolver.class);
        when(resolver.getResources(MIXED + "*.yaml")).thenThrow(new IOException("listing failed"));

        ImportProfileRegistry loaded = new ImportProfileRegistry(MIXED + "*.yaml", resolver);

        assertThat(loaded.getAll()).isEmpty();
    }

    @Test
    void should_ignore_the_file_without_failing_when_it_cannot_be_read() throws IOException {
        Resource unreadable = mock(Resource.class);
        when(unreadable.getDescription()).thenReturn("unreadable.yaml");
        when(unreadable.getInputStream()).thenThrow(new IOException("read failed"));
        ResourcePatternResolver resolver = mock(ResourcePatternResolver.class);
        when(resolver.getResources(MIXED + "*.yaml")).thenReturn(new Resource[]{unreadable});

        ImportProfileRegistry loaded = new ImportProfileRegistry(MIXED + "*.yaml", resolver);

        assertThat(loaded.getAll()).isEmpty();
    }
}
