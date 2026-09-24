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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AcceptInviteService {

    private final InvitationService invitationService;
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final RefreshTokenService refreshTokenService;
    private final UserOnboardingService userOnboardingService;

    @Transactional
    public AuthResponse acceptInvite(AcceptInviteRequest request) {
        Invitation invitation = invitationService.validatePublic(request.token())
                .orElseThrow(() -> new EntityNotFoundException("Invalid invitation."));

        if (userRepository.existsByEmail(invitation.getEmail())) {
            log.warn("Invite acceptance failed: email already exists: {}", invitation.getEmail());
            throw new IllegalArgumentException("Email already used");
        }

        User user = userOnboardingService.provisionUser(new UserOnboardingService.UserProvisioningRequest(
                invitation.getEmail(),
                request.password(),
                request.displayName(),
                request.currency(),
                request.timezone(),
                false,  // isAdmin
                false   // passwordResetRequired
        ));

        invitationService.markUsed(invitation);
        log.info("User onboarded via invitation: {}", user.getEmail());

        String token = jwtUtil.generateToken(user.getEmail());
        String refreshToken = refreshTokenService.generateRefreshToken(user);
        return new AuthResponse(token, refreshToken, user.getEmail(), user.getName(), false);
    }
}
