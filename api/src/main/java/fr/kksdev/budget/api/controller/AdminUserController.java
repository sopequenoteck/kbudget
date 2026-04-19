package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.response.AdminUserResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/admin/users")
@RequiredArgsConstructor
@Tag(name = "Admin - Utilisateurs", description = "Gestion des utilisateurs (admin)")
public class AdminUserController {

    private final AdminUserService adminUserService;
    private final UserRepository userRepository;

    @Operation(summary = "Lister tous les utilisateurs (tri createdAt ASC)")
    @GetMapping
    public ResponseEntity<List<AdminUserResponse>> list() {
        return ResponseEntity.ok(adminUserService.list());
    }

    @Operation(summary = "Désactiver un utilisateur (soft-disable)")
    @PatchMapping("/{id}/disable")
    public ResponseEntity<Void> disable(@PathVariable UUID id, Authentication authentication) {
        User admin = resolveCurrentUser(authentication);
        adminUserService.disable(id, admin);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Réactiver un utilisateur désactivé")
    @PatchMapping("/{id}/enable")
    public ResponseEntity<Void> enable(@PathVariable UUID id, Authentication authentication) {
        User admin = resolveCurrentUser(authentication);
        adminUserService.enable(id, admin);
        return ResponseEntity.noContent().build();
    }

    private User resolveCurrentUser(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur authentifié introuvable"));
    }
}
