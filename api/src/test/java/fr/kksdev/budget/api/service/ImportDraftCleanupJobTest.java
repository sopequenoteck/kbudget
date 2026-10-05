package fr.kksdev.budget.api.service;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.LoggerFactory;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ImportDraftCleanupJobTest {

    @Mock
    private ImportDraftRepository importDraftRepository;

    @InjectMocks
    private ImportDraftCleanupJob job;

    private ListAppender<ILoggingEvent> logAppender;
    private Logger jobLogger;

    @BeforeEach
    void setUpLogCapture() {
        jobLogger = (Logger) LoggerFactory.getLogger(ImportDraftCleanupJob.class);
        logAppender = new ListAppender<>();
        logAppender.start();
        jobLogger.addAppender(logAppender);
    }

    @AfterEach
    void detachLogCapture() {
        jobLogger.detachAppender(logAppender);
    }

    @Test
    void should_delete_pending_expired_drafts_and_log_their_count_when_job_runs() {
        when(importDraftRepository.findByStatusAndExpiresAtBefore(
                eq(ImportDraftStatus.PENDING), any(LocalDateTime.class)))
                .thenReturn(List.of(new ImportDraft(), new ImportDraft()));

        job.cleanupExpiredDrafts();

        verify(importDraftRepository).deleteByStatusAndExpiresAtBefore(
                eq(ImportDraftStatus.PENDING), any(LocalDateTime.class));
        List<String> messages = logAppender.list.stream().map(ILoggingEvent::getFormattedMessage).toList();
        assertThat(messages).containsExactly(
                "Expired import draft cleanup job started",
                "Expired import draft cleanup finished: 2 drafts deleted");
    }
}
