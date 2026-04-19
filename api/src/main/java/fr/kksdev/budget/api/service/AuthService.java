package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

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
        String token = jwtUtil.generateToken(user.getEmail());
        String refreshToken = refreshTokenService.generateRefreshToken(user);
        return new AuthResponse(token, refreshToken, user.getEmail(), user.getName());
    }
}
