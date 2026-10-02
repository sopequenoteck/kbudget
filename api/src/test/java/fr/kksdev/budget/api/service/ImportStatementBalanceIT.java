package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CsvMappingRequest;
import fr.kksdev.budget.api.dto.request.ImportLineUpdateRequest;
import fr.kksdev.budget.api.dto.response.ImportBalanceCheckResponse;
import fr.kksdev.budget.api.dto.response.ImportBalanceCheckResponse.SuspectTransaction;
import fr.kksdev.budget.api.dto.response.ImportConfirmResponse;
import fr.kksdev.budget.api.dto.response.ImportDetectionResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The balance given by the bank in a statement header (KKS-384), end to end on
 * the H2 database with the real Societe Generale profile: opening balance,
 * balance check after the import, account recognition and isolation between users.
 *
 * <p>The statements are synthetic ({@link ImportTestFiles}): zeroed account
 * numbers and fictitious merchants, never a real statement.
 *
 * <p>The three operations below add up to 895.70. With the bank balance of
 * 1842.37, the opening balance that makes both agree is 946.67.
 */
@SpringBootTest
@ActiveProfiles("test")
class ImportStatementBalanceIT {

    private static final String ACCOUNT_NUMBER = "00000000001596";
    private static final String OTHER_ACCOUNT_NUMBER = "00000000002222";
    private static final String BALANCE_DATE = "01/10/2026";
    private static final String BANK_BALANCE = "1842.37 EUR";
    private static final LocalDate BALANCE_LOCAL_DATE = LocalDate.of(2026, Month.OCTOBER, 1);
    private static final LocalDate BAKERY_DATE = LocalDate.of(2026, Month.SEPTEMBER, 16);
    private static final String GYM_LABEL = "Salle de sport";
    private static final LocalDate GYM_DATE = LocalDate.of(2026, Month.SEPTEMBER, 20);
    private static final LocalDate RENT_DATE = LocalDate.of(2026, Month.SEPTEMBER, 21);

    private static final String BAKERY = "16/09/2026;CARTE X1596 14/09 ;CARTE X1596 14/09 BOULANGERIE DU MARCHE 110600000000101IOPD ;-4,30;EUR";
    private static final String SALARY = "20/09/2026;VIR RECU    123456;VIR RECU    1234567890S DE: EMPLOYEUR TEST REF: SALAIRE ;1500,00;EUR";
    private static final String RENT = "21/09/2026;PRELEVEMENT EUROPE;PRELEVEMENT EUROPEEN 3333333333 DE: BAILLEUR TEST ID: FR00ZZZ000002 REF: ref-0202 ;-600,00;EUR";

    private static final CsvMappingRequest OTHER_BANK_MAPPING = new CsvMappingRequest(
            ",", "yyyy-MM-dd", "Booked", "Value", null, null, "Memo", "UTF-8", ".", 0, true, "My bank");

    @Autowired ImportService importService;
    @Autowired AccountService accountService;
    @Autowired UserRepository userRepository;
    @Autowired AccountRepository accountRepository;
    @Autowired TransactionRepository transactionRepository;
    @Autowired JdbcTemplate jdbcTemplate;

    private User user;
    private UUID userId;
    private UUID accountId;

    @BeforeEach
    void setUp() {
        user = createUser();
        userId = user.getId();
        accountId = createAccount(user, "0").getId();
    }

    // -------------------------------------------------------------------------
    // Draft: what the header gave, projected balance, proposed opening balance
    // -------------------------------------------------------------------------

    @Test
    void should_expose_the_header_and_propose_the_opening_balance_when_first_import() {
        ImportDraftResponse draft = upload();

        assertThat(draft.statementAccountSuffix()).isEqualTo("1596");
        assertThat(draft.statementBalance()).isEqualByComparingTo("1842.37");
        assertThat(draft.statementBalanceDate()).isEqualTo(BALANCE_LOCAL_DATE);
        assertThat(draft.projectedBalance()).isEqualByComparingTo("895.70");
        assertThat(draft.proposedOpeningBalance()).isEqualByComparingTo("946.67");
    }

    @Test
    void should_count_existing_transactions_in_the_projected_balance() {
        saveTransaction(accountId, TransactionType.RECETTE, "Prime", "100.00", LocalDate.of(2026, Month.AUGUST, 1));
        saveTransaction(accountId, TransactionType.RECETTE, "After the statement balance", "500.00", BALANCE_LOCAL_DATE.plusDays(1));

        ImportDraftResponse draft = upload();

        assertThat(draft.projectedBalance()).isEqualByComparingTo("995.70");
        assertThat(draft.proposedOpeningBalance()).isEqualByComparingTo("846.67");
    }

    @Test
    void should_recompute_the_projected_balance_when_a_line_is_skipped() {
        ImportDraftResponse draft = upload();
        UUID bakeryLine = draft.lines().stream()
                .filter(line -> line.rawLabel().contains("BOULANGERIE"))
                .findFirst().orElseThrow().id();

        importService.updateLine(draft.id(), bakeryLine, new ImportLineUpdateRequest(null, "SKIPPED", null, null), userId);
        ImportDraftResponse reloaded = importService.getDraft(draft.id(), userId);

        assertThat(reloaded.projectedBalance()).isEqualByComparingTo("900.00");
        assertThat(reloaded.proposedOpeningBalance()).isEqualByComparingTo("942.37");
        assertThat(reloaded.statementAccountSuffix()).isEqualTo("1596");
    }

    @Test
    void should_not_propose_an_opening_balance_when_the_account_already_has_an_import() {
        confirmedImport(false);

        ImportDraftResponse second = upload();

        assertThat(second.proposedOpeningBalance()).isNull();
        assertThat(second.projectedBalance()).isEqualByComparingTo("895.70");
    }

    @Test
    void should_give_no_balances_once_the_draft_is_confirmed() {
        ImportDraftResponse draft = upload();
        importService.confirm(draft.id(), false, userId);

        ImportDraftResponse reloaded = importService.getDraft(draft.id(), userId);

        assertThat(reloaded.statementBalance()).isEqualByComparingTo("1842.37");
        assertThat(reloaded.projectedBalance()).isNull();
        assertThat(reloaded.proposedOpeningBalance()).isNull();
    }

    // -------------------------------------------------------------------------
    // Confirmation: opening balance
    // -------------------------------------------------------------------------

    @Test
    void should_match_the_bank_balance_without_manual_adjustment_when_opening_balance_applied_on_first_import() {
        ImportConfirmResponse confirmed = confirmedImport(true);

        assertThat(accountService.getAccountById(accountId, userId).solde()).isEqualByComparingTo("1842.37");
        assertThat(accountRepository.findById(accountId).orElseThrow().getSoldeInitial()).isEqualByComparingTo("946.67");
        assertThat(adjustmentsOf(accountId)).isEmpty();
        assertThat(confirmed.balanceCheck().difference()).isEqualByComparingTo("0");
        assertThat(confirmed.balanceCheck().suspects()).isEmpty();
    }

    @Test
    void should_leave_the_opening_balance_alone_when_not_requested() {
        ImportConfirmResponse confirmed = confirmedImport(false);

        assertThat(accountRepository.findById(accountId).orElseThrow().getSoldeInitial()).isEqualByComparingTo("0");
        assertThat(confirmed.balanceCheck().computedBalance()).isEqualByComparingTo("895.70");
        assertThat(confirmed.balanceCheck().difference()).isEqualByComparingTo("-946.67");
    }

    @Test
    void should_ignore_the_opening_balance_request_when_the_account_already_has_an_import() {
        confirmedImport(false);
        ImportDraftResponse second = upload();

        importService.confirm(second.id(), true, userId);

        assertThat(accountRepository.findById(accountId).orElseThrow().getSoldeInitial()).isEqualByComparingTo("0");
    }

    @Test
    void should_fix_the_opening_balance_from_the_current_state_when_a_transaction_is_added_after_the_upload() {
        ImportDraftResponse draft = upload();
        // Before the period of the statement: no line can explain it, nor is it a suspect (KKS-443).
        saveTransaction(accountId, TransactionType.DEPENSE, "Added meanwhile", "10.00", BAKERY_DATE.minusDays(1));

        importService.confirm(draft.id(), true, userId);

        assertThat(accountService.getAccountById(accountId, userId).solde()).isEqualByComparingTo("1842.37");
    }

    @Test
    void should_propose_an_opening_balance_that_leaves_out_an_entry_the_statement_does_not_explain() {
        saveTransaction(accountId, TransactionType.DEPENSE, GYM_LABEL, "30.00", GYM_DATE);

        ImportDraftResponse draft = upload();

        // The real balance counts the entry; the proposal does not absorb it (KKS-443).
        assertThat(draft.projectedBalance()).isEqualByComparingTo("865.70");
        assertThat(draft.proposedOpeningBalance()).isEqualByComparingTo("946.67");
    }

    @Test
    void should_report_the_unexplained_entry_as_the_difference_and_a_suspect_when_the_proposed_opening_balance_is_applied() {
        Transaction gym = saveTransaction(accountId, TransactionType.DEPENSE, GYM_LABEL, "30.00", GYM_DATE);

        ImportBalanceCheckResponse check = confirmedImport(true).balanceCheck();

        assertThat(accountRepository.findById(accountId).orElseThrow().getSoldeInitial()).isEqualByComparingTo("946.67");
        assertThat(check.computedBalance()).isEqualByComparingTo("1812.37");
        assertThat(check.difference()).isEqualByComparingTo("-30.00");
        assertThat(check.suspects()).extracting(SuspectTransaction::id).containsExactly(gym.getId());
        assertThat(check.suspects().getFirst().libelle()).isEqualTo(GYM_LABEL);
    }

    @Test
    void should_match_the_bank_balance_once_the_unexplained_entry_is_deleted() {
        Transaction gym = saveTransaction(accountId, TransactionType.DEPENSE, GYM_LABEL, "30.00", GYM_DATE);
        confirmedImport(true);
        assertThat(accountService.getAccountById(accountId, userId).solde()).isEqualByComparingTo("1812.37");

        transactionRepository.deleteById(gym.getId());

        assertThat(accountService.getAccountById(accountId, userId).solde()).isEqualByComparingTo("1842.37");
    }

    @Test
    void should_not_leave_out_of_the_proposed_opening_balance_an_entry_the_statement_matches() {
        saveTransaction(accountId, TransactionType.DEPENSE, "Pain", "4.30", BAKERY_DATE);

        ImportDraftResponse draft = upload();
        ImportBalanceCheckResponse check = importService.confirm(draft.id(), true, userId).balanceCheck();

        assertThat(draft.matchedCount()).isEqualTo(1);
        assertThat(draft.proposedOpeningBalance()).isEqualByComparingTo("946.67");
        assertThat(check.difference()).isEqualByComparingTo("0");
        assertThat(check.suspects()).isEmpty();
    }

    // -------------------------------------------------------------------------
    // Confirmation: balance check
    // -------------------------------------------------------------------------

    @Test
    void should_report_the_duplicates_as_the_difference_and_list_them_as_suspects_but_not_adjustments() {
        // 946.67 would match the bank; the adjustment (+50) is compensated by a lower opening balance.
        UUID duplicatesAccount = createAccount(user, "896.67").getId();
        // Same amounts as the bakery and the rent, but dated outside the matching windows (KKS-385):
        // the bakery purchase is dated 14/09 (2 days either side), the rent booked on 21/09 (5 days before, 1 after).
        Transaction bread = saveTransaction(duplicatesAccount, TransactionType.DEPENSE, "Pain", "4.30", BAKERY_DATE.plusDays(1));
        Transaction rent = saveTransaction(duplicatesAccount, TransactionType.DEPENSE, "Loyer", "600.00", RENT_DATE.plusDays(2));
        saveTransaction(duplicatesAccount, TransactionType.AJUSTEMENT, "Balance adjustment", "50.00", LocalDate.of(2026, Month.SEPTEMBER, 18));

        ImportDraftResponse draft = importService.upload(statementFile(), duplicatesAccount, userId);
        assertThat(draft.duplicateCount()).isZero();
        ImportBalanceCheckResponse check = importService.confirm(draft.id(), false, userId).balanceCheck();

        assertThat(check.bankBalance()).isEqualByComparingTo("1842.37");
        assertThat(check.balanceDate()).isEqualTo(BALANCE_LOCAL_DATE);
        assertThat(check.computedBalance()).isEqualByComparingTo("1238.07");
        assertThat(check.difference()).isEqualByComparingTo("-604.30");
        assertThat(check.suspects()).extracting(SuspectTransaction::id).containsExactly(bread.getId(), rent.getId());
        assertThat(check.suspects().getFirst()).satisfies(suspect -> {
            assertThat(suspect.date()).isEqualTo(BAKERY_DATE.plusDays(1));
            assertThat(suspect.libelle()).isEqualTo("Pain");
            assertThat(suspect.montant()).isEqualByComparingTo("4.30");
            assertThat(suspect.type()).isEqualTo(TransactionType.DEPENSE);
        });
    }

    @Test
    void should_report_the_adjustment_in_the_difference_without_listing_it() {
        UUID adjustedAccount = createAccount(user, "946.67").getId();
        saveTransaction(adjustedAccount, TransactionType.AJUSTEMENT, "Balance adjustment", "50.00", LocalDate.of(2026, Month.SEPTEMBER, 18));

        ImportDraftResponse draft = importService.upload(statementFile(), adjustedAccount, userId);
        ImportBalanceCheckResponse check = importService.confirm(draft.id(), false, userId).balanceCheck();

        assertThat(check.difference()).isEqualByComparingTo("50.00");
        assertThat(check.suspects()).isEmpty();
    }

    @Test
    void should_not_list_transactions_dated_outside_the_period_of_the_statement() {
        UUID periodAccount = createAccount(user, "946.67").getId();
        saveTransaction(periodAccount, TransactionType.DEPENSE, "Before", "10.00", BAKERY_DATE.minusDays(1));
        saveTransaction(periodAccount, TransactionType.DEPENSE, "After", "20.00", BALANCE_LOCAL_DATE.plusDays(1));

        ImportDraftResponse draft = importService.upload(statementFile(), periodAccount, userId);
        ImportBalanceCheckResponse check = importService.confirm(draft.id(), false, userId).balanceCheck();

        assertThat(check.suspects()).isEmpty();
        assertThat(check.difference()).isEqualByComparingTo("-10.00");
    }

    @Test
    void should_list_a_transaction_dated_between_the_last_line_and_the_balance_date() {
        UUID periodAccount = createAccount(user, "946.67").getId();
        saveTransaction(periodAccount, TransactionType.DEPENSE, "Late duplicate", "20.00", RENT_DATE.plusDays(1));

        ImportDraftResponse draft = importService.upload(statementFile(), periodAccount, userId);
        ImportBalanceCheckResponse check = importService.confirm(draft.id(), false, userId).balanceCheck();

        assertThat(check.difference()).isEqualByComparingTo("-20.00");
        assertThat(check.suspects()).extracting(ImportBalanceCheckResponse.SuspectTransaction::libelle)
                .containsExactly("Late duplicate");
    }

    @Test
    void should_not_list_transactions_the_statement_already_knows_when_it_is_imported_again() {
        confirmedImport(true);
        ImportDraftResponse again = upload();
        assertThat(again.alreadyImportedCount()).isEqualTo(3);

        ImportBalanceCheckResponse check = importService.confirm(again.id(), false, userId).balanceCheck();

        assertThat(check.suspects()).isEmpty();
        assertThat(check.difference()).isEqualByComparingTo("0");
    }

    // -------------------------------------------------------------------------
    // Header unreadable or absent: behavior as before
    // -------------------------------------------------------------------------

    static Stream<Arguments> unreadableHeaders() {
        return Stream.of(
                Arguments.of("balance unreadable", ImportTestFiles.sgBankHeader(ACCOUNT_NUMBER, BALANCE_DATE, "N/A"),
                        "1596", null, BALANCE_LOCAL_DATE),
                Arguments.of("balance date unreadable", ImportTestFiles.sgBankHeader(ACCOUNT_NUMBER, "32/13/2026", BANK_BALANCE),
                        "1596", new BigDecimal("1842.37"), null),
                Arguments.of("account number shorter than four digits", ImportTestFiles.sgBankHeader("123", BALANCE_DATE, BANK_BALANCE),
                        null, new BigDecimal("1842.37"), BALANCE_LOCAL_DATE));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("unreadableHeaders")
    void should_import_as_before_with_the_unreadable_values_absent(
            String description, String header, String expectedSuffix, BigDecimal expectedBalance, LocalDate expectedDate) {
        ImportDraftResponse draft = importService.upload(
                new MockMultipartFile("file", "releve.csv", "text/csv", ImportTestFiles.sgStatementOf(header, BAKERY)),
                accountId, userId);

        assertThat(draft.readyCount()).isEqualTo(1);
        assertThat(draft.statementAccountSuffix()).isEqualTo(expectedSuffix);
        assertThat(draft.statementBalance()).isEqualTo(expectedBalance);
        assertThat(draft.statementBalanceDate()).isEqualTo(expectedDate);

        ImportConfirmResponse confirmed = importService.confirm(draft.id(), true, userId);

        assertThat(confirmed.importedCount()).isEqualTo(1);
        assertThat(accountRepository.findById(accountId).orElseThrow().getStatementAccountSuffix()).isEqualTo(expectedSuffix);
        if (expectedBalance == null || expectedDate == null) {
            assertThat(draft.projectedBalance()).isNull();
            assertThat(draft.proposedOpeningBalance()).isNull();
            assertThat(confirmed.balanceCheck()).isNull();
            assertThat(accountRepository.findById(accountId).orElseThrow().getSoldeInitial()).isEqualByComparingTo("0");
        } else {
            assertThat(confirmed.balanceCheck()).isNotNull();
        }
    }

    @Test
    void should_leave_every_new_field_empty_when_the_profile_has_no_statement_header() {
        UUID otherBankAccount = createAccount(user, "0").getId();
        MockMultipartFile file = new MockMultipartFile("file", "export.csv", "text/csv", ImportTestFiles.otherBankStatement());

        ImportDraftResponse draft = importService.uploadWithMapping(file, otherBankAccount, OTHER_BANK_MAPPING, userId);
        ImportConfirmResponse confirmed = importService.confirm(draft.id(), true, userId);

        assertThat(draft.statementAccountSuffix()).isNull();
        assertThat(draft.statementBalance()).isNull();
        assertThat(draft.statementBalanceDate()).isNull();
        assertThat(draft.projectedBalance()).isNull();
        assertThat(draft.proposedOpeningBalance()).isNull();
        assertThat(confirmed.importedCount()).isEqualTo(2);
        assertThat(confirmed.balanceCheck()).isNull();
        Account account = accountRepository.findById(otherBankAccount).orElseThrow();
        assertThat(account.getSoldeInitial()).isEqualByComparingTo("0");
        assertThat(account.getStatementProfileKey()).isNull();
        assertThat(account.getStatementAccountSuffix()).isNull();
    }

    @Test
    void should_detect_a_file_of_a_profile_without_header_with_no_suffix_and_no_suggestion() {
        importService.uploadWithMapping(
                new MockMultipartFile("file", "export.csv", "text/csv", ImportTestFiles.otherBankStatement()),
                createAccount(user, "0").getId(), OTHER_BANK_MAPPING, userId);

        ImportDetectionResponse detection = importService.detect(
                new MockMultipartFile("file", "export.csv", "text/csv", ImportTestFiles.otherBankStatement()), userId);

        assertThat(detection.recognized()).isTrue();
        assertThat(detection.accountSuffix()).isNull();
        assertThat(detection.suggestedAccountId()).isNull();
    }

    // -------------------------------------------------------------------------
    // Account recognition
    // -------------------------------------------------------------------------

    @Test
    void should_suggest_no_account_before_any_import_but_report_the_suffix() {
        ImportDetectionResponse detection = detect(userId);

        assertThat(detection.recognized()).isTrue();
        assertThat(detection.accountSuffix()).isEqualTo("1596");
        assertThat(detection.suggestedAccountId()).isNull();
    }

    @Test
    void should_suggest_the_account_the_same_number_was_imported_on() {
        confirmedImport(false);

        assertThat(detect(userId).suggestedAccountId()).isEqualTo(accountId);
    }

    @Test
    void should_record_the_profile_key_and_the_suffix_only_on_the_account() {
        confirmedImport(false);

        assertThat(jdbcTemplate.queryForMap(
                "SELECT statement_profile_key, statement_account_suffix FROM accounts WHERE id = ?", accountId))
                .containsEntry("STATEMENT_PROFILE_KEY", "REGISTRY:SG")
                .containsEntry("STATEMENT_ACCOUNT_SUFFIX", "1596");
        assertThat(accountService.getAccountById(accountId, userId).statementAccountSuffix()).isEqualTo("1596");
        assertThat(jdbcTemplate.queryForMap(
                "SELECT statement_profile_key, statement_account_suffix FROM import_drafts WHERE account_id = ?", accountId))
                .containsEntry("STATEMENT_ACCOUNT_SUFFIX", "1596");
    }

    @Test
    void should_suggest_nothing_when_two_active_accounts_carry_the_same_profile_and_suffix() {
        confirmedImport(false);
        UUID secondAccount = createAccount(user, "0").getId();
        importService.confirm(importService.upload(statementFile(), secondAccount, userId).id(), false, userId);

        assertThat(detect(userId).suggestedAccountId()).isNull();
    }

    @Test
    void should_suggest_the_remaining_account_when_the_other_one_is_inactive() {
        confirmedImport(false);
        UUID secondAccount = createAccount(user, "0").getId();
        importService.confirm(importService.upload(statementFile(), secondAccount, userId).id(), false, userId);
        Account second = accountRepository.findById(secondAccount).orElseThrow();
        second.setActif(false);
        accountRepository.save(second);

        assertThat(detect(userId).suggestedAccountId()).isEqualTo(accountId);
    }

    @Test
    void should_replace_the_association_of_the_account_when_another_number_is_imported_on_it() {
        confirmedImport(false);

        ImportDraftResponse other = importService.upload(
                new MockMultipartFile("file", "releve.csv", "text/csv",
                        ImportTestFiles.sgStatementOf(ImportTestFiles.sgBankHeader(OTHER_ACCOUNT_NUMBER, BALANCE_DATE, BANK_BALANCE), SALARY)),
                accountId, userId);
        importService.confirm(other.id(), false, userId);

        assertThat(accountRepository.findById(accountId).orElseThrow().getStatementAccountSuffix()).isEqualTo("2222");
        assertThat(detect(userId).suggestedAccountId()).isNull();
    }

    // -------------------------------------------------------------------------
    // Isolation between users
    // -------------------------------------------------------------------------

    @Test
    void should_never_read_or_write_the_association_of_another_user() {
        confirmedImport(false);
        User otherUser = createUser();
        UUID otherAccountId = createAccount(otherUser, "0").getId();

        // Same profile, same suffix: nothing of user one's accounts is suggested to user two.
        ImportDetectionResponse beforeImport = detect(otherUser.getId());
        assertThat(beforeImport.accountSuffix()).isEqualTo("1596");
        assertThat(beforeImport.suggestedAccountId()).isNull();

        // User two imports the same number on his own account: his association does not touch user one's.
        importService.confirm(importService.upload(statementFile(), otherAccountId, otherUser.getId()).id(), false, otherUser.getId());

        assertThat(detect(otherUser.getId()).suggestedAccountId()).isEqualTo(otherAccountId);
        assertThat(detect(userId).suggestedAccountId()).isEqualTo(accountId);
        assertThat(accountRepository.findById(accountId).orElseThrow().getStatementAccountSuffix()).isEqualTo("1596");
    }

    @Test
    void should_not_list_the_transactions_of_another_user_as_suspects() {
        User otherUser = createUser();
        saveTransaction(createAccount(otherUser, "0").getId(), TransactionType.DEPENSE, "Elsewhere", "1.00", BAKERY_DATE);

        ImportBalanceCheckResponse check = confirmedImport(false).balanceCheck();

        assertThat(check.suspects()).isEmpty();
    }

    // -------------------------------------------------------------------------

    private ImportConfirmResponse confirmedImport(boolean applyOpeningBalance) {
        ImportDraftResponse draft = upload();
        return importService.confirm(draft.id(), applyOpeningBalance, userId);
    }

    private ImportDraftResponse upload() {
        return importService.upload(statementFile(), accountId, userId);
    }

    private ImportDetectionResponse detect(UUID forUserId) {
        return importService.detect(statementFile(), forUserId);
    }

    private static MockMultipartFile statementFile() {
        return new MockMultipartFile("file", "releve.csv", "text/csv",
                ImportTestFiles.sgStatementOf(ImportTestFiles.sgBankHeader(ACCOUNT_NUMBER, BALANCE_DATE, BANK_BALANCE),
                        BAKERY, SALARY, RENT));
    }

    private List<Transaction> adjustmentsOf(UUID forAccountId) {
        return transactionRepository.findByUserIdAndAccountIdAndDateBetween(
                        userId, forAccountId, LocalDate.of(2000, Month.JANUARY, 1), LocalDate.of(2100, Month.JANUARY, 1))
                .stream().filter(t -> t.getType() == TransactionType.AJUSTEMENT).toList();
    }

    private Transaction saveTransaction(UUID forAccountId, TransactionType type, String libelle, String amount, LocalDate date) {
        Account account = accountRepository.findById(forAccountId).orElseThrow();
        return transactionRepository.save(Transaction.builder()
                .libelle(libelle)
                .montant(new BigDecimal(amount))
                .type(type)
                .date(date)
                .account(account)
                .user(account.getUser())
                .build());
    }

    private User createUser() {
        return userRepository.save(User.builder()
                .email("statement-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Statement")
                .build());
    }

    private Account createAccount(User owner, String openingBalance) {
        return accountRepository.save(Account.builder()
                // Unique name: PostgreSQL enforces UNIQUE(nom, user_id), which the generated H2 schema ignores.
                .nom("Compte " + UUID.randomUUID().toString().substring(0, 8))
                .type(AccountType.COURANT)
                .soldeInitial(new BigDecimal(openingBalance))
                .icone("🏦")
                .couleur("#000000")
                .bankCode("SG")
                .user(owner)
                .build());
    }
}
