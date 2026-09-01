package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.enums.TokenStatus;
import fr.kksdev.budget.api.model.RefreshToken;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.RefreshTokenRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.BootstrapSeedRunner;
import fr.kksdev.budget.api.service.ActiveAdminInvariantLock;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class UserDeletionConcurrencyIT {

    private static final String PASSWORD = "ConcurrentPassword1!";

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("app.admin-emails", () -> "");
        registry.add("app.jwt.secret", () -> "test-secret-key-budget-app-min-256-bits-long-enough-for-hmac-sha");
        registry.add("app.jwt.access-expiration", () -> "900000");
        registry.add("app.jwt.refresh-expiration", () -> "2592000000");
    }

    @Autowired MockMvc mockMvc;
    @Autowired UserRepository userRepository;
    @Autowired RefreshTokenRepository refreshTokenRepository;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired JwtUtil jwtUtil;
    @Autowired JdbcTemplate jdbcTemplate;
    @Autowired TransactionTemplate transactionTemplate;
    @Autowired ActiveAdminInvariantLock activeAdminInvariantLock;

    @MockitoBean BootstrapSeedRunner bootstrapSeedRunner;

    @BeforeEach
    void cleanDatabase() {
        jdbcTemplate.execute("TRUNCATE TABLE users CASCADE");
    }

    @Test
    void should_preserve_one_admin_and_rejected_admin_refresh_token_under_concurrent_deletion() {
        org.junit.jupiter.api.Assertions.assertTimeoutPreemptively(Duration.ofSeconds(30), this::runScenario);
    }

    @Test
    void vulnerable_count_then_disable_algorithm_deterministically_deletes_both_admins() {
        org.junit.jupiter.api.Assertions.assertTimeoutPreemptively(Duration.ofSeconds(30), () -> {
            User first = createAdmin("vulnerable-admin-1@example.com");
            User second = createAdmin("vulnerable-admin-2@example.com");
            var bothCountsCompleted = new CyclicBarrier(2);

            try (var executor = Executors.newFixedThreadPool(2)) {
                Future<?> firstDeletion = executor.submit(
                        () -> runVulnerableDeletion(first.getId(), bothCountsCompleted));
                Future<?> secondDeletion = executor.submit(
                        () -> runVulnerableDeletion(second.getId(), bothCountsCompleted));

                firstDeletion.get(20, TimeUnit.SECONDS);
                secondDeletion.get(20, TimeUnit.SECONDS);
            }

            assertThat(userRepository.countActiveAdmins()).isZero();
        });
    }

    @Test
    void advisory_lock_waits_for_independent_transaction_rollback() throws Exception {
        CountDownLatch firstAcquired = new CountDownLatch(1);
        CountDownLatch releaseFirst = new CountDownLatch(1);
        CountDownLatch secondAcquired = new CountDownLatch(1);

        try (var executor = Executors.newFixedThreadPool(2)) {
            Future<?> first = executor.submit(() -> {
                try {
                    transactionTemplate.executeWithoutResult(status -> {
                        activeAdminInvariantLock.acquire();
                        firstAcquired.countDown();
                        try {
                            releaseFirst.await(5, TimeUnit.SECONDS);
                        } catch (InterruptedException exception) {
                            Thread.currentThread().interrupt();
                            throw new IllegalStateException("Lock release barrier interrupted", exception);
                        }
                        status.setRollbackOnly();
                    });
                } finally {
                    releaseFirst.countDown();
                }
            });
            assertThat(firstAcquired.await(5, TimeUnit.SECONDS)).isTrue();

            Future<?> second = executor.submit(() -> transactionTemplate.executeWithoutResult(status -> {
                activeAdminInvariantLock.acquire();
                secondAcquired.countDown();
            }));

            assertThat(secondAcquired.await(250, TimeUnit.MILLISECONDS)).isFalse();
            releaseFirst.countDown();
            first.get(10, TimeUnit.SECONDS);
            second.get(10, TimeUnit.SECONDS);
            assertThat(secondAcquired.await(1, TimeUnit.SECONDS)).isTrue();
        }
    }

    private void runScenario() throws Exception {
        User first = createAdmin("concurrent-admin-1@example.com");
        User second = createAdmin("concurrent-admin-2@example.com");
        Map<String, String> refreshTokens = Map.of(
                first.getEmail(), createRefreshToken(first, "refresh-token-admin-1"),
                second.getEmail(), createRefreshToken(second, "refresh-token-admin-2"));

        var barrier = new CyclicBarrier(3);
        try (var executor = Executors.newFixedThreadPool(2)) {
            Future<DeletionResult> firstRequest = executor.submit(() -> deleteAfterBarrier(first, barrier));
            Future<DeletionResult> secondRequest = executor.submit(() -> deleteAfterBarrier(second, barrier));
            barrier.await(5, TimeUnit.SECONDS);

            List<DeletionResult> results = List.of(
                    firstRequest.get(20, TimeUnit.SECONDS), secondRequest.get(20, TimeUnit.SECONDS));
            assertThat(results).extracting(DeletionResult::status).containsExactlyInAnyOrder(204, 403);

            DeletionResult rejected = results.stream().filter(result -> result.status() == 403).findFirst().orElseThrow();
            assertThat(rejected.body()).contains("LAST_ADMIN_DELETION_FORBIDDEN");
            assertThat(rejected.body()).contains("Au moins un administrateur actif doit exister.");
            assertThat(userRepository.countActiveAdmins()).isEqualTo(1);

            User protectedAdmin = userRepository.findByEmail(rejected.email()).orElseThrow();
            User deletedAdmin = userRepository.findByEmail(
                    results.stream().filter(result -> result.status() == 204).findFirst().orElseThrow().email())
                    .orElseThrow();
            assertThat(protectedAdmin.getDisabledAt()).isNull();
            assertThat(deletedAdmin.getDisabledAt()).isNotNull();
            var protectedToken = transactionTemplate.execute(status -> refreshTokenRepository.findByToken(
                    refreshTokens.get(protectedAdmin.getEmail())));
            assertThat(protectedToken)
                    .get().extracting(RefreshToken::getStatus).isEqualTo(TokenStatus.ACTIVE);

            assertThat(refresh(refreshTokens.get(protectedAdmin.getEmail())).getResponse().getStatus()).isEqualTo(200);
            MvcResult revokedRefresh = refresh(refreshTokens.get(deletedAdmin.getEmail()));
            assertThat(revokedRefresh.getResponse().getStatus()).isEqualTo(401);
            assertThat(revokedRefresh.getResponse().getContentAsString()).contains("TOKEN_REVOKED");
        }
    }

    private DeletionResult deleteAfterBarrier(User user, CyclicBarrier barrier) throws Exception {
        barrier.await(5, TimeUnit.SECONDS);
        MvcResult result = mockMvc.perform(delete("/v1/users/me")
                        .header("Authorization", "Bearer " + jwtUtil.generateToken(user.getEmail()))
                        .contentType("application/json")
                        .content("{\"currentPassword\":\"" + PASSWORD + "\",\"confirmed\":true}"))
                .andReturn();
        return new DeletionResult(user.getEmail(), result.getResponse().getStatus(),
                result.getResponse().getContentAsString());
    }

    private void runVulnerableDeletion(java.util.UUID userId, CyclicBarrier bothCountsCompleted) {
        transactionTemplate.executeWithoutResult(status -> {
            Long activeAdmins = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM users WHERE is_admin = TRUE AND disabled_at IS NULL", Long.class);
            assertThat(activeAdmins).isEqualTo(2L);
            await(bothCountsCompleted);
            jdbcTemplate.update("UPDATE users SET disabled_at = CURRENT_TIMESTAMP WHERE id = ?", userId);
        });
    }

    private void await(CyclicBarrier barrier) {
        try {
            barrier.await(5, TimeUnit.SECONDS);
        } catch (Exception exception) {
            throw new IllegalStateException("Concurrent test barrier failed", exception);
        }
    }

    private MvcResult refresh(String token) throws Exception {
        return mockMvc.perform(post("/v1/auth/refresh")
                        .contentType("application/json")
                        .content("{\"refreshToken\":\"" + token + "\"}"))
                .andReturn();
    }

    private User createAdmin(String email) {
        return userRepository.saveAndFlush(User.builder()
                .email(email)
                .password(passwordEncoder.encode(PASSWORD))
                .name(email)
                .isAdmin(true)
                .passwordResetRequired(false)
                .build());
    }

    private String createRefreshToken(User user, String value) {
        refreshTokenRepository.saveAndFlush(RefreshToken.builder()
                .token(value)
                .status(TokenStatus.ACTIVE)
                .user(user)
                .expiresAt(LocalDateTime.now().plusHours(1))
                .build());
        return value;
    }

    private record DeletionResult(String email, int status, String body) {}
}
