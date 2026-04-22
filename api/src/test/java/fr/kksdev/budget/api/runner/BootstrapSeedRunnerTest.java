package fr.kksdev.budget.api.runner;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.UserPreferenceRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
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
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class BootstrapSeedRunnerTest {

    @Autowired
    private BootstrapSeedRunner bootstrapSeedRunner;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AccountRepository accountRepository;

    @Autowired
    private UserPreferenceRepository userPreferenceRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private ListAppender<ILoggingEvent> logAppender;
    private Logger runnerLogger;

    private final ApplicationArguments noArgs = new DefaultApplicationArguments();

    @BeforeEach
    void setUp() {
        purgeAllData();

        runnerLogger = (Logger) LoggerFactory.getLogger(BootstrapSeedRunner.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        runnerLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        runnerLogger.detachAppender(logAppender);
    }

    private void purgeAllData() {
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        jdbcTemplate.execute("DELETE FROM users");
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
    }

    @Test
    void should_seed_admin_user_with_is_admin_and_password_reset_required_flags_when_db_is_empty() throws Exception {
        bootstrapSeedRunner.run(noArgs);

        List<User> users = userRepository.findAll();
        assertThat(users).hasSize(1);

        User seeded = users.get(0);
        assertThat(seeded.isAdmin()).isTrue();
        assertThat(seeded.isPasswordResetRequired()).isTrue();
    }

    @Test
    void should_seed_account_and_preferences_when_db_is_empty() throws Exception {
        bootstrapSeedRunner.run(noArgs);

        List<User> users = userRepository.findAll();
        assertThat(users).hasSize(1);
        User seeded = users.get(0);

        assertThat(accountRepository.findByUserId(seeded.getId())).isNotEmpty();
        assertThat(userPreferenceRepository.findByUserId(seeded.getId())).isPresent();
    }

    @Test
    void should_log_banner_at_WARN_level_when_seeding() throws Exception {
        bootstrapSeedRunner.run(noArgs);

        List<ILoggingEvent> warnLogs = logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.WARN)
                .toList();

        assertThat(warnLogs).isNotEmpty();
        assertThat(warnLogs.get(0).getFormattedMessage()).contains("FIRST BOOT");
    }

    @Test
    void should_not_seed_when_users_already_exist() throws Exception {
        User existing = User.builder()
                .email("existing@example.com")
                .password("encoded")
                .name("Existing")
                .isAdmin(false)
                .passwordResetRequired(false)
                .build();
        userRepository.save(existing);

        bootstrapSeedRunner.run(noArgs);

        assertThat(userRepository.count()).isEqualTo(1);
        assertThat(logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.WARN)
                .filter(e -> e.getFormattedMessage().contains("FIRST BOOT"))
                .toList()).isEmpty();
    }

    @Test
    void should_not_regenerate_password_on_restart() throws Exception {
        bootstrapSeedRunner.run(noArgs);
        assertThat(userRepository.count()).isEqualTo(1);
        String passwordAfterFirstRun = userRepository.findAll().get(0).getPassword();

        bootstrapSeedRunner.run(noArgs);

        assertThat(userRepository.count()).isEqualTo(1);
        String passwordAfterSecondRun = userRepository.findAll().get(0).getPassword();
        assertThat(passwordAfterSecondRun).isEqualTo(passwordAfterFirstRun);

        long bannerLogCount = logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.WARN)
                .filter(e -> e.getFormattedMessage().contains("FIRST BOOT"))
                .count();
        assertThat(bannerLogCount).isEqualTo(1);
    }

    @Test
    void should_not_seed_when_db_contains_kelly_user_migrated_from_KKS_231() throws Exception {
        User existingAdmin = User.builder()
                .email("kelly@example.com")
                .password("encoded")
                .name("Kelly")
                .isAdmin(true)
                .passwordResetRequired(false)
                .build();
        userRepository.save(existingAdmin);

        bootstrapSeedRunner.run(noArgs);

        assertThat(userRepository.count()).isEqualTo(1);
        assertThat(logAppender.list.stream()
                .filter(e -> e.getLevel() == Level.WARN)
                .filter(e -> e.getFormattedMessage().contains("FIRST BOOT"))
                .toList()).isEmpty();
    }

    // T-024 — custom email via dedicated context with specific property
    @Nested
    @SpringBootTest
    @ActiveProfiles("test")
    @TestPropertySource(properties = "app.bootstrap.email=kelly@exemple.com")
    @DirtiesContext
    class CustomEmailTest {

        @Autowired
        private BootstrapSeedRunner bootstrapSeedRunner;

        @Autowired
        private UserRepository userRepository;

        @Autowired
        private JdbcTemplate jdbcTemplate;

        @BeforeEach
        void setUp() {
            jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
            jdbcTemplate.execute("DELETE FROM users");
            jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
        }

        @Test
        void should_use_custom_email_when_BOOTSTRAP_EMAIL_is_set() throws Exception {
            bootstrapSeedRunner.run(new DefaultApplicationArguments());

            List<User> users = userRepository.findAll();
            assertThat(users).hasSize(1);
            assertThat(users.get(0).getEmail()).isEqualTo("kelly@exemple.com");
        }
    }
}
