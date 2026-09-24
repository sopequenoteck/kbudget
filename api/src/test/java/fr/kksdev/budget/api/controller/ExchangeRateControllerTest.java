package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.response.ExchangeRateResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.ExchangeRateService;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ExchangeRateController.class)
@Import(SecurityConfig.class)
class ExchangeRateControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ExchangeRateService exchangeRateService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID rateId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmailAndDisabledAtIsNull("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    @Test
    void should_returnEmptyList_when_noRates() throws Exception {
        when(exchangeRateService.getAll(userId)).thenReturn(List.of());

        mockMvc.perform(get("/v1/exchange-rates")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void should_createRate_when_validUpsert() throws Exception {
        var response = new ExchangeRateResponse(rateId, "EUR", "XOF", new BigDecimal("655.957000"), LocalDateTime.now());
        when(exchangeRateService.upsert(any(), eq(userId))).thenReturn(response);

        mockMvc.perform(put("/v1/exchange-rates")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "baseCurrency": "EUR",
                                  "targetCurrency": "XOF",
                                  "rate": "655.957000"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.baseCurrency").value("EUR"))
                .andExpect(jsonPath("$.targetCurrency").value("XOF"))
                .andExpect(jsonPath("$.rate").value(655.957));
    }

    @Test
    void should_updateRate_when_existingPair() throws Exception {
        var response = new ExchangeRateResponse(rateId, "EUR", "XOF", new BigDecimal("660.000000"), LocalDateTime.now());
        when(exchangeRateService.upsert(any(), eq(userId))).thenReturn(response);

        mockMvc.perform(put("/v1/exchange-rates")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "baseCurrency": "EUR",
                                  "targetCurrency": "XOF",
                                  "rate": "660.000000"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(rateId.toString()))
                .andExpect(jsonPath("$.rate").value(660.0));
    }

    @Test
    void should_deleteRate_when_exists() throws Exception {
        doNothing().when(exchangeRateService).delete(userId, Currency.EUR, Currency.XOF);

        mockMvc.perform(delete("/v1/exchange-rates/EUR/XOF")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_return404_when_deletingNonExistent() throws Exception {
        doThrow(new EntityNotFoundException("Exchange rate not found"))
                .when(exchangeRateService).delete(userId, Currency.EUR, Currency.XOF);

        mockMvc.perform(delete("/v1/exchange-rates/EUR/XOF")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Exchange rate not found"));
    }

    @Test
    void should_return400_when_rateNegative() throws Exception {
        mockMvc.perform(put("/v1/exchange-rates")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "baseCurrency": "EUR",
                                  "targetCurrency": "XOF",
                                  "rate": "-1.000000"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return400_when_sameCurrency() throws Exception {
        doThrow(new IllegalArgumentException("Base and target currencies must be different"))
                .when(exchangeRateService).upsert(any(), eq(userId));

        mockMvc.perform(put("/v1/exchange-rates")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "baseCurrency": "EUR",
                                  "targetCurrency": "EUR",
                                  "rate": "1.000000"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Base and target currencies must be different"));
    }
}
