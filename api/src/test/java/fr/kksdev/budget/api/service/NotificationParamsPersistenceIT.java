package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.EntityType;
import fr.kksdev.budget.api.enums.NotificationType;
import fr.kksdev.budget.api.model.Notification;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.NotificationRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Aller-retour JSONB Postgres du champ {@code params} d'une notification
 * (KKS-397) : H2 (profil test) accepte le type SQL JSON mais ne prouve rien
 * sur le mapping JSONB reel utilise en production.
 */
@SpringBootTest
@Testcontainers
class NotificationParamsPersistenceIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("app.admin-emails", () -> "");
        // Sans profil "test" ici : la propriete doit etre posee a la main.
        registry.add("app.scheduling.enabled", () -> "false");
        registry.add("app.jwt.secret", () -> "test-secret-key-budget-app-min-256-bits-long-enough-for-hmac-sha");
    }

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private EntityManager entityManager;

    @MockitoBean
    private BootstrapSeedRunner bootstrapSeedRunner;

    private User buildUser(String email) {
        return userRepository.saveAndFlush(User.builder()
                .email(email)
                .password("encoded")
                .name("Params IT")
                .build());
    }

    @Test
    void should_persist_and_read_back_params_when_notification_has_params() {
        User user = buildUser("notification-params-it@example.com");
        Map<String, String> params = Map.of("name", "Netflix");
        Notification notification = Notification.builder()
                .user(user)
                .type(NotificationType.SUBSCRIPTION_DUE)
                .title("Subscription Netflix")
                .message("Netflix is due tomorrow")
                .entityType(EntityType.SUBSCRIPTION)
                .entityId(UUID.randomUUID())
                .params(params)
                .build();

        Notification saved = notificationRepository.saveAndFlush(notification);
        entityManager.clear();

        Notification reloaded = notificationRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getParams()).isEqualTo(params);
    }

    @Test
    void should_persist_null_params_when_notification_has_no_params() {
        User user = buildUser("notification-no-params-it@example.com");
        Notification notification = Notification.builder()
                .user(user)
                .type(NotificationType.DEBT_DUE)
                .title("Debt with Alice")
                .message("Debt with Alice is due tomorrow")
                .entityType(EntityType.DEBT)
                .entityId(UUID.randomUUID())
                .build();

        Notification saved = notificationRepository.saveAndFlush(notification);
        entityManager.clear();

        Notification reloaded = notificationRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getParams()).isNull();
    }
}
