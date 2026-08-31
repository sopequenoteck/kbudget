package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.dto.request.FirstLoginResetRequest;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.runner.AdminSyncRunner;
import fr.kksdev.budget.api.service.UserOnboardingService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@TestPropertySource(properties = "app.admin-emails=foo@bar.com")
class AuthControllerFirstLoginResetIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private AdminSyncRunner adminSyncRunner;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        jdbcTemplate.execute("DELETE FROM refresh_tokens");
        jdbcTemplate.execute("DELETE FROM users");
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
    }

    private User createUserWithResetFlag(String email, String rawPassword) {
        User user = User.builder()
                .email(email)
                .password(passwordEncoder.encode(rawPassword))
                .name("Admin")
                .isAdmin(true)
                .passwordResetRequired(true)
                .build();
        return userRepository.save(user);
    }

    private User createNormalUser(String email, String rawPassword) {
        User user = User.builder()
                .email(email)
                .password(passwordEncoder.encode(rawPassword))
                .name("User")
                .isAdmin(false)
                .passwordResetRequired(false)
                .build();
        return userRepository.save(user);
    }

    private String generateResetJwt(String email) {
        return jwtUtil.generateToken(email, Map.of("mustResetCredentials", true));
    }

    private String generateNormalJwt(String email) {
        return jwtUtil.generateToken(email);
    }

    // ---- TC-1 : Reset réussi ----

    @Test
    void should_reset_credentials_and_return_new_jwt_when_all_valid() throws Exception {
        User user = createUserWithResetFlag("admin@test.com", "OldPass123!");
        String jwt = generateResetJwt(user.getEmail());

        var request = new FirstLoginResetRequest("newadmin@test.com", "NewPass4567890!", "New Name");

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mustResetCredentials").value(false))
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.email").value("newadmin@test.com"));

        User updated = userRepository.findById(user.getId()).orElseThrow();
        assertThat(updated.isPasswordResetRequired()).isFalse();
        assertThat(updated.getEmail()).isEqualTo("newadmin@test.com");
        assertThat(updated.getName()).isEqualTo("New Name");
    }

    // ---- TC-2 : Password inchangé → 400 ----

    @Test
    void should_return_400_when_password_is_unchanged() throws Exception {
        User user = createUserWithResetFlag("admin@test.com", "SamePass123!");
        String jwt = generateResetJwt(user.getEmail());

        var request = new FirstLoginResetRequest("admin@test.com", "SamePass123!", "Admin");

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("PASSWORD_UNCHANGED"));
    }

    // ---- TC-3 : Email invalide → 400 Bean Validation ----

    @Test
    void should_return_400_when_email_is_invalid() throws Exception {
        User user = createUserWithResetFlag("admin@test.com", "OldPass123!");
        String jwt = generateResetJwt(user.getEmail());

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"not-an-email\",\"password\":\"NewPass456!\",\"displayName\":\"Admin\"}"))
                .andExpect(status().isBadRequest());
    }

    // ---- TC-4 : Password trop court → 400 Bean Validation ----

    @Test
    void should_return_400_when_password_is_too_short() throws Exception {
        User user = createUserWithResetFlag("admin@test.com", "OldPass123!");
        String jwt = generateResetJwt(user.getEmail());

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"admin@test.com\",\"password\":\"short\",\"displayName\":\"Admin\"}"))
                .andExpect(status().isBadRequest());
    }

    // ---- TC-5 : displayName manquant → 400 Bean Validation ----

    @Test
    void should_return_400_when_displayName_is_missing() throws Exception {
        User user = createUserWithResetFlag("admin@test.com", "OldPass123!");
        String jwt = generateResetJwt(user.getEmail());

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"admin@test.com\",\"password\":\"NewPass456!\",\"displayName\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    // ---- TC-6 : Flag déjà false → 403 ----

    @Test
    void should_return_403_with_PASSWORD_RESET_NOT_REQUIRED_payload_when_flag_is_already_false() throws Exception {
        User user = createNormalUser("user@test.com", "Pass123456!");
        // JWT sans le claim mustResetCredentials
        String jwt = generateNormalJwt(user.getEmail());

        var request = new FirstLoginResetRequest("user@test.com", "NewPass4567890!", "User");

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("PASSWORD_RESET_NOT_REQUIRED"))
                .andExpect(jsonPath("$.message").exists());
    }

    // ---- TC-7 : Email déjà utilisé par un autre user → 409 ----

    @Test
    void should_return_409_when_email_already_used_by_another_user() throws Exception {
        User admin = createUserWithResetFlag("admin@test.com", "OldPass123!");
        createNormalUser("taken@test.com", "AnotherPass1!");

        String jwt = generateResetJwt(admin.getEmail());
        var request = new FirstLoginResetRequest("taken@test.com", "NewPass4567890!", "Admin");

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("EMAIL_ALREADY_EXISTS"));
    }

    // ---- TC-8 : Conserver le même email → pas de conflit ----

    @Test
    void should_allow_reset_when_keeping_same_email() throws Exception {
        User user = createUserWithResetFlag("admin@test.com", "OldPass123!");
        String jwt = generateResetJwt(user.getEmail());

        var request = new FirstLoginResetRequest("admin@test.com", "NewPass4567890!", "Admin");

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mustResetCredentials").value(false));

        User updated = userRepository.findById(user.getId()).orElseThrow();
        assertThat(updated.isPasswordResetRequired()).isFalse();
    }

    // ---- TC-9 : JWT avec claim bloque les autres routes, mais autorise reset endpoint ----

    @Test
    void should_block_protected_endpoint_with_reset_jwt_and_allow_reset_endpoint() throws Exception {
        User user = createUserWithResetFlag("admin@test.com", "OldPass123!");
        String jwt = generateResetJwt(user.getEmail());

        // Endpoint protégé → 403 car JWT porte mustResetCredentials=true
        mockMvc.perform(get("/v1/users/me")
                        .header("Authorization", "Bearer " + jwt))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("PASSWORD_RESET_REQUIRED"))
                .andExpect(jsonPath("$.message").isNotEmpty())
                .andExpect(jsonPath("$.length()").value(2));

        // Reset endpoint → 200 OK malgré le claim
        var request = new FirstLoginResetRequest("admin@test.com", "NewPass4567890!", "Admin");
        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + jwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());
    }

    // ---- TC-10 : Sans JWT → 401 ----

    @Test
    void should_return_401_when_no_jwt() throws Exception {
        var request = new FirstLoginResetRequest("admin@test.com", "NewPass4567890!", "Admin");

        mockMvc.perform(post("/v1/auth/first-login-reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("UNAUTHENTICATED"))
                .andExpect(jsonPath("$.message").value("Authentification requise"))
                .andExpect(jsonPath("$.length()").value(2));
    }

    // ---- TC-11 : Préservation admin après reset vers email absent de ADMIN_EMAILS (SC-005) ----

    @Test
    void should_preserve_admin_access_after_reset_to_email_not_in_ADMIN_EMAILS() throws Exception {
        // 1. kelly@exemple.com n'est pas dans ADMIN_EMAILS (seul foo@bar.com l'est — @TestPropertySource)

        // 2. Créer un user admin seed avec passwordResetRequired=true (simule le bootstrap)
        String initialPassword = "BootstrapPass123!";
        User seedAdmin = createUserWithResetFlag("admin@localhost", initialPassword);

        // 3. Login avec admin@localhost + password initial
        String loginBody = objectMapper.writeValueAsString(
                Map.of("email", "admin@localhost", "password", initialPassword));

        String loginResponse = mockMvc.perform(post("/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mustResetCredentials").value(true))
                .andReturn().getResponse().getContentAsString();

        String resetToken = objectMapper.readTree(loginResponse).get("token").asText();

        // 5. POST /auth/first-login-reset avec le nouvel email kelly@exemple.com
        var resetRequest = new FirstLoginResetRequest("kelly@exemple.com", "NouveauMotFort123!", "Kelly");

        String resetResponse = mockMvc.perform(post("/v1/auth/first-login-reset")
                        .header("Authorization", "Bearer " + resetToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(resetRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mustResetCredentials").value(false))
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.email").value("kelly@exemple.com"))
                .andReturn().getResponse().getContentAsString();

        String newToken = objectMapper.readTree(resetResponse).get("token").asText();

        // 6. Accéder à GET /admin/users avec le nouveau token → 200 (admin préservé)
        mockMvc.perform(get("/v1/admin/users")
                        .header("Authorization", "Bearer " + newToken))
                .andExpect(status().isOk());

        // 7. Simuler un redémarrage : appeler AdminSyncRunner.run() manuellement
        //    (ADMIN_EMAILS=foo@bar.com ne contient pas kelly@exemple.com)
        adminSyncRunner.run(new DefaultApplicationArguments());

        // Vérifier que isAdmin reste true en DB après la simulation de redémarrage
        User afterRestart = userRepository.findByEmail("kelly@exemple.com").orElseThrow();
        assertThat(afterRestart.isAdmin()).isTrue();
        assertThat(afterRestart.isPasswordResetRequired()).isFalse();

        // 8. Re-login avec kelly@exemple.com pour obtenir un JWT frais (post-restart)
        String reloginBody = objectMapper.writeValueAsString(
                Map.of("email", "kelly@exemple.com", "password", "NouveauMotFort123!"));

        String reloginResponse = mockMvc.perform(post("/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reloginBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mustResetCredentials").value(false))
                .andReturn().getResponse().getContentAsString();

        String freshToken = objectMapper.readTree(reloginResponse).get("token").asText();

        // 9. Appeler GET /admin/users avec le token frais → 200 OK
        mockMvc.perform(get("/v1/admin/users")
                        .header("Authorization", "Bearer " + freshToken))
                .andExpect(status().isOk());
    }
}
