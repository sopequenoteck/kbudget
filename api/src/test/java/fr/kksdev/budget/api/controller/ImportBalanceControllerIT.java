package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.ImportTestFiles;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.Month;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * HTTP contract of the statement balance (KKS-384): the optional body of the
 * confirmation, the new fields of the draft, the confirmation, the detection and
 * the account. Synthetic statements only ({@link ImportTestFiles}).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ImportBalanceControllerIT {

    private static final String BALANCE_DATE = "01/10/2026";
    private static final String BANK_BALANCE = "1842,37 EUR";
    private static final String BAKERY = "16/09/2026;CARTE X1596 14/09 ;CARTE X1596 14/09 BOULANGERIE DU MARCHE 110600000000101IOPD ;-4,30;EUR";
    private static final String SALARY = "20/09/2026;VIR RECU    123456;VIR RECU    1234567890S DE: EMPLOYEUR TEST REF: SALAIRE ;1500,00;EUR";
    private static final String RENT = "21/09/2026;PRELEVEMENT EUROPE;PRELEVEMENT EUROPEEN 3333333333 DE: BAILLEUR TEST ID: FR00ZZZ000002 REF: ref-0202 ;-600,00;EUR";

    @Autowired MockMvc mockMvc;
    @Autowired UserRepository userRepository;
    @Autowired AccountRepository accountRepository;
    @Autowired TransactionRepository transactionRepository;
    @Autowired JwtUtil jwtUtil;

    private User user;
    private Account account;

    @BeforeEach
    void setUp() {
        user = createUser();
        account = createAccount(user);
    }

    // -------------------------------------------------------------------------
    // Draft
    // -------------------------------------------------------------------------

    @Test
    void should_return_the_statement_fields_with_the_draft_on_upload_and_on_read() throws Exception {
        String draftId = uploadAndReadId();

        mockMvc.perform(get("/v1/imports/drafts/" + draftId).header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.statementAccountSuffix").value("1596"))
                .andExpect(jsonPath("$.statementBalance").value(1842.37))
                .andExpect(jsonPath("$.statementBalanceDate").value("2026-10-01"))
                .andExpect(jsonPath("$.projectedBalance").value(895.70))
                .andExpect(jsonPath("$.proposedOpeningBalance").value(946.67));
    }

    // -------------------------------------------------------------------------
    // Confirmation: the body is optional
    // -------------------------------------------------------------------------

    @Test
    void should_confirm_as_before_when_there_is_no_body() throws Exception {
        String draftId = uploadAndReadId();

        mockMvc.perform(post("/v1/imports/drafts/" + draftId + "/confirm").header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.importedCount").value(3))
                .andExpect(jsonPath("$.skippedCount").value(0))
                .andExpect(jsonPath("$.alreadyImportedCount").value(0))
                .andExpect(jsonPath("$.historyId").isNotEmpty())
                .andExpect(jsonPath("$.balanceCheck.bankBalance").value(1842.37))
                .andExpect(jsonPath("$.balanceCheck.balanceDate").value("2026-10-01"))
                .andExpect(jsonPath("$.balanceCheck.computedBalance").value(895.70))
                .andExpect(jsonPath("$.balanceCheck.difference").value(-946.67))
                .andExpect(jsonPath("$.balanceCheck.suspects", hasSize(0)));

        assertThat(openingBalance()).isEqualByComparingTo("0");
    }

    @ParameterizedTest
    @ValueSource(strings = {"{}", "{\"applyOpeningBalance\":false}", "{\"applyOpeningBalance\":null}"})
    void should_leave_the_opening_balance_when_the_body_does_not_ask_for_it(String body) throws Exception {
        String draftId = uploadAndReadId();

        mockMvc.perform(post("/v1/imports/drafts/" + draftId + "/confirm")
                        .header("Authorization", bearer(user))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.importedCount").value(3));

        assertThat(openingBalance()).isEqualByComparingTo("0");
    }

    @Test
    void should_apply_the_opening_balance_when_the_body_asks_for_it() throws Exception {
        String draftId = uploadAndReadId();

        mockMvc.perform(post("/v1/imports/drafts/" + draftId + "/confirm")
                        .header("Authorization", bearer(user))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"applyOpeningBalance\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balanceCheck.computedBalance").value(1842.37))
                .andExpect(jsonPath("$.balanceCheck.difference").value(0.0));

        assertThat(openingBalance()).isEqualByComparingTo("946.67");
        mockMvc.perform(get("/v1/accounts/" + account.getId()).header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.solde").value(1842.37));
    }

    @Test
    void should_confirm_with_an_empty_json_body() throws Exception {
        String draftId = uploadAndReadId();

        mockMvc.perform(post("/v1/imports/drafts/" + draftId + "/confirm")
                        .header("Authorization", bearer(user))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.importedCount").value(3));
    }

    @Test
    void should_list_the_suspects_in_the_confirmation_response() throws Exception {
        // Dated 17/09: the bakery purchase is dated 14/09, so the window of 2 days (KKS-385) does not reach it.
        Transaction duplicate = transactionRepository.save(Transaction.builder()
                .libelle("Pain").montant(new BigDecimal("4.30")).type(TransactionType.DEPENSE)
                .date(LocalDate.of(2026, Month.SEPTEMBER, 17)).account(account).user(user).build());
        String draftId = uploadAndReadId();

        mockMvc.perform(post("/v1/imports/drafts/" + draftId + "/confirm").header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balanceCheck.suspects", hasSize(1)))
                .andExpect(jsonPath("$.balanceCheck.suspects[0].id").value(duplicate.getId().toString()))
                .andExpect(jsonPath("$.balanceCheck.suspects[0].date").value("2026-09-17"))
                .andExpect(jsonPath("$.balanceCheck.suspects[0].libelle").value("Pain"))
                .andExpect(jsonPath("$.balanceCheck.suspects[0].montant").value(4.30))
                .andExpect(jsonPath("$.balanceCheck.suspects[0].type").value("DEPENSE"));
    }

    @Test
    void should_return_a_null_balance_check_when_the_statement_gives_no_balance() throws Exception {
        MockMultipartFile noBalance = new MockMultipartFile("file", "releve.csv", "text/csv",
                ImportTestFiles.sgStatementOf(ImportTestFiles.sgBankHeader("0000000000001596", BALANCE_DATE, "N/A"), BAKERY));
        String draftId = uploadAndReadId(noBalance);

        mockMvc.perform(post("/v1/imports/drafts/" + draftId + "/confirm").header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.importedCount").value(1))
                .andExpect(jsonPath("$.balanceCheck").value(nullValue()));
    }

    // -------------------------------------------------------------------------
    // Detection and account
    // -------------------------------------------------------------------------

    @Test
    void should_suggest_the_account_and_expose_its_suffix_once_the_number_was_imported() throws Exception {
        mockMvc.perform(multipart("/v1/imports/detect").file(statementFile()).header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accountSuffix").value("1596"))
                .andExpect(jsonPath("$.suggestedAccountId").value(nullValue()));
        String draftId = uploadAndReadId();
        mockMvc.perform(post("/v1/imports/drafts/" + draftId + "/confirm").header("Authorization", bearer(user)))
                .andExpect(status().isOk());

        mockMvc.perform(multipart("/v1/imports/detect").file(statementFile()).header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recognized").value(true))
                .andExpect(jsonPath("$.accountSuffix").value("1596"))
                .andExpect(jsonPath("$.suggestedAccountId").value(account.getId().toString()));
        mockMvc.perform(get("/v1/accounts/" + account.getId()).header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.statementAccountSuffix").value("1596"));
    }

    @Test
    void should_not_suggest_the_account_of_another_user() throws Exception {
        String draftId = uploadAndReadId();
        mockMvc.perform(post("/v1/imports/drafts/" + draftId + "/confirm").header("Authorization", bearer(user)))
                .andExpect(status().isOk());
        User otherUser = createUser();

        mockMvc.perform(multipart("/v1/imports/detect").file(statementFile()).header("Authorization", bearer(otherUser)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accountSuffix").value("1596"))
                .andExpect(jsonPath("$.suggestedAccountId").value(nullValue()));
    }

    @Test
    void should_expose_no_suffix_on_an_account_without_import() throws Exception {
        mockMvc.perform(get("/v1/accounts/" + account.getId()).header("Authorization", bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.statementAccountSuffix").value(nullValue()));
    }

    // -------------------------------------------------------------------------

    private String uploadAndReadId() throws Exception {
        return uploadAndReadId(statementFile());
    }

    private String uploadAndReadId(MockMultipartFile file) throws Exception {
        String body = mockMvc.perform(multipart("/v1/imports/upload").file(file)
                        .param("accountId", account.getId().toString())
                        .header("Authorization", bearer(user)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return new ObjectMapper().readTree(body).get("id").asText();
    }

    private BigDecimal openingBalance() {
        return accountRepository.findById(account.getId()).orElseThrow().getSoldeInitial();
    }

    private static MockMultipartFile statementFile() {
        return new MockMultipartFile("file", "releve.csv", "text/csv",
                ImportTestFiles.sgStatementOf(ImportTestFiles.sgBankHeader("0000000000001596", BALANCE_DATE, BANK_BALANCE),
                        BAKERY, SALARY, RENT));
    }

    private String bearer(User forUser) {
        return "Bearer " + jwtUtil.generateToken(forUser.getEmail());
    }

    private User createUser() {
        return userRepository.save(User.builder()
                .email("balance-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Balance")
                .passwordResetRequired(false)
                .build());
    }

    private Account createAccount(User owner) {
        return accountRepository.save(Account.builder()
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
