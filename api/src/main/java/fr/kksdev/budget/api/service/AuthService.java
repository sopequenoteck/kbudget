package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.request.RegisterRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final CategoryService categoryService;
    private final RefreshTokenService refreshTokenService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            log.warn("Registration failed: email already exists: {}", request.email());
            throw new IllegalArgumentException("Email déjà utilisé");
        }

        User user = User.builder()
                .email(request.email())
                .password(passwordEncoder.encode(request.password()))
                .name(request.name())
                .build();

        userRepository.save(user);
        categoryService.seedSystemCategories(user);
        log.info("User registered: {}", user.getEmail());

        String token = jwtUtil.generateToken(user.getEmail());
        String refreshToken = refreshTokenService.generateRefreshToken(user);
        return new AuthResponse(token, refreshToken, user.getEmail(), user.getName());
    }

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
