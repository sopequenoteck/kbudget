package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.AccountRequest;
import fr.kksdev.budget.api.dto.request.AdjustBalanceRequest;
import fr.kksdev.budget.api.dto.request.TransferRequest;
import fr.kksdev.budget.api.dto.response.AccountResponse;
import fr.kksdev.budget.api.dto.response.TransferResponse;
import fr.kksdev.budget.api.service.AccountService;
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
@RequestMapping("/accounts")
@RequiredArgsConstructor
@Tag(name = "Comptes", description = "Gestion des comptes bancaires")
public class AccountController {

    private final AccountService accountService;

    @Operation(summary = "Lister les comptes de l'utilisateur")
    @GetMapping
    public ResponseEntity<List<AccountResponse>> getAll(
            @RequestParam(required = false, defaultValue = "false") boolean includeInactive,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(accountService.getAccounts(userId, includeInactive));
    }

    @Operation(summary = "Consulter un compte par son ID")
    @GetMapping("/{id}")
    public ResponseEntity<AccountResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(accountService.getAccountById(id, userId));
    }

    @Operation(summary = "Créer un compte")
    @PostMapping
    public ResponseEntity<AccountResponse> create(
            @Valid @RequestBody AccountRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(accountService.createAccount(request, userId));
    }

    @Operation(summary = "Modifier un compte")
    @PutMapping("/{id}")
    public ResponseEntity<AccountResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody AccountRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(accountService.updateAccount(id, request, userId));
    }

    @Operation(summary = "Supprimer un compte")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        accountService.deleteAccount(id, userId);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Effectuer un virement entre deux comptes")
    @PostMapping("/transfer")
    public ResponseEntity<TransferResponse> transfer(
            @Valid @RequestBody TransferRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(accountService.transfer(request, userId));
    }

    @Operation(summary = "Ajuster le solde d'un compte")
    @PostMapping("/{id}/adjust-balance")
    public ResponseEntity<AccountResponse> adjustBalance(
            @PathVariable UUID id,
            @Valid @RequestBody AdjustBalanceRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(accountService.adjustBalance(id, request.newBalance(), userId));
    }

    @Operation(summary = "Désigner un compte comme compte par défaut")
    @PutMapping("/{id}/default")
    public ResponseEntity<AccountResponse> setDefault(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(accountService.setDefault(id, userId));
    }
}
