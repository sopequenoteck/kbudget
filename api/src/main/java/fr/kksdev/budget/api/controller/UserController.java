package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.ChangePasswordRequest;
import fr.kksdev.budget.api.dto.request.UpdateProfileRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.dto.response.AvatarMetadataResponse;
import fr.kksdev.budget.api.dto.response.UserResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.service.AvatarStorageService;
import fr.kksdev.budget.api.service.UserPasswordService;
import fr.kksdev.budget.api.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Tag(name = "Utilisateurs", description = "Gestion du profil utilisateur")
public class UserController {

    private final UserService userService;
    private final AvatarStorageService avatarStorageService;
    private final UserPasswordService userPasswordService;

    @Operation(summary = "Consulter le profil de l'utilisateur connecté")
    @GetMapping("/me")
    public ResponseEntity<UserResponse> getProfile(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(userService.getProfile(userId));
    }

    @Operation(summary = "Mettre à jour le profil de l'utilisateur connecté")
    @PutMapping("/me")
    public ResponseEntity<UserResponse> updateProfile(
            Authentication authentication,
            @Valid @RequestBody UpdateProfileRequest request) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(userService.updateProfile(userId, request));
    }

    @Operation(summary = "Uploader l'avatar de l'utilisateur connecté")
    @PostMapping("/me/avatar")
    public ResponseEntity<AvatarMetadataResponse> uploadAvatar(
            Authentication authentication,
            @RequestParam("file") MultipartFile file) {
        User user = resolveUser(authentication);
        avatarStorageService.store(user, file);
        byte[] avatarBytes = avatarStorageService.read(user);
        String etag = avatarStorageService.computeEtag(avatarBytes);
        return ResponseEntity.ok(new AvatarMetadataResponse(
                "/api/users/me/avatar",
                etag,
                Instant.now()
        ));
    }

    @Operation(summary = "Récupérer l'avatar de l'utilisateur connecté")
    @GetMapping("/me/avatar")
    public ResponseEntity<byte[]> getAvatar(
            Authentication authentication,
            @RequestHeader(value = "If-None-Match", required = false) String ifNoneMatch) {
        User user = resolveUser(authentication);
        byte[] avatarBytes = avatarStorageService.read(user);
        String etag = avatarStorageService.computeEtag(avatarBytes);
        String etagQuoted = "\"" + etag + "\"";

        if (etagQuoted.equals(ifNoneMatch)) {
            return ResponseEntity.status(304).build();
        }

        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_JPEG)
                .cacheControl(CacheControl.noCache().mustRevalidate().cachePrivate())
                .eTag(etag)
                .body(avatarBytes);
    }

    @Operation(summary = "Supprimer l'avatar de l'utilisateur connecté")
    @DeleteMapping("/me/avatar")
    public ResponseEntity<Void> deleteAvatar(Authentication authentication) {
        User user = resolveUser(authentication);
        avatarStorageService.delete(user);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Changer le mot de passe de l'utilisateur connecté")
    @PostMapping("/me/password")
    public ResponseEntity<AuthResponse> changePassword(
            Authentication authentication,
            @Valid @RequestBody ChangePasswordRequest request) {
        User user = resolveUser(authentication);
        AuthResponse response = userPasswordService.changePassword(user, request);
        return ResponseEntity.ok(response);
    }

    private User resolveUser(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return userService.findById(userId);
    }
}
