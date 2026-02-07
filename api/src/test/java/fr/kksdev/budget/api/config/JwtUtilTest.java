package fr.kksdev.budget.api.config;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class JwtUtilTest {

    private static final String SECRET = "test-secret-key-budget-app-min-256-bits-long-enough-for-hmac-sha";
    private static final long EXPIRATION = 86400000L;
    private static final String EMAIL = "test@mail.com";

    private final JwtUtil jwtUtil = new JwtUtil(SECRET, EXPIRATION);

    @Test
    void should_generate_non_empty_token_when_email_provided() {
        String token = jwtUtil.generateToken(EMAIL);

        assertThat(token).isNotBlank();
    }

    @Test
    void should_extract_email_when_token_valid() {
        String token = jwtUtil.generateToken(EMAIL);

        String extracted = jwtUtil.extractEmail(token);

        assertThat(extracted).isEqualTo(EMAIL);
    }

    @Test
    void should_return_true_when_token_valid() {
        String token = jwtUtil.generateToken(EMAIL);

        assertThat(jwtUtil.isTokenValid(token)).isTrue();
    }

    @Test
    void should_return_false_when_token_malformed() {
        assertThat(jwtUtil.isTokenValid("not-a-jwt-token")).isFalse();
    }

    @Test
    void should_return_false_when_token_empty() {
        assertThat(jwtUtil.isTokenValid("")).isFalse();
    }

    @Test
    void should_return_false_when_token_signed_with_different_key() {
        var otherJwtUtil = new JwtUtil(
                "other-secret-key-budget-app-min-256-bits-long-enough-for-hmac-sha",
                EXPIRATION);
        String token = otherJwtUtil.generateToken(EMAIL);

        assertThat(jwtUtil.isTokenValid(token)).isFalse();
    }

    @Test
    void should_return_false_when_token_expired() {
        var expiredJwtUtil = new JwtUtil(SECRET, -1000L);
        String token = expiredJwtUtil.generateToken(EMAIL);

        assertThat(jwtUtil.isTokenValid(token)).isFalse();
    }

    @Test
    void should_generate_different_tokens_for_different_emails() {
        String token1 = jwtUtil.generateToken("user1@mail.com");
        String token2 = jwtUtil.generateToken("user2@mail.com");

        assertThat(token1).isNotEqualTo(token2);
    }
}
