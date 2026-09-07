package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CsvMappingRequest;
import fr.kksdev.budget.api.dto.request.ImportLineBatchUpdateRequest;
import fr.kksdev.budget.api.dto.request.ImportLineUpdateRequest;
import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.CsvProfileNotFoundException;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.ImportDraftLineRepository;
import fr.kksdev.budget.api.repository.ImportDraftRepository;
import fr.kksdev.budget.api.repository.ImportHistoryRepository;
import fr.kksdev.budget.api.repository.ImportProfileRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ImportServiceTest {

    /** Date fixe : un test date verifie sinon un comportement different
     * selon le jour ou il tourne (meme raison que ClockConfig, KKS-355). */
    private static final LocalDate FIXED_DATE = LocalDate.of(2026, 3, 12);

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private ImportDraftRepository importDraftRepository;

    @Mock
    private ImportDraftLineRepository importDraftLineRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private ImportHistoryRepository importHistoryRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CsvParsingService csvParsingService;

    @Mock
    private CategoryRuleService categoryRuleService;

    @Mock
    private DeduplicationService deduplicationService;

    @Mock
    private ImportProfileRepository importProfileRepository;

    @InjectMocks
    private ImportService importService;

    private final UUID userId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();
    private final UUID draftId = UUID.randomUUID();
    private final UUID lineId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Account buildActiveAccount(User user) {
        return Account.builder()
                .id(accountId)
                .nom("Compte Principal")
                .bankCode("SG")
                .actif(true)
                .user(user)
                .build();
    }

    private ImportDraft buildDraft(User user, Account account, ImportDraftStatus status) {
        return ImportDraft.builder()
                .id(draftId)
                .user(user)
                .account(account)
                .status(status)
                .build();
    }

    private ImportDraftLine buildLine(ImportDraft draft, ImportLineStatus status) {
        return ImportDraftLine.builder()
                .id(lineId)
                .draft(draft)
                .lineNumber(1)
                .rawLabel("CARREFOUR")
                .cleanLabel("Carrefour")
                .amount(new BigDecimal("10.00"))
                .date(FIXED_DATE)
                .transactionType(TransactionType.DEPENSE)
                .status(status)
                .build();
    }

    private MockMultipartFile validCsvFile() {
        return new MockMultipartFile("file", "test.csv", "text/csv", "date;label;amount\n".getBytes());
    }

    // -------------------------------------------------------------------------
    // upload() / uploadWithMapping()
    // -------------------------------------------------------------------------

    @Test
    void should_throw_when_noImportProfileForBank() {
        var user = buildUser();
        var account = buildActiveAccount(user);

        when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
        when(importDraftRepository.findByUserIdAndAccountIdAndStatus(userId, accountId, ImportDraftStatus.PENDING))
                .thenReturn(Optional.empty());
        when(csvParsingService.detectProfile("SG")).thenReturn(Optional.empty());

        var file = validCsvFile();

        assertThatThrownBy(() -> importService.upload(file, accountId, userId))
                .isInstanceOf(CsvProfileNotFoundException.class)
                .hasMessage("No import profile available for bank: SG");
    }

    @Test
    void should_throw_when_fileUnreadableOnUpload() throws IOException {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var profile = new ImportProfileRegistry.ImportProfileConfig(
                "SG", "Société Générale", ";", "dd/MM/yyyy", "Date", "Montant",
                null, null, "Libellé", "UTF-8", ",", 1, List.of());

        when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
        when(importDraftRepository.findByUserIdAndAccountIdAndStatus(userId, accountId, ImportDraftStatus.PENDING))
                .thenReturn(Optional.empty());
        when(csvParsingService.detectProfile("SG")).thenReturn(Optional.of(profile));

        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(false);
        when(file.getSize()).thenReturn(100L);
        when(file.getOriginalFilename()).thenReturn("test.csv");
        when(file.getInputStream()).thenThrow(new IOException("stream closed"));

        assertThatThrownBy(() -> importService.upload(file, accountId, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Unable to read the file: stream closed");
    }

    @Test
    void should_throw_when_fileUnreadableOnUploadWithMapping() throws IOException {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var mapping = new CsvMappingRequest(";", "dd/MM/yyyy", "Date", "Montant", null, null,
                "Libellé", "UTF-8", ",", 1, false, null);

        when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
        when(importDraftRepository.findByUserIdAndAccountIdAndStatus(userId, accountId, ImportDraftStatus.PENDING))
                .thenReturn(Optional.empty());

        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(false);
        when(file.getSize()).thenReturn(100L);
        when(file.getOriginalFilename()).thenReturn("test.csv");
        when(file.getInputStream()).thenThrow(new IOException("stream closed"));

        assertThatThrownBy(() -> importService.uploadWithMapping(file, accountId, mapping, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Unable to read the file: stream closed");
    }

    @Test
    void should_throw_when_fileUnreadableOnPreview() throws IOException {
        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(false);
        when(file.getSize()).thenReturn(100L);
        when(file.getOriginalFilename()).thenReturn("test.csv");
        when(file.getInputStream()).thenThrow(new IOException("stream closed"));

        assertThatThrownBy(() -> importService.preview(file, ";", "UTF-8", 1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Unable to read the file: stream closed");
    }

    @Test
    void should_throw_when_accountNotFoundOrInactiveOnUpload() {
        when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.empty());

        var file = validCsvFile();

        assertThatThrownBy(() -> importService.upload(file, accountId, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Account not found or inactive");
    }

    @Test
    void should_throw_when_importAlreadyInProgressForAccount() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var existingDraft = buildDraft(user, account, ImportDraftStatus.PENDING);

        when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
        when(importDraftRepository.findByUserIdAndAccountIdAndStatus(userId, accountId, ImportDraftStatus.PENDING))
                .thenReturn(Optional.of(existingDraft));

        var file = validCsvFile();

        assertThatThrownBy(() -> importService.upload(file, accountId, userId))
                .isInstanceOf(ConflictException.class)
                .hasMessage("An import is already in progress for this account: " + draftId);
    }

    // -------------------------------------------------------------------------
    // validateFile()
    // -------------------------------------------------------------------------

    @Test
    void should_throw_when_fileIsEmpty() {
        var emptyFile = new MockMultipartFile("file", "test.csv", "text/csv", new byte[0]);

        assertThatThrownBy(() -> importService.preview(emptyFile, ";", "UTF-8", 1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("The file is empty");
    }

    @Test
    void should_throw_when_fileExceedsMaxSize() {
        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(false);
        when(file.getSize()).thenReturn(6L * 1024 * 1024);

        assertThatThrownBy(() -> importService.preview(file, ";", "UTF-8", 1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("The file exceeds the maximum allowed size (5MB)");
    }

    @Test
    void should_throw_when_fileNotCsvFormat() {
        var file = new MockMultipartFile("file", "test.txt", "application/json", "not a csv".getBytes());

        assertThatThrownBy(() -> importService.preview(file, ";", "UTF-8", 1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("The file must be in CSV format");
    }

    // -------------------------------------------------------------------------
    // confirm()
    // -------------------------------------------------------------------------

    @Test
    void should_throw_when_confirmingDraftNotPending() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var draft = buildDraft(user, account, ImportDraftStatus.COMPLETED);

        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));

        assertThatThrownBy(() -> importService.confirm(draftId, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Import is not awaiting confirmation, status: COMPLETED");
    }

    @Test
    void should_throw_when_confirmingWithLinesRequiringReview() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var draft = buildDraft(user, account, ImportDraftStatus.PENDING);
        var line = buildLine(draft, ImportLineStatus.NEEDS_REVIEW);

        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));
        when(importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draftId)).thenReturn(List.of(line));

        assertThatThrownBy(() -> importService.confirm(draftId, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Some lines require review before confirmation");
    }

    // -------------------------------------------------------------------------
    // updateLine()
    // -------------------------------------------------------------------------

    @Test
    void should_throw_when_updatingLineOnNonEditableDraft() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var draft = buildDraft(user, account, ImportDraftStatus.COMPLETED);
        var request = new ImportLineUpdateRequest(null, null);

        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));

        assertThatThrownBy(() -> importService.updateLine(draftId, lineId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("The draft is no longer editable");
    }

    @Test
    void should_throw_when_importLineNotFound() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var draft = buildDraft(user, account, ImportDraftStatus.PENDING);
        var request = new ImportLineUpdateRequest(null, null);

        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));
        when(importDraftLineRepository.findById(lineId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> importService.updateLine(draftId, lineId, request, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Import line not found");
    }

    @Test
    void should_throw_when_categoryNotFoundOnUpdateLine() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var draft = buildDraft(user, account, ImportDraftStatus.PENDING);
        var line = buildLine(draft, ImportLineStatus.NEEDS_REVIEW);
        var request = new ImportLineUpdateRequest(categoryId, null);

        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));
        when(importDraftLineRepository.findById(lineId)).thenReturn(Optional.of(line));
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> importService.updateLine(draftId, lineId, request, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Category not found");
    }

    @Test
    void should_throw_when_lineStatusInvalidOnUpdateLine() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var draft = buildDraft(user, account, ImportDraftStatus.PENDING);
        var line = buildLine(draft, ImportLineStatus.NEEDS_REVIEW);
        var request = new ImportLineUpdateRequest(null, "BOGUS");

        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));
        when(importDraftLineRepository.findById(lineId)).thenReturn(Optional.of(line));

        assertThatThrownBy(() -> importService.updateLine(draftId, lineId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Invalid line status: BOGUS");
    }

    // -------------------------------------------------------------------------
    // batchUpdateLines()
    // -------------------------------------------------------------------------

    @Test
    void should_throw_when_batchUpdatingDraftNotPending() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var draft = buildDraft(user, account, ImportDraftStatus.COMPLETED);
        var request = new ImportLineBatchUpdateRequest(List.of(lineId), null, null);

        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));

        assertThatThrownBy(() -> importService.batchUpdateLines(draftId, request, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Import is not awaiting modification, status: COMPLETED");
    }

    @Test
    void should_throw_when_categoryNotFoundOnBatchUpdateLines() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var draft = buildDraft(user, account, ImportDraftStatus.PENDING);
        var request = new ImportLineBatchUpdateRequest(List.of(lineId), categoryId, null);

        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));
        when(importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draftId)).thenReturn(List.of());
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> importService.batchUpdateLines(draftId, request, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Category not found");
    }

    // -------------------------------------------------------------------------
    // deleteDraft() / deleteProfile()
    // -------------------------------------------------------------------------

    @Test
    void should_throw_when_importDraftNotFound() {
        when(importDraftRepository.findById(draftId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> importService.deleteDraft(draftId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Import draft not found");
    }

    @Test
    void should_throw_when_importProfileNotFound() {
        var profileId = UUID.randomUUID();
        when(importProfileRepository.findByIdAndUserId(profileId, userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> importService.deleteProfile(profileId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Import profile not found");
    }
}
