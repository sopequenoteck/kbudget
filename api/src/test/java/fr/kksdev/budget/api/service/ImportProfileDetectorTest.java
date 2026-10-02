package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.ImportProfileSource;
import fr.kksdev.budget.api.model.ImportProfile;
import fr.kksdev.budget.api.repository.ImportProfileRepository;
import fr.kksdev.budget.api.service.ImportProfileDetector.Detection;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

class ImportProfileDetectorTest {

    private static final String OTHER_BANK = "OTHER";

    private final UUID userId = UUID.randomUUID();

    private ImportProfileRepository repository;
    private ImportProfileDetector detector;

    @BeforeEach
    void setUp() {
        repository = mock(ImportProfileRepository.class);
        CsvParsingService csvParsingService = new CsvParsingService(
                mock(LabelCleaningService.class), mock(CategorySuggestionService.class));
        detector = new ImportProfileDetector(new ImportProfileRegistry(), repository, csvParsingService);
    }

    private ImportProfile customProfile(String name, String dateColumn, String labelColumn, String amountColumn) {
        return ImportProfile.builder()
                .id(UUID.randomUUID())
                .name(name)
                .separator(",")
                .dateColumn(dateColumn)
                .labelColumn(labelColumn)
                .amountColumn(amountColumn)
                .build();
    }

    private void givenCustomProfiles(ImportProfile... profiles) {
        when(repository.findByUserIdOrderByUpdatedAtDescIdDesc(userId)).thenReturn(List.of(profiles));
    }

    // -------------------------------------------------------------------------
    // Bundled profiles
    // -------------------------------------------------------------------------

    @Test
    void should_recognize_societe_generale_when_columns_match_the_signature() {
        Optional<Detection> detection = detector.detect(ImportTestFiles.sgStatement(), userId);

        assertThat(detection).hasValueSatisfying(found -> {
            assertThat(found.source()).isEqualTo(ImportProfileSource.REGISTRY);
            assertThat(found.config().bankCode()).isEqualTo("SG");
            assertThat(found.customProfileId()).isNull();
        });
    }

    @Test
    void should_not_read_custom_profiles_when_a_bundled_profile_recognizes_the_file() {
        detector.detect(ImportTestFiles.sgStatement(), userId);

        verifyNoInteractions(repository);
    }

    @Test
    void should_resolve_societe_generale_when_the_account_belongs_to_another_bank() {
        Optional<Detection> detection = detector.resolve(ImportTestFiles.sgStatement(), OTHER_BANK, userId);

        assertThat(detection).hasValueSatisfying(found -> assertThat(found.config().bankCode()).isEqualTo("SG"));
    }

    @Test
    void should_recognize_the_file_when_header_columns_are_surrounded_by_spaces() {
        String statement = ImportTestFiles.SG_STATEMENT.replace(
                "Date de l'opération;Libellé;Détail de l'écriture;Montant de l'opération",
                " Date de l'opération ; Libellé ;Détail de l'écriture; Montant de l'opération ");

        Optional<Detection> detection = detector.detect(
                ImportTestFiles.bytes(statement, StandardCharsets.ISO_8859_1), userId);

        assertThat(detection).isPresent();
    }

    @Test
    void should_not_recognize_the_file_when_header_columns_differ_by_case() {
        String statement = ImportTestFiles.SG_STATEMENT.replace("Libellé;", "LIBELLÉ;");

        Optional<Detection> detection = detector.detect(
                ImportTestFiles.bytes(statement, StandardCharsets.ISO_8859_1), userId);

        assertThat(detection).isEmpty();
    }

    @Test
    void should_not_recognize_the_file_when_a_signature_column_is_missing() {
        String statement = ImportTestFiles.SG_STATEMENT.replace("Libellé;", "");

        assertThat(detector.detect(ImportTestFiles.bytes(statement, StandardCharsets.ISO_8859_1), userId)).isEmpty();
    }

    @Test
    void should_not_recognize_the_file_when_it_ends_before_the_bank_header_is_skipped() {
        byte[] emptyFile = ImportTestFiles.bytes("", StandardCharsets.ISO_8859_1);

        assertThat(detector.detect(emptyFile, userId)).isEmpty();
    }

    @Test
    void should_not_recognize_the_file_when_it_is_decoded_with_the_wrong_encoding() {
        Optional<Detection> detection = detector.detect(
                ImportTestFiles.bytes(ImportTestFiles.SG_STATEMENT, StandardCharsets.UTF_8), userId);

        assertThat(detection).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Fallback and absence
    // -------------------------------------------------------------------------

    @Test
    void should_fall_back_to_the_bank_profile_when_no_signature_matches() {
        when(repository.findByUserIdOrderByUpdatedAtDescIdDesc(userId)).thenReturn(List.of());

        Optional<Detection> detection = detector.resolve(ImportTestFiles.otherBankStatement(), "sg", userId);

        assertThat(detection).hasValueSatisfying(found -> {
            assertThat(found.source()).isEqualTo(ImportProfileSource.REGISTRY);
            assertThat(found.config().bankCode()).isEqualTo("SG");
            assertThat(found.customProfileId()).isNull();
        });
    }

    @Test
    void should_resolve_nothing_when_no_signature_matches_and_the_bank_has_no_profile() {
        assertThat(detector.resolve(ImportTestFiles.otherBankStatement(), OTHER_BANK, userId)).isEmpty();
    }

    @Test
    void should_resolve_nothing_when_no_signature_matches_and_the_account_has_no_bank() {
        assertThat(detector.resolve(ImportTestFiles.otherBankStatement(), null, userId)).isEmpty();
    }

    @Test
    void should_not_recognize_an_empty_file() {
        assertThat(detector.detect(new byte[0], userId)).isEmpty();
    }

    @Test
    void should_not_recognize_a_file_made_of_the_bank_header_only() {
        byte[] bankHeaderOnly = ImportTestFiles.bytes("=\"0000000000001596\";15/09/2026\n", StandardCharsets.ISO_8859_1);

        assertThat(detector.detect(bankHeaderOnly, userId)).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Custom profiles
    // -------------------------------------------------------------------------

    @Test
    void should_recognize_a_custom_profile_when_its_mapped_columns_are_on_the_header() {
        ImportProfile mine = customProfile("My bank", "Booked", "Memo", "Value");
        givenCustomProfiles(mine);

        Optional<Detection> detection = detector.detect(ImportTestFiles.otherBankStatement(), userId);

        assertThat(detection).hasValueSatisfying(found -> {
            assertThat(found.source()).isEqualTo(ImportProfileSource.CUSTOM);
            assertThat(found.customProfileId()).isEqualTo(mine.getId());
            assertThat(found.config().name()).isEqualTo("My bank");
            assertThat(found.config().bankCode()).isNull();
        });
    }

    @Test
    void should_prefer_the_first_matching_custom_profile_when_several_match() {
        ImportProfile mostRecent = customProfile("Recent", "Booked", "Memo", "Value");
        ImportProfile older = customProfile("Older", "Booked", "Memo", "Value");
        givenCustomProfiles(mostRecent, older);

        Optional<Detection> detection = detector.detect(ImportTestFiles.otherBankStatement(), userId);

        assertThat(detection).hasValueSatisfying(found -> assertThat(found.customProfileId()).isEqualTo(mostRecent.getId()));
    }

    @Test
    void should_skip_a_custom_profile_when_one_of_its_columns_is_absent_from_the_file() {
        ImportProfile otherFormat = customProfile("Other format", "Booked", "Memo", "Amount");
        ImportProfile matching = customProfile("Matching", "Booked", "Memo", "Value");
        givenCustomProfiles(otherFormat, matching);

        Optional<Detection> detection = detector.detect(ImportTestFiles.otherBankStatement(), userId);

        assertThat(detection).hasValueSatisfying(found -> assertThat(found.customProfileId()).isEqualTo(matching.getId()));
    }

    @Test
    void should_only_read_the_custom_profiles_of_the_authenticated_user() {
        givenCustomProfiles();

        detector.detect(ImportTestFiles.otherBankStatement(), userId);

        verify(repository).findByUserIdOrderByUpdatedAtDescIdDesc(userId);
        verifyNoMoreInteractions(repository);
    }

    @Test
    void should_prefer_a_custom_profile_over_the_bank_fallback_when_the_account_is_societe_generale() {
        ImportProfile mine = customProfile("My bank", "Booked", "Memo", "Value");
        givenCustomProfiles(mine);

        Optional<Detection> detection = detector.resolve(ImportTestFiles.otherBankStatement(), "SG", userId);

        assertThat(detection).hasValueSatisfying(found -> assertThat(found.source()).isEqualTo(ImportProfileSource.CUSTOM));
    }

    @Test
    void should_read_the_custom_profile_with_its_own_separator_encoding_and_skipped_lines() {
        ImportProfile semicolons = ImportProfile.builder()
                .id(UUID.randomUUID())
                .name("Semicolons")
                .separator(";")
                .encoding("ISO-8859-1")
                .skipHeaderLines(2)
                .dateColumn("Date")
                .labelColumn("Libellé")
                .amountColumn("Montant")
                .build();
        givenCustomProfiles(semicolons);
        byte[] file = ImportTestFiles.bytes("Bank\nAccount 1\nDate;Libellé;Montant\n01/09/2026;Café;-3,00\n",
                StandardCharsets.ISO_8859_1);

        assertThat(detector.detect(file, userId)).isPresent();
    }

    @Test
    void should_include_debit_and_credit_columns_in_the_signature_of_a_custom_profile() {
        ImportProfile debitCredit = ImportProfile.builder()
                .id(UUID.randomUUID())
                .name("Debit credit")
                .separator(",")
                .dateColumn("Date")
                .labelColumn("Memo")
                .debitColumn("Debit")
                .creditColumn("Credit")
                .build();
        givenCustomProfiles(debitCredit);

        assertThat(detector.detect(ImportTestFiles.bytes("Date,Memo,Debit,Credit\n", StandardCharsets.UTF_8), userId)).isPresent();
        assertThat(detector.detect(ImportTestFiles.bytes("Date,Memo,Debit\n", StandardCharsets.UTF_8), userId)).isEmpty();
    }

    @Test
    void should_ignore_a_blank_mapped_column_in_the_signature_of_a_custom_profile() {
        givenCustomProfiles(customProfile("Blank amount", "Booked", "Memo", " "));

        assertThat(detector.detect(ImportTestFiles.otherBankStatement(), userId)).isPresent();
    }

    @Test
    void should_read_no_skipped_line_when_the_custom_profile_does_not_set_skip_header_lines() {
        ImportProfile profile = customProfile("No skip", "Booked", "Memo", "Value");
        profile.setSkipHeaderLines(null);
        givenCustomProfiles(profile);

        assertThat(detector.detect(ImportTestFiles.otherBankStatement(), userId)).isPresent();
    }

    @Test
    void should_not_recognize_a_custom_profile_whose_separator_is_empty() {
        ImportProfile profile = customProfile("Empty separator", "Booked", "Memo", "Value");
        profile.setSeparator("");
        givenCustomProfiles(profile);

        assertThat(detector.detect(ImportTestFiles.otherBankStatement(), userId)).isEmpty();
    }

    @Test
    void should_not_recognize_a_custom_profile_whose_encoding_is_unknown() {
        ImportProfile profile = customProfile("Unknown encoding", "Booked", "Memo", "Value");
        profile.setEncoding("NOT-A-CHARSET");
        givenCustomProfiles(profile);

        assertThat(detector.detect(ImportTestFiles.otherBankStatement(), userId)).isEmpty();
    }

    @Test
    void should_not_recognize_a_custom_profile_that_maps_no_column() {
        ImportProfile unmapped = customProfile("Unmapped", " ", " ", null);
        givenCustomProfiles(unmapped);

        assertThat(detector.detect(ImportTestFiles.otherBankStatement(), userId)).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Detection.profileKey() (KKS-384)
    // -------------------------------------------------------------------------

    private static ImportProfileRegistry.ImportProfileConfig configOfBank(String bankCode) {
        return new ImportProfileRegistry.ImportProfileConfig(
                bankCode, "Any", ";", "dd/MM/yyyy", "Date", "Amount", null, null, "Label", "UTF-8", ",", 0,
                List.of(), List.of(), null, null);
    }

    @Test
    void should_key_a_bundled_profile_by_its_bank_code() {
        Detection detection = new Detection(configOfBank("SG"), ImportProfileSource.REGISTRY, null);

        assertThat(detection.profileKey()).isEqualTo("REGISTRY:SG");
    }

    @Test
    void should_key_a_custom_profile_by_its_id() {
        UUID profileId = UUID.randomUUID();
        Detection detection = new Detection(configOfBank(null), ImportProfileSource.CUSTOM, profileId);

        assertThat(detection.profileKey()).isEqualTo("CUSTOM:" + profileId);
    }

    @Test
    void should_give_no_key_to_a_profile_without_identity() {
        assertThat(new Detection(configOfBank(null), ImportProfileSource.REGISTRY, null).profileKey()).isNull();
        assertThat(new Detection(configOfBank(null), ImportProfileSource.CUSTOM, null).profileKey()).isNull();
    }
}
