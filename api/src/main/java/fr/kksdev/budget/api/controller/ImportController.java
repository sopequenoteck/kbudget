package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.CategoryRuleRequest;
import fr.kksdev.budget.api.dto.request.CsvMappingRequest;
import fr.kksdev.budget.api.dto.request.ImportLineBatchUpdateRequest;
import fr.kksdev.budget.api.dto.request.ImportLineUpdateRequest;
import fr.kksdev.budget.api.dto.response.CategoryRuleResponse;
import fr.kksdev.budget.api.dto.response.CsvPreviewResponse;
import fr.kksdev.budget.api.dto.response.ImportConfirmResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftLineResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftSummaryResponse;
import fr.kksdev.budget.api.dto.response.ImportHistoryResponse;
import fr.kksdev.budget.api.dto.response.ImportProfileResponse;
import fr.kksdev.budget.api.service.CategoryRuleService;
import fr.kksdev.budget.api.service.ImportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/imports")
@RequiredArgsConstructor
@Tag(name = "Import CSV", description = "Import de transactions depuis un fichier CSV bancaire")
public class ImportController {

    private static final com.fasterxml.jackson.databind.ObjectMapper OBJECT_MAPPER = new com.fasterxml.jackson.databind.ObjectMapper();

    private final ImportService importService;
    private final CategoryRuleService categoryRuleService;

    @Operation(summary = "Uploader un fichier CSV pour import")
    @PostMapping("/upload")
    public ResponseEntity<ImportDraftResponse> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam("accountId") UUID accountId,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        ImportDraftResponse response = importService.upload(file, accountId, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Operation(summary = "Consulter un draft d'import")
    @GetMapping("/drafts/{draftId}")
    public ResponseEntity<ImportDraftResponse> getDraft(
            @PathVariable UUID draftId,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(importService.getDraft(draftId, userId));
    }

    @Operation(summary = "Mettre à jour une ligne d'import")
    @PutMapping("/drafts/{draftId}/lines/{lineId}")
    public ResponseEntity<ImportDraftLineResponse> updateLine(
            @PathVariable UUID draftId,
            @PathVariable UUID lineId,
            @RequestBody @Valid ImportLineUpdateRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(importService.updateLine(draftId, lineId, request, userId));
    }

    @Operation(summary = "Mettre à jour plusieurs lignes d'import en lot")
    @PutMapping("/drafts/{draftId}/lines/batch")
    public ResponseEntity<List<ImportDraftLineResponse>> batchUpdateLines(
            @PathVariable UUID draftId,
            @RequestBody @Valid ImportLineBatchUpdateRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(importService.batchUpdateLines(draftId, request, userId));
    }

    @Operation(summary = "Confirmer un import et créer les transactions")
    @PostMapping("/drafts/{draftId}/confirm")
    public ResponseEntity<ImportConfirmResponse> confirm(
            @PathVariable UUID draftId,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(importService.confirm(draftId, userId));
    }

    @Operation(summary = "Lister les drafts d'import en attente")
    @GetMapping("/drafts")
    public ResponseEntity<List<ImportDraftSummaryResponse>> listDrafts(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(importService.listDrafts(userId));
    }

    @Operation(summary = "Historique des imports confirmés")
    @GetMapping("/history")
    public ResponseEntity<Page<ImportHistoryResponse>> listHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(importService.listHistory(userId, page, size));
    }

    @Operation(summary = "Supprimer un draft d'import")
    @DeleteMapping("/drafts/{draftId}")
    public ResponseEntity<Void> deleteDraft(
            @PathVariable UUID draftId,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        importService.deleteDraft(draftId, userId);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Lister les règles de catégorisation automatique")
    @GetMapping("/rules")
    public ResponseEntity<List<CategoryRuleResponse>> getRules(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(categoryRuleService.getAllByUser(userId));
    }

    @Operation(summary = "Créer une règle de catégorisation automatique")
    @PostMapping("/rules")
    public ResponseEntity<CategoryRuleResponse> createRule(
            @RequestBody @Valid CategoryRuleRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        CategoryRuleResponse response = categoryRuleService.create(request.pattern(), request.categoryId(), userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Operation(summary = "Mettre à jour une règle de catégorisation automatique")
    @PutMapping("/rules/{ruleId}")
    public ResponseEntity<CategoryRuleResponse> updateRule(
            @PathVariable UUID ruleId,
            @RequestBody @Valid CategoryRuleRequest request,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(categoryRuleService.update(ruleId, request.pattern(), request.categoryId(), userId));
    }

    @Operation(summary = "Supprimer une règle de catégorisation automatique")
    @DeleteMapping("/rules/{ruleId}")
    public ResponseEntity<Void> deleteRule(
            @PathVariable UUID ruleId,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        categoryRuleService.delete(ruleId, userId);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Prévisualiser un fichier CSV avant import")
    @PostMapping("/preview")
    public ResponseEntity<CsvPreviewResponse> preview(
            @RequestParam("file") MultipartFile file,
            @RequestParam(required = false) String separator,
            @RequestParam(required = false) String encoding,
            @RequestParam(defaultValue = "0") int skipHeaderLines) {
        CsvPreviewResponse response = importService.preview(file, separator, encoding, skipHeaderLines);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Uploader un fichier CSV avec mapping personnalisé")
    @PostMapping("/upload-with-mapping")
    public ResponseEntity<ImportDraftResponse> uploadWithMapping(
            @RequestParam("file") MultipartFile file,
            @RequestParam("accountId") UUID accountId,
            @RequestParam("mapping") String mappingJson,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        CsvMappingRequest mapping;
        try {
            mapping = OBJECT_MAPPER.readValue(mappingJson, CsvMappingRequest.class);
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            throw new IllegalArgumentException("Invalid JSON mapping: " + e.getMessage());
        }
        ImportDraftResponse response = importService.uploadWithMapping(file, accountId, mapping, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Operation(summary = "Lister les profils d'import disponibles")
    @GetMapping("/profiles")
    public ResponseEntity<List<ImportProfileResponse>> listProfiles(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(importService.listProfiles(userId));
    }

    @Operation(summary = "Supprimer un profil d'import personnalisé")
    @DeleteMapping("/profiles/{profileId}")
    public ResponseEntity<Void> deleteProfile(
            @PathVariable UUID profileId,
            Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        importService.deleteProfile(profileId, userId);
        return ResponseEntity.noContent().build();
    }
}
