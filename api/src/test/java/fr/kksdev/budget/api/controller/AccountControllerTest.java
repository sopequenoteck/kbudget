package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.AccountRequest;
import fr.kksdev.budget.api.dto.response.AccountResponse;
import fr.kksdev.budget.api.dto.response.CurrencyBalance;
import fr.kksdev.budget.api.dto.response.TotalBalanceResponse;
import fr.kksdev.budget.api.dto.response.TransferResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.AccountService;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import java.time.LocalDate;

import static org.hamcrest.Matchers.nullValue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AccountController.class)
@Import(SecurityConfig.class)
class AccountControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AccountService accountService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private AccountResponse buildAccountResponse() {
        return new AccountResponse(
                accountId, "Compte Principal", AccountType.COURANT,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🏦", "#3b82f6", true, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);
    }

    @Test
    void should_listActiveAccounts_when_authenticated() throws Exception {
        when(accountService.getAccounts(userId, false)).thenReturn(List.of(buildAccountResponse()));

        mockMvc.perform(get("/accounts")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nom").value("Compte Principal"))
                .andExpect(jsonPath("$[0].isDefault").value(true));
    }

    @Test
    void should_createAccount_when_validRequest() throws Exception {
        var response = new AccountResponse(
                UUID.randomUUID(), "Livret A", AccountType.EPARGNE,
                new BigDecimal("5000.00"), new BigDecimal("5000.00"),
                "🐷", "#22c55e", false, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.createAccount(any(AccountRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/accounts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Livret A",
                                    "type": "EPARGNE",
                                    "soldeInitial": 5000.00
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.nom").value("Livret A"))
                .andExpect(jsonPath("$.type").value("EPARGNE"))
                .andExpect(jsonPath("$.solde").value(5000.00));
    }

    @Test
    void should_return400_when_duplicateName() throws Exception {
        when(accountService.createAccount(any(AccountRequest.class), eq(userId)))
                .thenThrow(new IllegalArgumentException("Un compte avec ce nom existe déjà"));

        mockMvc.perform(post("/accounts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Compte Principal",
                                    "type": "COURANT"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Un compte avec ce nom existe déjà"));
    }

    @Test
    void should_updateAccount_when_exists() throws Exception {
        var response = new AccountResponse(
                accountId, "Nouveau Nom", AccountType.COURANT,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🏦", "#3b82f6", true, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.updateAccount(eq(accountId), any(AccountRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/accounts/{id}", accountId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Nouveau Nom",
                                    "type": "COURANT"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nom").value("Nouveau Nom"));
    }

    @Test
    void should_deleteAccount_when_noDataAttached() throws Exception {
        doNothing().when(accountService).deleteAccount(accountId, userId);

        mockMvc.perform(delete("/accounts/{id}", accountId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return400_when_deleteWithTransactions() throws Exception {
        doThrow(new IllegalArgumentException("Impossible de supprimer un compte avec des transactions rattachées"))
                .when(accountService).deleteAccount(accountId, userId);

        mockMvc.perform(delete("/accounts/{id}", accountId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Impossible de supprimer un compte avec des transactions rattachées"));
    }

    @Test
    void should_setDefault_when_accountExists() throws Exception {
        var response = new AccountResponse(
                accountId, "Livret A", AccountType.EPARGNE,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🐷", "#22c55e", true, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.setDefault(accountId, userId)).thenReturn(response);

        mockMvc.perform(put("/accounts/{id}/default", accountId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isDefault").value(true));
    }

    @Test
    void should_return404_when_accountNotFound() throws Exception {
        when(accountService.getAccountById(accountId, userId))
                .thenThrow(new EntityNotFoundException("Compte non trouvé"));

        mockMvc.perform(get("/accounts/{id}", accountId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Compte non trouvé"));
    }

    @Test
    void should_return401_when_notAuthenticated() throws Exception {
        mockMvc.perform(get("/accounts"))
                .andExpect(status().isUnauthorized());
    }

    // --- Transfer tests (T030) ---

    @Test
    void should_createTransfer_when_validRequest() throws Exception {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        UUID transferId = UUID.randomUUID();

        var response = new TransferResponse(
                transferId,
                new TransferResponse.TransactionResponseRef(
                        UUID.randomUUID(), new BigDecimal("100.00"), "Virement vers Livret A",
                        TransactionType.DEPENSE, LocalDate.now(), fromId, "Compte Principal"),
                new TransferResponse.TransactionResponseRef(
                        UUID.randomUUID(), new BigDecimal("100.00"), "Virement depuis Compte Principal",
                        TransactionType.RECETTE, LocalDate.now(), toId, "Livret A"));

        when(accountService.transfer(any(), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/accounts/transfer")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "fromAccountId": "%s",
                                    "toAccountId": "%s",
                                    "montant": 100.00
                                }
                                """.formatted(fromId, toId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.transferId").value(transferId.toString()))
                .andExpect(jsonPath("$.debitTransaction.type").value("DEPENSE"))
                .andExpect(jsonPath("$.creditTransaction.type").value("RECETTE"))
                .andExpect(jsonPath("$.debitTransaction.montant").value(100.00))
                .andExpect(jsonPath("$.creditTransaction.montant").value(100.00));
    }

    @Test
    void should_return400_when_transferSameAccount() throws Exception {
        UUID sameId = UUID.randomUUID();

        when(accountService.transfer(any(), eq(userId)))
                .thenThrow(new IllegalArgumentException("Les comptes source et destination doivent être différents"));

        mockMvc.perform(post("/accounts/transfer")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "fromAccountId": "%s",
                                    "toAccountId": "%s",
                                    "montant": 50.00
                                }
                                """.formatted(sameId, sameId)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Les comptes source et destination doivent être différents"));
    }

    @Test
    void should_return400_when_transferInactiveAccount() throws Exception {
        when(accountService.transfer(any(), eq(userId)))
                .thenThrow(new IllegalArgumentException("Le compte source est inactif"));

        mockMvc.perform(post("/accounts/transfer")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "fromAccountId": "%s",
                                    "toAccountId": "%s",
                                    "montant": 50.00
                                }
                                """.formatted(UUID.randomUUID(), UUID.randomUUID())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Le compte source est inactif"));
    }

    // --- Adjust Balance tests (T032) ---

    @Test
    void should_adjustBalance_when_newBalanceHigher() throws Exception {
        var response = new AccountResponse(
                accountId, "Compte Principal", AccountType.COURANT,
                BigDecimal.ZERO, new BigDecimal("750.00"),
                "🏦", "#3b82f6", true, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.adjustBalance(eq(accountId), eq(new BigDecimal("750.00")), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(post("/accounts/{id}/adjust-balance", accountId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "newBalance": 750.00 }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.solde").value(750.00));
    }

    @Test
    void should_adjustBalance_when_newBalanceLower() throws Exception {
        var response = new AccountResponse(
                accountId, "Compte Principal", AccountType.COURANT,
                new BigDecimal("500.00"), new BigDecimal("300.00"),
                "🏦", "#3b82f6", true, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.adjustBalance(eq(accountId), eq(new BigDecimal("300.00")), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(post("/accounts/{id}/adjust-balance", accountId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "newBalance": 300.00 }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.solde").value(300.00));
    }

    @Test
    void should_notCreateTransaction_when_sameBalance() throws Exception {
        var response = new AccountResponse(
                accountId, "Compte Principal", AccountType.COURANT,
                new BigDecimal("500.00"), new BigDecimal("500.00"),
                "🏦", "#3b82f6", true, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.adjustBalance(eq(accountId), eq(new BigDecimal("500.00")), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(post("/accounts/{id}/adjust-balance", accountId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "newBalance": 500.00 }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.solde").value(500.00));
    }

    @Test
    void should_rejectAdjustment_when_accountInactive() throws Exception {
        when(accountService.adjustBalance(eq(accountId), any(BigDecimal.class), eq(userId)))
                .thenThrow(new IllegalArgumentException("Impossible d'ajuster le solde d'un compte inactif"));

        mockMvc.perform(post("/accounts/{id}/adjust-balance", accountId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "newBalance": 750.00 }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Impossible d'ajuster le solde d'un compte inactif"));
    }

    @Test
    void should_rejectAdjustment_when_accountNotFound() throws Exception {
        when(accountService.adjustBalance(eq(accountId), any(BigDecimal.class), eq(userId)))
                .thenThrow(new EntityNotFoundException("Compte non trouvé"));

        mockMvc.perform(post("/accounts/{id}/adjust-balance", accountId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "newBalance": 750.00 }
                                """))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Compte non trouvé"));
    }

    @Test
    void should_acceptNegativeBalance() throws Exception {
        var response = new AccountResponse(
                accountId, "Compte Principal", AccountType.COURANT,
                BigDecimal.ZERO, new BigDecimal("-100.00"),
                "🏦", "#3b82f6", true, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.adjustBalance(eq(accountId), eq(new BigDecimal("-100.00")), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(post("/accounts/{id}/adjust-balance", accountId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "newBalance": -100.00 }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.solde").value(-100.00));
    }

    // --- T027 — Total Balance ---

    @Test
    void should_return_200_when_get_total_balance() throws Exception {
        var response = new TotalBalanceResponse(List.of(
                new CurrencyBalance(Currency.EUR, new BigDecimal("1500.00"))));

        when(accountService.getTotalBalance(userId)).thenReturn(response);

        mockMvc.perform(get("/accounts/total-balance")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balances[0].currency").value("EUR"))
                .andExpect(jsonPath("$.balances[0].amount").value(1500.00));
    }

    @Test
    void should_return_200_when_get_total_balance_multi_currency() throws Exception {
        var response = new TotalBalanceResponse(List.of(
                new CurrencyBalance(Currency.EUR, new BigDecimal("1500.00")),
                new CurrencyBalance(Currency.USD, new BigDecimal("500.00"))));

        when(accountService.getTotalBalance(userId)).thenReturn(response);

        mockMvc.perform(get("/accounts/total-balance")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balances").isArray())
                .andExpect(jsonPath("$.balances.length()").value(2));
    }

    // --- Bank info tests (T012) ---

    @Test
    void should_createAccountWithBankCode_when_validBankCode() throws Exception {
        var response = new AccountResponse(
                UUID.randomUUID(), "Compte SG", AccountType.COURANT,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🏦", "#e2001a", false, true, "EUR",
                "SG", "Société Générale", "FR", "#e2001a", "/api/bank-logos/sg.svg", null, null);

        when(accountService.createAccount(any(AccountRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/accounts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Compte SG",
                                    "type": "COURANT",
                                    "bankCode": "SG"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bankCode").value("SG"))
                .andExpect(jsonPath("$.bankName").value("Société Générale"));
    }

    @Test
    void should_createAccountWithDefaultBank_when_noBankCode() throws Exception {
        var response = new AccountResponse(
                UUID.randomUUID(), "Compte Sans Banque", AccountType.COURANT,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🏦", "#3b82f6", false, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.createAccount(any(AccountRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/accounts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Compte Sans Banque",
                                    "type": "COURANT"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bankCode").value("OTHER"));
    }

    @Test
    void should_return400_when_invalidBankCode() throws Exception {
        when(accountService.createAccount(any(AccountRequest.class), eq(userId)))
                .thenThrow(new IllegalArgumentException("Invalid bank code: INEXISTANT"));

        mockMvc.perform(post("/accounts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Compte Invalide",
                                    "type": "COURANT",
                                    "bankCode": "INEXISTANT"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Invalid bank code: INEXISTANT"));
    }

    @Test
    void should_returnBankInfo_when_getAccount() throws Exception {
        var response = new AccountResponse(
                accountId, "Compte BNP", AccountType.COURANT,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🏦", "#00915a", true, true, "EUR",
                "BNP", "BNP Paribas", "FR", "#00915a", "/api/bank-logos/bnp.svg", null, null);

        when(accountService.getAccountById(accountId, userId)).thenReturn(response);

        mockMvc.perform(get("/accounts/{id}", accountId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bankCode").value("BNP"))
                .andExpect(jsonPath("$.bankName").value("BNP Paribas"))
                .andExpect(jsonPath("$.bankCountry").value("FR"))
                .andExpect(jsonPath("$.bankBrandColor").value("#00915a"))
                .andExpect(jsonPath("$.bankLogoUrl").value("/api/bank-logos/bnp.svg"));
    }

    // --- US3: Custom bank (OTHER) tests (T019) ---

    @Test
    void should_createAccountWithOtherAndCustomName_when_otherBankCode() throws Exception {
        var response = new AccountResponse(
                UUID.randomUUID(), "Ma Banque Perso", AccountType.COURANT,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🏦", "#6b7280", false, true, "EUR",
                "OTHER", "Ma Banque", null, "#6b7280", "/api/bank-logos/other.svg",
                "Ma Banque", null);

        when(accountService.createAccount(any(AccountRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/accounts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Ma Banque Perso",
                                    "type": "COURANT",
                                    "bankCode": "OTHER",
                                    "bankCustomName": "Ma Banque"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bankCode").value("OTHER"))
                .andExpect(jsonPath("$.bankCustomName").value("Ma Banque"));
    }

    @Test
    void should_createAccountWithOtherAndCustomLogo_when_otherBankCode() throws Exception {
        var response = new AccountResponse(
                UUID.randomUUID(), "Ma Banque Logo", AccountType.COURANT,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🏦", "#6b7280", false, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg",
                null, "data:image/png;base64,abc");

        when(accountService.createAccount(any(AccountRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/accounts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Ma Banque Logo",
                                    "type": "COURANT",
                                    "bankCode": "OTHER",
                                    "bankCustomLogo": "data:image/png;base64,abc"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bankCode").value("OTHER"))
                .andExpect(jsonPath("$.bankCustomLogo").value("data:image/png;base64,abc"));
    }

    @Test
    void should_ignoreCustomFieldsForKnownBank_when_bankCodeIsKnown() throws Exception {
        var response = new AccountResponse(
                UUID.randomUUID(), "Compte SG Custom", AccountType.COURANT,
                BigDecimal.ZERO, BigDecimal.ZERO,
                "🏦", "#e2001a", false, true, "EUR",
                "SG", "Société Générale", "FR", "#e2001a", "/api/bank-logos/sg.svg", null, null);

        when(accountService.createAccount(any(AccountRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/accounts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "Compte SG Custom",
                                    "type": "COURANT",
                                    "bankCode": "SG",
                                    "bankCustomName": "ignored"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bankCode").value("SG"))
                .andExpect(jsonPath("$.bankCustomName").value(nullValue()));
    }

    // --- US4: Retrocompatibility tests (T022) ---

    @Test
    void should_returnDefaultOtherBank_when_existingAccountHasNoBankCode() throws Exception {
        var response = new AccountResponse(
                accountId, "Ancien Compte", AccountType.COURANT,
                new BigDecimal("200.00"), new BigDecimal("200.00"),
                "💰", "#22c55e", false, true, "EUR",
                "OTHER", "Autre", null, "#6b7280", "/api/bank-logos/other.svg", null, null);

        when(accountService.getAccountById(accountId, userId)).thenReturn(response);

        mockMvc.perform(get("/accounts/{id}", accountId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bankCode").value("OTHER"))
                .andExpect(jsonPath("$.icone").value("💰"))
                .andExpect(jsonPath("$.couleur").value("#22c55e"));
    }
}
