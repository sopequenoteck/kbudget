package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.ProductRequest;
import fr.kksdev.budget.api.dto.request.ProductUpdateRequest;
import fr.kksdev.budget.api.dto.request.RestockRequest;
import fr.kksdev.budget.api.dto.response.ProductResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.service.ProductService;
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
@RequestMapping("/products")
@RequiredArgsConstructor
@Tag(name = "Produits", description = "CRUD produits boutique")
public class ProductController {

    private final ProductService productService;

    @Operation(summary = "Créer un produit")
    @PostMapping
    public ResponseEntity<ProductResponse> create(
            @Valid @RequestBody ProductRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED).body(productService.create(request, userId));
    }

    @Operation(summary = "Lister les produits actifs")
    @GetMapping
    public ResponseEntity<List<ProductResponse>> getAll(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(productService.getAllByUser(userId));
    }

    @Operation(summary = "Consulter un produit")
    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(productService.getById(id, userId));
    }

    @Operation(summary = "Modifier un produit")
    @PutMapping("/{id}")
    public ResponseEntity<ProductResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody ProductUpdateRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(productService.update(id, request, userId));
    }

    @Operation(summary = "Supprimer un produit")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        productService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Vendre un produit")
    @PostMapping("/{id}/sell")
    public ResponseEntity<ProductResponse> sell(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(productService.sell(id, userId));
    }

    @Operation(summary = "Restocker un produit")
    @PostMapping("/{id}/restock")
    public ResponseEntity<ProductResponse> restock(
            @PathVariable UUID id,
            @Valid @RequestBody RestockRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(productService.restock(id, request, userId));
    }

    @Operation(summary = "Historique des ventes d'un produit")
    @GetMapping("/{id}/sales")
    public ResponseEntity<List<TransactionResponse>> getSalesHistory(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(productService.getSalesHistory(id, userId));
    }
}
