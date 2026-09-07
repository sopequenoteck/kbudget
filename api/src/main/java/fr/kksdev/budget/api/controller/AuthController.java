package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.AcceptInviteRequest;
import fr.kksdev.budget.api.dto.request.FirstLoginResetRequest;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.request.LogoutRequest;
import fr.kksdev.budget.api.dto.request.RefreshRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.dto.response.InviteLookupResponse;
import fr.kksdev.budget.api.model.Invitation;
import fr.kksdev.budget.api.service.AcceptInviteService;
import fr.kksdev.budget.api.service.AuthService;
import fr.kksdev.budget.api.service.InvitationService;
import fr.kksdev.budget.api.service.RefreshTokenService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Tag(name = "Authentification", description = "Connexion, gestion des tokens et onboarding via invitation")
public class AuthController {

    private final AuthService authService;
    private final RefreshTokenService refreshTokenService;
    private final AcceptInviteService acceptInviteService;
    private final InvitationService invitationService;

    @Operation(summary = "Se connecter et obtenir un token JWT")
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @Operation(summary = "Renouveler les tokens via refresh token")
    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(refreshTokenService.refreshAccessToken(request.refreshToken()));
    }

    @Operation(summary = "Se déconnecter et révoquer le refresh token")
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@Valid @RequestBody LogoutRequest request) {
        refreshTokenService.revokeRefreshToken(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Valider un token d'invitation (public)")
    @GetMapping("/invitations/{token}")
    public ResponseEntity<InviteLookupResponse> lookupInvitation(@PathVariable UUID token) {
        Invitation invitation = invitationService.validatePublic(token)
                .orElseThrow(() -> new EntityNotFoundException("Invalid invitation."));
        return ResponseEntity.ok(new InviteLookupResponse(invitation.getEmail()));
    }

    @Operation(summary = "Accepter une invitation et créer le compte utilisateur")
    @PostMapping("/accept-invite")
    public ResponseEntity<AuthResponse> acceptInvite(@Valid @RequestBody AcceptInviteRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(acceptInviteService.acceptInvite(request));
    }

    @Operation(summary = "Reset forcé des credentials à la première connexion")
    @PostMapping("/first-login-reset")
    public ResponseEntity<AuthResponse> firstLoginReset(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody FirstLoginResetRequest request) {
        return ResponseEntity.ok(authService.firstLoginReset(userId, request));
    }
}
