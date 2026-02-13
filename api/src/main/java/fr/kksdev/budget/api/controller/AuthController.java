package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.request.LogoutRequest;
import fr.kksdev.budget.api.dto.request.RefreshRequest;
import fr.kksdev.budget.api.dto.request.RegisterRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.service.AuthService;
import fr.kksdev.budget.api.service.RefreshTokenService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Tag(name = "Authentification", description = "Inscription, connexion et gestion des tokens")
public class AuthController {

    private final AuthService authService;
    private final RefreshTokenService refreshTokenService;

    @Operation(summary = "Inscrire un nouvel utilisateur")
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

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
}
