package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ImportLineBatchUpdateRequest;
import fr.kksdev.budget.api.dto.request.ImportLineUpdateRequest;
import fr.kksdev.budget.api.dto.response.CategoryRuleResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftLineResponse;
import fr.kksdev.budget.api.dto.response.ImportDraftResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.CategoryRuleOrigin;
import fr.kksdev.budget.api.enums.CategorySource;
import fr.kksdev.budget.api.enums.ImportLineStatus;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.CategoryRule;
import fr.kksdev.budget.api.model.ImportDraftLine;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.CategoryRuleRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.groups.Tuple.tuple;

/**
 * Categorisation des lignes d'un releve par les regles puis par l'historique
 * de l'utilisateur, et propagation d'une correction (KKS-383).
 *
 * <p>Commercants et montants fictifs, reproduisant les motifs observes sur des
 * donnees reelles : plusieurs abonnements sous un meme libelle, distingues par
 * leur montant.
 */
@SpringBootTest
@ActiveProfiles("test")
class CategorySuggestionIT {

    private static final LocalDate MARCH_2 = LocalDate.of(2026, Month.MARCH, 2);

    private static final String HEADER = """
            ="0000000000000000";01/03/2026;12/03/2026;0;12/03/2026;0,00 EUR

            Date de l'opération;Libellé;Détail de l'écriture;Montant de l'opération;Devise
            """;

    @Autowired CategorySuggestionService categorySuggestionService;
    @Autowired CategoryRuleService categoryRuleService;
    @Autowired ImportService importService;
    @Autowired UserRepository userRepository;
    @Autowired AccountRepository accountRepository;
    @Autowired CategoryRepository categoryRepository;
    @Autowired CategoryRuleRepository categoryRuleRepository;
    @Autowired TransactionRepository transactionRepository;
    @Autowired TransactionTemplate transactionTemplate;

    private User user;
    private Account account;
    private Category groceries;
    private Category software;
    private Category storage;

    @BeforeEach
    void setUp() {
        user = createUser();
        account = createSgAccount(user);
        groceries = createCategory(user, "Courses");
        software = createCategory(user, "Logiciels");
        storage = createCategory(user, "Stockage");
    }

    // -------------------------------------------------------------------------
    // Suggestion a l'upload
    // -------------------------------------------------------------------------

    @Test
    void should_use_category_of_same_merchant_when_history_has_one() {
        saveHistory("BOULANGERIE TEST", "4.10", TransactionType.DEPENSE, groceries, MARCH_2);

        ImportDraftLine line = suggestOne("BOULANGERIE TEST", "3.20", TransactionType.DEPENSE);

        assertThat(line.getCategory().getId()).isEqualTo(groceries.getId());
        assertThat(line.getCategorySource()).isEqualTo(CategorySource.HISTORY);
    }

    @Test
    void should_tell_apart_subscriptions_of_same_merchant_when_amounts_differ() {
        saveHistory("APPLE.COM/BILL", "10.00", TransactionType.DEPENSE, software, MARCH_2);
        saveHistory("APPLE.COM/BILL", "10.00", TransactionType.DEPENSE, software, MARCH_2.minusMonths(1));
        saveHistory("APPLE", "2.99", TransactionType.DEPENSE, storage, MARCH_2);

        assertThat(suggestOne("APPLE", "10.00", TransactionType.DEPENSE).getCategory().getId())
                .isEqualTo(software.getId());
        assertThat(suggestOne("APPLE.COM/BILL", "2.99", TransactionType.DEPENSE).getCategory().getId())
                .isEqualTo(storage.getId());
    }

    @Test
    void should_use_merchant_majority_when_no_past_transaction_has_same_amount() {
        saveHistory("APPLE.COM/BILL", "10.00", TransactionType.DEPENSE, software, MARCH_2);
        saveHistory("APPLE.COM/BILL", "25.95", TransactionType.DEPENSE, software, MARCH_2);
        saveHistory("APPLE", "2.99", TransactionType.DEPENSE, storage, MARCH_2);

        assertThat(suggestOne("APPLE.COM/BILL", "6.99", TransactionType.DEPENSE).getCategory().getId())
                .isEqualTo(software.getId());
    }

    @Test
    void should_prefer_most_recent_category_when_counts_are_tied() {
        saveHistory("EPICERIE TEST", "12.00", TransactionType.DEPENSE, software, MARCH_2.minusMonths(2));
        saveHistory("EPICERIE TEST", "13.00", TransactionType.DEPENSE, groceries, MARCH_2);

        assertThat(suggestOne("EPICERIE TEST", "9.00", TransactionType.DEPENSE).getCategory().getId())
                .isEqualTo(groceries.getId());
    }

    @Test
    void should_not_inherit_expense_category_when_line_is_income() {
        saveHistory("BOULANGERIE TEST", "4.10", TransactionType.DEPENSE, groceries, MARCH_2);

        assertThat(suggestOne("BOULANGERIE TEST", "4.10", TransactionType.RECETTE).getCategory()).isNull();
    }

    @Test
    void should_prefer_user_rule_when_history_disagrees() {
        saveHistory("BOULANGERIE TEST", "4.10", TransactionType.DEPENSE, groceries, MARCH_2);
        categoryRuleService.create("BOULANGERIE", software.getId(), user.getId());

        ImportDraftLine line = suggestOne("BOULANGERIE TEST", "3.20", TransactionType.DEPENSE);

        assertThat(line.getCategory().getId()).isEqualTo(software.getId());
        assertThat(line.getCategorySource()).isEqualTo(CategorySource.RULE);
    }

    @Test
    void should_ignore_history_of_other_users() {
        User other = createUser();
        Category othersCategory = createCategory(other, "Courses");
        transactionRepository.save(historyOf(other, createSgAccount(other), "BOULANGERIE TEST", "4.10",
                TransactionType.DEPENSE, othersCategory, MARCH_2));

        assertThat(suggestOne("BOULANGERIE TEST", "4.10", TransactionType.DEPENSE).getCategory()).isNull();
    }

    @Test
    void should_match_auto_rule_on_whole_words_only() {
        categoryRuleRepository.save(CategoryRule.builder()
                .user(user).pattern("Y B").category(groceries).origin(CategoryRuleOrigin.AUTO).build());

        assertThat(suggestOne("EASY BAR", "5.00", TransactionType.DEPENSE).getCategory()).isNull();
        assertThat(suggestOne("Y.B", "5.00", TransactionType.DEPENSE).getCategory().getId())
                .isEqualTo(groceries.getId());
    }

    // -------------------------------------------------------------------------
    // Correction pendant la revue
    // -------------------------------------------------------------------------

    @Test
    void should_propagate_correction_and_create_auto_rule_when_user_categorizes_a_line() {
        ImportDraftResponse draft = upload(
                "02/03/2026;CARTE X0000 01/03 ;CARTE X0000 01/03 BOULANGERIE TEST 110600000000001IOPD ;-3,20;EUR",
                "04/03/2026;CARTE X0000 03/03 ;CARTE X0000 03/03 BOULANGERIE TEST 110600000000002IOPD ;-4,10;EUR",
                "05/03/2026;CARTE X0000 04/03 ;CARTE X0000 04/03 EPICERIE TEST 110600000000003IOPD ;-9,00;EUR");
        ImportDraftLineResponse first = lineLabelled(draft, "BOULANGERIE TEST", "3.20");

        importService.updateLine(draft.id(), first.id(), new ImportLineUpdateRequest(groceries.getId(), null), user.getId());

        ImportDraftResponse reloaded = importService.getDraft(draft.id(), user.getId());
        assertThat(lineLabelled(reloaded, "BOULANGERIE TEST", "4.10").categoryId()).isEqualTo(groceries.getId());
        assertThat(lineLabelled(reloaded, "BOULANGERIE TEST", "4.10").categorySource()).isEqualTo("USER");
        assertThat(lineLabelled(reloaded, "EPICERIE TEST", "9.00").categoryId()).isNull();
        assertThat(categoryRuleService.getAllByUser(user.getId()))
                .extracting(CategoryRuleResponse::pattern, CategoryRuleResponse::origin)
                .containsExactly(tuple("BOULANGERIE TEST", "AUTO"));
    }

    @Test
    void should_apply_auto_rule_on_next_statement_when_correction_was_confirmed() {
        ImportDraftResponse draft = upload(
                "02/03/2026;CARTE X0000 01/03 ;CARTE X0000 01/03 BOULANGERIE TEST 110600000000001IOPD ;-3,20;EUR");
        importService.updateLine(draft.id(), draft.lines().getFirst().id(),
                new ImportLineUpdateRequest(groceries.getId(), null), user.getId());
        importService.confirm(draft.id(), user.getId());

        ImportDraftResponse next = upload(
                "09/03/2026;CARTE X0000 08/03 ;CARTE X0000 08/03 BOULANGERIE TEST 110600000000004IOPD ;-2,60;EUR");

        assertThat(next.lines().getFirst().categoryId()).isEqualTo(groceries.getId());
        assertThat(next.lines().getFirst().categorySource()).isEqualTo("RULE");
    }

    @Test
    void should_not_overwrite_rule_category_when_propagating() {
        // "APPLE.COM/BILL" et "APPLE" ont la meme cle commercant ; la regle ne vise que le premier.
        categoryRuleService.create("APPLE.COM", software.getId(), user.getId());
        ImportDraftResponse draft = upload(
                "02/03/2026;CARTE X0000 01/03 ;CARTE X0000 01/03 APPLE.COM/BILL 10,00 EUR IRLANDE COMMERCE ELECTRONIQUE 230600000000001IOPD ;-10,00;EUR",
                "04/03/2026;CARTE X0000 03/03 ;CARTE X0000 03/03 APPLE COMMERCE ELECTRONIQUE 110600000000002IOPD ;-2,99;EUR");
        UUID lineWithoutRule = lineLabelled(draft, "APPLE", "2.99").id();

        importService.updateLine(draft.id(), lineWithoutRule, new ImportLineUpdateRequest(storage.getId(), null), user.getId());

        ImportDraftLineResponse ruled = lineLabelled(importService.getDraft(draft.id(), user.getId()), "APPLE.COM/BILL", "10.00");
        assertThat(ruled.categoryId()).isEqualTo(software.getId());
        assertThat(ruled.categorySource()).isEqualTo("RULE");
    }

    @Test
    void should_accept_category_on_ready_line_when_status_ready_is_sent_again() {
        ImportDraftResponse draft = upload(
                "02/03/2026;CARTE X0000 01/03 ;CARTE X0000 01/03 BOULANGERIE TEST 110600000000001IOPD ;-3,20;EUR");
        UUID lineId = draft.lines().getFirst().id();

        ImportDraftLineResponse updated = importService.updateLine(draft.id(), lineId,
                new ImportLineUpdateRequest(groceries.getId(), "READY"), user.getId());

        assertThat(updated.categoryId()).isEqualTo(groceries.getId());
        assertThat(updated.status()).isEqualTo(ImportLineStatus.READY.name());
    }

    @Test
    void should_assign_category_in_batch_when_selection_contains_ready_lines() {
        ImportDraftResponse draft = upload(
                "02/03/2026;CARTE X0000 01/03 ;CARTE X0000 01/03 BOULANGERIE TEST 110600000000001IOPD ;-3,20;EUR",
                "05/03/2026;CARTE X0000 04/03 ;CARTE X0000 04/03 EPICERIE TEST 110600000000003IOPD ;-9,00;EUR");
        List<UUID> all = draft.lines().stream().map(ImportDraftLineResponse::id).toList();

        List<ImportDraftLineResponse> updated = importService.batchUpdateLines(draft.id(),
                new ImportLineBatchUpdateRequest(all, groceries.getId(), "READY"), user.getId());

        assertThat(updated).hasSize(2).allSatisfy(l -> assertThat(l.categoryId()).isEqualTo(groceries.getId()));
    }

    // -------------------------------------------------------------------------

    private ImportDraftLine suggestOne(String cleanLabel, String amount, TransactionType type) {
        ImportDraftLine line = ImportDraftLine.builder()
                .lineNumber(1)
                .rawLabel(cleanLabel)
                .cleanLabel(cleanLabel)
                .amount(new BigDecimal(amount))
                .date(MARCH_2.plusDays(7))
                .transactionType(type)
                .status(ImportLineStatus.READY)
                .build();
        // Transaction explicite, comme a l'upload : la categorie suggeree est un proxy lazy.
        transactionTemplate.executeWithoutResult(s -> categorySuggestionService.suggest(List.of(line), user.getId()));
        return line;
    }

    private ImportDraftResponse upload(String... csvLines) {
        String content = HEADER + String.join("\n", csvLines) + "\n";
        MockMultipartFile file = new MockMultipartFile("file", "releve.csv", "text/csv",
                content.getBytes(StandardCharsets.ISO_8859_1));
        return importService.upload(file, account.getId(), user.getId());
    }

    private static ImportDraftLineResponse lineLabelled(ImportDraftResponse draft, String cleanLabel, String amount) {
        return draft.lines().stream()
                .filter(l -> l.cleanLabel().startsWith(cleanLabel) && l.amount().compareTo(new BigDecimal(amount)) == 0)
                .findFirst()
                .orElseThrow();
    }

    private void saveHistory(String libelle, String amount, TransactionType type, Category category, LocalDate date) {
        transactionRepository.save(historyOf(user, account, libelle, amount, type, category, date));
    }

    private static Transaction historyOf(User owner, Account in, String libelle, String amount, TransactionType type,
                                         Category category, LocalDate date) {
        return Transaction.builder()
                .libelle(libelle)
                .montant(new BigDecimal(amount))
                .type(type)
                .date(date)
                .category(category)
                .account(in)
                .user(owner)
                .build();
    }

    private Category createCategory(User owner, String name) {
        return categoryRepository.save(Category.builder()
                .nom(name).icone("🏷").couleur("#000000").user(owner).build());
    }

    private User createUser() {
        return userRepository.save(User.builder()
                .email("categories-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Categories")
                .build());
    }

    private Account createSgAccount(User owner) {
        return accountRepository.save(Account.builder()
                // Nom unique : PostgreSQL impose UNIQUE(nom, user_id), que le schema H2 genere ignore.
                .nom("Compte " + UUID.randomUUID().toString().substring(0, 8))
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#000000")
                .bankCode("SG")
                .user(owner)
                .build());
    }
}
