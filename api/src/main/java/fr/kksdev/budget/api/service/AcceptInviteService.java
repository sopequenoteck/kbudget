package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.AcceptInviteRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.model.Invitation;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AcceptInviteService {

    private final InvitationService invitationService;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final CategoryService categoryService;
    private final AccountService accountService;
    private final RefreshTokenService refreshTokenService;
    private final PreferenceService preferenceService;

    @Transactional
    public AuthResponse acceptInvite(AcceptInviteRequest request) {
        Invitation invitation = invitationService.validatePublic(request.token())
                .orElseThrow(() -> new EntityNotFoundException("Invitation invalide."));

        if (userRepository.existsByEmail(invitation.getEmail())) {
            log.warn("Invite acceptance failed: email already exists: {}", invitation.getEmail());
            throw new IllegalArgumentException("Email déjà utilisé");
        }

        User user = User.builder()
                .email(invitation.getEmail())
                .password(passwordEncoder.encode(request.password()))
                .name(request.displayName())
                .build();

        userRepository.save(user);
        categoryService.seedSystemCategories(user);
        accountService.createDefaultAccount(user, request.currency());
        preferenceService.createInitialPreference(user, request.currency(), request.timezone());
        invitationService.markUsed(invitation);
        log.info("User onboarded via invitation: {}", user.getEmail());

        String token = jwtUtil.generateToken(user.getEmail());
        String refreshToken = refreshTokenService.generateRefreshToken(user);
        return new AuthResponse(token, refreshToken, user.getEmail(), user.getName());
    }
}
