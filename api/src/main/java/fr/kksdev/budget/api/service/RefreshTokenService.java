package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.enums.TokenStatus;
import fr.kksdev.budget.api.exception.TokenExpiredException;
import fr.kksdev.budget.api.exception.TokenInvalidException;
import fr.kksdev.budget.api.exception.TokenReusedException;
import fr.kksdev.budget.api.exception.TokenRevokedException;
import fr.kksdev.budget.api.model.RefreshToken;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.RefreshTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtUtil jwtUtil;

    @Value("${app.jwt.refresh-expiration}")
    private long refreshExpiration;

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    public String generateRefreshToken(User user) {
        String tokenValue = generateOpaqueToken();

        RefreshToken refreshToken = RefreshToken.builder()
                .token(tokenValue)
                .status(TokenStatus.ACTIVE)
                .user(user)
                .expiresAt(LocalDateTime.now().plusSeconds(refreshExpiration / 1000))
                .build();

        refreshTokenRepository.save(refreshToken);
        log.info("Refresh token issued for user: {}", user.getEmail());

        return tokenValue;
    }

    public AuthResponse refreshAccessToken(String refreshTokenValue) {
        RefreshToken refreshToken = refreshTokenRepository.findByToken(refreshTokenValue)
                .orElseThrow(TokenInvalidException::new);

        if (refreshToken.getStatus() == TokenStatus.CONSUMED) {
            log.error("Refresh token reuse detected for user: {}. Revoking all active tokens.",
                    refreshToken.getUser().getEmail());
            revokeAllUserTokens(refreshToken.getUser());
            throw new TokenReusedException();
        }

        if (refreshToken.getStatus() == TokenStatus.REVOKED) {
            throw new TokenRevokedException();
        }

        if (refreshToken.getStatus() != TokenStatus.ACTIVE) {
            throw new TokenInvalidException();
        }

        if (refreshToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new TokenExpiredException();
        }

        refreshToken.setStatus(TokenStatus.CONSUMED);
        refreshTokenRepository.save(refreshToken);

        User user = refreshToken.getUser();
        String newRefreshTokenValue = generateRefreshToken(user);
        java.util.Map<String, Object> extraClaims = user.isPasswordResetRequired()
                ? java.util.Map.of("mustResetCredentials", true)
                : java.util.Map.of();
        String newAccessToken = jwtUtil.generateToken(user.getEmail(), extraClaims);

        log.info("Token refreshed for user: {}", user.getEmail());

        return new AuthResponse(newAccessToken, newRefreshTokenValue, user.getEmail(), user.getName(),
                user.isPasswordResetRequired());
    }

    public void revokeAllUserTokens(User user) {
        List<RefreshToken> activeTokens = refreshTokenRepository.findByUserAndStatus(user, TokenStatus.ACTIVE);
        activeTokens.forEach(token -> token.setStatus(TokenStatus.REVOKED));
        refreshTokenRepository.saveAll(activeTokens);
        log.warn("All active refresh tokens revoked for user: {} (count: {})",
                user.getEmail(), activeTokens.size());
    }

    public void revokeRefreshToken(String refreshTokenValue) {
        RefreshToken refreshToken = refreshTokenRepository.findByToken(refreshTokenValue)
                .orElseThrow(TokenInvalidException::new);

        if (refreshToken.getStatus() != TokenStatus.ACTIVE) {
            throw new TokenInvalidException();
        }

        refreshToken.setStatus(TokenStatus.REVOKED);
        refreshTokenRepository.save(refreshToken);
        log.info("Refresh token revoked for user: {}", refreshToken.getUser().getEmail());
    }

    private String generateOpaqueToken() {
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
