package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.ExchangeRateRequest;
import fr.kksdev.budget.api.dto.response.ExchangeRateResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.service.ExchangeRateService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/exchange-rates")
@RequiredArgsConstructor
@Tag(name = "Taux de change", description = "Gestion des taux de conversion manuels")
public class ExchangeRateController {

    private final ExchangeRateService exchangeRateService;

    @Operation(summary = "Lister tous les taux de conversion")
    @GetMapping
    public ResponseEntity<List<ExchangeRateResponse>> getAll(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(exchangeRateService.getAll(userId));
    }

    @Operation(summary = "Créer ou mettre à jour un taux de conversion")
    @PutMapping
    public ResponseEntity<ExchangeRateResponse> upsert(
            Authentication authentication,
            @Valid @RequestBody ExchangeRateRequest request) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(exchangeRateService.upsert(request, userId));
    }

    @Operation(summary = "Supprimer un taux de conversion")
    @DeleteMapping("/{baseCurrency}/{targetCurrency}")
    public ResponseEntity<Void> delete(
            Authentication authentication,
            @PathVariable Currency baseCurrency,
            @PathVariable Currency targetCurrency) {
        UUID userId = (UUID) authentication.getPrincipal();
        exchangeRateService.delete(userId, baseCurrency, targetCurrency);
        return ResponseEntity.noContent().build();
    }
}
