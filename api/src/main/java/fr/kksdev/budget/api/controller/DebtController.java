package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.DebtRequest;
import fr.kksdev.budget.api.dto.response.DebtResponse;
import fr.kksdev.budget.api.service.DebtService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/debts")
@RequiredArgsConstructor
public class DebtController {

    private final DebtService debtService;

    @PostMapping
    public ResponseEntity<DebtResponse> create(
            @Valid @RequestBody DebtRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(debtService.create(request, userId));
    }

    @GetMapping
    public ResponseEntity<List<DebtResponse>> getAll(
            @RequestParam(required = false) Boolean rembourse,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        if (Boolean.FALSE.equals(rembourse)) {
            return ResponseEntity.ok(debtService.getUnpaidByUser(userId));
        }
        return ResponseEntity.ok(debtService.getAllByUser(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DebtResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(debtService.getById(id, userId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DebtResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody DebtRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(debtService.update(id, request, userId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        debtService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
