package fr.kksdev.budget.api.runner;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = "app.admin-emails=sync-admin@example.com,another-admin@example.com")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class AdminSyncRunnerTest {

    @Autowired
    private AdminSyncRunner adminSyncRunner;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private ListAppender<ILoggingEvent> logAppender;
    private Logger runnerLogger;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        jdbcTemplate.execute("DELETE FROM users");
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");

        runnerLogger = (Logger) LoggerFactory.getLogger(AdminSyncRunner.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        runnerLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        runnerLogger.detachAppender(logAppender);
    }

    @Test
    void should_promote_user_when_email_is_in_ADMIN_EMAILS_and_isAdmin_is_false() throws Exception {
        User user = userRepository.save(User.builder()
                .email("sync-admin@example.com")
                .password("encoded")
                .name("Sync Admin")
                .isAdmin(false)
                .passwordResetRequired(false)
                .build());

        adminSyncRunner.run(new DefaultApplicationArguments());

        User updated = userRepository.findById(user.getId()).orElseThrow();
        assertThat(updated.isAdmin()).isTrue();

        List<ILoggingEvent> infoLogs = logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.INFO)
                .filter(e -> e.getFormattedMessage().contains("Admin promoted via ADMIN_EMAILS sync"))
                .toList();
        assertThat(infoLogs).isNotEmpty();
    }

    @Test
    void should_not_downgrade_user_when_isAdmin_true_and_email_absent_from_ADMIN_EMAILS() throws Exception {
        // Critical test — FR-012b: runner never downgrades
        User adminUser = userRepository.save(User.builder()
                .email("independent-admin@example.com")
                .password("encoded")
                .name("Independent Admin")
                .isAdmin(true)
                .passwordResetRequired(false)
                .build());

        adminSyncRunner.run(new DefaultApplicationArguments());

        User after = userRepository.findById(adminUser.getId()).orElseThrow();
        assertThat(after.isAdmin()).isTrue();
    }

    @Test
    void should_be_idempotent_on_successive_runs() throws Exception {
        User user = userRepository.save(User.builder()
                .email("sync-admin@example.com")
                .password("encoded")
                .name("Sync Admin")
                .isAdmin(false)
                .passwordResetRequired(false)
                .build());

        // First run — promotes
        adminSyncRunner.run(new DefaultApplicationArguments());

        long infoCountAfterFirst = logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.INFO)
                .filter(e -> e.getFormattedMessage().contains("Admin promoted via ADMIN_EMAILS sync"))
                .count();
        assertThat(infoCountAfterFirst).isEqualTo(1);

        // Second run — no additional promotion
        adminSyncRunner.run(new DefaultApplicationArguments());

        long infoCountAfterSecond = logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.INFO)
                .filter(e -> e.getFormattedMessage().contains("Admin promoted via ADMIN_EMAILS sync"))
                .count();
        assertThat(infoCountAfterSecond).isEqualTo(1);

        User after = userRepository.findById(user.getId()).orElseThrow();
        assertThat(after.isAdmin()).isTrue();
    }

    @Test
    void should_do_nothing_when_ADMIN_EMAILS_references_nonexistent_user() throws Exception {
        // sync-admin@example.com is in ADMIN_EMAILS but no user exists in DB
        long countBefore = userRepository.count();

        adminSyncRunner.run(new DefaultApplicationArguments());

        assertThat(userRepository.count()).isEqualTo(countBefore);
        assertThat(logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.INFO)
                .filter(e -> e.getFormattedMessage().contains("Admin promoted via ADMIN_EMAILS sync"))
                .toList()).isEmpty();
    }
}
