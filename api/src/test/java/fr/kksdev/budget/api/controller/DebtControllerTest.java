package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.DebtRepayRequest;
import fr.kksdev.budget.api.dto.request.DebtRequest;
import fr.kksdev.budget.api.dto.request.DebtSnoozeRequest;
import fr.kksdev.budget.api.dto.response.DebtPaymentResponse;
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
import java.time.LocalTime;
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
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("100.00"),
                null, null, false, null, null);

        when(debtService.create(any(DebtRequest.class), any(UUID.class))).thenReturn(response);

        mockMvc.perform(post("/debts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(debtJson("Alice", "100.00", "EMPRUNT", "2026-02-01")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.personne").value("Alice"))
                .andExpect(jsonPath("$.rembourse").value(false));
    }

    @Test
    void should_return_200_when_get_all_debts() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("100.00"),
                null, null, false, null, null);

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
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("100.00"),
                null, null, false, null, null);

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
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("100.00"),
                null, null, false, null, null);

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
                DebtType.PRET, LocalDate.of(2026, 2, 5),
                null, "EUR", true, new BigDecimal("100.00"),
                null, null, false, null, null);

        when(debtService.update(eq(debtId), any(DebtRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/debts/{id}", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(debtJson("Bob", "200.00", "PRET", "2026-02-05")))
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

    // --- T017 — US1: Partial/Full Repayment ---

    @Test
    void should_return_200_when_partial_repay() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("50.00"),
                null, null, false, null, null);

        when(debtService.repay(eq(debtId), any(DebtRepayRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(post("/debts/{id}/repay", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"accountId": "%s", "amount": 50.00}
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.montantRestant").value(50.00))
                .andExpect(jsonPath("$.rembourse").value(false));
    }

    @Test
    void should_return_200_when_full_repay() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", true, BigDecimal.ZERO,
                null, null, false, null, null);

        when(debtService.repay(eq(debtId), any(DebtRepayRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(post("/debts/{id}/repay", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"accountId": "%s"}
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rembourse").value(true))
                .andExpect(jsonPath("$.montantRestant").value(0));
    }

    @Test
    void should_return_400_when_repay_exceeds_remaining() throws Exception {
        when(debtService.repay(eq(debtId), any(DebtRepayRequest.class), eq(userId)))
                .thenThrow(new IllegalArgumentException("Le montant dépasse le montant restant"));

        mockMvc.perform(post("/debts/{id}/repay", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"accountId": "%s", "amount": 200.00}
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_debt_already_repaid() throws Exception {
        when(debtService.repay(eq(debtId), any(DebtRepayRequest.class), eq(userId)))
                .thenThrow(new IllegalArgumentException("Cette dette est déjà remboursée"));

        mockMvc.perform(post("/debts/{id}/repay", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"accountId": "%s", "amount": 50.00}
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_200_when_get_payments() throws Exception {
        var payment = new DebtPaymentResponse(
                UUID.randomUUID(), new BigDecimal("50.00"),
                LocalDate.of(2026, 3, 10), "Compte Principal");

        when(debtService.getPayments(debtId, userId)).thenReturn(List.of(payment));

        mockMvc.perform(get("/debts/{id}/payments", debtId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].amount").value(50.00))
                .andExpect(jsonPath("$[0].accountName").value("Compte Principal"));
    }

    @Test
    void should_return_200_when_get_payments_empty() throws Exception {
        when(debtService.getPayments(debtId, userId)).thenReturn(List.of());

        mockMvc.perform(get("/debts/{id}/payments", debtId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    void should_return_404_when_repay_debt_not_found() throws Exception {
        when(debtService.repay(eq(debtId), any(DebtRepayRequest.class), eq(userId)))
                .thenThrow(new EntityNotFoundException("Dette non trouvée"));

        mockMvc.perform(post("/debts/{id}/repay", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"accountId": "%s", "amount": 50.00}
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isNotFound());
    }

    // --- T020 — US2: Account Association ---

    @Test
    void should_return_201_when_create_with_account() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("100.00"),
                null, null, false, null, null);

        when(debtService.create(any(DebtRequest.class), any(UUID.class))).thenReturn(response);

        mockMvc.perform(post("/debts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "personne": "Alice",
                                    "montant": 100.00,
                                    "sens": "EMPRUNT",
                                    "date": "2026-02-01",
                                    "accountId": "%s"
                                }
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.personne").value("Alice"));
    }

    @Test
    void should_return_200_when_update_with_new_account() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("110.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "USD", false, new BigDecimal("110.00"),
                null, null, false, null, null);

        when(debtService.update(eq(debtId), any(DebtRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/debts/{id}", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "personne": "Alice",
                                    "montant": 100.00,
                                    "sens": "EMPRUNT",
                                    "date": "2026-02-01",
                                    "accountId": "%s"
                                }
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currency").value("USD"));
    }

    // --- T031 — US4: Reminder ---

    @Test
    void should_return_200_when_update_with_reminder() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("100.00"),
                null, null, false,
                LocalDate.of(2026, 3, 15), LocalTime.of(14, 0));

        when(debtService.update(eq(debtId), any(DebtRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/debts/{id}", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "personne": "Alice",
                                    "montant": 100.00,
                                    "sens": "EMPRUNT",
                                    "date": "2026-02-01",
                                    "reminderDate": "2026-03-15",
                                    "reminderTime": "14:00"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reminderDate").value("2026-03-15"))
                .andExpect(jsonPath("$.reminderTime").value("14:00:00"));
    }

    @Test
    void should_return_201_when_create_with_reminder() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("100.00"),
                null, null, false,
                LocalDate.of(2026, 3, 15), LocalTime.of(14, 0));

        when(debtService.create(any(DebtRequest.class), any(UUID.class))).thenReturn(response);

        mockMvc.perform(post("/debts")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "personne": "Alice",
                                    "montant": 100.00,
                                    "sens": "EMPRUNT",
                                    "date": "2026-02-01",
                                    "reminderDate": "2026-03-15",
                                    "reminderTime": "14:00"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.reminderDate").value("2026-03-15"));
    }

    // --- T036 — US5: Snooze ---

    @Test
    void should_return_200_when_snooze() throws Exception {
        var response = new DebtResponse(
                debtId, "Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1),
                null, "EUR", false, new BigDecimal("100.00"),
                null, null, false,
                LocalDate.of(2026, 3, 20), LocalTime.of(10, 0));

        when(debtService.snooze(eq(debtId), any(DebtSnoozeRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(post("/debts/{id}/snooze", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reminderDate": "2026-03-20", "reminderTime": "10:00"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reminderDate").value("2026-03-20"));
    }

    @Test
    void should_return_400_when_snooze_no_existing_reminder() throws Exception {
        when(debtService.snooze(eq(debtId), any(DebtSnoozeRequest.class), eq(userId)))
                .thenThrow(new IllegalArgumentException("Cette dette n'a pas de rappel configuré"));

        mockMvc.perform(post("/debts/{id}/snooze", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reminderDate": "2026-03-20", "reminderTime": "10:00"}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_404_when_snooze_debt_not_found() throws Exception {
        when(debtService.snooze(eq(debtId), any(DebtSnoozeRequest.class), eq(userId)))
                .thenThrow(new EntityNotFoundException("Dette non trouvée"));

        mockMvc.perform(post("/debts/{id}/snooze", debtId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reminderDate": "2026-03-20", "reminderTime": "10:00"}
                                """))
                .andExpect(status().isNotFound());
    }
}
