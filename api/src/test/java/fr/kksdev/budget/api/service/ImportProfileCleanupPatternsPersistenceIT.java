package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CsvMappingRequest;
import fr.kksdev.budget.api.dto.response.ImportDraftLineResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.exception.CsvProfileNotFoundException;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportProfile;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.ImportProfileRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Migration V44 and the cleanup patterns of custom import profiles (KKS-442) on a real
 * PostgreSQL: Flyway adds the JSONB column, Hibernate validates the mapping against it, the
 * list of patterns survives the round trip in order, and a profile saved before V44 (NULL) is
 * still read. H2 (profile test) generates its schema from the entities and proves none of it.
 */
@SpringBootTest
@Testcontainers
class ImportProfileCleanupPatternsPersistenceIT {

    private static final String OTHER_BANK = "OTHER";
    private static final String PROFILE_NAME = "My bank";

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("app.admin-emails", () -> "");
        // Without the "test" profile here: the property must be set by hand.
        registry.add("app.scheduling.enabled", () -> "false");
        registry.add("app.jwt.secret", () -> "test-secret-key-budget-app-min-256-bits-long-enough-for-hmac-sha");
    }

    @Autowired private UserRepository userRepository;
    @Autowired private AccountRepository accountRepository;
    @Autowired private ImportProfileRepository importProfileRepository;
    @Autowired private ImportService importService;
    @Autowired private EntityManager entityManager;
    @Autowired private JdbcTemplate jdbcTemplate;

    @MockitoBean
    private BootstrapSeedRunner bootstrapSeedRunner;

    private User user;
    private UUID accountId;

    @BeforeEach
    void setUp() {
        user = createUser();
        accountId = createAccount(user).getId();
    }

    @Test
    void should_read_back_the_same_patterns_in_the_same_order_when_a_profile_is_saved() {
        List<String> patterns = List.of("CARTE\\s+\\w+\\d{4}\\s+", "\\d{2},\\d{2}", "REF\\d+");
        ImportProfile saved = importProfileRepository.saveAndFlush(profile(user, "Round trip", patterns));
        entityManager.clear();

        ImportProfile read = importProfileRepository.findById(saved.getId()).orElseThrow();

        assertThat(read.getCleanupPatterns()).containsExactlyElementsOf(patterns);
    }

    @Test
    void should_import_without_error_and_keep_labels_when_the_profile_predates_the_column() {
        UUID legacyId = UUID.randomUUID();
        jdbcTemplate.update("""
                INSERT INTO import_profiles (id, user_id, name, separator, date_format, date_column, amount_column,
                    label_column, encoding, decimal_separator, skip_header_lines, created_at, updated_at)
                VALUES (?, ?, 'Legacy', ',', 'yyyy-MM-dd', 'Booked', 'Value', 'Memo', 'UTF-8', '.', 0, now(), now())
                """, legacyId, user.getId());
        entityManager.clear();

        ImportDraftResponse draft = importService.upload(otherBankCardFile(), accountId, user.getId());

        assertThat(draft.profileName()).isEqualTo("Legacy");
        assertThat(draft.lines()).extracting(ImportDraftLineResponse::cleanLabel)
                .containsExactly("CARTE X1234 14/09 BAKERY", "CARTE X1234 15/09 GROCER");
    }

    @Test
    void should_clean_labels_at_the_first_import_and_at_the_reimport_when_the_mapping_has_a_pattern() {
        var mapping = new CsvMappingRequest(",", "yyyy-MM-dd", "Booked", "Value", null, null, "Memo", "UTF-8", ".", 0,
                true, PROFILE_NAME, List.of(ImportTestFiles.CARD_PATTERN));

        ImportDraftResponse first = importService.uploadWithMapping(otherBankCardFile(), accountId, mapping, user.getId());
        importService.deleteDraft(first.id(), user.getId());
        entityManager.clear();
        ImportDraftResponse second = importService.upload(otherBankCardFile(), accountId, user.getId());

        assertThat(first.lines()).extracting(ImportDraftLineResponse::cleanLabel).containsExactly("BAKERY", "GROCER");
        assertThat(first.lines().getFirst().rawLabel()).isEqualTo("CARTE X1234 14/09 BAKERY");
        assertThat(second.profileSource()).isEqualTo("CUSTOM");
        assertThat(second.lines()).extracting(ImportDraftLineResponse::cleanLabel).containsExactly("BAKERY", "GROCER");
    }

    @Test
    void should_not_recognize_the_profile_of_another_user_when_importing_the_same_format() {
        User owner = createUser();
        importProfileRepository.saveAndFlush(profile(owner, "Someone else's", List.of(ImportTestFiles.CARD_PATTERN)));
        UUID userId = user.getId();
        MockMultipartFile file = otherBankCardFile();

        assertThatThrownBy(() -> importService.upload(file, accountId, userId))
                .isInstanceOf(CsvProfileNotFoundException.class);
    }

    private static MockMultipartFile otherBankCardFile() {
        return new MockMultipartFile("file", "export.csv", "text/csv", ImportTestFiles.otherBankCardStatement());
    }

    private static ImportProfile profile(User owner, String name, List<String> patterns) {
        return ImportProfile.builder()
                .user(owner).name(name).separator(",").dateFormat("yyyy-MM-dd")
                .dateColumn("Booked").amountColumn("Value").labelColumn("Memo")
                .cleanupPatterns(patterns).build();
    }

    private User createUser() {
        return userRepository.saveAndFlush(User.builder()
                .email("cleanup-patterns-" + UUID.randomUUID() + "@example.com")
                .password("encoded").name("Cleanup patterns IT").build());
    }

    private Account createAccount(User owner) {
        return accountRepository.saveAndFlush(Account.builder()
                .nom("Compte " + UUID.randomUUID().toString().substring(0, 8))
                .type(AccountType.COURANT).soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#000000").bankCode(OTHER_BANK).user(owner).build());
    }
}
