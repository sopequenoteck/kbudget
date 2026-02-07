package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.DebtRequest;
import fr.kksdev.budget.api.dto.DebtResponse;
import fr.kksdev.budget.api.model.User;
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
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(debtService.create(request, user));
    }

    @GetMapping
    public ResponseEntity<List<DebtResponse>> getAll(
            @RequestParam(required = false) Boolean rembourse,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        if (Boolean.FALSE.equals(rembourse)) {
            return ResponseEntity.ok(debtService.getUnpaidByUser(user.getId()));
        }
        return ResponseEntity.ok(debtService.getAllByUser(user.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DebtResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.ok(debtService.getById(id, user.getId()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DebtResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody DebtRequest request,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.ok(debtService.update(id, request, user.getId()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        debtService.delete(id, user.getId());
        return ResponseEntity.noContent().build();
    }
}
