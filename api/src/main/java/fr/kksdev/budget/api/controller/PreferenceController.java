package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.UserPreferenceRequest;
import fr.kksdev.budget.api.dto.response.UserPreferenceResponse;
import fr.kksdev.budget.api.service.PreferenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/users/me/preferences")
@RequiredArgsConstructor
@Tag(name = "Préférences", description = "Gestion des préférences utilisateur (feature toggles)")
public class PreferenceController {

    private final PreferenceService preferenceService;

    @Operation(summary = "Consulter les préférences de l'utilisateur connecté")
    @GetMapping
    public ResponseEntity<UserPreferenceResponse> getPreferences(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(preferenceService.getPreferences(userId));
    }

    @Operation(summary = "Mettre à jour les préférences de l'utilisateur connecté")
    @PutMapping
    public ResponseEntity<UserPreferenceResponse> updatePreferences(
            Authentication authentication,
            @Valid @RequestBody UserPreferenceRequest request) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(preferenceService.updatePreferences(request, userId));
    }
}
