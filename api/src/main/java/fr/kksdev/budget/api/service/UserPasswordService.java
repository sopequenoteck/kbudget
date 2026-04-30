package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.ChangePasswordRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.exception.PasswordIncorrectException;
import fr.kksdev.budget.api.exception.PasswordUnchangedException;
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
public class UserPasswordService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RefreshTokenService refreshTokenService;

    @Transactional
    public AuthResponse changePassword(User user, ChangePasswordRequest req) {
        if (!passwordEncoder.matches(req.currentPassword(), user.getPassword())) {
            throw new PasswordIncorrectException();
        }

        if (passwordEncoder.matches(req.newPassword(), user.getPassword())) {
            throw new PasswordUnchangedException();
        }

        user.setPassword(passwordEncoder.encode(req.newPassword()));
        userRepository.save(user);

        refreshTokenService.revokeAllUserTokens(user);

        String token = jwtUtil.generateToken(user.getEmail());
        String refreshToken = refreshTokenService.generateRefreshToken(user);

        log.info("User {} changed password", user.getId());

        return new AuthResponse(
                token,
                refreshToken,
                user.getEmail(),
                user.getName(),
                user.isPasswordResetRequired()
        );
    }
}
