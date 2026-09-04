package fr.kksdev.budget.api.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

@Component
public class JwtUtil {

    private final SecretKey key;
    private final long expiration;

    /**
     * Longueur minimale du secret : HS256 exige une cle d'au moins 256 bits.
     * En deca, {@code Keys.hmacShaKeyFor} leve une exception dont le message
     * ne dit pas quoi faire.
     */
    private static final int MIN_SECRET_LENGTH = 32;

    /** Valeur portee par {@code .env.example}, jamais valide en execution. */
    private static final String PLACEHOLDER_PREFIX = "CHANGEME";

    public JwtUtil(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.access-expiration}") long expiration) {
        validateSecret(secret);
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expiration = expiration;
    }

    /**
     * Refuse de demarrer plutot que de signer avec un secret devinable
     * (KKS-320).
     *
     * <p>Un secret laisse a la valeur d'exemple est public : il est dans le
     * depot. N'importe qui pourrait forger un jeton valide pour n'importe quel
     * compte de l'instance. L'echec au demarrage est bruyant, mais il l'est
     * beaucoup moins qu'une compromission silencieuse.
     */
    private static void validateSecret(String secret) {
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException(
                    "JWT_SECRET is not set. Generate one with: openssl rand -base64 48");
        }
        if (secret.startsWith(PLACEHOLDER_PREFIX)) {
            throw new IllegalStateException(
                    "JWT_SECRET still holds the example value from .env.example. "
                            + "That value is public: anyone could forge a token for any account. "
                            + "Generate your own with: openssl rand -base64 48");
        }
        if (secret.length() < MIN_SECRET_LENGTH) {
            throw new IllegalStateException(
                    "JWT_SECRET is too short (" + secret.length() + " characters, "
                            + MIN_SECRET_LENGTH + " required for HS256). "
                            + "Generate one with: openssl rand -base64 48");
        }
    }

    public String generateToken(String email) {
        return generateToken(email, Map.of());
    }

    public String generateToken(String email, Map<String, Object> extraClaims) {
        var builder = Jwts.builder()
                .subject(email)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiration));
        extraClaims.forEach(builder::claim);
        return builder.signWith(key).compact();
    }

    public Object extractClaim(String token, String claimName) {
        return extractClaims(token).get(claimName);
    }

    public String extractEmail(String token) {
        return extractClaims(token).getSubject();
    }

    public boolean isTokenValid(String token) {
        try {
            extractClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private Claims extractClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
