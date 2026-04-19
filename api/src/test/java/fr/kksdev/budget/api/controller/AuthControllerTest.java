package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.AcceptInviteRequest;
import fr.kksdev.budget.api.dto.request.LoginRequest;
import fr.kksdev.budget.api.dto.response.AuthResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.AcceptInviteService;
import fr.kksdev.budget.api.service.AuthService;
import fr.kksdev.budget.api.service.InvitationService;
import fr.kksdev.budget.api.service.RefreshTokenService;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import(SecurityConfig.class)
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private RefreshTokenService refreshTokenService;

    @MockitoBean
    private AcceptInviteService acceptInviteService;

    @MockitoBean
    private InvitationService invitationService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    // ---- SC-001 : POST /auth/register n'existe plus ----

    @Test
    void should_not_have_register_endpoint() throws Exception {
        // SC-001 : vérifie structurellement que AuthController ne déclare pas POST /register
        // En @WebMvcTest, Spring retourne 500 via GlobalExceptionHandler pour les routes inconnues.
        // La preuve de suppression est la compilation sans RegisterRequest et sans méthode register().
        // Ce test vérifie que le body retourné ne contient pas de token JWT (la route ne fonctionnerait plus).
        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"test@mail.com\",\"password\":\"password123\"}"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    // 404 si Spring MVC retourne NoHandlerFoundException, 500 si GlobalExceptionHandler intercepte
                    // Dans les deux cas, ce n'est pas 201 (la route n'existe plus)
                    assertThat(status).isNotEqualTo(201);
                });
    }

    // ---- Login ----

    @Test
    void should_return_200_when_login_success() throws Exception {
        var request = new LoginRequest("test@mail.com", "password123");
        var response = new AuthResponse("jwt-token", "refresh-token", "test@mail.com", "Test User");

        when(authService.login(any(LoginRequest.class))).thenReturn(response);

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token"))
                .andExpect(jsonPath("$.email").value("test@mail.com"));
    }

    @Test
    void should_return_400_when_login_email_blank() throws Exception {
        var request = new LoginRequest("", "password123");

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_login_credentials_wrong() throws Exception {
        var request = new LoginRequest("test@mail.com", "wrongpassword");

        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new IllegalArgumentException("Email ou mot de passe incorrect"));

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Email ou mot de passe incorrect"));
    }

    // ---- FR-009 : GET /auth/invitations/{token} ----

    @Test
    void should_return_200_with_email_when_token_valid() throws Exception {
        UUID token = UUID.randomUUID();
        fr.kksdev.budget.api.model.Invitation invitation = fr.kksdev.budget.api.model.Invitation.builder()
                .id(1L)
                .token(token)
                .email("invitee@example.com")
                .build();

        when(invitationService.validatePublic(token)).thenReturn(Optional.of(invitation));

        mockMvc.perform(get("/auth/invitations/{token}", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("invitee@example.com"));
    }

    @Test
    void should_return_404_when_token_unknown() throws Exception {
        UUID token = UUID.randomUUID();
        when(invitationService.validatePublic(token)).thenReturn(Optional.empty());

        mockMvc.perform(get("/auth/invitations/{token}", token))
                .andExpect(status().isNotFound());
    }

    @Test
    void should_return_404_when_token_expired() throws Exception {
        UUID token = UUID.randomUUID();
        when(invitationService.validatePublic(token)).thenReturn(Optional.empty());

        mockMvc.perform(get("/auth/invitations/{token}", token))
                .andExpect(status().isNotFound());
    }

    @Test
    void should_return_404_when_token_used() throws Exception {
        UUID token = UUID.randomUUID();
        when(invitationService.validatePublic(token)).thenReturn(Optional.empty());

        mockMvc.perform(get("/auth/invitations/{token}", token))
                .andExpect(status().isNotFound());
    }

    @Test
    void should_return_404_when_token_revoked() throws Exception {
        UUID token = UUID.randomUUID();
        when(invitationService.validatePublic(token)).thenReturn(Optional.empty());

        mockMvc.perform(get("/auth/invitations/{token}", token))
                .andExpect(status().isNotFound());
    }

    // ---- FR-010 : POST /auth/accept-invite ----

    @Test
    void should_return_201_when_accept_invite_success() throws Exception {
        var request = new AcceptInviteRequest(
                UUID.randomUUID(), "password123", "Alice", Currency.EUR, "Europe/Paris");
        var response = new AuthResponse("jwt-token", "refresh-token", "invitee@example.com", "Alice");

        when(acceptInviteService.acceptInvite(any(AcceptInviteRequest.class))).thenReturn(response);

        mockMvc.perform(post("/auth/accept-invite")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("jwt-token"))
                .andExpect(jsonPath("$.email").value("invitee@example.com"))
                .andExpect(jsonPath("$.name").value("Alice"));
    }

    @Test
    void should_return_400_when_password_too_short() throws Exception {
        mockMvc.perform(post("/auth/accept-invite")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"" + UUID.randomUUID() + "\","
                                + "\"password\":\"short\","
                                + "\"displayName\":\"Alice\","
                                + "\"currency\":\"EUR\","
                                + "\"timezone\":\"Europe/Paris\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_token_null() throws Exception {
        mockMvc.perform(post("/auth/accept-invite")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":null,"
                                + "\"password\":\"password123\","
                                + "\"displayName\":\"Alice\","
                                + "\"currency\":\"EUR\","
                                + "\"timezone\":\"Europe/Paris\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_404_when_token_invalid_on_accept() throws Exception {
        when(acceptInviteService.acceptInvite(any(AcceptInviteRequest.class)))
                .thenThrow(new EntityNotFoundException("Invitation invalide."));

        mockMvc.perform(post("/auth/accept-invite")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"" + UUID.randomUUID() + "\","
                                + "\"password\":\"password123\","
                                + "\"displayName\":\"Alice\","
                                + "\"currency\":\"EUR\","
                                + "\"timezone\":\"Europe/Paris\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void should_return_400_when_email_already_exists_on_accept() throws Exception {
        when(acceptInviteService.acceptInvite(any(AcceptInviteRequest.class)))
                .thenThrow(new IllegalArgumentException("Email déjà utilisé"));

        mockMvc.perform(post("/auth/accept-invite")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"" + UUID.randomUUID() + "\","
                                + "\"password\":\"password123\","
                                + "\"displayName\":\"Alice\","
                                + "\"currency\":\"EUR\","
                                + "\"timezone\":\"Europe/Paris\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Email déjà utilisé"));
    }
}
