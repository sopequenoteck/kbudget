package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.SubscriptionRequest;
import fr.kksdev.budget.api.dto.response.SubscriptionPaymentResponse;
import fr.kksdev.budget.api.dto.response.SubscriptionResponse;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.SubscriptionPaymentService;
import fr.kksdev.budget.api.service.SubscriptionService;
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
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(SubscriptionController.class)
@Import(SecurityConfig.class)
class SubscriptionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private SubscriptionService subscriptionService;

    @MockitoBean
    private SubscriptionPaymentService subscriptionPaymentService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID subscriptionId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private String subscriptionJson(String nom, String montant, String frequence, String dateDebut) {
        return """
                {
                    "nom": "%s",
                    "montant": %s,
                    "frequence": "%s",
                    "dateDebut": "%s"
                }
                """.formatted(nom, montant, frequence, dateDebut);
    }

    @Test
    void should_return_201_when_create_subscription() throws Exception {
        var response = new SubscriptionResponse(
                subscriptionId, "Netflix", new BigDecimal("13.99"),
                Frequency.MENSUEL, LocalDate.of(2026, 1, 1), true, null, null, "EUR");

        when(subscriptionService.create(any(SubscriptionRequest.class), any(UUID.class))).thenReturn(response);

        mockMvc.perform(post("/subscriptions")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(subscriptionJson("Netflix", "13.99", "MENSUEL", "2026-01-01")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.nom").value("Netflix"))
                .andExpect(jsonPath("$.actif").value(true));
    }

    @Test
    void should_return_200_when_get_all_subscriptions() throws Exception {
        var response = new SubscriptionResponse(
                subscriptionId, "Netflix", new BigDecimal("13.99"),
                Frequency.MENSUEL, LocalDate.of(2026, 1, 1), true, null, null, "EUR");

        when(subscriptionService.getAllByUser(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/subscriptions")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nom").value("Netflix"));
    }

    @Test
    void should_return_200_when_get_active_subscriptions() throws Exception {
        var response = new SubscriptionResponse(
                subscriptionId, "Netflix", new BigDecimal("13.99"),
                Frequency.MENSUEL, LocalDate.of(2026, 1, 1), true, null, null, "EUR");

        when(subscriptionService.getActiveByUser(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/subscriptions")
                        .param("actif", "true")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].actif").value(true));
    }

    @Test
    void should_return_200_when_get_subscription_by_id() throws Exception {
        var response = new SubscriptionResponse(
                subscriptionId, "Netflix", new BigDecimal("13.99"),
                Frequency.MENSUEL, LocalDate.of(2026, 1, 1), true, null, null, "EUR");

        when(subscriptionService.getById(subscriptionId, userId)).thenReturn(response);

        mockMvc.perform(get("/subscriptions/{id}", subscriptionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nom").value("Netflix"));
    }

    @Test
    void should_return_200_when_update_subscription() throws Exception {
        var response = new SubscriptionResponse(
                subscriptionId, "Spotify", new BigDecimal("9.99"),
                Frequency.MENSUEL, LocalDate.of(2026, 2, 1), true, null, null, "EUR");

        when(subscriptionService.update(eq(subscriptionId), any(SubscriptionRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/subscriptions/{id}", subscriptionId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(subscriptionJson("Spotify", "9.99", "MENSUEL", "2026-02-01")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nom").value("Spotify"));
    }

    @Test
    void should_return_204_when_delete_subscription() throws Exception {
        doNothing().when(subscriptionService).delete(subscriptionId, userId);

        mockMvc.perform(delete("/subscriptions/{id}", subscriptionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return_404_when_subscription_not_found() throws Exception {
        when(subscriptionService.getById(subscriptionId, userId))
                .thenThrow(new EntityNotFoundException("Abonnement non trouvé"));

        mockMvc.perform(get("/subscriptions/{id}", subscriptionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Abonnement non trouvé"));
    }

    @Test
    void should_return_400_when_create_with_missing_fields() throws Exception {
        mockMvc.perform(post("/subscriptions")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return201_when_paySubscription() throws Exception {
        var paymentResponse = new SubscriptionPaymentResponse(
                UUID.randomUUID(), new BigDecimal("13.99"), LocalDate.of(2026, 3, 14),
                "Netflix", "Compte Principal");

        when(subscriptionPaymentService.pay(eq(subscriptionId), any(UUID.class))).thenReturn(paymentResponse);

        mockMvc.perform(post("/subscriptions/{id}/pay", subscriptionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.subscriptionName").value("Netflix"))
                .andExpect(jsonPath("$.accountName").value("Compte Principal"))
                .andExpect(jsonPath("$.montant").value(13.99));
    }

    @Test
    void should_return400_when_payInactiveSubscription() throws Exception {
        when(subscriptionPaymentService.pay(eq(subscriptionId), any(UUID.class)))
                .thenThrow(new IllegalStateException("L'abonnement est inactif"));

        mockMvc.perform(post("/subscriptions/{id}/pay", subscriptionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return404_when_payNonexistentSubscription() throws Exception {
        when(subscriptionPaymentService.pay(eq(subscriptionId), any(UUID.class)))
                .thenThrow(new EntityNotFoundException("Abonnement non trouvé"));

        mockMvc.perform(post("/subscriptions/{id}/pay", subscriptionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Abonnement non trouvé"));
    }

    @Test
    void should_return200_when_getPayments() throws Exception {
        var paymentResponse = new SubscriptionPaymentResponse(
                UUID.randomUUID(), new BigDecimal("13.99"), LocalDate.of(2026, 3, 14),
                "Netflix", "Compte Principal");

        when(subscriptionPaymentService.getPayments(eq(subscriptionId), any(UUID.class)))
                .thenReturn(List.of(paymentResponse));

        mockMvc.perform(get("/subscriptions/{id}/payments", subscriptionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].subscriptionName").value("Netflix"))
                .andExpect(jsonPath("$[0].montant").value(13.99));
    }

    @Test
    void should_return200_when_getTotalPaid() throws Exception {
        var totalResponse = Map.<String, Object>of(
                "subscriptionId", subscriptionId,
                "subscriptionName", "Netflix",
                "totalPaid", new BigDecimal("27.98"),
                "paymentCount", 2L);

        when(subscriptionPaymentService.getTotalPaid(eq(subscriptionId), any(UUID.class)))
                .thenReturn(totalResponse);

        mockMvc.perform(get("/subscriptions/{id}/payments/total", subscriptionId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subscriptionName").value("Netflix"))
                .andExpect(jsonPath("$.paymentCount").value(2));
    }
}
