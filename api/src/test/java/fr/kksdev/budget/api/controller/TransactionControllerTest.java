package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.TransactionRequest;
import fr.kksdev.budget.api.dto.response.AccountSummary;
import fr.kksdev.budget.api.dto.response.MonthlySummaryResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.TransactionService;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TransactionController.class)
@Import(SecurityConfig.class)
class TransactionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private TransactionService transactionService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID transactionId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();
    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private AccountSummary buildAccountSummary() {
        return new AccountSummary(accountId, "Compte Principal", "🏦", "#3b82f6", "EUR", null, null);
    }

    private String transactionJson(String montant, String libelle, String type, String date) {
        return """
                {
                    "montant": %s,
                    "libelle": "%s",
                    "type": "%s",
                    "date": "%s"
                }
                """.formatted(montant, libelle, type, date);
    }

    @Test
    void should_return_201_when_create_transaction() throws Exception {
        var response = new TransactionResponse(
                transactionId, new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), null, null, buildAccountSummary(), null, null);

        when(transactionService.create(any(TransactionRequest.class), any(UUID.class))).thenReturn(response);

        mockMvc.perform(post("/v1/transactions")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(transactionJson("50.00", "Courses", "DEPENSE", "2026-02-07")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(transactionId.toString()))
                .andExpect(jsonPath("$.libelle").value("Courses"))
                .andExpect(jsonPath("$.montant").value(50.00))
                .andExpect(jsonPath("$.account.nom").value("Compte Principal"));
    }

    @Test
    void should_return_200_when_get_all_transactions() throws Exception {
        var response = new TransactionResponse(
                transactionId, new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), null, null, buildAccountSummary(), null, null);

        when(transactionService.getAllByUser(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/v1/transactions")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].libelle").value("Courses"))
                .andExpect(jsonPath("$[0].account.nom").value("Compte Principal"));
    }

    @Test
    void should_return_200_when_get_transaction_by_id() throws Exception {
        var response = new TransactionResponse(
                transactionId, new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), null, null, buildAccountSummary(), null, null);

        when(transactionService.getById(transactionId, userId)).thenReturn(response);

        mockMvc.perform(get("/v1/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.libelle").value("Courses"));
    }

    @Test
    void should_return_200_when_update_transaction() throws Exception {
        var response = new TransactionResponse(
                transactionId, new BigDecimal("75.00"), "Courses modifiées", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 8), null, null, buildAccountSummary(), null, null);

        when(transactionService.update(eq(transactionId), any(TransactionRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/v1/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(transactionJson("75.00", "Courses modifiées", "DEPENSE", "2026-02-08")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.montant").value(75.00));
    }

    @Test
    void should_return_204_when_delete_transaction() throws Exception {
        doNothing().when(transactionService).delete(transactionId, userId);

        mockMvc.perform(delete("/v1/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_404_when_transaction_not_found() throws Exception {
        when(transactionService.getById(transactionId, userId))
                .thenThrow(new EntityNotFoundException("Transaction non trouvée"));

        mockMvc.perform(get("/v1/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Transaction non trouvée"));
    }

    @Test
    void should_return_200_when_get_monthly_summary() throws Exception {
        var summary = new MonthlySummaryResponse(2, 2026,
                new BigDecimal("2000.00"), new BigDecimal("50.00"), new BigDecimal("1950.00"), "EUR");

        when(transactionService.getMonthlySummary(2, 2026, userId)).thenReturn(List.of(summary));

        mockMvc.perform(get("/v1/transactions/summary")
                        .param("month", "2")
                        .param("year", "2026")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].month").value(2))
                .andExpect(jsonPath("$[0].year").value(2026))
                .andExpect(jsonPath("$[0].totalRecettes").value(2000.00))
                .andExpect(jsonPath("$[0].totalDepenses").value(50.00))
                .andExpect(jsonPath("$[0].solde").value(1950.00))
                .andExpect(jsonPath("$[0].currency").value("EUR"));
    }

    @Test
    void should_return_400_when_create_with_missing_fields() throws Exception {
        mockMvc.perform(post("/v1/transactions")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_401_when_no_token() throws Exception {
        mockMvc.perform(get("/v1/transactions"))
                .andExpect(status().isUnauthorized());
    }

    // --- Immutability & creation guard tests (T032) ---

    @Test
    void should_return403_when_updatingAdjustmentTransaction() throws Exception {
        when(transactionService.update(eq(transactionId), any(TransactionRequest.class), eq(userId)))
                .thenThrow(new AccessDeniedException("Les transactions d'ajustement ne peuvent pas être modifiées"));

        mockMvc.perform(put("/v1/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(transactionJson("100.00", "Test", "DEPENSE", "2026-02-19")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Les transactions d'ajustement ne peuvent pas être modifiées"));
    }

    @Test
    void should_return403_when_deletingAdjustmentTransaction() throws Exception {
        doThrow(new AccessDeniedException("Les transactions d'ajustement ne peuvent pas être supprimées"))
                .when(transactionService).delete(transactionId, userId);

        mockMvc.perform(delete("/v1/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Les transactions d'ajustement ne peuvent pas être supprimées"));
    }

    @Test
    void should_return400_when_creatingAdjustmentDirectly() throws Exception {
        when(transactionService.create(any(TransactionRequest.class), eq(userId)))
                .thenThrow(new IllegalArgumentException("Les transactions d'ajustement ne peuvent être créées que via l'endpoint adjust-balance"));

        mockMvc.perform(post("/v1/transactions")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(transactionJson("250.00", "Ajustement", "AJUSTEMENT", "2026-02-19")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Les transactions d'ajustement ne peuvent être créées que via l'endpoint adjust-balance"));
    }

    // --- T-020 [US5] : 401 sans JWT ---

    @Test
    void should_return_401_when_unauthenticated() throws Exception {
        mockMvc.perform(get("/v1/transactions/libelles"))
                .andExpect(status().isUnauthorized());
    }

    // --- T-021 [US5] : isolation des libellés par user ---

    @Test
    void should_isolate_libelles_by_user() throws Exception {
        UUID userAId = UUID.randomUUID();
        UUID userBId = UUID.randomUUID();
        User userA = User.builder().id(userAId).email("usera@test.com").name("User A").build();
        User userB = User.builder().id(userBId).email("userb@test.com").name("User B").build();

        // userA se connecte avec son propre token
        when(jwtUtil.isTokenValid("token-user-a")).thenReturn(true);
        when(jwtUtil.extractEmail("token-user-a")).thenReturn("usera@test.com");
        when(userRepository.findByEmailAndDisabledAtIsNull("usera@test.com")).thenReturn(Optional.of(userA));

        // Les libellés de userA
        List<String> libellesUserA = List.of("Salaire A", "Loyer A");
        when(transactionService.getLibelleSuggestions(eq(userAId), any(), any()))
                .thenReturn(libellesUserA);

        // Les libellés de userB (ne doivent pas apparaître pour userA)
        List<String> libellesUserB = List.of("Salaire B", "Loyer B");
        when(transactionService.getLibelleSuggestions(eq(userBId), any(), any()))
                .thenReturn(libellesUserB);

        // Appel en tant que userA → doit retourner uniquement les libellés de A
        mockMvc.perform(get("/v1/transactions/libelles")
                        .header("Authorization", "Bearer token-user-a"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0]").value("Salaire A"))
                .andExpect(jsonPath("$[1]").value("Loyer A"))
                // Assertions croisées : aucun libellé de userB ne doit apparaître
                .andExpect(jsonPath("$[?(@=='Salaire B')]").isEmpty())
                .andExpect(jsonPath("$[?(@=='Loyer B')]").isEmpty());
    }
}
