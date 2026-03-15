package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.response.AccountSummary;
import fr.kksdev.budget.api.dto.response.RecurringTransactionResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.RecurringTransactionService;
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
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RecurringTransactionController.class)
@Import(SecurityConfig.class)
class RecurringTransactionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private RecurringTransactionService recurringTransactionService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID recurringId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private RecurringTransactionResponse buildRecurringResponse() {
        var account = new AccountSummary(UUID.randomUUID(), "Compte Principal", "🏦", "#3b82f6", "EUR");
        return new RecurringTransactionResponse(
                recurringId, new BigDecimal("50.00"), "Loyer", TransactionType.DEPENSE,
                Frequency.MENSUEL, LocalDate.of(2026, 3, 15), true, null, account);
    }

    private String recurringRequestJson(String montant, String libelle, String type, String frequency, String nextOccurrence) {
        return """
                {
                    "montant": %s,
                    "libelle": "%s",
                    "type": "%s",
                    "frequency": "%s",
                    "nextOccurrence": "%s"
                }
                """.formatted(montant, libelle, type, frequency, nextOccurrence);
    }

    @Test
    void should_return201_when_createRecurringTransaction() throws Exception {
        var response = buildRecurringResponse();

        when(recurringTransactionService.create(any(), any(UUID.class))).thenReturn(response);

        mockMvc.perform(post("/transactions/recurring")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(recurringRequestJson("50.00", "Loyer", "DEPENSE", "MENSUEL", "2026-03-15")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.libelle").value("Loyer"))
                .andExpect(jsonPath("$.frequency").value("MENSUEL"))
                .andExpect(jsonPath("$.recurringActive").value(true));
    }

    @Test
    void should_return400_when_missingFrequency() throws Exception {
        mockMvc.perform(post("/transactions/recurring")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "montant": 50.00,
                                    "libelle": "Loyer",
                                    "type": "DEPENSE",
                                    "nextOccurrence": "2026-03-15"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return400_when_missingNextOccurrence() throws Exception {
        mockMvc.perform(post("/transactions/recurring")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "montant": 50.00,
                                    "libelle": "Loyer",
                                    "type": "DEPENSE",
                                    "frequency": "MENSUEL"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return200_when_listRecurringTransactions() throws Exception {
        var response = buildRecurringResponse();

        when(recurringTransactionService.listActive(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/transactions/recurring")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].libelle").value("Loyer"))
                .andExpect(jsonPath("$[0].frequency").value("MENSUEL"));
    }

    @Test
    void should_return201_when_validateRecurrence() throws Exception {
        var account = new AccountSummary(UUID.randomUUID(), "Compte Principal", "🏦", "#3b82f6", "EUR");
        var transactionResponse = new TransactionResponse(
                UUID.randomUUID(), new BigDecimal("50.00"), "Loyer", TransactionType.DEPENSE,
                LocalDate.now(), null, null, account, null, null, null, null);

        when(recurringTransactionService.validate(eq(recurringId), any(UUID.class))).thenReturn(transactionResponse);

        mockMvc.perform(post("/transactions/recurring/{id}/validate", recurringId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.libelle").value("Loyer"));
    }

    @Test
    void should_return404_when_validateNonexistentRecurrence() throws Exception {
        when(recurringTransactionService.validate(eq(recurringId), any(UUID.class)))
                .thenThrow(new EntityNotFoundException("Transaction récurrente non trouvée"));

        mockMvc.perform(post("/transactions/recurring/{id}/validate", recurringId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Transaction récurrente non trouvée"));
    }

    @Test
    void should_return401_when_notAuthenticated() throws Exception {
        mockMvc.perform(get("/transactions/recurring"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void should_return200_when_skipRecurrence() throws Exception {
        var response = buildRecurringResponse();

        when(recurringTransactionService.skip(eq(recurringId), any(UUID.class))).thenReturn(response);

        mockMvc.perform(patch("/transactions/recurring/{id}/skip", recurringId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.libelle").value("Loyer"))
                .andExpect(jsonPath("$.recurringActive").value(true));
    }

    @Test
    void should_return400_when_skipInactiveRecurrence() throws Exception {
        when(recurringTransactionService.skip(eq(recurringId), any(UUID.class)))
                .thenThrow(new IllegalStateException("La transaction récurrente est désactivée"));

        mockMvc.perform(patch("/transactions/recurring/{id}/skip", recurringId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("La transaction récurrente est désactivée"));
    }

    @Test
    void should_return200_when_deactivateRecurrence() throws Exception {
        var deactivatedResponse = new RecurringTransactionResponse(
                recurringId, new BigDecimal("50.00"), "Loyer", TransactionType.DEPENSE,
                Frequency.MENSUEL, LocalDate.of(2026, 3, 15), false, null,
                new AccountSummary(UUID.randomUUID(), "Compte Principal", "🏦", "#3b82f6", "EUR"));

        when(recurringTransactionService.deactivate(eq(recurringId), any(UUID.class))).thenReturn(deactivatedResponse);

        mockMvc.perform(patch("/transactions/recurring/{id}/deactivate", recurringId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recurringActive").value(false));
    }

    @Test
    void should_return404_when_deactivateNonexistent() throws Exception {
        when(recurringTransactionService.deactivate(eq(recurringId), any(UUID.class)))
                .thenThrow(new EntityNotFoundException("Transaction récurrente non trouvée"));

        mockMvc.perform(patch("/transactions/recurring/{id}/deactivate", recurringId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Transaction récurrente non trouvée"));
    }
}
