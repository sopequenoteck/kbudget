package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.DebtRequest;
import fr.kksdev.budget.api.dto.response.DebtResponse;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.DebtService;
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

@WebMvcTest(DebtController.class)
@Import(SecurityConfig.class)
class DebtControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private DebtService debtService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID debtId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private String debtJson(String personne, String montant, String sens, String date) {
        return """
                {
                    "personne": "%s",
                    "montant": %s,
                    "sens": "%s",
                    "date": "%s"
                }
                """.formatted(personne, montant, sens, date);
    }

    @Test
    void should_return_201_when_create_debt() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.JE_DOIS, LocalDate.of(2026, 2, 1), false, null);

        when(debtService.create(any(DebtRequest.class), any(UUID.class))).thenReturn(response);

        mockMvc.perform(post("/debts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(debtJson("Alice", "100.00", "JE_DOIS", "2026-02-01")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.personne").value("Alice"))
                .andExpect(jsonPath("$.rembourse").value(false));
    }

    @Test
    void should_return_200_when_get_all_debts() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.JE_DOIS, LocalDate.of(2026, 2, 1), false, null);

        when(debtService.getAllByUser(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/debts")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].personne").value("Alice"));
    }

    @Test
    void should_return_200_when_get_unpaid_debts() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.JE_DOIS, LocalDate.of(2026, 2, 1), false, null);

        when(debtService.getUnpaidByUser(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/debts")
                        .param("rembourse", "false")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].rembourse").value(false));
    }

    @Test
    void should_return_200_when_get_debt_by_id() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.JE_DOIS, LocalDate.of(2026, 2, 1), false, null);

        when(debtService.getById(debtId, userId)).thenReturn(response);

        mockMvc.perform(get("/debts/{id}", debtId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.personne").value("Alice"));
    }

    @Test
    void should_return_200_when_update_debt() throws Exception {
        var response = new DebtResponse(
                debtId, "Bob", new BigDecimal("200.00"),
                DebtType.ON_ME_DOIT, LocalDate.of(2026, 2, 5), true, null);

        when(debtService.update(eq(debtId), any(DebtRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/debts/{id}", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(debtJson("Bob", "200.00", "ON_ME_DOIT", "2026-02-05")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.personne").value("Bob"));
    }

    @Test
    void should_return_204_when_delete_debt() throws Exception {
        doNothing().when(debtService).delete(debtId, userId);

        mockMvc.perform(delete("/debts/{id}", debtId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_404_when_debt_not_found() throws Exception {
        when(debtService.getById(debtId, userId))
                .thenThrow(new EntityNotFoundException("Dette non trouvée"));

        mockMvc.perform(get("/debts/{id}", debtId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Dette non trouvée"));
    }

    @Test
    void should_return_400_when_create_with_missing_fields() throws Exception {
        mockMvc.perform(post("/debts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }
}
