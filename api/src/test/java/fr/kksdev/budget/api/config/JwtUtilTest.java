package fr.kksdev.budget.api.config;

import org.junit.jupiter.api.Test;

import java.util.Map;

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

    // ---- T-034 : Tests extra claims (FR-008) ----

    @Test
    void should_include_extra_claims_when_generating_token() {
        String token = jwtUtil.generateToken(EMAIL, Map.of("mustResetCredentials", true));

        Object claim = jwtUtil.extractClaim(token, "mustResetCredentials");

        assertThat(claim).isEqualTo(true);
    }

    @Test
    void should_return_null_when_extracting_absent_claim() {
        String token = jwtUtil.generateToken(EMAIL);

        Object claim = jwtUtil.extractClaim(token, "unknown");

        assertThat(claim).isNull();
    }

    @Test
    void should_return_claim_value_when_extracting_present_claim() {
        String token = jwtUtil.generateToken(EMAIL, Map.of("mustResetCredentials", true));

        Object claim = jwtUtil.extractClaim(token, "mustResetCredentials");

        assertThat(claim).isEqualTo(true);
    }

    @Test
    void should_preserve_subject_when_adding_claims() {
        String token = jwtUtil.generateToken(EMAIL, Map.of("mustResetCredentials", true));

        String extracted = jwtUtil.extractEmail(token);

        assertThat(extracted).isEqualTo(EMAIL);
    }
}
