package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.response.UserPreferenceResponse;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.PreferenceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(PreferenceController.class)
@Import(SecurityConfig.class)
class PreferenceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PreferenceService preferenceService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    // === US1: GET /users/me/preferences ===

    @Test
    void should_return200WithDefaultPreferences_when_noCustomPreferences() throws Exception {
        var response = new UserPreferenceResponse(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP)
        );
        when(preferenceService.getPreferences(userId)).thenReturn(response);

        mockMvc.perform(get("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabledFeatures.length()").value(3))
                .andExpect(jsonPath("$.enabledFeatures[0]").value("SUBSCRIPTIONS"))
                .andExpect(jsonPath("$.enabledFeatures[1]").value("DEBTS"))
                .andExpect(jsonPath("$.enabledFeatures[2]").value("SHOP"))
                .andExpect(jsonPath("$.navOrder.length()").value(3))
                .andExpect(jsonPath("$.navOrder[0]").value("SUBSCRIPTIONS"));
    }

    @Test
    void should_return200WithCustomPreferences_when_preferencesExist() throws Exception {
        var response = new UserPreferenceResponse(
                List.of(Feature.SUBSCRIPTIONS, Feature.SHOP),
                List.of(Feature.SHOP, Feature.SUBSCRIPTIONS)
        );
        when(preferenceService.getPreferences(userId)).thenReturn(response);

        mockMvc.perform(get("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabledFeatures.length()").value(2))
                .andExpect(jsonPath("$.enabledFeatures[0]").value("SUBSCRIPTIONS"))
                .andExpect(jsonPath("$.enabledFeatures[1]").value("SHOP"))
                .andExpect(jsonPath("$.navOrder[0]").value("SHOP"))
                .andExpect(jsonPath("$.navOrder[1]").value("SUBSCRIPTIONS"));
    }

    @Test
    void should_return401_when_noTokenOnGet() throws Exception {
        mockMvc.perform(get("/users/me/preferences"))
                .andExpect(status().isUnauthorized());
    }

    // === US2: PUT /users/me/preferences (toggle features) ===

    @Test
    void should_return200_when_toggleFeaturesWithoutNavOrder() throws Exception {
        var response = new UserPreferenceResponse(
                List.of(Feature.SUBSCRIPTIONS, Feature.SHOP),
                List.of(Feature.SUBSCRIPTIONS, Feature.SHOP)
        );
        when(preferenceService.updatePreferences(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS", "SHOP"]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabledFeatures.length()").value(2))
                .andExpect(jsonPath("$.navOrder.length()").value(2));
    }

    @Test
    void should_return200_when_disableAllFeatures() throws Exception {
        var response = new UserPreferenceResponse(List.of(), List.of());
        when(preferenceService.updatePreferences(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": []}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabledFeatures.length()").value(0))
                .andExpect(jsonPath("$.navOrder.length()").value(0));
    }

    @Test
    void should_return400_when_unknownFeature() throws Exception {
        mockMvc.perform(put("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS", "UNKNOWN_FEATURE"]}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return401_when_noTokenOnPut() throws Exception {
        mockMvc.perform(put("/users/me/preferences")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS"]}
                                """))
                .andExpect(status().isUnauthorized());
    }

    // === US3: PUT /users/me/preferences (reorder) ===

    @Test
    void should_return200_when_validNavOrderProvided() throws Exception {
        var response = new UserPreferenceResponse(
                List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP),
                List.of(Feature.SHOP, Feature.DEBTS, Feature.SUBSCRIPTIONS)
        );
        when(preferenceService.updatePreferences(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS", "DEBTS", "SHOP"], "navOrder": ["SHOP", "DEBTS", "SUBSCRIPTIONS"]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.navOrder[0]").value("SHOP"))
                .andExpect(jsonPath("$.navOrder[1]").value("DEBTS"))
                .andExpect(jsonPath("$.navOrder[2]").value("SUBSCRIPTIONS"));
    }

    @Test
    void should_return400_when_navOrderHasDuplicates() throws Exception {
        when(preferenceService.updatePreferences(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.eq(userId)))
                .thenThrow(new IllegalArgumentException("L'ordre de navigation ne doit pas contenir de doublons"));

        mockMvc.perform(put("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS", "DEBTS"], "navOrder": ["SUBSCRIPTIONS", "SUBSCRIPTIONS"]}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("L'ordre de navigation ne doit pas contenir de doublons"));
    }

    @Test
    void should_return400_when_navOrderMissingEnabledFeature() throws Exception {
        when(preferenceService.updatePreferences(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.eq(userId)))
                .thenThrow(new IllegalArgumentException("L'ordre de navigation doit contenir exactement les fonctionnalités activées"));

        mockMvc.perform(put("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS", "DEBTS"], "navOrder": ["SUBSCRIPTIONS"]}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("L'ordre de navigation doit contenir exactement les fonctionnalités activées"));
    }

    @Test
    void should_return400_when_navOrderContainsDisabledFeature() throws Exception {
        when(preferenceService.updatePreferences(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.eq(userId)))
                .thenThrow(new IllegalArgumentException("L'ordre de navigation doit contenir exactement les fonctionnalités activées"));

        mockMvc.perform(put("/users/me/preferences")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS"], "navOrder": ["SUBSCRIPTIONS", "DEBTS"]}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("L'ordre de navigation doit contenir exactement les fonctionnalités activées"));
    }
}
