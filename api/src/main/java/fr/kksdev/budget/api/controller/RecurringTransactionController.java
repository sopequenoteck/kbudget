package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.RecurringTransactionRequest;
import fr.kksdev.budget.api.dto.response.RecurringTransactionResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.service.RecurringTransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/transactions/recurring")
@RequiredArgsConstructor
@Tag(name = "Transactions récurrentes", description = "Gestion des transactions récurrentes")
public class RecurringTransactionController {

    private final RecurringTransactionService recurringTransactionService;

    @Operation(summary = "Créer une transaction récurrente")
    @PostMapping
    public ResponseEntity<RecurringTransactionResponse> create(
            @Valid @RequestBody RecurringTransactionRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(recurringTransactionService.create(request, userId));
    }

    @Operation(summary = "Lister les transactions récurrentes actives")
    @GetMapping
    public ResponseEntity<List<RecurringTransactionResponse>> listActive(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(recurringTransactionService.listActive(userId));
    }

    @Operation(summary = "Valider une occurrence")
    @PostMapping("/{id}/validate")
    public ResponseEntity<TransactionResponse> validate(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(recurringTransactionService.validate(id, userId));
    }

    @Operation(summary = "Passer une occurrence")
    @PatchMapping("/{id}/skip")
    public ResponseEntity<RecurringTransactionResponse> skip(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(recurringTransactionService.skip(id, userId));
    }

    @Operation(summary = "Désactiver une récurrence")
    @PatchMapping("/{id}/deactivate")
    public ResponseEntity<RecurringTransactionResponse> deactivate(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(recurringTransactionService.deactivate(id, userId));
    }
}
