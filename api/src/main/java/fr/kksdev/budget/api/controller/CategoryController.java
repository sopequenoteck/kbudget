package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.CategoryRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.service.CategoryService;
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
@RequestMapping("/categories")
@RequiredArgsConstructor
@Tag(name = "Catégories", description = "Gestion des catégories personnalisées")
public class CategoryController {

    private final CategoryService categoryService;

    @Operation(summary = "Creer une categorie")
    @PostMapping
    public ResponseEntity<CategoryResponse> create(
            @Valid @RequestBody CategoryRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(categoryService.create(request, userId));
    }

    @Operation(summary = "Lister toutes les categories")
    @GetMapping
    public ResponseEntity<List<CategoryResponse>> getAll(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(categoryService.getAllByUser(userId));
    }

    @Operation(summary = "Consulter une categorie par son ID")
    @GetMapping("/{id}")
    public ResponseEntity<CategoryResponse> getById(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(categoryService.getById(id, userId));
    }

    @Operation(summary = "Modifier une categorie")
    @PutMapping("/{id}")
    public ResponseEntity<CategoryResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody CategoryRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(categoryService.update(id, request, userId));
    }

    @Operation(summary = "Supprimer une categorie")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        categoryService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
