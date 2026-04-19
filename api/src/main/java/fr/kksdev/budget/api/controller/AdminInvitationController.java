package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.CreateInvitationRequest;
import fr.kksdev.budget.api.dto.response.InvitationCreatedResponse;
import fr.kksdev.budget.api.dto.response.InvitationResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.InvitationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/admin/invitations")
@RequiredArgsConstructor
@Tag(name = "Admin - Invitations", description = "Gestion des invitations d'onboarding (admin)")
public class AdminInvitationController {

    private final InvitationService invitationService;
    private final UserRepository userRepository;

    @Operation(summary = "Créer une invitation pour un email donné")
    @PostMapping
    public ResponseEntity<InvitationCreatedResponse> createInvitation(
            Authentication authentication,
            @Valid @RequestBody CreateInvitationRequest request) {
        UUID currentUserId = (UUID) authentication.getPrincipal();
        User currentUser = userRepository.findById(currentUserId).orElseThrow();
        var invitation = invitationService.create(currentUser, request.email());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new InvitationCreatedResponse(invitation.getToken(), invitation.getExpiresAt()));
    }

    @Operation(summary = "Lister toutes les invitations (tri createdAt DESC)")
    @GetMapping
    public ResponseEntity<List<InvitationResponse>> listInvitations() {
        return ResponseEntity.ok(invitationService.list());
    }

    @Operation(summary = "Révoquer une invitation non-utilisée")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> revokeInvitation(
            Authentication authentication,
            @PathVariable Long id) {
        UUID currentUserId = (UUID) authentication.getPrincipal();
        User currentUser = userRepository.findById(currentUserId).orElseThrow();
        invitationService.revoke(id, currentUser);
        return ResponseEntity.noContent().build();
    }
}
