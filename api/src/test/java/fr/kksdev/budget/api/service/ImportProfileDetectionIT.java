package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CsvMappingRequest;
import fr.kksdev.budget.api.dto.response.ImportDetectionResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.exception.CsvProfileNotFoundException;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportProfile;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import fr.kksdev.budget.api.repository.ImportProfileRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.Month;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Profile resolution at upload (KKS-440), end to end on the H2 database: the
 * file is recognized by its columns, a custom profile is reused on the next
 * import, and the custom profiles of another user are never read.
 *
 * <p>The files are synthetic ({@link ImportTestFiles}), never a real statement.
 */
@SpringBootTest
@ActiveProfiles("test")
class ImportProfileDetectionIT {

    private static final String OTHER_BANK = "OTHER";
    private static final String CUSTOM_PROFILE_NAME = "My bank";

    private static final CsvMappingRequest OTHER_BANK_MAPPING = new CsvMappingRequest(
            ",", "yyyy-MM-dd", "Booked", "Value", null, null, "Memo", "UTF-8", ".", 0, true, CUSTOM_PROFILE_NAME);

    @Autowired ImportService importService;
    @Autowired UserRepository userRepository;
    @Autowired AccountRepository accountRepository;
    @Autowired ImportDraftRepository importDraftRepository;
    @Autowired ImportProfileRepository importProfileRepository;
    @Autowired JdbcTemplate jdbcTemplate;

    private User user;
    private UUID accountId;

    @BeforeEach
    void setUp() {
        user = createUser();
        accountId = createAccount(user, OTHER_BANK).getId();
    }

    // -------------------------------------------------------------------------
    // Bundled profile, recognized from the file
    // -------------------------------------------------------------------------

    @Test
    void should_import_societe_generale_statement_when_account_belongs_to_another_bank() {
        ImportDraftResponse draft = importService.upload(sgFile(), accountId, user.getId());

        assertThat(draft.profileSource()).isEqualTo("REGISTRY");
        assertThat(draft.profileName()).isEqualTo("Société Générale");
        assertThat(draft.totalLines()).isEqualTo(2);
        assertThat(draft.readyCount()).isEqualTo(2);
        assertThat(draft.lines().getFirst().amount()).isEqualByComparingTo(new BigDecimal("4.30"));
        assertThat(importDraftRepository.findById(draft.id()).orElseThrow().getProfileId()).isNull();
    }

    @Test
    void should_fall_back_to_the_bank_profile_when_the_file_matches_no_signature() {
        UUID sgAccountId = createAccount(user, "SG").getId();

        ImportDraftResponse draft = importService.upload(otherBankFile(), sgAccountId, user.getId());

        assertThat(draft.profileSource()).isEqualTo("REGISTRY");
        assertThat(draft.profileName()).isEqualTo("Société Générale");
        assertThat(draft.readyCount()).isZero();
    }

    @Test
    void should_refuse_the_file_when_it_matches_no_profile_and_the_bank_has_none() {
        UUID userId = user.getId();
        MockMultipartFile file = otherBankFile();

        assertThatThrownBy(() -> importService.upload(file, accountId, userId))
                .isInstanceOf(CsvProfileNotFoundException.class)
                .hasMessage("No import profile available for bank: " + OTHER_BANK);
    }

    // -------------------------------------------------------------------------
    // Custom profile, reused at the next import
    // -------------------------------------------------------------------------

    @Test
    void should_reuse_the_saved_custom_profile_when_the_same_format_is_imported_again() {
        ImportDraftResponse first = importService.uploadWithMapping(otherBankFile(), accountId, OTHER_BANK_MAPPING, user.getId());
        UUID savedProfileId = importDraftRepository.findById(first.id()).orElseThrow().getProfileId();
        importService.deleteDraft(first.id(), user.getId());

        ImportDraftResponse second = importService.upload(otherBankFile(), accountId, user.getId());

        assertThat(second.profileSource()).isEqualTo("CUSTOM");
        assertThat(second.profileName()).isEqualTo(CUSTOM_PROFILE_NAME);
        assertThat(second.readyCount()).isEqualTo(2);
        assertThat(importDraftRepository.findById(second.id()).orElseThrow().getProfileId()).isEqualTo(savedProfileId);
    }

    @Test
    void should_detect_the_custom_profile_of_the_user_without_creating_anything() {
        importService.uploadWithMapping(otherBankFile(), accountId, OTHER_BANK_MAPPING, user.getId());
        long drafts = importDraftRepository.count();

        ImportDetectionResponse detection = importService.detect(otherBankFile(), user.getId());

        assertThat(detection).isEqualTo(new ImportDetectionResponse(true, "CUSTOM", null, CUSTOM_PROFILE_NAME));
        assertThat(importDraftRepository.count()).isEqualTo(drafts);
    }

    @Test
    void should_choose_the_most_recently_modified_custom_profile_when_several_match() {
        ImportProfile older = saveCustomProfile(user, "Older");
        ImportProfile newer = saveCustomProfile(user, "Newer");
        setUpdatedAt(older, LocalDateTime.of(2026, Month.JANUARY, 1, 10, 0));
        setUpdatedAt(newer, LocalDateTime.of(2026, Month.JUNE, 1, 10, 0));

        assertThat(importService.detect(otherBankFile(), user.getId()).profileName()).isEqualTo("Newer");

        setUpdatedAt(older, LocalDateTime.of(2026, Month.SEPTEMBER, 1, 10, 0));

        assertThat(importService.detect(otherBankFile(), user.getId()).profileName()).isEqualTo("Older");
    }

    // -------------------------------------------------------------------------
    // Isolation between users
    // -------------------------------------------------------------------------

    @Test
    void should_never_use_the_custom_profile_of_another_user() {
        User otherUser = createUser();
        saveCustomProfile(otherUser, "Someone else's profile");
        UUID userId = user.getId();
        MockMultipartFile file = otherBankFile();

        assertThatThrownBy(() -> importService.upload(file, accountId, userId))
                .isInstanceOf(CsvProfileNotFoundException.class);
        assertThat(importService.detect(otherBankFile(), userId)).isEqualTo(new ImportDetectionResponse(false, null, null, null));
        assertThat(importService.detect(otherBankFile(), otherUser.getId()).profileName()).isEqualTo("Someone else's profile");
    }

    // -------------------------------------------------------------------------

    private static MockMultipartFile sgFile() {
        return new MockMultipartFile("file", "releve.csv", "text/csv", ImportTestFiles.sgStatement());
    }

    private static MockMultipartFile otherBankFile() {
        return new MockMultipartFile("file", "export.csv", "text/csv", ImportTestFiles.otherBankStatement());
    }

    private ImportProfile saveCustomProfile(User owner, String name) {
        return importProfileRepository.save(ImportProfile.builder()
                .user(owner)
                .name(name)
                .separator(",")
                .dateFormat("yyyy-MM-dd")
                .dateColumn("Booked")
                .amountColumn("Value")
                .labelColumn("Memo")
                .build());
    }

    private void setUpdatedAt(ImportProfile profile, LocalDateTime updatedAt) {
        jdbcTemplate.update("UPDATE import_profiles SET updated_at = ? WHERE id = ?",
                Timestamp.valueOf(updatedAt), profile.getId());
    }

    private User createUser() {
        return userRepository.save(User.builder()
                .email("detect-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Detect")
                .build());
    }

    private Account createAccount(User owner, String bankCode) {
        return accountRepository.save(Account.builder()
                // Unique name: PostgreSQL enforces UNIQUE(nom, user_id), which the generated H2 schema does not.
                .nom("Compte " + UUID.randomUUID().toString().substring(0, 8))
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#000000")
                .bankCode(bankCode)
                .user(owner)
                .build());
    }
}
