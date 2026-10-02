package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.request.CategoryApplyRequest;
import fr.kksdev.budget.api.dto.request.DuplicateMergeRequest;
import fr.kksdev.budget.api.dto.request.SubscriptionDuplicateMergeRequest;
import fr.kksdev.budget.api.dto.response.AdjustmentReviewResponse;
import fr.kksdev.budget.api.dto.response.CategoryApplyResponse;
import fr.kksdev.budget.api.dto.response.CategoryProposalsResponse;
import fr.kksdev.budget.api.dto.response.DuplicateMergeResponse;
import fr.kksdev.budget.api.dto.response.DuplicateProposalsResponse;
import fr.kksdev.budget.api.service.AdjustmentReviewService;
import fr.kksdev.budget.api.service.DuplicateCleanupService;
import fr.kksdev.budget.api.service.UncategorizedCleanupService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Catch-up of the history already stored (KKS-387). The GET endpoints propose, change nothing;
 * each POST applies one proposal the user validated.
 */
@RestController
@RequestMapping("/history-cleanup")
@RequiredArgsConstructor
@Tag(name = "Rattrapage de l'historique", description = "Propositions de correction des donnees deja en base, validees une a une")
public class HistoryCleanupController {

    private final DuplicateCleanupService duplicateCleanupService;
    private final UncategorizedCleanupService uncategorizedCleanupService;
    private final AdjustmentReviewService adjustmentReviewService;

    @Operation(summary = "Proposer les doublons probables : operations importees deja saisies, paiements d'abonnement multiples")
    @GetMapping("/duplicates")
    public ResponseEntity<DuplicateProposalsResponse> getDuplicates(Authentication authentication) {
        return ResponseEntity.ok(duplicateCleanupService.findProposals(userId(authentication)));
    }

    @Operation(summary = "Fusionner une operation importee dans la saisie manuelle qu'elle double")
    @PostMapping("/duplicates/merge")
    public ResponseEntity<DuplicateMergeResponse> mergeDuplicate(
            @RequestBody @Valid DuplicateMergeRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(duplicateCleanupService.mergeImported(request, userId(authentication)));
    }

    @Operation(summary = "Ne garder qu'un paiement d'abonnement pour une echeance")
    @PostMapping("/subscription-duplicates/merge")
    public ResponseEntity<DuplicateMergeResponse> mergeSubscriptionDuplicates(
            @RequestBody @Valid SubscriptionDuplicateMergeRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(duplicateCleanupService.mergeSubscriptionPayments(request, userId(authentication)));
    }

    @Operation(summary = "Proposer une categorie aux transactions sans categorie, groupees par commercant")
    @GetMapping("/uncategorized")
    public ResponseEntity<CategoryProposalsResponse> getUncategorized(Authentication authentication) {
        return ResponseEntity.ok(uncategorizedCleanupService.findProposals(userId(authentication)));
    }

    @Operation(summary = "Appliquer la categorie choisie a un groupe de transactions sans categorie")
    @PostMapping("/uncategorized/apply")
    public ResponseEntity<CategoryApplyResponse> applyCategory(
            @RequestBody @Valid CategoryApplyRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(uncategorizedCleanupService.apply(request, userId(authentication)));
    }

    @Operation(summary = "Lister les ajustements de solde, par compte, et signaler ceux que le solde bancaire rend probablement inutiles")
    @GetMapping("/adjustments")
    public ResponseEntity<AdjustmentReviewResponse> getAdjustments(Authentication authentication) {
        return ResponseEntity.ok(adjustmentReviewService.review(userId(authentication)));
    }

    private static UUID userId(Authentication authentication) {
        return (UUID) authentication.getPrincipal();
    }
}
