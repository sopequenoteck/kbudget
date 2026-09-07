package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CsvMappingRequest;
import fr.kksdev.budget.api.dto.request.ImportLineBatchUpdateRequest;
import fr.kksdev.budget.api.dto.response.CsvPreviewResponse;
import fr.kksdev.budget.api.dto.response.ImportConfirmResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftLineResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftSummaryResponse;
import fr.kksdev.budget.api.dto.response.ImportHistoryResponse;
import fr.kksdev.budget.api.dto.response.ImportProfileResponse;
import fr.kksdev.budget.api.dto.request.ImportLineUpdateRequest;
import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.ImportProfileSource;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.CsvProfileNotFoundException;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.ImportHistory;
import fr.kksdev.budget.api.model.ImportProfile;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.ImportDraftLineRepository;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import fr.kksdev.budget.api.repository.ImportHistoryRepository;
import fr.kksdev.budget.api.repository.ImportProfileRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ImportService {

    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
    private static final int DRAFT_EXPIRY_DAYS = 7;

    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final ImportDraftRepository importDraftRepository;
    private final ImportDraftLineRepository importDraftLineRepository;
    private final TransactionRepository transactionRepository;
    private final ImportHistoryRepository importHistoryRepository;
    private final UserRepository userRepository;
    private final CsvParsingService csvParsingService;
    private final CategoryRuleService categoryRuleService;
    private final DeduplicationService deduplicationService;
    private final ImportProfileRepository importProfileRepository;

    @Transactional
    public ImportDraftResponse upload(MultipartFile file, UUID accountId, UUID userId) {
        validateFile(file);

        Account account = validateAccountForImport(accountId, userId);

        ImportProfileRegistry.ImportProfileConfig profile = csvParsingService.detectProfile(account.getBankCode())
                .orElseThrow(() -> new CsvProfileNotFoundException(
                        "No import profile available for bank: " + account.getBankCode()));

        List<ImportDraftLine> parsedLines;
        try {
            parsedLines = csvParsingService.parse(file.getInputStream(), profile, userId);
        } catch (IOException e) {
            throw new IllegalArgumentException("Unable to read the file: " + e.getMessage());
        }

        deduplicationService.detectDuplicates(parsedLines, accountId, userId);

        log.info("CSV import uploaded: {} lines from file '{}' for account {}", parsedLines.size(), file.getOriginalFilename(), accountId);

        ImportDraft savedDraft = createDraftFromLines(parsedLines, account, userId, file.getOriginalFilename(), null, ImportProfileSource.REGISTRY);
        return buildResponseWithProfileName(savedDraft, profile.name());
    }

    @Transactional
    public ImportConfirmResponse confirm(UUID draftId, UUID userId) {
        ImportDraft draft = findDraftByIdAndUser(draftId, userId);

        if (draft.getStatus() != ImportDraftStatus.PENDING) {
            throw new IllegalArgumentException("Import is not awaiting confirmation, status: " + draft.getStatus());
        }

        List<ImportDraftLine> allLines = importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draftId);

        // Check no lines require review or are duplicates
        boolean hasBlockingLines = allLines.stream()
                .anyMatch(l -> l.getStatus() == ImportLineStatus.NEEDS_REVIEW
                        || l.getStatus() == ImportLineStatus.DUPLICATE);
        if (hasBlockingLines) {
            throw new IllegalArgumentException("Some lines require review before confirmation");
        }

        List<ImportDraftLine> readyLines = allLines.stream()
                .filter(l -> l.getStatus() == ImportLineStatus.READY)
                .toList();

        int skippedCount = (int) allLines.stream()
                .filter(l -> l.getStatus() == ImportLineStatus.SKIPPED)
                .count();

        List<Transaction> transactions = buildTransactionsFromLines(draft, readyLines);
        transactionRepository.saveAll(transactions);

        // Create import history
        ImportHistory history = ImportHistory.builder()
                .user(draft.getUser())
                .account(draft.getAccount())
                .transactionCount(readyLines.size())
                .fileName(draft.getFileName())
                .build();
        history = importHistoryRepository.save(history);

        // Mark draft as completed
        draft.setStatus(ImportDraftStatus.COMPLETED);
        importDraftRepository.save(draft);

        log.info("Import confirmé: {} transactions créées, {} ignorées pour le draft {}", readyLines.size(), skippedCount, draftId);

        return new ImportConfirmResponse(readyLines.size(), skippedCount, history.getId());
    }

    public ImportDraftResponse getDraft(UUID draftId, UUID userId) {
        ImportDraft draft = findDraftByIdAndUser(draftId, userId);
        List<ImportDraftLine> lines = importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draftId);
        draft.getLines().clear();
        draft.getLines().addAll(lines);
        return ImportDraftResponse.from(draft);
    }

    @Transactional
    public void deleteDraft(UUID draftId, UUID userId) {
        ImportDraft draft = findDraftByIdAndUser(draftId, userId);
        importDraftRepository.delete(draft);
        log.info("Draft d'import supprimé: {}", draftId);
    }

    @Transactional
    public ImportDraftLineResponse updateLine(UUID draftId, UUID lineId, ImportLineUpdateRequest request, UUID userId) {
        ImportDraft draft = findDraftByIdAndUser(draftId, userId);

        if (draft.getStatus() != ImportDraftStatus.PENDING) {
            throw new IllegalArgumentException("The draft is no longer editable");
        }

        ImportDraftLine line = importDraftLineRepository.findById(lineId)
                .filter(l -> l.getDraft().getId().equals(draftId))
                .orElseThrow(() -> {
                    log.error("Ligne d'import non trouvée: id={}, draftId={}", lineId, draftId);
                    return new EntityNotFoundException("Import line not found");
                });

        boolean suggestRule = false;

        if (request.categoryId() != null) {
            fr.kksdev.budget.api.model.Category category = categoryRepository.findById(request.categoryId())
                    .filter(c -> c.getUser().getId().equals(userId))
                    .orElseThrow(() -> {
                        log.error("Catégorie non trouvée: id={}, userId={}", request.categoryId(), userId);
                        return new EntityNotFoundException("Category not found");
                    });
            line.setCategory(category);

            // Suggest creating a rule if no existing rule matches this label
            String cleanLabel = line.getCleanLabel();
            if (cleanLabel != null && !cleanLabel.isBlank()) {
                boolean ruleExists = categoryRuleService.getAllByUser(userId).stream()
                        .anyMatch(r -> cleanLabel.toLowerCase().contains(r.pattern().toLowerCase()));
                suggestRule = !ruleExists;
            }
        }

        if (request.status() != null) {
            ImportLineStatus newStatus = parseLineStatus(request.status());
            validateStatusTransition(line.getStatus(), newStatus);
            line.setStatus(newStatus);
        }

        line = importDraftLineRepository.save(line);

        // Recalculate draft counts
        recalculateDraftCounts(draft);
        importDraftRepository.save(draft);

        log.info("Import draft line updated: lineId={}, draftId={}, newStatus={}", lineId, draftId, line.getStatus());

        return ImportDraftLineResponse.from(line, suggestRule);
    }

    @Transactional
    public List<ImportDraftLineResponse> batchUpdateLines(UUID draftId, ImportLineBatchUpdateRequest request, UUID userId) {
        ImportDraft draft = findDraftByIdAndUser(draftId, userId);

        if (draft.getStatus() != ImportDraftStatus.PENDING) {
            throw new IllegalArgumentException("Import is not awaiting modification, status: " + draft.getStatus());
        }

        List<ImportDraftLine> allLines = importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draftId);

        fr.kksdev.budget.api.model.Category category = null;
        if (request.categoryId() != null) {
            category = categoryRepository.findById(request.categoryId())
                    .filter(c -> c.getUser().getId().equals(userId))
                    .orElseThrow(() -> {
                        log.error("Category not found: id={}, userId={}", request.categoryId(), userId);
                        return new jakarta.persistence.EntityNotFoundException("Category not found");
                    });
        }

        ImportLineStatus newStatus = null;
        if (request.status() != null) {
            newStatus = parseLineStatus(request.status());
        }

        List<ImportDraftLine> matchedLines = allLines.stream()
                .filter(l -> request.lineIds().contains(l.getId()))
                .toList();

        for (ImportDraftLine line : matchedLines) {
            if (category != null) {
                line.setCategory(category);
            }
            if (newStatus != null) {
                validateStatusTransition(line.getStatus(), newStatus);
                line.setStatus(newStatus);
            }
        }

        importDraftLineRepository.saveAll(matchedLines);

        recalculateDraftCounts(draft, allLines);
        importDraftRepository.save(draft);

        log.info("Batch update: {} lignes mises à jour pour le draft {}", matchedLines.size(), draftId);

        return matchedLines.stream()
                .map(ImportDraftLineResponse::from)
                .toList();
    }

    public List<ImportDraftSummaryResponse> listDrafts(UUID userId) {
        return importDraftRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(d -> d.getStatus() == ImportDraftStatus.PENDING)
                .map(ImportDraftSummaryResponse::from)
                .toList();
    }

    public Page<ImportHistoryResponse> listHistory(UUID userId, int page, int size) {
        return importHistoryRepository.findByUserIdOrderByImportedAtDesc(userId, PageRequest.of(page, size))
                .map(ImportHistoryResponse::from);
    }

    public CsvPreviewResponse preview(MultipartFile file, String separator, String encoding, int skipHeaderLines) {
        validateFile(file);
        try {
            return csvParsingService.preview(file.getInputStream(), separator, encoding, skipHeaderLines);
        } catch (IOException e) {
            throw new IllegalArgumentException("Unable to read the file: " + e.getMessage());
        }
    }

    @Transactional
    public ImportDraftResponse uploadWithMapping(MultipartFile file, UUID accountId, CsvMappingRequest mapping, UUID userId) {
        validateFile(file);

        Account account = validateAccountForImport(accountId, userId);

        ImportProfileRegistry.ImportProfileConfig profile = new ImportProfileRegistry.ImportProfileConfig(
                null,
                mapping.profileName() != null ? mapping.profileName() : "Custom",
                mapping.separator(),
                mapping.dateFormat(),
                mapping.dateColumn(),
                mapping.amountColumn(),
                mapping.debitColumn(),
                mapping.creditColumn(),
                mapping.labelColumn(),
                mapping.encoding(),
                mapping.decimalSeparator(),
                mapping.skipHeaderLines(),
                List.of()
        );

        List<ImportDraftLine> parsedLines;
        try {
            parsedLines = csvParsingService.parse(file.getInputStream(), profile, userId);
        } catch (IOException e) {
            throw new IllegalArgumentException("Unable to read the file: " + e.getMessage());
        }

        deduplicationService.detectDuplicates(parsedLines, accountId, userId);

        UUID savedProfileId = null;

        if (mapping.saveAsProfile() && mapping.profileName() != null && !mapping.profileName().isBlank()) {
            ImportProfile customProfile = ImportProfile.builder()
                    .user(userRepository.getReferenceById(userId))
                    .name(mapping.profileName())
                    .separator(mapping.separator())
                    .dateFormat(mapping.dateFormat())
                    .dateColumn(mapping.dateColumn())
                    .amountColumn(mapping.amountColumn())
                    .debitColumn(mapping.debitColumn())
                    .creditColumn(mapping.creditColumn())
                    .labelColumn(mapping.labelColumn())
                    .encoding(mapping.encoding())
                    .decimalSeparator(mapping.decimalSeparator())
                    .skipHeaderLines(mapping.skipHeaderLines())
                    .build();
            customProfile = importProfileRepository.save(customProfile);
            savedProfileId = customProfile.getId();
            log.info("Profil d'import sauvegardé: id={}, name={}", savedProfileId, mapping.profileName());
        }

        log.info("CSV import (mapping custom) uploaded: {} lines from file '{}' for account {}", parsedLines.size(), file.getOriginalFilename(), accountId);

        ImportDraft savedDraft = createDraftFromLines(parsedLines, account, userId, file.getOriginalFilename(), savedProfileId, ImportProfileSource.CUSTOM);
        return buildResponseWithProfileName(savedDraft, profile.name());
    }

    public List<ImportProfileResponse> listProfiles(UUID userId) {
        List<ImportProfileResponse> result = new ArrayList<>();

        // Registry profiles
        for (ImportProfileRegistry.ImportProfileConfig cfg : ImportProfileRegistry.getAll()) {
            result.add(new ImportProfileResponse(null, cfg.bankCode(), cfg.name(), "REGISTRY", false));
        }

        // Custom profiles
        importProfileRepository.findByUserIdOrderByNameAsc(userId).stream()
                .map(p -> new ImportProfileResponse(p.getId(), null, p.getName(), "CUSTOM", true))
                .forEach(result::add);

        return result;
    }

    @Transactional
    public void deleteProfile(UUID profileId, UUID userId) {
        ImportProfile profile = importProfileRepository.findByIdAndUserId(profileId, userId)
                .orElseThrow(() -> {
                    log.error("Profil d'import non trouvé: id={}, userId={}", profileId, userId);
                    return new EntityNotFoundException("Import profile not found");
                });
        importProfileRepository.delete(profile);
        log.info("Profil d'import supprimé: {}", profileId);
    }

    private ImportDraft createDraftFromLines(List<ImportDraftLine> lines, Account account, UUID userId,
                                              String fileName, UUID profileId, ImportProfileSource profileSource) {
        int readyCount = (int) lines.stream().filter(l -> l.getStatus() == ImportLineStatus.READY).count();
        int reviewCount = (int) lines.stream().filter(l -> l.getStatus() == ImportLineStatus.NEEDS_REVIEW).count();
        int duplicateCount = (int) lines.stream().filter(l -> l.getStatus() == ImportLineStatus.DUPLICATE).count();
        int skippedCount = (int) lines.stream().filter(l -> l.getStatus() == ImportLineStatus.SKIPPED).count();

        ImportDraft draft = ImportDraft.builder()
                .user(userRepository.getReferenceById(userId))
                .account(account)
                .fileName(fileName)
                .totalLines(lines.size())
                .readyCount(readyCount)
                .reviewCount(reviewCount)
                .duplicateCount(duplicateCount)
                .skippedCount(skippedCount)
                .profileId(profileId)
                .profileSource(profileSource)
                .expiresAt(LocalDateTime.now().plusDays(DRAFT_EXPIRY_DAYS))
                .build();

        draft = importDraftRepository.save(draft);

        final ImportDraft savedDraft = draft;
        lines.forEach(line -> line.setDraft(savedDraft));
        importDraftLineRepository.saveAll(lines);
        savedDraft.getLines().addAll(lines);

        return savedDraft;
    }

    private ImportDraft findDraftByIdAndUser(UUID draftId, UUID userId) {
        return importDraftRepository.findById(draftId)
                .filter(d -> d.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Draft d'import non trouvé: id={}, userId={}", draftId, userId);
                    return new EntityNotFoundException("Import draft not found");
                });
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("The file is empty");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("The file exceeds the maximum allowed size (5MB)");
        }
        String originalFilename = file.getOriginalFilename();
        String contentType = file.getContentType();
        boolean validExtension = originalFilename != null && originalFilename.toLowerCase().endsWith(".csv");
        boolean validContentType = "text/csv".equalsIgnoreCase(contentType)
                || "application/csv".equalsIgnoreCase(contentType)
                || "text/plain".equalsIgnoreCase(contentType);
        if (!validExtension && !validContentType) {
            throw new IllegalArgumentException("The file must be in CSV format");
        }
    }

    private ImportLineStatus parseLineStatus(String status) {
        try {
            return ImportLineStatus.valueOf(status.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid line status: " + status);
        }
    }

    private void validateStatusTransition(ImportLineStatus current, ImportLineStatus next) {
        boolean valid = switch (next) {
            case READY -> current == ImportLineStatus.NEEDS_REVIEW || current == ImportLineStatus.DUPLICATE;
            case SKIPPED -> true;
            default -> false;
        };
        if (!valid) {
            throw new IllegalArgumentException(
                    "Invalid status transition: " + current + " → " + next);
        }
    }

    private void recalculateDraftCounts(ImportDraft draft) {
        List<ImportDraftLine> allLines = importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draft.getId());
        recalculateDraftCounts(draft, allLines);
    }

    private void recalculateDraftCounts(ImportDraft draft, List<ImportDraftLine> lines) {
        draft.setReadyCount((int) lines.stream().filter(l -> l.getStatus() == ImportLineStatus.READY).count());
        draft.setReviewCount((int) lines.stream().filter(l -> l.getStatus() == ImportLineStatus.NEEDS_REVIEW).count());
        draft.setDuplicateCount((int) lines.stream().filter(l -> l.getStatus() == ImportLineStatus.DUPLICATE).count());
        draft.setSkippedCount((int) lines.stream().filter(l -> l.getStatus() == ImportLineStatus.SKIPPED).count());
    }

    private Account validateAccountForImport(UUID accountId, UUID userId) {
        Account account = accountRepository.findByIdAndUserId(accountId, userId)
                .filter(a -> Boolean.TRUE.equals(a.getActif()))
                .orElseThrow(() -> {
                    log.error("Compte non trouvé ou inactif: id={}, userId={}", accountId, userId);
                    return new IllegalArgumentException("Account not found or inactive");
                });
        importDraftRepository.findByUserIdAndAccountIdAndStatus(userId, accountId, ImportDraftStatus.PENDING)
                .ifPresent(existing -> {
                    throw new ConflictException("An import is already in progress for this account: " + existing.getId());
                });
        return account;
    }

    private List<Transaction> buildTransactionsFromLines(ImportDraft draft, List<ImportDraftLine> readyLines) {
        return readyLines.stream()
                .map(line -> Transaction.builder()
                        .montant(line.getAmount())
                        .libelle(line.getCleanLabel())
                        .type(line.getTransactionType())
                        .date(line.getDate())
                        .category(line.getCategory())
                        .account(draft.getAccount())
                        .user(draft.getUser())
                        .build())
                .toList();
    }

    private ImportDraftResponse buildResponseWithProfileName(ImportDraft draft, String profileName) {
        List<ImportDraftLineResponse> lineResponses = draft.getLines().stream()
                .map(ImportDraftLineResponse::from)
                .toList();
        return new ImportDraftResponse(
                draft.getId(),
                draft.getAccount().getId(),
                draft.getAccount().getNom(),
                draft.getStatus().name(),
                draft.getFileName(),
                draft.getTotalLines(),
                draft.getReadyCount(),
                draft.getReviewCount(),
                draft.getDuplicateCount(),
                draft.getSkippedCount(),
                profileName,
                draft.getProfileSource() != null ? draft.getProfileSource().name() : null,
                draft.getCreatedAt(),
                draft.getExpiresAt(),
                lineResponses
        );
    }
}
