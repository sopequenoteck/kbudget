package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CsvMappingRequest;
import fr.kksdev.budget.api.dto.request.ImportLineBatchUpdateRequest;
import fr.kksdev.budget.api.dto.request.ImportLineUpdateRequest;
import fr.kksdev.budget.api.dto.response.ImportBalanceCheckResponse;
import fr.kksdev.budget.api.dto.response.ImportProfileResponse;
import fr.kksdev.budget.api.enums.ImportDraftStatus;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.ImportProfileSource;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.CsvProfileNotFoundException;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.ImportDraft;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.ImportHistory;
import fr.kksdev.budget.api.model.ImportProfile;
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
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.same;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ImportServiceTest {

    /** Date fixe : un test date verifie sinon un comportement different
     * selon le jour ou il tourne (meme raison que ClockConfig, KKS-355). */
    private static final LocalDate FIXED_DATE = LocalDate.of(2026, Month.MARCH, 12);

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

    @Mock
    private ImportProfileRegistry importProfileRegistry;

    @Mock
    private ImportProfileDetector importProfileDetector;

    @Mock
    private ImportBalanceService importBalanceService;

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
        when(importProfileDetector.resolve(any(), eq("SG"), eq(userId))).thenReturn(Optional.empty());

        var file = validCsvFile();

        assertThatThrownBy(() -> importService.upload(file, accountId, userId))
                .isInstanceOf(CsvProfileNotFoundException.class)
                .hasMessage("No import profile available for bank: SG");
    }

    @Test
    void should_throw_when_fileUnreadableOnUpload() throws IOException {
        var user = buildUser();
        var account = buildActiveAccount(user);

        when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
        when(importDraftRepository.findByUserIdAndAccountIdAndStatus(userId, accountId, ImportDraftStatus.PENDING))
                .thenReturn(Optional.empty());

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

        assertThatThrownBy(() -> importService.confirm(draftId, false, userId))
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

        assertThatThrownBy(() -> importService.confirm(draftId, false, userId))
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
    // detect() (KKS-440)
    // -------------------------------------------------------------------------

    private ImportProfileRegistry.ImportProfileConfig sgConfig() {
        return new ImportProfileRegistry.ImportProfileConfig(
                "SG", "Société Générale", ";", "dd/MM/yyyy", "Date", "Montant",
                null, null, "Libellé", "ISO-8859-1", ",", 1, List.of(), List.of(), null, null);
    }

    @Test
    void should_describe_the_bundled_profile_when_detecting_a_recognized_file() {
        when(importProfileDetector.detect(any(), eq(userId)))
                .thenReturn(Optional.of(new ImportProfileDetector.Detection(sgConfig(), ImportProfileSource.REGISTRY, null)));

        var response = importService.detect(validCsvFile(), userId);

        assertThat(response.recognized()).isTrue();
        assertThat(response.profileSource()).isEqualTo("REGISTRY");
        assertThat(response.bankCode()).isEqualTo("SG");
        assertThat(response.profileName()).isEqualTo("Société Générale");
    }

    @Test
    void should_describe_the_custom_profile_without_bank_code_when_detecting_a_recognized_file() {
        var custom = new ImportProfileRegistry.ImportProfileConfig(
                null, "My bank", ",", "dd/MM/yyyy", "Date", "Montant", null, null, "Libellé", "UTF-8", ".", 0, List.of(), List.of(), null, null);
        when(importProfileDetector.detect(any(), eq(userId)))
                .thenReturn(Optional.of(new ImportProfileDetector.Detection(custom, ImportProfileSource.CUSTOM, UUID.randomUUID())));

        var response = importService.detect(validCsvFile(), userId);

        assertThat(response.recognized()).isTrue();
        assertThat(response.profileSource()).isEqualTo("CUSTOM");
        assertThat(response.bankCode()).isNull();
        assertThat(response.profileName()).isEqualTo("My bank");
    }

    @Test
    void should_report_not_recognized_without_profile_when_detecting_an_unknown_file() {
        when(importProfileDetector.detect(any(), eq(userId))).thenReturn(Optional.empty());

        var response = importService.detect(validCsvFile(), userId);

        assertThat(response.recognized()).isFalse();
        assertThat(response.profileSource()).isNull();
        assertThat(response.bankCode()).isNull();
        assertThat(response.profileName()).isNull();
    }

    @Test
    void should_create_nothing_when_detecting_a_file() {
        when(importProfileDetector.detect(any(), eq(userId))).thenReturn(Optional.empty());

        importService.detect(validCsvFile(), userId);

        verifyNoInteractions(importDraftRepository, importDraftLineRepository, importProfileRepository, transactionRepository);
    }

    static Stream<Arguments> rejectedFiles() {
        return Stream.of(
                Arguments.of("empty file", new MockMultipartFile("file", "test.csv", "text/csv", new byte[0]),
                        "The file is empty"),
                Arguments.of("no file", null, "The file is empty"),
                Arguments.of("not a csv", new MockMultipartFile("file", "statement.pdf", "application/pdf", "x".getBytes()),
                        "The file must be in CSV format"));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("rejectedFiles")
    void should_throw_when_detecting_a_file_that_is_not_acceptable(String description, MultipartFile file, String message) {
        assertThatThrownBy(() -> importService.detect(file, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage(message);
    }

    @Test
    void should_throw_when_detecting_a_file_that_cannot_be_read() throws IOException {
        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(false);
        when(file.getSize()).thenReturn(100L);
        when(file.getOriginalFilename()).thenReturn("test.csv");
        when(file.getInputStream()).thenThrow(new IOException("stream closed"));

        assertThatThrownBy(() -> importService.detect(file, userId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Unable to read the file: stream closed");
    }

    // -------------------------------------------------------------------------
    // listProfiles()
    // -------------------------------------------------------------------------

    @Test
    void should_list_bundled_profiles_then_custom_profiles_of_the_user() {
        var customId = UUID.randomUUID();
        var custom = ImportProfile.builder().id(customId).name("My bank").build();
        when(importProfileRegistry.getAll()).thenReturn(List.of(sgConfig()));
        when(importProfileRepository.findByUserIdOrderByNameAsc(userId)).thenReturn(List.of(custom));

        var profiles = importService.listProfiles(userId);

        assertThat(profiles).containsExactly(
                new ImportProfileResponse(null, "SG", "Société Générale", "REGISTRY", false),
                new ImportProfileResponse(customId, null, "My bank", "CUSTOM", true));
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

    // -------------------------------------------------------------------------
    // Statement header: account recognition and balance (KKS-384)
    // -------------------------------------------------------------------------

    private static final List<String> SG_HEADER_LINES =
            List.of("=\"0000000000001596\";15/09/2026;01/10/2026;2;01/10/2026;1842,37 EUR");

    private ImportProfileRegistry.ImportProfileConfig sgConfigWithHeader() {
        var config = sgConfig();
        return new ImportProfileRegistry.ImportProfileConfig(
                config.bankCode(), config.name(), config.separator(), config.dateFormat(), config.dateColumn(),
                config.amountColumn(), null, null, config.labelColumn(), config.encoding(), config.decimalSeparator(),
                config.skipHeaderLines(), List.of(), List.of(),
                StatementHeaderSpec.of(0, ";", 0, 5, 4, "dd/MM/yyyy"), null);
    }

    private void givenDetected(ImportProfileRegistry.ImportProfileConfig config, ImportProfileSource source, UUID customId) {
        when(importProfileDetector.detect(any(), eq(userId)))
                .thenReturn(Optional.of(new ImportProfileDetector.Detection(config, source, customId)));
        when(csvParsingService.readSkippedLines(any(), any())).thenReturn(SG_HEADER_LINES);
    }

    @Test
    void should_suggest_the_account_when_exactly_one_active_account_carries_the_profile_and_suffix() {
        givenDetected(sgConfigWithHeader(), ImportProfileSource.REGISTRY, null);
        var suggested = buildActiveAccount(buildUser());
        when(accountRepository.findByUserIdAndActifTrueAndStatementProfileKeyAndStatementAccountSuffix(
                userId, "REGISTRY:SG", "1596")).thenReturn(List.of(suggested));

        var response = importService.detect(validCsvFile(), userId);

        assertThat(response.accountSuffix()).isEqualTo("1596");
        assertThat(response.suggestedAccountId()).isEqualTo(accountId);
    }

    static Stream<List<Account>> ambiguousOrMissingMatches() {
        return Stream.of(
                List.of(),
                List.of(Account.builder().id(UUID.randomUUID()).build(), Account.builder().id(UUID.randomUUID()).build()));
    }

    @ParameterizedTest
    @MethodSource("ambiguousOrMissingMatches")
    void should_suggest_no_account_when_none_or_several_carry_the_profile_and_suffix(List<Account> matches) {
        givenDetected(sgConfigWithHeader(), ImportProfileSource.REGISTRY, null);
        when(accountRepository.findByUserIdAndActifTrueAndStatementProfileKeyAndStatementAccountSuffix(
                userId, "REGISTRY:SG", "1596")).thenReturn(matches);

        var response = importService.detect(validCsvFile(), userId);

        assertThat(response.accountSuffix()).isEqualTo("1596");
        assertThat(response.suggestedAccountId()).isNull();
    }

    @Test
    void should_report_the_suffix_but_look_up_no_account_when_the_profile_has_no_identity() {
        givenDetected(sgConfigWithHeader(), ImportProfileSource.CUSTOM, null);

        var response = importService.detect(validCsvFile(), userId);

        assertThat(response.accountSuffix()).isEqualTo("1596");
        assertThat(response.suggestedAccountId()).isNull();
        verifyNoInteractions(accountRepository);
    }

    @Test
    void should_report_no_suffix_and_look_up_no_account_when_the_header_is_unreadable() {
        givenDetected(sgConfigWithHeader(), ImportProfileSource.REGISTRY, null);
        when(csvParsingService.readSkippedLines(any(), any())).thenReturn(List.of());

        var response = importService.detect(validCsvFile(), userId);

        assertThat(response.recognized()).isTrue();
        assertThat(response.accountSuffix()).isNull();
        assertThat(response.suggestedAccountId()).isNull();
        verifyNoInteractions(accountRepository);
    }

    @Test
    void should_not_read_any_header_when_the_profile_has_no_statement_header() {
        when(importProfileDetector.detect(any(), eq(userId)))
                .thenReturn(Optional.of(new ImportProfileDetector.Detection(sgConfig(), ImportProfileSource.REGISTRY, null)));

        var response = importService.detect(validCsvFile(), userId);

        assertThat(response.accountSuffix()).isNull();
        assertThat(response.suggestedAccountId()).isNull();
        verifyNoInteractions(csvParsingService, accountRepository);
    }

    @Test
    void should_store_the_statement_header_on_the_draft_and_return_it_with_the_balances_when_uploading() {
        var user = buildUser();
        var account = buildActiveAccount(user);
        var detection = new ImportProfileDetector.Detection(sgConfigWithHeader(), ImportProfileSource.REGISTRY, null);
        when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
        when(importDraftRepository.findByUserIdAndAccountIdAndStatus(userId, accountId, ImportDraftStatus.PENDING))
                .thenReturn(Optional.empty());
        when(importProfileDetector.resolve(any(), eq("SG"), eq(userId))).thenReturn(Optional.of(detection));
        when(csvParsingService.parse(any(), any(), eq(userId))).thenReturn(List.of());
        when(csvParsingService.readSkippedLines(any(), any())).thenReturn(SG_HEADER_LINES);
        when(importDraftRepository.save(any(ImportDraft.class))).thenAnswer(invocation -> {
            ImportDraft saved = invocation.getArgument(0);
            saved.setStatus(ImportDraftStatus.PENDING);
            return saved;
        });
        when(importBalanceService.draftBalances(any(), any(), eq(userId)))
                .thenReturn(new ImportBalanceService.DraftBalances(new BigDecimal("10.00"), new BigDecimal("20.00")));

        var response = importService.upload(validCsvFile(), accountId, userId);

        ArgumentCaptor<ImportDraft> saved = ArgumentCaptor.forClass(ImportDraft.class);
        verify(importDraftRepository).save(saved.capture());
        assertThat(saved.getValue().getStatementProfileKey()).isEqualTo("REGISTRY:SG");
        assertThat(saved.getValue().getStatementAccountSuffix()).isEqualTo("1596");
        assertThat(saved.getValue().getStatementBalance()).isEqualByComparingTo("1842.37");
        assertThat(saved.getValue().getStatementBalanceDate()).isEqualTo(LocalDate.of(2026, Month.OCTOBER, 1));
        assertThat(response.statementAccountSuffix()).isEqualTo("1596");
        assertThat(response.statementBalance()).isEqualByComparingTo("1842.37");
        assertThat(response.statementBalanceDate()).isEqualTo(LocalDate.of(2026, Month.OCTOBER, 1));
        assertThat(response.projectedBalance()).isEqualByComparingTo("10.00");
        assertThat(response.proposedOpeningBalance()).isEqualByComparingTo("20.00");
    }

    // -------------------------------------------------------------------------
    // confirm(): opening balance, account recognition, balance check (KKS-384)
    // -------------------------------------------------------------------------

    private ImportDraft confirmableDraft(Account account, String profileKey, String suffix) {
        var draft = buildDraft(buildUser(), account, ImportDraftStatus.PENDING);
        draft.setStatementProfileKey(profileKey);
        draft.setStatementAccountSuffix(suffix);
        var ready = buildLine(draft, ImportLineStatus.READY);
        when(importDraftRepository.findById(draftId)).thenReturn(Optional.of(draft));
        when(importDraftLineRepository.findByDraftIdOrderByLineNumberAsc(draftId)).thenReturn(List.of(ready));
        when(importHistoryRepository.save(any())).thenReturn(ImportHistory.builder().id(UUID.randomUUID()).build());
        return draft;
    }

    private Account accountWithOpeningBalance(String openingBalance) {
        var account = buildActiveAccount(buildUser());
        account.setSoldeInitial(new BigDecimal(openingBalance));
        return account;
    }

    private void givenProposedOpeningBalance(String proposed) {
        when(importBalanceService.draftBalances(any(), any(), eq(userId))).thenReturn(
                new ImportBalanceService.DraftBalances(
                        new BigDecimal("1.00"), proposed == null ? null : new BigDecimal(proposed)));
    }

    @Test
    void should_set_the_opening_balance_from_the_statement_when_requested_on_the_first_import() {
        var account = accountWithOpeningBalance("0");
        confirmableDraft(account, "REGISTRY:SG", "1596");
        givenProposedOpeningBalance("946.67");

        importService.confirm(draftId, true, userId);

        assertThat(account.getSoldeInitial()).isEqualByComparingTo("946.67");
        verify(accountRepository).save(account);
    }

    @Test
    void should_keep_the_opening_balance_without_asking_for_a_proposal_when_not_requested() {
        var account = accountWithOpeningBalance("12.00");
        confirmableDraft(account, "REGISTRY:SG", "1596");

        importService.confirm(draftId, false, userId);

        assertThat(account.getSoldeInitial()).isEqualByComparingTo("12.00");
        verify(importBalanceService, never()).draftBalances(any(), any(), any());
    }

    @Test
    void should_keep_the_opening_balance_when_requested_but_there_is_no_proposal() {
        var account = accountWithOpeningBalance("12.00");
        confirmableDraft(account, "REGISTRY:SG", "1596");
        givenProposedOpeningBalance(null);

        importService.confirm(draftId, true, userId);

        assertThat(account.getSoldeInitial()).isEqualByComparingTo("12.00");
    }

    @Test
    void should_record_the_profile_and_suffix_on_the_chosen_account_replacing_the_previous_ones() {
        var account = accountWithOpeningBalance("0");
        account.setStatementProfileKey("REGISTRY:OLD");
        account.setStatementAccountSuffix("0000");
        confirmableDraft(account, "REGISTRY:SG", "1596");

        importService.confirm(draftId, false, userId);

        assertThat(account.getStatementProfileKey()).isEqualTo("REGISTRY:SG");
        assertThat(account.getStatementAccountSuffix()).isEqualTo("1596");
        verify(accountRepository).save(account);
    }

    @ParameterizedTest
    @CsvSource(value = {"null,1596", "REGISTRY:SG,null", "null,null"}, nullValues = "null")
    void should_keep_the_previous_association_when_the_statement_gives_no_profile_key_or_no_suffix(
            String profileKey, String suffix) {
        var account = accountWithOpeningBalance("0");
        account.setStatementProfileKey("REGISTRY:OLD");
        account.setStatementAccountSuffix("0000");
        confirmableDraft(account, profileKey, suffix);

        importService.confirm(draftId, false, userId);

        assertThat(account.getStatementProfileKey()).isEqualTo("REGISTRY:OLD");
        assertThat(account.getStatementAccountSuffix()).isEqualTo("0000");
    }

    @Test
    void should_return_the_balance_check_with_the_ids_of_the_created_transactions_when_confirming() {
        var account = accountWithOpeningBalance("0");
        var draft = confirmableDraft(account, null, null);
        var check = new ImportBalanceCheckResponse(
                new BigDecimal("1.00"), LocalDate.of(2026, Month.OCTOBER, 1), new BigDecimal("1.00"), BigDecimal.ZERO, List.of());
        when(importBalanceService.check(any(), any(), any(), any())).thenReturn(check);

        var response = importService.confirm(draftId, false, userId);

        assertThat(response.balanceCheck()).isSameAs(check);
        assertThat(response.importedCount()).isEqualTo(1);
        verify(importBalanceService).check(same(draft), any(), any(), any());
    }
}
