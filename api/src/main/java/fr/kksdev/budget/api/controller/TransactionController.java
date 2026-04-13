package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.TransactionRequest;
import fr.kksdev.budget.api.dto.response.MonthlySummaryResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Slf4j
@Validated
@RestController
@RequestMapping("/transactions")
@RequiredArgsConstructor
@Tag(name = "Transactions", description = "Gestion des dépenses et recettes")
public class TransactionController {

    private final TransactionService transactionService;

    @Operation(summary = "Lister les libellés déjà utilisés (autocomplete)")
    @GetMapping("/libelles")
    public ResponseEntity<List<String>> getLibelleSuggestions(
            @RequestParam(required = false) @Size(max = 255) String q,
            @RequestParam(required = false, defaultValue = "20") Integer limit,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        log.info("GET /transactions/libelles user={} q={} limit={}", userId, q, limit);
        return ResponseEntity.ok(transactionService.getLibelleSuggestions(userId, q, limit));
    }

    @Operation(summary = "Créer une transaction")
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
    public ResponseEntity<List<TransactionResponse>> getAll(
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        if (month != null && year != null) {
            return ResponseEntity.ok(transactionService.getByMonth(month, year, userId));
        }
        return ResponseEntity.ok(transactionService.getAllByUser(userId));
    }

    @Operation(summary = "Obtenir le bilan mensuel des transactions groupé par devise")
    @GetMapping("/summary")
    public ResponseEntity<List<MonthlySummaryResponse>> getMonthlySummary(
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
