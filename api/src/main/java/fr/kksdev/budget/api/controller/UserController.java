package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.ChangePasswordRequest;
import fr.kksdev.budget.api.dto.request.DeleteAccountRequest;
import fr.kksdev.budget.api.dto.request.UpdateProfileRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.dto.response.AvatarMetadataResponse;
import fr.kksdev.budget.api.dto.response.UserExportResponse;
import fr.kksdev.budget.api.dto.response.UserResponse;
import fr.kksdev.budget.api.exception.InvalidExportFormatException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.service.AvatarStorageService;
import fr.kksdev.budget.api.service.UserDeletionService;
import fr.kksdev.budget.api.service.UserExportService;
import fr.kksdev.budget.api.service.UserPasswordService;
import fr.kksdev.budget.api.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Tag(name = "Utilisateurs", description = "Gestion du profil utilisateur")
public class UserController {

    private final UserService userService;
    private final AvatarStorageService avatarStorageService;
    private final UserPasswordService userPasswordService;
    private final UserExportService userExportService;
    private final UserDeletionService userDeletionService;

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

    @Operation(summary = "Exporter les données de l'utilisateur connecté au format JSON")
    @GetMapping(value = "/me/export", params = "format=json")
    public ResponseEntity<UserExportResponse> exportJson(Authentication authentication) {
        User user = resolveUser(authentication);
        UserExportResponse response = userExportService.exportJson(user);
        String filename = "kbudget-export-" + user.getId() + "-"
                + LocalDate.now().toString().replace("-", "") + ".json";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_JSON)
                .body(response);
    }

    @Operation(summary = "Exporter les transactions de l'utilisateur connecté au format CSV")
    @GetMapping(value = "/me/export", params = "format=csv")
    public ResponseEntity<StreamingResponseBody> exportCsv(Authentication authentication) {
        User user = resolveUser(authentication);
        String filename = "kbudget-transactions-" + user.getId() + "-"
                + LocalDate.now().toString().replace("-", "") + ".csv";
        StreamingResponseBody stream = out -> userExportService.exportCsv(user, out);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv;charset=utf-8"))
                .body(stream);
    }

    @Operation(summary = "Format d'export invalide — déclenche 400 INVALID_EXPORT_FORMAT")
    @GetMapping("/me/export")
    public ResponseEntity<Void> exportInvalidFormat(@RequestParam(value = "format", required = false) String format) {
        throw new InvalidExportFormatException();
    }

    @Operation(summary = "Supprimer le compte de l'utilisateur connecté (soft-delete)")
    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteAccount(
            Authentication authentication,
            @Valid @RequestBody DeleteAccountRequest request) {
        User user = resolveUser(authentication);
        userDeletionService.softDelete(user, request);
        return ResponseEntity.noContent().build();
    }

    private User resolveUser(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return userService.findById(userId);
    }
}
