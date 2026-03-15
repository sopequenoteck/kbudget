package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.SubscriptionRequest;
import fr.kksdev.budget.api.dto.response.SubscriptionPaymentResponse;
import fr.kksdev.budget.api.dto.response.SubscriptionResponse;
import fr.kksdev.budget.api.service.SubscriptionPaymentService;
import fr.kksdev.budget.api.service.SubscriptionService;
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
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/subscriptions")
@RequiredArgsConstructor
@Tag(name = "Abonnements", description = "Gestion des abonnements recurrents")
public class SubscriptionController {

    private final SubscriptionService subscriptionService;
    private final SubscriptionPaymentService subscriptionPaymentService;

    @Operation(summary = "Créer un abonnement")
    @PostMapping
    public ResponseEntity<SubscriptionResponse> create(
            @Valid @RequestBody SubscriptionRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(subscriptionService.create(request, userId));
    }

    @Operation(summary = "Lister les abonnements")
    @GetMapping
    public ResponseEntity<List<SubscriptionResponse>> getAll(
            @RequestParam(required = false) Boolean actif,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        if (Boolean.TRUE.equals(actif)) {
            return ResponseEntity.ok(subscriptionService.getActiveByUser(userId));
        }
        return ResponseEntity.ok(subscriptionService.getAllByUser(userId));
    }

    @Operation(summary = "Consulter un abonnement par son ID")
    @GetMapping("/{id}")
    public ResponseEntity<SubscriptionResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(subscriptionService.getById(id, userId));
    }

    @Operation(summary = "Modifier un abonnement")
    @PutMapping("/{id}")
    public ResponseEntity<SubscriptionResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody SubscriptionRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(subscriptionService.update(id, request, userId));
    }

    @Operation(summary = "Supprimer un abonnement")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        subscriptionService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Payer un abonnement")
    @PostMapping("/{id}/pay")
    public ResponseEntity<SubscriptionPaymentResponse> pay(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(subscriptionPaymentService.pay(id, userId));
    }

    @Operation(summary = "Historique des paiements d'un abonnement")
    @GetMapping("/{id}/payments")
    public ResponseEntity<List<SubscriptionPaymentResponse>> getPayments(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(subscriptionPaymentService.getPayments(id, userId));
    }

    @Operation(summary = "Cumul des paiements d'un abonnement")
    @GetMapping("/{id}/payments/total")
    public ResponseEntity<Map<String, Object>> getTotalPaid(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(subscriptionPaymentService.getTotalPaid(id, userId));
    }
}
