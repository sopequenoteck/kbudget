package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.BudgetRequest;
import fr.kksdev.budget.api.dto.response.BudgetHistoryResponse;
import fr.kksdev.budget.api.dto.response.BudgetOverviewResponse;
import fr.kksdev.budget.api.dto.response.BudgetResponse;
import fr.kksdev.budget.api.service.BudgetService;
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
@RequestMapping("/budgets")
@RequiredArgsConstructor
@Tag(name = "Budgets", description = "Gestion des budgets par catégorie")
public class BudgetController {

    private final BudgetService budgetService;

    @Operation(summary = "Créer un budget")
    @PostMapping
    public ResponseEntity<BudgetResponse> create(
            @Valid @RequestBody BudgetRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(budgetService.create(request, userId));
    }

    @Operation(summary = "Lister les budgets")
    @GetMapping
    public ResponseEntity<List<BudgetResponse>> getAll(
            @RequestParam(defaultValue = "false") boolean includeInactive,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(budgetService.getAll(userId, includeInactive));
    }

    @Operation(summary = "Tableau de bord budgétaire du mois courant")
    @GetMapping("/overview")
    public ResponseEntity<BudgetOverviewResponse> getOverview(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(budgetService.getOverview(userId));
    }

    @Operation(summary = "Historique budgétaire d'un mois passé")
    @GetMapping("/history")
    public ResponseEntity<BudgetHistoryResponse> getHistory(
            @RequestParam String month,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(budgetService.getHistory(month, userId));
    }

    @Operation(summary = "Consulter un budget")
    @GetMapping("/{id}")
    public ResponseEntity<BudgetResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(budgetService.getById(id, userId));
    }

    @Operation(summary = "Modifier un budget")
    @PutMapping("/{id}")
    public ResponseEntity<BudgetResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody BudgetRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(budgetService.update(id, request, userId));
    }

    @Operation(summary = "Supprimer un budget")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        budgetService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
