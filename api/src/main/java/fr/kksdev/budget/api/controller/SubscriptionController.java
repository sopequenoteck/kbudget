package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.SubscriptionRequest;
import fr.kksdev.budget.api.dto.SubscriptionResponse;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.service.SubscriptionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/subscriptions")
@RequiredArgsConstructor
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    @PostMapping
    public ResponseEntity<SubscriptionResponse> create(
            @Valid @RequestBody SubscriptionRequest request,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(subscriptionService.create(request, user));
    }

    @GetMapping
    public ResponseEntity<List<SubscriptionResponse>> getAll(
            @RequestParam(required = false) Boolean actif,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        if (Boolean.TRUE.equals(actif)) {
            return ResponseEntity.ok(subscriptionService.getActiveByUser(user.getId()));
        }
        return ResponseEntity.ok(subscriptionService.getAllByUser(user.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<SubscriptionResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.ok(subscriptionService.getById(id, user.getId()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<SubscriptionResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody SubscriptionRequest request,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.ok(subscriptionService.update(id, request, user.getId()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        subscriptionService.delete(id, user.getId());
        return ResponseEntity.noContent().build();
    }
}
