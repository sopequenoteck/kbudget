package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.MonthlySummaryResponse;
import fr.kksdev.budget.api.dto.TransactionRequest;
import fr.kksdev.budget.api.dto.TransactionResponse;
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
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
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

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID transactionId = UUID.randomUUID();
    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private String transactionJson(String montant, String libelle, String type, String date, String categorie) {
        return """
                {
                    "montant": %s,
                    "libelle": "%s",
                    "type": "%s",
                    "date": "%s",
                    "categorie": "%s"
                }
                """.formatted(montant, libelle, type, date, categorie);
    }

    @Test
    void should_return_201_when_create_transaction() throws Exception {
        var response = new TransactionResponse(
                transactionId, new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), "Alimentation", null);

        when(transactionService.create(any(TransactionRequest.class), any(User.class))).thenReturn(response);

        mockMvc.perform(post("/transactions")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(transactionJson("50.00", "Courses", "DEPENSE", "2026-02-07", "Alimentation")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(transactionId.toString()))
                .andExpect(jsonPath("$.libelle").value("Courses"))
                .andExpect(jsonPath("$.montant").value(50.00));
    }

    @Test
    void should_return_200_when_get_all_transactions() throws Exception {
        var response = new TransactionResponse(
                transactionId, new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), "Alimentation", null);

        when(transactionService.getAllByUser(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/transactions")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].libelle").value("Courses"));
    }

    @Test
    void should_return_200_when_get_transaction_by_id() throws Exception {
        var response = new TransactionResponse(
                transactionId, new BigDecimal("50.00"), "Courses", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 7), "Alimentation", null);

        when(transactionService.getById(transactionId, userId)).thenReturn(response);

        mockMvc.perform(get("/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.libelle").value("Courses"));
    }

    @Test
    void should_return_200_when_update_transaction() throws Exception {
        var response = new TransactionResponse(
                transactionId, new BigDecimal("75.00"), "Courses modifiées", TransactionType.DEPENSE,
                LocalDate.of(2026, 2, 8), "Alimentation", null);

        when(transactionService.update(eq(transactionId), any(TransactionRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(transactionJson("75.00", "Courses modifiées", "DEPENSE", "2026-02-08", "Alimentation")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.montant").value(75.00));
    }

    @Test
    void should_return_204_when_delete_transaction() throws Exception {
        doNothing().when(transactionService).delete(transactionId, userId);

        mockMvc.perform(delete("/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_404_when_transaction_not_found() throws Exception {
        when(transactionService.getById(transactionId, userId))
                .thenThrow(new EntityNotFoundException("Transaction non trouvée"));

        mockMvc.perform(get("/transactions/{id}", transactionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Transaction non trouvée"));
    }

    @Test
    void should_return_200_when_get_monthly_summary() throws Exception {
        var summary = new MonthlySummaryResponse(2, 2026,
                new BigDecimal("2000.00"), new BigDecimal("50.00"), new BigDecimal("1950.00"));

        when(transactionService.getMonthlySummary(2, 2026, userId)).thenReturn(summary);

        mockMvc.perform(get("/transactions/summary")
                        .param("month", "2")
                        .param("year", "2026")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.month").value(2))
                .andExpect(jsonPath("$.year").value(2026))
                .andExpect(jsonPath("$.totalRecettes").value(2000.00))
                .andExpect(jsonPath("$.totalDepenses").value(50.00))
                .andExpect(jsonPath("$.solde").value(1950.00));
    }

    @Test
    void should_return_400_when_create_with_missing_fields() throws Exception {
        mockMvc.perform(post("/transactions")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_403_when_no_token() throws Exception {
        mockMvc.perform(get("/transactions"))
                .andExpect(status().isForbidden());
    }
}
