package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.ImportDraftLineResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.ImportReadError;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.ImportDraftLineRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Migration V43 and the read error of statement lines (KKS-441) on a real PostgreSQL: Flyway
 * creates the columns, Hibernate validates the mapping against them, and the code and the raw
 * value of an unreadable line survive the round trip. H2 (profile test) generates its schema
 * from the entities and proves none of it.
 */
@SpringBootTest
@Testcontainers
class ImportReadErrorPersistenceIT {

    private static final String BAD_DATE = "99/99/2026;CARTE X1596 14/09 ;CARTE X1596 14/09 BOULANGERIE DU MARCHE 110600000000101IOPD ;-4,30;EUR";
    private static final String BAD_AMOUNT = "16/09/2026;CARTE X1596 14/09 ;CARTE X1596 14/09 BOULANGERIE DU MARCHE 110600000000101IOPD ;abc;EUR";
    private static final String READABLE = "20/09/2026;VIR RECU    123456;VIR RECU    1234567890S DE: EMPLOYEUR TEST REF: SALAIRE ;1500,00;EUR";

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
    @Autowired private ImportDraftLineRepository importDraftLineRepository;
    @Autowired private ImportService importService;
    @Autowired private EntityManager entityManager;

    @MockitoBean
    private BootstrapSeedRunner bootstrapSeedRunner;

    @Test
    void should_persist_and_serve_the_read_error_when_lines_are_unreadable_on_postgres() {
        User user = userRepository.saveAndFlush(
                User.builder().email("read-error-persistence-it@example.com").password("encoded").name("Read error IT").build());
        Account account = accountRepository.saveAndFlush(Account.builder()
                .nom("Compte principal").type(AccountType.COURANT).soldeInitial(BigDecimal.ZERO)
                .icone("🏦").couleur("#000000").bankCode("SG").user(user).build());
        MockMultipartFile file = new MockMultipartFile("file", "releve.csv", "text/csv", ImportTestFiles.sgStatementOf(
                ImportTestFiles.sgBankHeader("00000000001596", "01/10/2026", "0.00 EUR"), BAD_DATE, BAD_AMOUNT, READABLE));

        ImportDraftResponse draft = importService.upload(file, account.getId(), user.getId());
        entityManager.clear();

        List<ImportDraftLine> stored = importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draft.id());
        assertThat(stored).extracting(ImportDraftLine::getReadError)
                .containsExactly(ImportReadError.INVALID_DATE, ImportReadError.INVALID_AMOUNT, null);
        assertThat(stored).extracting(ImportDraftLine::getReadErrorValue).containsExactly("99/99/2026", "abc", null);

        List<ImportDraftLineResponse> served = importService.getDraft(draft.id(), user.getId()).lines();
        assertThat(served.get(0).readError()).isEqualTo("INVALID_DATE");
        assertThat(served.get(0).readErrorValue()).isEqualTo("99/99/2026");
        assertThat(served.get(0).statusMessage()).startsWith("Invalid date: ");
        assertThat(served.get(1).readError()).isEqualTo("INVALID_AMOUNT");
        assertThat(served.get(1).readErrorValue()).isEqualTo("abc");
        assertThat(served.get(1).statusMessage()).startsWith("Invalid amount: ");
        assertThat(served.get(2).readError()).isNull();
        assertThat(served.get(2).readErrorValue()).isNull();
        assertThat(served.get(2).statusMessage()).isNull();
    }
}
