package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ImportLineBatchUpdateRequest;
import fr.kksdev.budget.api.dto.response.ImportConfirmResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftLineResponse;
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
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Reimport d'un releve qui chevauche le precedent (KKS-382), de bout en bout :
 * parsing du profil SG reel, deduplication, confirmation, base H2.
 *
 * <p>Les releves sont synthetiques : commercants et references fictifs, jamais
 * de releve reel dans le depot ({@code docs/direction.md} §4.7). Ils reproduisent
 * les motifs observes sur des donnees reelles : chevauchement de periode et
 * lignes identiques legitimes le meme jour.
 */
@SpringBootTest
@ActiveProfiles("test")
class ImportReimportIT {

    private static final String HEADER = """
            ="0000000000000000";01/03/2026;12/03/2026;0;12/03/2026;0,00 EUR

            Date de l'opération;Libellé;Détail de l'écriture;Montant de l'opération;Devise
            """;

    private static final String BAKERY = "02/03/2026;CARTE X0000 01/03 ;CARTE X0000 01/03 BOULANGERIE TEST 110600000000001IOPD ;-3,20;EUR";
    private static final String FEE = "03/03/2026;FRAIS BANCAIRES;FRAIS BANCAIRES TEST ;-45,00;EUR";
    private static final String DIRECT_DEBIT = "05/03/2026;PRELEVEMENT EUROPE;PRELEVEMENT EUROPEEN 1111111111 DE: OPERATEUR TEST ID: FR00ZZZ000000 REF: ref-0001 ;-19,99;EUR";
    private static final String SALARY = "06/03/2026;VIR RECU    123456;VIR RECU    1234567890S DE: EMPLOYEUR TEST REF: SALAIRE ;1500,00;EUR";
    private static final String GROCERY = "10/03/2026;CARTE X0000 09/03 ;CARTE X0000 09/03 EPICERIE TEST 110600000000002IOPD ;-12,50;EUR";
    private static final String LATER_FEE = "11/03/2026;FRAIS BANCAIRES;FRAIS BANCAIRES TEST ;-45,00;EUR";

    /** Premier releve : deux frais identiques le meme jour, deux operations reelles. */
    private static final List<String> FIRST_STATEMENT = List.of(SALARY, DIRECT_DEBIT, FEE, FEE, BAKERY);

    /** Releve suivant : reprend la fin du premier et ajoute deux operations. */
    private static final List<String> OVERLAPPING_STATEMENT = List.of(LATER_FEE, GROCERY, SALARY, DIRECT_DEBIT, FEE, FEE);

    @Autowired ImportService importService;
    @Autowired LabelCleaningService labelCleaningService;
    @Autowired UserRepository userRepository;
    @Autowired AccountRepository accountRepository;
    @Autowired TransactionRepository transactionRepository;

    private UUID userId;
    private UUID accountId;

    @BeforeEach
    void setUp() {
        User user = createUser();
        userId = user.getId();
        accountId = createSgAccount(user).getId();
    }

    @Test
    void should_skip_already_imported_lines_without_blocking_when_statement_overlaps() {
        importAndConfirm(FIRST_STATEMENT);

        ImportDraftResponse draft = upload(OVERLAPPING_STATEMENT);

        assertThat(draft.alreadyImportedCount()).isEqualTo(4);
        assertThat(draft.skippedCount()).isEqualTo(4);
        assertThat(draft.duplicateCount()).isZero();
        assertThat(draft.readyCount()).isEqualTo(2);
        assertThat(draft.lines())
                .filteredOn(l -> "ALREADY_IMPORTED".equals(l.skipReason()))
                .allSatisfy(l -> {
                    assertThat(l.status()).isEqualTo("SKIPPED");
                    assertThat(l.duplicateTransactionId()).isNotNull();
                });

        ImportConfirmResponse confirmed = importService.confirm(draft.id(), userId);

        assertThat(confirmed.importedCount()).isEqualTo(2);
        assertThat(confirmed.alreadyImportedCount()).isEqualTo(4);
        assertThat(accountTransactions()).hasSize(7);
    }

    @Test
    void should_import_identical_lines_as_distinct_operations_when_database_holds_fewer() {
        importAndConfirm(List.of(FEE, FEE));

        ImportDraftResponse draft = upload(List.of(FEE, FEE, FEE));

        assertThat(draft.alreadyImportedCount()).isEqualTo(2);
        assertThat(draft.readyCount()).isEqualTo(1);

        importService.confirm(draft.id(), userId);
        assertThat(accountTransactions()).hasSize(3);

        ImportDraftResponse again = upload(List.of(FEE, FEE, FEE));
        assertThat(again.alreadyImportedCount()).isEqualTo(3);
        assertThat(again.readyCount()).isZero();
    }

    @Test
    void should_recognize_imported_transaction_when_user_renamed_and_redated_it() {
        importAndConfirm(List.of(SALARY));
        Transaction salary = accountTransactions().getFirst();
        salary.setLibelle("Mon salaire");
        salary.setDate(LocalDate.of(2026, Month.FEBRUARY, 1));
        transactionRepository.save(salary);

        ImportDraftResponse draft = upload(List.of(SALARY));

        assertThat(draft.alreadyImportedCount()).isEqualTo(1);
        assertThat(draft.lines().getFirst().duplicateTransactionId()).isEqualTo(salary.getId());
    }

    @Test
    void should_recognize_and_fingerprint_transaction_imported_before_fingerprints() {
        Transaction legacy = saveLegacyImport(cleanLabelOf(BAKERY), "3.20", LocalDate.of(2026, Month.MARCH, 2));

        ImportDraftResponse draft = upload(List.of(BAKERY));
        assertThat(draft.alreadyImportedCount()).isEqualTo(1);

        importService.confirm(draft.id(), userId);
        Transaction backfilled = transactionRepository.findById(legacy.getId()).orElseThrow();
        assertThat(backfilled.getImportFingerprint()).isNotNull();

        // Une fois l'empreinte posee, le renommage ne l'empeche plus d'etre reconnue.
        backfilled.setLibelle("Pain");
        transactionRepository.save(backfilled);
        assertThat(upload(List.of(BAKERY)).alreadyImportedCount()).isEqualTo(1);
    }

    @Test
    void should_keep_probable_duplicate_blocking_when_label_is_only_similar() {
        saveLegacyImport(cleanLabelOf(BAKERY) + "S", "3.20", LocalDate.of(2026, Month.MARCH, 2));

        ImportDraftResponse draft = upload(List.of(BAKERY));

        assertThat(draft.alreadyImportedCount()).isZero();
        assertThat(draft.duplicateCount()).isEqualTo(1);
        assertThatThrownBy(() -> importService.confirm(draft.id(), userId))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void should_ignore_transactions_of_other_users_and_accounts() {
        importAndConfirm(FIRST_STATEMENT);

        User otherUser = createUser();
        UUID otherUsersAccount = createSgAccount(otherUser).getId();
        ImportDraftResponse otherUsersDraft = importService.upload(csv(FIRST_STATEMENT), otherUsersAccount, otherUser.getId());
        assertThat(otherUsersDraft.alreadyImportedCount()).isZero();

        UUID sameUsersOtherAccount = createSgAccount(userRepository.findById(userId).orElseThrow()).getId();
        ImportDraftResponse otherAccountDraft = importService.upload(csv(FIRST_STATEMENT), sameUsersOtherAccount, userId);
        assertThat(otherAccountDraft.alreadyImportedCount()).isZero();
    }

    @Test
    void should_leave_already_imported_lines_untouched_when_batch_updating_all_lines() {
        importAndConfirm(FIRST_STATEMENT);
        ImportDraftResponse draft = upload(OVERLAPPING_STATEMENT);
        List<UUID> allLineIds = draft.lines().stream().map(ImportDraftLineResponse::id).toList();

        List<ImportDraftLineResponse> updated = importService.batchUpdateLines(
                draft.id(), new ImportLineBatchUpdateRequest(allLineIds, null, "SKIPPED"), userId);

        assertThat(updated).hasSize(2);
        ImportDraftResponse reloaded = importService.getDraft(draft.id(), userId);
        assertThat(reloaded.alreadyImportedCount()).isEqualTo(4);
        assertThat(reloaded.lines())
                .filteredOn(l -> "ALREADY_IMPORTED".equals(l.skipReason()))
                .hasSize(4);
    }

    // -------------------------------------------------------------------------

    private void importAndConfirm(List<String> lines) {
        ImportDraftResponse draft = upload(lines);
        importService.confirm(draft.id(), userId);
    }

    private ImportDraftResponse upload(List<String> lines) {
        return importService.upload(csv(lines), accountId, userId);
    }

    private static MockMultipartFile csv(List<String> lines) {
        String content = HEADER + String.join("\n", lines) + "\n";
        return new MockMultipartFile("file", "releve.csv", "text/csv", content.getBytes(StandardCharsets.ISO_8859_1));
    }

    private String cleanLabelOf(String csvLine) {
        String detail = csvLine.split(";")[2];
        List<String> sgPatterns = ImportProfileRegistry.findByBankCode("SG").orElseThrow().cleanupPatterns();
        return labelCleaningService.clean(detail.trim(), sgPatterns);
    }

    private List<Transaction> accountTransactions() {
        return transactionRepository.findByUserIdAndAccountIdAndDateBetween(
                userId, accountId, LocalDate.of(2000, Month.JANUARY, 1), LocalDate.of(2100, Month.JANUARY, 1));
    }

    /** Transaction importee avant KKS-382 : meme forme qu'un import, sans empreinte. */
    private Transaction saveLegacyImport(String libelle, String amount, LocalDate date) {
        return transactionRepository.save(Transaction.builder()
                .libelle(libelle)
                .montant(new BigDecimal(amount))
                .type(TransactionType.DEPENSE)
                .date(date)
                .account(accountRepository.findById(accountId).orElseThrow())
                .user(userRepository.findById(userId).orElseThrow())
                .build());
    }

    private User createUser() {
        return userRepository.save(User.builder()
                .email("import-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Import")
                .build());
    }

    private Account createSgAccount(User user) {
        return accountRepository.save(Account.builder()
                // Nom unique : PostgreSQL impose UNIQUE(nom, user_id), que le schema H2 genere ignore.
                .nom("Compte " + UUID.randomUUID().toString().substring(0, 8))
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#000000")
                .bankCode("SG")
                .user(user)
                .build());
    }
}
