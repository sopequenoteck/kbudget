package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.TransactionRequest;
import fr.kksdev.budget.api.dto.response.MonthlySummaryResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/transactions")
@RequiredArgsConstructor
@Tag(name = "Transactions", description = "Gestion des depenses et recettes")
public class TransactionController {

    private final TransactionService transactionService;

    @Operation(summary = "Creer une transaction")
    @PostMapping
    public ResponseEntity<TransactionResponse> create(
            @Valid @RequestBody TransactionRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(transactionService.create(request, userId));
    }

    @Operation(summary = "Lister toutes les transactions")
    @GetMapping
    public ResponseEntity<List<TransactionResponse>> getAll(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(transactionService.getAllByUser(userId));
    }

    @Operation(summary = "Obtenir le bilan mensuel des transactions")
    @GetMapping("/summary")
    public ResponseEntity<MonthlySummaryResponse> getMonthlySummary(
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        LocalDate now = LocalDate.now();
        int m = month != null ? month : now.getMonthValue();
        int y = year != null ? year : now.getYear();
        return ResponseEntity.ok(transactionService.getMonthlySummary(m, y, userId));
    }

    @Operation(summary = "Consulter une transaction par son ID")
    @GetMapping("/{id}")
    public ResponseEntity<TransactionResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(transactionService.getById(id, userId));
    }

    @Operation(summary = "Modifier une transaction")
    @PutMapping("/{id}")
    public ResponseEntity<TransactionResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody TransactionRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(transactionService.update(id, request, userId));
    }

    @Operation(summary = "Supprimer une transaction")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        transactionService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
