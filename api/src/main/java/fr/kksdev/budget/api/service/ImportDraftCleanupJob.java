package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class ImportDraftCleanupJob {

    private final ImportDraftRepository importDraftRepository;

    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void cleanupExpiredDrafts() {
        log.info("Expired import draft cleanup job started");

        List<?> expiredDrafts = importDraftRepository
                .findByStatusAndExpiresAtBefore(ImportDraftStatus.PENDING, LocalDateTime.now());

        int count = expiredDrafts.size();

        importDraftRepository.deleteByStatusAndExpiresAtBefore(ImportDraftStatus.PENDING, LocalDateTime.now());

        log.info("Expired import draft cleanup finished: {} drafts deleted", count);
    }
}
