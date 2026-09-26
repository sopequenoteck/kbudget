package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserPreferenceRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration test pour {@code DELETE /users/me/preferences/language} (KKS-380).
 *
 * <p>Remet la preference de langue de l'utilisateur authentifie a {@code null}
 * (« automatique » : le client suit la langue du navigateur).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class PreferenceLanguageResetIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserPreferenceRepository userPreferenceRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        jdbcTemplate.execute("DELETE FROM user_preferences");
        jdbcTemplate.execute("DELETE FROM refresh_tokens");
        jdbcTemplate.execute("DELETE FROM users");
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
    }

    private User createUser(String email) {
        User user = User.builder()
                .email(email)
                .password(passwordEncoder.encode("Pass123456!"))
                .name("User")
                .isAdmin(false)
                .passwordResetRequired(false)
                .build();
        return userRepository.save(user);
    }

    private String jwtFor(User user) {
        return jwtUtil.generateToken(user.getEmail());
    }

    @Test
    void should_return204_when_resettingLanguage() throws Exception {
        User user = createUser("user@test.com");
        String jwt = jwtFor(user);

        mockMvc.perform(delete("/v1/users/me/preferences/language")
                        .header("Authorization", "Bearer " + jwt))
                .andExpect(status().isNoContent());
    }

    @Test
    void should_returnNullLanguage_when_gettingPreferencesAfterReset() throws Exception {
        User user = createUser("user@test.com");
        String jwt = jwtFor(user);

        mockMvc.perform(put("/v1/users/me/preferences")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS"], "language": "fr"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.language").value("fr"));

        mockMvc.perform(delete("/v1/users/me/preferences/language")
                        .header("Authorization", "Bearer " + jwt))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/v1/users/me/preferences")
                        .header("Authorization", "Bearer " + jwt))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.language").value(org.hamcrest.Matchers.nullValue()));
    }

    @Test
    void should_return401_when_noTokenOnDeleteLanguage() throws Exception {
        mockMvc.perform(delete("/v1/users/me/preferences/language"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void should_notAffectOtherUser_when_resettingLanguage() throws Exception {
        User user = createUser("user@test.com");
        User otherUser = createUser("other@test.com");
        String jwt = jwtFor(user);
        String otherJwt = jwtFor(otherUser);

        mockMvc.perform(put("/v1/users/me/preferences")
                        .header("Authorization", "Bearer " + otherJwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"enabledFeatures": ["SUBSCRIPTIONS"], "language": "en"}
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(delete("/v1/users/me/preferences/language")
                        .header("Authorization", "Bearer " + jwt))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/v1/users/me/preferences")
                        .header("Authorization", "Bearer " + otherJwt))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.language").value("en"));

        var otherPreference = userPreferenceRepository.findByUserId(otherUser.getId()).orElseThrow();
        assertThat(otherPreference.getLanguage()).isEqualTo("en");
    }
}
