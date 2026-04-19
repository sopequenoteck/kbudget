package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.response.BudgetHistoryItemResponse;
import fr.kksdev.budget.api.dto.response.BudgetHistoryResponse;
import fr.kksdev.budget.api.dto.response.BudgetOverviewItemResponse;
import fr.kksdev.budget.api.dto.response.BudgetOverviewResponse;
import fr.kksdev.budget.api.dto.response.BudgetResponse;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.BudgetService;
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
import java.time.LocalDateTime;
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

@WebMvcTest(BudgetController.class)
@Import(SecurityConfig.class)
class BudgetControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private BudgetService budgetService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID budgetId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private String budgetJson(String categoryId, String montant, String frequence,
                              String currency, String seuilNotification, String actif) {
        StringBuilder json = new StringBuilder("{");
        if (categoryId != null) json.append("\"categoryId\": \"").append(categoryId).append("\", ");
        if (montant != null) json.append("\"montant\": ").append(montant).append(", ");
        if (frequence != null) json.append("\"frequence\": \"").append(frequence).append("\", ");
        if (currency != null) json.append("\"currency\": \"").append(currency).append("\", ");
        if (seuilNotification != null) json.append("\"seuilNotification\": ").append(seuilNotification).append(", ");
        if (actif != null) json.append("\"actif\": ").append(actif).append(", ");
        // Remove trailing comma+space if present
        String result = json.toString();
        if (result.endsWith(", ")) result = result.substring(0, result.length() - 2);
        return result + "}";
    }

    private BudgetResponse buildBudgetResponse() {
        var category = new CategoryResponse(categoryId, "Alimentation", "\uD83C\uDF54", "#FF5733", false);
        return new BudgetResponse(
                budgetId,
                new BigDecimal("500.00"),
                "EUR",
                "MENSUEL",
                80,
                true,
                category,
                new BigDecimal("200.00"),
                LocalDateTime.of(2026, 3, 1, 10, 0)
        );
    }

    // --- US1 CRUD tests ---

    @Test
    void should_create_budget_return_201() throws Exception {
        when(budgetService.create(any(), any(UUID.class))).thenReturn(buildBudgetResponse());

        mockMvc.perform(post("/budgets")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "500.00", "MENSUEL", "EUR", "80", "true")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(budgetId.toString()))
                .andExpect(jsonPath("$.montant").value(500.00))
                .andExpect(jsonPath("$.currency").value("EUR"))
                .andExpect(jsonPath("$.frequence").value("MENSUEL"))
                .andExpect(jsonPath("$.actif").value(true));
    }

    @Test
    void should_return_409_when_duplicate_category() throws Exception {
        when(budgetService.create(any(), any(UUID.class)))
                .thenThrow(new ConflictException("Un budget existe déjà pour cette catégorie"));

        mockMvc.perform(post("/budgets")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "500.00", "MENSUEL", "EUR", "80", "true")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Un budget existe déjà pour cette catégorie"));
    }

    @Test
    void should_list_budgets_with_spent() throws Exception {
        when(budgetService.getAll(eq(userId), eq(false))).thenReturn(List.of(buildBudgetResponse()));

        mockMvc.perform(get("/budgets")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(budgetId.toString()))
                .andExpect(jsonPath("$[0].spent").value(200.00))
                .andExpect(jsonPath("$[0].category.nom").value("Alimentation"));
    }

    @Test
    void should_get_budget_by_id() throws Exception {
        when(budgetService.getById(eq(budgetId), eq(userId))).thenReturn(buildBudgetResponse());

        mockMvc.perform(get("/budgets/{id}", budgetId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(budgetId.toString()))
                .andExpect(jsonPath("$.montant").value(500.00));
    }

    @Test
    void should_update_budget() throws Exception {
        var updated = new BudgetResponse(
                budgetId,
                new BigDecimal("600.00"),
                "EUR",
                "MENSUEL",
                70,
                true,
                new CategoryResponse(categoryId, "Alimentation", "\uD83C\uDF54", "#FF5733", false),
                new BigDecimal("200.00"),
                LocalDateTime.of(2026, 3, 2, 10, 0)
        );
        when(budgetService.update(eq(budgetId), any(), eq(userId))).thenReturn(updated);

        mockMvc.perform(put("/budgets/{id}", budgetId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "600.00", "MENSUEL", "EUR", "70", "true")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.montant").value(600.00))
                .andExpect(jsonPath("$.seuilNotification").value(70));
    }

    @Test
    void should_delete_budget_return_204() throws Exception {
        doNothing().when(budgetService).delete(eq(budgetId), eq(userId));

        mockMvc.perform(delete("/budgets/{id}", budgetId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_404_when_not_found() throws Exception {
        when(budgetService.getById(eq(budgetId), eq(userId)))
                .thenThrow(new EntityNotFoundException("Budget non trouvé"));

        mockMvc.perform(get("/budgets/{id}", budgetId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Budget non trouvé"));
    }

    @Test
    void should_validate_positive_montant() throws Exception {
        mockMvc.perform(post("/budgets")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "0", "MENSUEL", "EUR", "80", "true")))
                .andExpect(status().isBadRequest());

        mockMvc.perform(post("/budgets")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "-10.00", "MENSUEL", "EUR", "80", "true")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_validate_seuil_range() throws Exception {
        mockMvc.perform(post("/budgets")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "500.00", "MENSUEL", "EUR", "101", "true")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_accept_seuil_0_and_100() throws Exception {
        when(budgetService.create(any(), any(UUID.class))).thenReturn(buildBudgetResponse());

        mockMvc.perform(post("/budgets")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "500.00", "MENSUEL", "EUR", "0", "true")))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/budgets")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "500.00", "MENSUEL", "EUR", "100", "true")))
                .andExpect(status().isCreated());
    }

    @Test
    void should_return_403_when_feature_disabled() throws Exception {
        when(budgetService.create(any(), any(UUID.class)))
                .thenThrow(new FeatureDisabledException("Budgets"));

        mockMvc.perform(post("/budgets")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(budgetJson(categoryId.toString(), "500.00", "MENSUEL", "EUR", "80", "true")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Fonctionnalité Budgets désactivée"));
    }

    // --- US2 Overview tests ---

    @Test
    void should_return_overview_with_totals() throws Exception {
        var item = new BudgetOverviewItemResponse(
                budgetId, categoryId, "Alimentation", "\uD83C\uDF54", "#FF5733",
                new BigDecimal("500.00"), new BigDecimal("500.00"), "EUR",
                new BigDecimal("200.00"), new BigDecimal("40.00"), "MENSUEL"
        );
        var overview = new BudgetOverviewResponse(
                "2026-03",
                new BigDecimal("500.00"),
                new BigDecimal("200.00"),
                new BigDecimal("40.00"),
                "EUR",
                List.of(item),
                List.of(),
                BigDecimal.ZERO
        );
        when(budgetService.getOverview(eq(userId))).thenReturn(overview);

        mockMvc.perform(get("/budgets/overview")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.month").value("2026-03"))
                .andExpect(jsonPath("$.totalBudget").value(500.00))
                .andExpect(jsonPath("$.totalSpent").value(200.00))
                .andExpect(jsonPath("$.percentage").value(40.00))
                .andExpect(jsonPath("$.currency").value("EUR"))
                .andExpect(jsonPath("$.items[0].categoryNom").value("Alimentation"));
    }

    @Test
    void should_return_overview_with_normalized_amounts() throws Exception {
        var item = new BudgetOverviewItemResponse(
                budgetId, categoryId, "Abonnements", "\uD83D\uDCFA", "#6366f1",
                new BigDecimal("1200.00"), new BigDecimal("100.00"), "EUR",
                new BigDecimal("45.00"), new BigDecimal("45.00"), "ANNUEL"
        );
        var overview = new BudgetOverviewResponse(
                "2026-03",
                new BigDecimal("100.00"),
                new BigDecimal("45.00"),
                new BigDecimal("45.00"),
                "EUR",
                List.of(item),
                List.of(),
                BigDecimal.ZERO
        );
        when(budgetService.getOverview(eq(userId))).thenReturn(overview);

        mockMvc.perform(get("/budgets/overview")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].montantBudget").value(1200.00))
                .andExpect(jsonPath("$.items[0].montantBudgetNormalise").value(100.00))
                .andExpect(jsonPath("$.items[0].frequence").value("ANNUEL"));
    }

    // --- US3 History tests ---

    @Test
    void should_return_history_for_past_month() throws Exception {
        var item = new BudgetHistoryItemResponse(
                categoryId, "Alimentation", "\uD83C\uDF54", "#FF5733",
                new BigDecimal("500.00"), "EUR", BigDecimal.ONE,
                new BigDecimal("350.00"), new BigDecimal("70.00"),
                LocalDateTime.of(2026, 2, 1, 0, 0)
        );
        var history = new BudgetHistoryResponse(
                "2026-02",
                new BigDecimal("500.00"),
                new BigDecimal("350.00"),
                new BigDecimal("70.00"),
                "EUR",
                List.of(item),
                List.of(),
                BigDecimal.ZERO
        );
        when(budgetService.getHistory(eq("2026-02"), eq(userId))).thenReturn(history);

        mockMvc.perform(get("/budgets/history")
                        .header("Authorization", BEARER_TOKEN)
                        .param("month", "2026-02"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.month").value("2026-02"))
                .andExpect(jsonPath("$.totalBudget").value(500.00))
                .andExpect(jsonPath("$.totalSpent").value(350.00))
                .andExpect(jsonPath("$.percentage").value(70.00))
                .andExpect(jsonPath("$.items[0].categoryNom").value("Alimentation"));
    }

    @Test
    void should_return_400_for_current_month() throws Exception {
        when(budgetService.getHistory(eq("2026-03"), eq(userId)))
                .thenThrow(new IllegalArgumentException("Seuls les mois passés sont autorisés"));

        mockMvc.perform(get("/budgets/history")
                        .header("Authorization", BEARER_TOKEN)
                        .param("month", "2026-03"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Seuls les mois passés sont autorisés"));
    }

    @Test
    void should_return_400_for_invalid_month_format() throws Exception {
        when(budgetService.getHistory(eq("invalid"), eq(userId)))
                .thenThrow(new IllegalArgumentException("Format de mois invalide. Utilisez YYYY-MM"));

        mockMvc.perform(get("/budgets/history")
                        .header("Authorization", BEARER_TOKEN)
                        .param("month", "invalid"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Format de mois invalide. Utilisez YYYY-MM"));
    }
}
