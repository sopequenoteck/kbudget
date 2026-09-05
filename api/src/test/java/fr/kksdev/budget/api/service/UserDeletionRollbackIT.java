package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.DeleteAccountRequest;
import fr.kksdev.budget.api.enums.TokenStatus;
import fr.kksdev.budget.api.model.RefreshToken;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.RefreshTokenRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.doThrow;

@SpringBootTest
@Testcontainers
class UserDeletionRollbackIT {

    private static final String PASSWORD = "RollbackPassword1!";

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @org.springframework.test.context.DynamicPropertySource
    static void postgresProperties(org.springframework.test.context.DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("app.admin-emails", () -> "");
        // Sans profil "test" ici : la propriete doit etre posee a la main.
        // Une tache planifiee qui lit users pendant le TRUNCATE interbloque (KKS-356).
        registry.add("app.scheduling.enabled", () -> "false");
        registry.add("app.jwt.secret", () -> "test-secret-key-budget-app-min-256-bits-long-enough-for-hmac-sha");
    }

    @Autowired UserRepository userRepository;
    @Autowired RefreshTokenRepository refreshTokenRepository;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired UserDeletionService userDeletionService;
    @Autowired TransactionTemplate transactionTemplate;
    @Autowired JdbcTemplate jdbcTemplate;

    @MockitoBean BootstrapSeedRunner bootstrapSeedRunner;
    @MockitoBean RefreshTokenService refreshTokenService;

    @Test
    void revoke_failure_rolls_back_user_and_all_refresh_tokens() {
        jdbcTemplate.execute("TRUNCATE TABLE users CASCADE");
        User user = userRepository.saveAndFlush(User.builder()
                .email("rollback@example.com")
                .password(passwordEncoder.encode(PASSWORD))
                .name("Rollback")
                .isAdmin(false)
                .passwordResetRequired(false)
                .build());
        refreshTokenRepository.saveAndFlush(RefreshToken.builder()
                .token("rollback-refresh-token")
                .status(TokenStatus.ACTIVE)
                .user(user)
                .expiresAt(LocalDateTime.now().plusHours(1))
                .build());
        doThrow(new IllegalStateException("forced revoke failure"))
                .when(refreshTokenService).revokeAllUserTokens(org.mockito.ArgumentMatchers.any(User.class));

        assertThatThrownBy(() -> transactionTemplate.executeWithoutResult(status ->
                userDeletionService.softDelete(user, new DeleteAccountRequest(PASSWORD, true))))
                .isInstanceOf(IllegalStateException.class);

        assertThat(userRepository.findById(user.getId())).get().extracting(User::getDisabledAt).isNull();
        var tokenAfterRollback = transactionTemplate.execute(status ->
                refreshTokenRepository.findByToken("rollback-refresh-token"));
        assertThat(tokenAfterRollback)
                .get().extracting(RefreshToken::getStatus).isEqualTo(TokenStatus.ACTIVE);
    }
}
