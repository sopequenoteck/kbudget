package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.FirstLoginResetRequest;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.PasswordResetNotRequiredException;
import fr.kksdev.budget.api.exception.PasswordUnchangedException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RefreshTokenService refreshTokenService;

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> {
                    log.error("Login failed for email: {}", request.email());
                    return new IllegalArgumentException("Email ou mot de passe incorrect");
                });

        if (!passwordEncoder.matches(request.password(), user.getPassword())) {
            log.error("Login failed for email: {}", request.email());
            throw new IllegalArgumentException("Email ou mot de passe incorrect");
        }

        log.info("User logged in: {}", user.getEmail());
        Map<String, Object> extraClaims = user.isPasswordResetRequired()
                ? Map.of("mustResetCredentials", true)
                : Map.of();
        String token = jwtUtil.generateToken(user.getEmail(), extraClaims);
        String refreshToken = refreshTokenService.generateRefreshToken(user);
        return new AuthResponse(token, refreshToken, user.getEmail(), user.getName(),
                user.isPasswordResetRequired());
    }

    @Transactional
    public AuthResponse firstLoginReset(UUID userId, FirstLoginResetRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur non trouvé"));

        if (!user.isPasswordResetRequired()) {
            log.warn("First-login-reset refused: flag already cleared for userId={}", userId);
            throw new PasswordResetNotRequiredException();
        }

        // Vérifier unicité email si changement
        if (!request.email().equalsIgnoreCase(user.getEmail())
                && userRepository.existsByEmail(request.email())) {
            log.warn("First-login-reset refused: email already used: {}", request.email());
            throw new ConflictException("EMAIL_ALREADY_EXISTS");
        }

        // Refuser si password inchangé
        if (passwordEncoder.matches(request.password(), user.getPassword())) {
            throw new PasswordUnchangedException();
        }

        user.setEmail(request.email());
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setName(request.displayName());
        user.setPasswordResetRequired(false);
        userRepository.save(user);

        log.info("User reset credentials: userId={} newEmail={}", userId, request.email());

        String token = jwtUtil.generateToken(user.getEmail());
        String refreshToken = refreshTokenService.generateRefreshToken(user);
        return new AuthResponse(token, refreshToken, user.getEmail(), user.getName(), false);
    }
}
